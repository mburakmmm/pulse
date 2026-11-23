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
while IFS= read -r example_file; do
  "$noxc_bin" check "$example_file"
  output="$("$noxc_bin" run --backend "$backend" "$example_file")"
  case "${example_file##*/}" in
    hello_metrics.nox)
      grep -Fxq "checkout.requests total 3" <<<"$output"
      grep -Fxq "checkout.duration count 1" <<<"$output"
      grep -Fxq '# TYPE target_info gauge' <<<"$output"
      grep -Fxq 'target_info{service_name="checkout-example"} 1' <<<"$output"
      grep -Fxq '# TYPE checkout_requests_total counter' <<<"$output"
      grep -Fq 'checkout_duration_milliseconds_count{route="/checkout"} 1' <<<"$output"
      ;;
    hello_traces.nox)
      grep -Fxq "ended span checkout.validate" <<<"$output"
      grep -Fxq "span attributes 1" <<<"$output"
      ;;
    *)
      echo "No output check for example: $example_file" >&2
      exit 1
      ;;
  esac
done < <(find examples -type f -name '*.nox' -print | sort)

printf 'pulse examples: backend=%s compile=pass run=pass\n' "$backend"
