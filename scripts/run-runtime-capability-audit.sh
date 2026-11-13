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
output="$($noxc_bin run --backend "$backend" tests/capability/runtime_divergence_probe.nox)"
printf '%s\n' "$output"

grep -Fxq "char_from_byte_nul_byte_len 1" <<<"$output"
grep -Fxq "embedded_nul_byte_len 3" <<<"$output"
grep -Fxq "embedded_nul_middle_byte 0" <<<"$output"
grep -Fxq "json_retains_after_nul True" <<<"$output"
grep -Fxq "json_escapes_nul True" <<<"$output"

grep -Fxq "parsed_nan_self_inequality True" <<<"$output"
grep -Fxq "sqrt_nan_self_inequality True" <<<"$output"

grep -Fxq "sqrt_nan_less_than_zero False" <<<"$output"
grep -Fxq "sqrt_nan_less_equal_inf False" <<<"$output"

printf 'pulse runtime capability audit: backend=%s nan-parity=pass nul-byte=pass json-escaping=pass\n' "$backend"
