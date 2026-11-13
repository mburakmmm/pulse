#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-golden.XXXXXX")"
trap 'rm -rf "$output_root"' EXIT

cd "$project_root"
"$noxc_bin" build --backend "$backend" -o "$output_root/attribute-snapshot" tests/golden/attribute_snapshot_golden.nox
golden_binary="$output_root/attribute-snapshot"
if [[ -f "$golden_binary.exe" ]]; then
  golden_binary="$golden_binary.exe"
fi
"$golden_binary" | tr -d '\r' >"$output_root/attribute-snapshot.actual"
diff -u tests/golden/attribute_snapshot.expected "$output_root/attribute-snapshot.actual"

printf 'pulse golden tests: backend=%s attribute_snapshot=pass\n' "$backend"
