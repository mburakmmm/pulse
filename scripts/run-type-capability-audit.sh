#!/usr/bin/env bash
set -euo pipefail

noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-type-audit.XXXXXX")"
project_probe=""
project_probe_root=""
trap 'rm -rf "$probe_root"; if [[ -n "${project_probe_root:-}" ]]; then rm -rf "$project_probe_root"; fi' EXIT

cp "$project_root/fixtures/capability/generic_class.nox.txt" "$probe_root/generic_class.nox"
cp "$project_root/fixtures/capability/large_float_literal.nox.txt" "$probe_root/large_float_literal.nox"
cp "$project_root/fixtures/capability/min_int_literal.nox.txt" "$probe_root/min_int_literal.nox"
cp "$project_root/fixtures/capability/nul_escape.nox.txt" "$probe_root/nul_escape.nox"
cp "$project_root/fixtures/capability/pass_only_class.nox.txt" "$probe_root/pass_only_class.nox"
cp "$project_root/fixtures/capability/optional_float_field.nox.txt" "$probe_root/optional_float_field.nox"

"$noxc_bin" check "$probe_root/generic_class.nox"
"$noxc_bin" fmt "$probe_root/generic_class.nox"
"$noxc_bin" check "$probe_root/generic_class.nox"
grep -Fq "class Box[T]:" "$probe_root/generic_class.nox"

"$noxc_bin" check "$probe_root/large_float_literal.nox"
"$noxc_bin" fmt "$probe_root/large_float_literal.nox"
"$noxc_bin" check "$probe_root/large_float_literal.nox"

"$noxc_bin" check "$probe_root/min_int_literal.nox"
"$noxc_bin" fmt "$probe_root/min_int_literal.nox"
"$noxc_bin" check "$probe_root/min_int_literal.nox"

"$noxc_bin" check "$probe_root/nul_escape.nox"
"$noxc_bin" fmt "$probe_root/nul_escape.nox"
"$noxc_bin" check "$probe_root/nul_escape.nox"
file "$probe_root/nul_escape.nox" | grep -Eq ': (ASCII|Unicode) text'
if od -An -tx1 "$probe_root/nul_escape.nox" | grep -qw '00'; then
  echo "formatter wrote a literal NUL byte into source" >&2
  exit 1
fi

"$noxc_bin" check "$probe_root/pass_only_class.nox"
"$noxc_bin" fmt "$probe_root/pass_only_class.nox"
"$noxc_bin" check "$probe_root/pass_only_class.nox"

"$noxc_bin" check "$probe_root/optional_float_field.nox"

project_probe_root="$(mktemp -d "$project_root/.pulse-codegen-audit.XXXXXX")"
project_probe="$project_probe_root/imported_metric_data_iterable.nox"
cp "$project_root/fixtures/capability/imported_metric_data_iterable.nox.txt" "$project_probe"
"$noxc_bin" check "$project_probe"
for backend in qbe llvm; do
  "$noxc_bin" build --backend "$backend" -o "$probe_root/optional-float-$backend" "$probe_root/optional_float_field.nox"
  "$noxc_bin" build --backend "$backend" -o "$probe_root/imported-metric-data-$backend" "$project_probe"
  "$noxc_bin" build --backend "$backend" -o "$probe_root/metric-data-containment-$backend" "$project_root/tests/capability/metric_data_codegen_probe.nox"
done

printf 'pulse type capability audit: generic-class-format=pass large-float-format=pass min-int-literal=pass nul-escape-format=pass pass-only-class=pass optional-float-field=qbe+llvm-pass imported-metric-data-iterable=qbe+llvm-pass containment=qbe+llvm-pass\n'
