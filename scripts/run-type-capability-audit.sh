#!/usr/bin/env bash
set -euo pipefail

noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-type-audit.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

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
if "$noxc_bin" check "$probe_root/pass_only_class.nox" >"$probe_root/pass-only-class.log" 2>&1; then
  echo "expected pass-only class formatter reproducer to expose NOX-FMT-004" >&2
  exit 1
fi
grep -Fq "unexpected 'value' (expected indent)" "$probe_root/pass-only-class.log"

"$noxc_bin" check "$probe_root/optional_float_field.nox"
if "$noxc_bin" build -o "$probe_root/optional-float-field" "$probe_root/optional_float_field.nox" >"$probe_root/optional-float-field.log" 2>&1; then
  echo "expected optional float field reproducer to expose NOX-CODEGEN-001" >&2
  exit 1
fi
grep -Fq "codegen: this program contains a construct that is not supported" "$probe_root/optional-float-field.log"

printf 'pulse type capability audit: generic-class-format=pass large-float-format=pass min-int-literal=pass nul-escape-format=pass pass-only-class=known-incompatible optional-float-field=known-incompatible\n'
