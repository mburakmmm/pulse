#!/usr/bin/env bash
set -euo pipefail

noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
audit_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-transfer-audit.XXXXXX")"
trap 'rm -rf "$audit_root"' EXIT

cd "$project_root"

for case_name in spawn_class_transfer thread_class_transfer thread_tasklocal_transfer thread_mutable_graph thread_locked_graph; do
  source_path="$audit_root/$case_name.nox"
  cp "fixtures/capability/$case_name.nox.txt" "$source_path"
  "$noxc_bin" fmt "$source_path"
  for backend in qbe llvm; do
    probe_binary="$audit_root/$case_name-$backend"
    "$noxc_bin" build --backend "$backend" -o "$probe_binary" "$source_path"
    if [[ -f "$probe_binary.exe" ]]; then
      probe_binary="$probe_binary.exe"
    fi
    NOX_POOL_WORKERS=4 "$probe_binary"
  done
done

printf 'pulse backend transfer audit: spawn-class=qbe+llvm-pass thread-class=qbe+llvm-pass thread-tasklocal-isolation=qbe+llvm-pass joined-mutable-graph=qbe+llvm-pass locked-dictionary=qbe+llvm-pass\n'
