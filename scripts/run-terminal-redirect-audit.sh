#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-terminal-audit.XXXXXX")"
trap 'rm -rf "$output_root"' EXIT

cd "$project_root"
"$noxc_bin" build --backend "$backend" -o "$output_root/terminal-redirect" tests/capability/terminal_redirect_probe.nox
probe_binary="$output_root/terminal-redirect"
if [[ -f "$probe_binary.exe" ]]; then
  probe_binary="$probe_binary.exe"
fi

"$probe_binary" >"$output_root/stdout"
printf 'terminal-redirect-ok\n' >"$output_root/expected"
cmp "$output_root/expected" "$output_root/stdout"
printf 'pulse terminal redirect audit: platform=%s backend=%s write_raw=pass\n' "$(uname -s)" "$backend"
