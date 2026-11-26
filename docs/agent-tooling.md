# Codex tool policy for Pulse

Pulse provides project hooks for `SessionStart`, `SubagentStart`,
`PostCompact`, `PreToolUse` and `PostToolUse`. They live in
`.codex/hooks.json` and are scoped to trusted Pulse workspaces.

Install RTK and Python 3 on PATH. In a new Pulse session, review the project
hooks using `/hooks` in Codex CLI or **Settings > Hooks** in the desktop app.
Codex requires trust for each new or changed hook definition. Existing
user-level RTK hooks are independent of this project policy.

- Bash commands that RTK can rewrite must use RTK. The project policy emits
  an explicit denial for raw supported commands. It leaves execution and
  approvals to Codex. Missing RTK or a failed RTK check also emits a denial.
- Unsupported commands can run directly. Use `rtk bypass` when exact bytes
  are required or condensed output is unusable.
- Session and subagent hooks inject the same rules. The compaction hook
  restates them. With Graphify installed and a local `graphify-out/graph.json`,
  the discovery hooks run Graphify strict guards and the compaction hook
  invokes its compact guard. Build the local index with
  `graphify update . --no-cluster`. NOX uses Graphify's Python
  language mapping for approximate discovery. Verify findings against source.
- The post-tool hook gives a size-based advisory. It never persists command
  text, tool output or secrets. Hook enforcement applies to tool paths that
  Codex exposes to project hooks. The repository guidance covers the rest.

Run `python3 -m unittest discover -s scripts/hooks -p 'test_*.py'` to check
the hook policy. See the [Codex hooks reference](https://developers.openai.com/codex/hooks/).
