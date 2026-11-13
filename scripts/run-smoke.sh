#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-smoke.XXXXXX")"
trap 'rm -rf "$output_root"' EXIT

cd "$project_root"
"$noxc_bin" check tests/smoke/project_smoke_test.nox
PULSE_TEST_TMP_DIR="$output_root" "$noxc_bin" test --backend "$backend" tests/smoke
"$noxc_bin" build --backend "$backend" -o "$output_root/project-smoke" tests/smoke/project_smoke_test.nox
smoke_binary="$output_root/project-smoke"
if [[ -f "$smoke_binary.exe" ]]; then
  smoke_binary="$smoke_binary.exe"
fi
"$smoke_binary"

printf 'pulse smoke: backend=%s check=pass tests=pass build=pass run=pass\n' "$backend"

