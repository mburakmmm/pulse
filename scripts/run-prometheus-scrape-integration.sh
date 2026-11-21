#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/pulse-prometheus-scrape.XXXXXX")"
server_pid=""

cleanup() {
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$output_root"
}
trap cleanup EXIT

cd "$project_root"
"$noxc_bin" build --backend "$backend" -o "$output_root/prometheus-scrape-server" tests/integration/prometheus_scrape_server.nox
"$noxc_bin" build --backend "$backend" -o "$output_root/prometheus-scrape-client" tests/integration/prometheus_scrape_client.nox
server_binary="$output_root/prometheus-scrape-server"
client_binary="$output_root/prometheus-scrape-client"
if [[ -f "$server_binary.exe" ]]; then
  server_binary="$server_binary.exe"
fi
if [[ -f "$client_binary.exe" ]]; then
  client_binary="$client_binary.exe"
fi

port="$((30000 + RANDOM % 20000))"
"$server_binary" "$port" >"$output_root/server.log" 2>&1 &
server_pid="$!"

connected="false"
for _ in {1..50}; do
  if "$client_binary" "$port" >"$output_root/metrics.txt" 2>"$output_root/client.log"; then
    connected="true"
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    cat "$output_root/server.log" >&2
    cat "$output_root/client.log" >&2
    exit 1
  fi
  sleep 0.1
done

if [[ "$connected" != "true" ]]; then
  echo "Prometheus scrape client could not connect" >&2
  cat "$output_root/server.log" >&2
  cat "$output_root/client.log" >&2
  exit 1
fi

wait "$server_pid"
server_pid=""
if [[ -n "${PROMTOOL:-}" ]]; then
  "$PROMTOOL" check metrics <"$output_root/metrics.txt"
fi
printf 'pulse Prometheus scrape integration: backend=%s listener=explicit-ipv4-loopback endpoint=real status=200 content_type=pass resource_allowlist=pass exact_counter=pass privacy=pass shutdown=pass\n' "$backend"
