#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$project_root"
while IFS= read -r source_file; do
  "$noxc_bin" check "$source_file"
done < <(rg --files api core sdk -g '*.nox' | sort)

"$noxc_bin" test --backend "$backend" tests/unit
"$noxc_bin" test --backend "$backend" tests/security
"$noxc_bin" test --backend "$backend" tests/property
NOXC="$noxc_bin" bash scripts/run-golden-tests.sh "$backend"

printf 'pulse phase1 tests: backend=%s modules=pass unit=pass security=pass property=pass golden=pass\n' "$backend"
