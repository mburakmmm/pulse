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
done < <(find metrics -type f -name '*.nox' -print | sort)

while IFS= read -r test_file; do
  "$noxc_bin" test --backend "$backend" "$test_file"
done < <(find tests/unit -type f -name 'metrics_*_test.nox' -print | sort)

"$noxc_bin" test --backend "$backend" tests/stress/metrics_cardinality_stress_test.nox

printf 'pulse phase2 tests: backend=%s provider=single-owner-pass instruments=pass counter=pass updown=pass histogram=pass series=pass cardinality=pass stress_100k=pass\n' "$backend"
