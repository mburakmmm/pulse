"""Project-scoped tool policy for Codex. Never run or persist a tool input."""

import json
from pathlib import Path
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
GRAPH = ROOT / "graphify-out" / "graph.json"
RULES = (
    "Pulse: use RTK for supported Bash commands. Use rtk bypass only when "
    "condensed output is unusable or exact bytes are needed. "
    "Use the project graph for exploration when available and keep reads narrow. "
    "Follow AGENTS.md and verify against the pinned NOX compiler."
)


def decision(reason):
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def run_hook(args, data=None):
    return subprocess.run(
        args, input=json.dumps(data) if data is not None else "",
        capture_output=True, text=True, timeout=4, cwd=ROOT, check=False,
    )


def rtk_decision(command):
    rtk = shutil.which("rtk")
    if rtk is None:
        return decision("Install RTK on PATH before running Bash tools in Pulse.")
    try:
        result = run_hook([rtk, "hook", "check", "--agent", "codex", "--", command])
    except (OSError, subprocess.TimeoutExpired):
        return decision("RTK compatibility check failed. Verify the local RTK installation.")
    line = result.stdout.strip()
    if result.returncode == 1 and (line or result.stderr.strip()).startswith("No rewrite for:"):
        return {}
    if result.returncode != 0 or not line:
        return decision("RTK compatibility check did not return a usable result.")
    if line != command.strip():
        return decision("RTK supports this command. Run it with RTK, or use rtk bypass for an exact-output recovery.")
    return {}


def graph_decision(data):
    graphify = shutil.which("graphify")
    if graphify is None or not GRAPH.is_file():
        return {}
    tool = data.get("tool_name")
    if isinstance(tool, str):
        tool = {"read_file": "Read", "list_directory": "Glob", "search_files": "Grep"}.get(
            tool.rsplit("__", 1)[-1], tool
        )
    action = "read" if tool in ("Read", "Glob") else "search"
    tool_input = data.get("tool_input")
    if isinstance(tool_input, dict) and tool == "Read" and "file_path" not in tool_input:
        tool_input = {**tool_input, "file_path": tool_input.get("path", "")}
    try:
        result = run_hook(
            [graphify, "hook-guard", action, "--strict"],
            {**data, "tool_name": tool, "tool_input": tool_input, "cwd": str(ROOT)},
        )
        if result.returncode == 2:
            return decision("Graphify requires a targeted discovery or read step first.")
        response = json.loads(result.stdout) if result.stdout.strip() else {}
        specific = response.get("hookSpecificOutput", {})
        if response.get("decision") == "block" or specific.get("permissionDecision") == "deny":
            return decision("Graphify requires a targeted discovery or read step first.")
    except (OSError, ValueError, AttributeError, subprocess.TimeoutExpired):
        return {}
    return {}


def compact_context(data):
    graphify = shutil.which("graphify")
    if graphify is not None and GRAPH.is_file():
        try:
            result = run_hook([graphify, "hook-guard", "compact"], data)
            if result.returncode == 0 and result.stdout.strip():
                return {"systemMessage": RULES + " Reuse existing graph findings after compaction."}
        except (OSError, subprocess.TimeoutExpired):
            pass
    return {"systemMessage": RULES}


def evaluate(mode, data):
    if mode == "rules":
        missing = " RTK is missing from PATH." if shutil.which("rtk") is None else ""
        return {"hookSpecificOutput": {
            "hookEventName": data.get("hook_event_name", "SessionStart"),
            "additionalContext": RULES + missing,
        }}
    if mode == "compact":
        return compact_context(data)
    if mode == "post":
        size = len(json.dumps(data.get("tool_response", ""), ensure_ascii=False))
        if size > 20000:
            return {"hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": "Large tool output. Use targeted queries or narrow reads for follow-ups.",
            }}
        return {}
    if mode == "pre":
        if data.get("tool_name") == "Bash":
            args = data.get("tool_input")
            command = args.get("command") if isinstance(args, dict) else None
            if not isinstance(command, str):
                return decision("Bash tool input lacks a command.")
            check = rtk_decision(command)
            if check:
                return check
        return graph_decision(data)
    raise ValueError("unknown hook mode")


if __name__ == "__main__":
    mode = sys.argv[1]
    try:
        data = json.load(sys.stdin)
        output = evaluate(mode, data)
    except (ValueError, AttributeError, UnicodeError):
        output = decision("Pulse could not read the hook input.") if mode == "pre" else {}
    print(json.dumps(output))
