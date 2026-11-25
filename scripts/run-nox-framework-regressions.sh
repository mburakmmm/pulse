#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-framework-audit.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

run_probe() {
  local fixture="$1" expected="$2" binary stdout
  cp "$project_root/fixtures/capability/$fixture.nox.txt" "$probe_root/$fixture.nox"
  binary="$probe_root/$fixture"
  "$noxc_bin" check "$probe_root/$fixture.nox"
  "$noxc_bin" build --backend "$backend" -o "$binary" "$probe_root/$fixture.nox"
  if [[ -f "$binary.exe" ]]; then
    binary="$binary.exe"
  fi
  stdout="$("$binary" | tr -d '\r')"
  if [[ "$stdout" != "$expected" ]]; then
    printf 'Unexpected %s output on %s: %s\n' "$fixture" "$backend" "$stdout" >&2
    return 1
  fi
}

run_probe match_case_binding_scope 3
run_probe context_manager_field 42
run_probe cancel_blocked_channel_receive cancelled
printf 'pulse framework regressions: backend=%s match-arm=pass with-field=pass cancelled-channel=pass\n' "$backend"
