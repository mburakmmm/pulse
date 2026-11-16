# Prometheus exposition

Status: Phase 3 is active. Pulse has an experimental, pure renderer for the
Prometheus text exposition format `0.0.4`. It does not yet provide an HTTP scrape
listener or a complete OpenTelemetry-to-Prometheus unit translation policy. It
supports a pure HTTP response adapter and explicit allowlisted Resource promotion
through `target_info`; golden and real scrape output are accepted by the
independently installed Prometheus `promtool` 3.16.0 parser.

## Implemented slice

`exporters.prometheus.render_metrics(collection, max_output_bytes)` renders an
already-collected cumulative `MetricCollection`. It performs no network, file,
clock or provider calls. The caller supplies a positive byte ceiling; output over
that ceiling fails with `TelemetryError`.

`render_metrics_with_resource(collection, resource, allowlist, max_output_bytes)`
adds a `target_info` gauge before the metric families. Resource promotion is off
unless this explicit API is selected and the allowlist contains a matching key.
The allowlist is capped at 32 keys, each key is bounded, sensitive keys are
rejected, normalized label collisions fail closed and the target family counts
toward the same output-byte ceiling. Non-allowlisted Resource attributes are never
rendered.

`scrape_response()` and `scrape_response_with_resource()` convert an explicit
`HttpRequest` plus immutable collection into an `HttpResponse`. They accept only
`GET` on the configured absolute path, ignore query parameters for routing,
reject request bodies, return 404/405/400 as appropriate and contain renderer
failures behind a generic 500. Successful responses declare text `0.0.4`, disable
caching and add `nosniff`. The adapter performs no bind, clock, network or
recording operation, so it cannot recursively instrument itself. Configured paths
are capped at 256 bytes and direct request targets at 4 KiB; oversized targets
return 414 even when the adapter is invoked outside the NOX server.

Pulse intentionally does not own a listener. NOX 2.1.64 server APIs accept a port
but not a bind address and bind `0.0.0.0`; see `NOX-HTTP-004`. Applications must
make the exposure decision explicitly and apply firewall/container policy or a
trusted loopback reverse proxy for local-only access. The integration fixture's
wildcard listener is test infrastructure, not a secure production default.

Current mappings are:

- Counter → Prometheus `counter`, with an idempotent `_total` suffix;
- UpDownCounter → Prometheus `gauge`;
- explicit-boundary Histogram → cumulative `_bucket`, `_sum` and `_count`
  samples, including a mandatory `le="+Inf"` bucket equal to total count;
- explicitly allowlisted Resource attributes → one `target_info` gauge with
  deterministic labels and value `1`.

Metric and label names use the legacy text-format ASCII grammar. Unsupported
bytes are replaced deterministically with `_`; labels beginning with the reserved
`__` namespace are prefixed with `otel`. A family or label collision after
normalization is rejected instead of silently merging semantically different
series.

HELP backslashes/newlines and label backslashes/newlines/quotes are escaped.
Scalar attribute values retain their exact integer path; homogeneous arrays use
deterministic JSON text as one label value. Sensitive values cannot reach the
renderer through the normal recording path because they are dropped before
aggregation.

## Explicit limitations

- Instrument units are preserved in the snapshot but do not yet rename or scale
  Prometheus samples. Unit translation remains open; no base-unit compliance is
  claimed.
- Duplicate normalized family names, including the same instrument name from
  separate scopes, fail the render. View-based conflict resolution is not yet
  implemented.
- `render_metrics()` intentionally receives no Resource. Callers that need
  `target_info` must choose `render_metrics_with_resource()` and provide the
  allowlist; bulk/default promotion is unsupported.
- Scrape-time concurrent consistency is limited by the current single-owner
  provider. An immutable collection is consistent after it has been collected;
  concurrent provider collection is not yet supported.
- No timestamps are emitted. Prometheus assigns scrape time.
- OpenMetrics is unsupported.
- Golden fixtures and real HTTP scrape responses pass QBE and LLVM plus
  checksum-verified `promtool` 3.16.0. General concurrent collection remains
  unsupported because the provider is still single-owner.

## Evidence

`scripts/run-phase3-tests.sh <llvm|qbe>` type-checks the renderer, runs behavioral
and failure tests, and compares byte-for-byte output against
`fixtures/prometheus/text-0.0.4.golden.txt`. The helper uses portable `print`
output rather than `nox.terminal.write_raw`; `NOX-IO-001` tracks the latter's
redirected-output failure on Windows independently from renderer correctness.

`scripts/run-prometheus-conformance.sh` then feeds that fixture to Prometheus
`promtool check metrics`. CI downloads the official Linux x64 Prometheus 3.16.0
archive and requires SHA-256
`68727009472a2c02e1ff7f062fd5b3e637285bffc8fc2d340c76fb449d6e0f34` before
executing the parser. Local macOS ARM64 evidence used the official archive with
SHA-256 `f7c71b553316f822bdd860a3ea527ebefb2f8e944e5b7dfd419ae2653cf3ba01`.

`scripts/run-prometheus-scrape-integration.sh <llvm|qbe>` builds a real NOX
server and client, applies small request/header/read/connection/drain limits,
scrapes exact values and safe Resource metadata, checks credential absence and
waits for graceful shutdown. With `PROMTOOL` set, the received HTTP body is also
parsed independently.
