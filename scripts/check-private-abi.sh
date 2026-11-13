#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if rg -n '__nox_|from[[:space:]]+"zig-out/lib/noxrt\.o"' --glob '*.nox' --glob '*.zig' .; then
  echo "private NOX runtime ABI usage is forbidden; use a reviewed public API or documented NNI boundary" >&2
  exit 1
fi

printf 'private ABI check: pass\n'
