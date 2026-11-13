#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

private_abi_status=0
private_abi_matches="$(grep -ERn --include='*.nox' --include='*.zig' '__nox_|from[[:space:]]+"zig-out/lib/noxrt\.o"' .)" || private_abi_status=$?
if [[ $private_abi_status -gt 1 ]]; then
  echo "private ABI scan failed" >&2
  exit "$private_abi_status"
fi
if [[ -n "$private_abi_matches" ]]; then
  printf '%s\n' "$private_abi_matches"
  echo "private NOX runtime ABI usage is forbidden; use a reviewed public API or documented NNI boundary" >&2
  exit 1
fi

printf 'private ABI check: pass\n'
