#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-prometheus.XXXXXX")"
trap 'rm -rf "$output_root"' EXIT

cd "$project_root"
"$noxc_bin" check exporters/prometheus.nox
"$noxc_bin" test --backend "$backend" tests/unit/prometheus_renderer_test.nox
"$noxc_bin" build --backend "$backend" -o "$output_root/prometheus-golden" tests/golden/prometheus_renderer_golden.nox
"$output_root/prometheus-golden" >"$output_root/prometheus-golden.actual"

if ! cmp -s fixtures/prometheus/text-0.0.4.golden.txt "$output_root/prometheus-golden.actual"; then
  diff -u fixtures/prometheus/text-0.0.4.golden.txt "$output_root/prometheus-golden.actual"
  exit 1
fi

printf 'pulse phase3 renderer tests: backend=%s text_format=0.0.4 pure_renderer=pass escaping=pass counter=pass gauge=pass histogram=pass output_bound=pass golden=pass external_parser=separate-gate endpoint=pending\n' "$backend"
