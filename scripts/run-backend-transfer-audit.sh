#!/usr/bin/env bash
set -euo pipefail

noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
audit_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-transfer-audit.XXXXXX")"
trap 'rm -rf "$audit_root"' EXIT

cd "$project_root"

for case_name in spawn_class_transfer thread_class_transfer thread_tasklocal_transfer; do
  source_path="$audit_root/$case_name.nox"
  llvm_binary="$audit_root/$case_name-llvm"
  qbe_log="$audit_root/$case_name-qbe.log"
  cp "fixtures/capability/$case_name.nox.txt" "$source_path"
  "$noxc_bin" fmt "$source_path"
  "$noxc_bin" build --backend llvm -o "$llvm_binary" "$source_path"
  if [[ -f "$llvm_binary.exe" ]]; then
    llvm_binary="$llvm_binary.exe"
  fi
  "$llvm_binary"
  if "$noxc_bin" build --backend qbe -o "$audit_root/$case_name-qbe" "$source_path" >"$qbe_log" 2>&1; then
    echo "expected QBE to reject $case_name" >&2
    exit 1
  fi
  grep -Eq "unsupported type|not safe across threads" "$qbe_log"
done

printf 'pulse backend transfer audit: LLVM class/tasklocal transfer=pass QBE restricted-transfer diagnostics=pass\n'
