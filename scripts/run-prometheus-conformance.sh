#!/usr/bin/env bash
set -euo pipefail

promtool_bin="${PROMTOOL:-promtool}"
expected_version="${PROMETHEUS_VERSION:-3.16.0}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$project_root"
version_output="$("$promtool_bin" --version 2>&1)"
if [[ "$version_output" != *"version $expected_version"* ]]; then
  echo "unexpected promtool version; expected $expected_version" >&2
  echo "$version_output" >&2
  exit 1
fi

"$promtool_bin" check metrics <fixtures/prometheus/text-0.0.4.golden.txt

printf 'pulse Prometheus conformance: promtool=%s text_format=0.0.4 golden=pass endpoint=pending\n' "$expected_version"
