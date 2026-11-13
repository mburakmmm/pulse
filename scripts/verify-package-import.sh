#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
noxc_bin="${NOXC:-noxc}"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-package-import.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"

mkdir -p "$package_root/_internal" "$consumer_root" "$probe_nox_home"
cp "$project_root/nox.json" "$package_root/"
cp "$project_root/_internal/build_info.nox" "$package_root/_internal/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Pulse package probe"
git -C "$package_root" config user.email "pulse-probe@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "package import probe"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
cp "$project_root/tests/fixtures/consumer_main.nox" main.nox
NOX_HOME="$probe_nox_home" "$noxc_bin" add pulse "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null

llvm_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend llvm main.nox)"
qbe_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend qbe main.nox)"
expected="pulse-package-smoke-ok"

test "$llvm_output" = "$expected"
test "$qbe_output" = "$expected"

resolved_sha="$(git -C "$package_root" rev-parse HEAD)"
grep -q "\"resolved\": \"$resolved_sha\"" nox.lock

printf 'package import: LLVM=pass QBE=pass lock=pass\n'

