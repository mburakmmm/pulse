import subprocess
import unittest
from unittest.mock import patch

import codex_policy as policy


class CodexPolicyTest(unittest.TestCase):
    @staticmethod
    def bash(command):
        return {"tool_name": "Bash", "tool_input": {"command": command}}

    @patch.object(policy, "graph_decision", return_value={})
    @patch.object(policy.shutil, "which", return_value="/opt/bin/rtk")
    @patch.object(policy, "run_hook")
    def test_strict_pre_tool_policy(self, run_hook, _which, _graph):
        run_hook.return_value = subprocess.CompletedProcess([], 0, "rtk git status\n")
        result = policy.evaluate("pre", self.bash("git status"))
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertNotIn("updatedInput", result["hookSpecificOutput"])
        for command in ("rtk git status", "rtk bypass git diff", "noxc check code.nox"):
            run_hook.return_value = subprocess.CompletedProcess([], 1, "", f"No rewrite for: {command}\n")
            self.assertEqual(policy.evaluate("pre", self.bash(command)), {})

    @patch.object(policy.shutil, "which", return_value=None)
    def test_missing_rtk_denies_bash(self, _which):
        result = policy.evaluate("pre", self.bash("git status"))
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_session_and_subagent_receive_rules(self):
        for event in ("SessionStart", "SubagentStart"):
            result = policy.evaluate("rules", {"hook_event_name": event})
            self.assertEqual(result["hookSpecificOutput"]["hookEventName"], event)
            self.assertIn("RTK", result["hookSpecificOutput"]["additionalContext"])

    def test_advisory_does_not_echo_tool_output(self):
        result = policy.evaluate("post", {"tool_response": "credential-marker" * 2000})
        self.assertIn("additionalContext", result["hookSpecificOutput"])
        self.assertNotIn("credential-marker", str(result))

    @patch.object(policy.shutil, "which", return_value="/opt/bin/graphify")
    @patch.object(policy, "run_hook")
    def test_graphify_strict_denial_is_adapted(self, run_hook, _which):
        run_hook.return_value = subprocess.CompletedProcess([], 0, '{"decision":"block"}')
        with patch.object(policy, "GRAPH") as graph:
            graph.is_file.return_value = True
            result = policy.evaluate("pre", {"tool_name": "mcp__fs__read_file", "tool_input": {"path": "api/context.nox"}})
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertEqual(run_hook.call_args.args[0][2:], ["read", "--strict"])
        self.assertEqual(run_hook.call_args.args[1]["tool_name"], "Read")
        self.assertEqual(run_hook.call_args.args[1]["tool_input"]["file_path"], "api/context.nox")

    @patch.object(policy.shutil, "which", return_value="/opt/bin/graphify")
    @patch.object(policy, "run_hook")
    def test_compact_refreshes_rules(self, run_hook, _which):
        run_hook.return_value = subprocess.CompletedProcess([], 0, "graph reminder")
        with patch.object(policy, "GRAPH") as graph:
            graph.is_file.return_value = True
            result = policy.evaluate("compact", {"hook_event_name": "PostCompact"})
        self.assertIn("RTK", result["systemMessage"])
        self.assertEqual(run_hook.call_args.args[0][2], "compact")


if __name__ == "__main__":
    unittest.main()
