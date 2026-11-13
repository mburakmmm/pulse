#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
audit_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-http-audit.XXXXXX")"
port_file="$audit_root/port"
server_log="$audit_root/server.log"
server_pid=""
tls_port_file="$audit_root/tls-port"
tls_server_log="$audit_root/tls-server.log"
tls_server_pid=""

cleanup() {
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  if [[ -n "$tls_server_pid" ]] && kill -0 "$tls_server_pid" 2>/dev/null; then
    kill "$tls_server_pid" 2>/dev/null || true
    wait "$tls_server_pid" 2>/dev/null || true
  fi
  rm -rf "$audit_root"
}
trap cleanup EXIT

cd "$project_root"
python3 tests/fixtures/http_capability_server.py "$port_file" >"$server_log" 2>&1 &
server_pid="$!"

for _ in {1..100}; do
  if [[ -s "$port_file" ]]; then
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    cat "$server_log" >&2
    exit 1
  fi
  sleep 0.05
done

if [[ ! -s "$port_file" ]]; then
  echo "HTTP capability server did not publish its port" >&2
  cat "$server_log" >&2
  exit 1
fi

port="$(<"$port_file")"

openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 1 -subj "/CN=localhost" -keyout "$audit_root/tls.key" -out "$audit_root/tls.crt" >"$audit_root/openssl.log" 2>&1
python3 tests/fixtures/http_capability_server.py "$tls_port_file" "$audit_root/tls.crt" "$audit_root/tls.key" >"$tls_server_log" 2>&1 &
tls_server_pid="$!"

for _ in {1..100}; do
  if [[ -s "$tls_port_file" ]]; then
    break
  fi
  if ! kill -0 "$tls_server_pid" 2>/dev/null; then
    cat "$tls_server_log" >&2
    exit 1
  fi
  sleep 0.05
done

if [[ ! -s "$tls_port_file" ]]; then
  echo "HTTPS capability server did not publish its port" >&2
  cat "$tls_server_log" >&2
  exit 1
fi

tls_port="$(<"$tls_port_file")"
PULSE_HTTP_BASE_URL="http://127.0.0.1:$port" PULSE_HTTPS_SELF_SIGNED_URL="https://127.0.0.1:$tls_port" "$noxc_bin" run --backend "$backend" tests/capability/http_client_probe.nox
printf 'pulse HTTP capability audit: backend=%s binary=pass headers=pass redirect=pass status=pass gzip=pass timeout=pass tls-untrusted-rejection=pass unsupported-method=pass get-body-validation=pass\n' "$backend"
