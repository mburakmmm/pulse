#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

bash scripts/check-import-boundaries.sh
bash scripts/check-private-abi.sh

for backend in llvm qbe; do
  bash scripts/run-smoke.sh "$backend"
  bash scripts/run-phase1-tests.sh "$backend"
  bash scripts/run-phase2-tests.sh "$backend"
  bash scripts/run-examples.sh "$backend"
done

bash scripts/verify-package-import.sh

printf 'pulse core CI: LLVM=pass QBE=pass package-import=pass\n'
