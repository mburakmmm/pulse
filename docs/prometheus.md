# Prometheus exposition

Status: Phase 3 is active. Pulse has an experimental, pure renderer for the
Prometheus text exposition format `0.0.4`. It does not provide an HTTP scrape
listener. It supports pinned OpenTelemetry unit-to-name translation, a pure HTTP
response adapter and explicit allowlisted Resource promotion through
`target_info`; golden and real scrape output are accepted by the independently
installed Prometheus `promtool` 3.16.0 parser.

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

The application owns the listener. Call
`nox.http.configure(bind_address="127.0.0.1")` before serving metrics locally, as
in the real scrape fixture. NOX defaults to wildcard binding when no address is
configured. For a remote scraper, select the bind address explicitly and apply
network or reverse-proxy access controls.

Current mappings are:

- Counter → Prometheus `counter`, with an idempotent `_total` suffix;
- UpDownCounter → Prometheus `gauge`;
- explicit-boundary Histogram → cumulative `_bucket`, `_sum` and `_count`
  samples, including a mandatory `le="+Inf"` bucket equal to total count;
- explicitly allowlisted Resource attributes → one `target_info` gauge with
  deterministic labels and value `1`.

The pinned OpenTelemetry `v1.62.0` Prometheus compatibility rules drive unit
translation. Known UCUM atoms use the normative word table (`ms` →
`milliseconds`, `By` → `bytes`); annotations in braces are removed; rates use a
plural numerator and singular denominator (`m/s` → `meters_per_second`). The unit
suffix precedes the counter suffix, so a seconds counter ends in
`_seconds_total`. Dimensionless `1` adds no suffix, an existing suffix is not
duplicated, and malformed annotations/rates fail closed. Unknown ASCII atoms are
normalized deterministically. Translation changes names only: values, histogram
boundaries and sums are never scaled or converted, preserving exact integer
paths and the instrument's declared measurement magnitude. Text format `0.0.4`
has no UNIT metadata line, so Pulse emits the required information in the family
name only.

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

- Unit translation implements the pinned suffix rules, not arbitrary UCUM
  dimensional algebra. It does not rescale values or infer a base unit.
- Duplicate normalized family names, including the same instrument name from
  separate scopes, fail the render. View-based conflict resolution is not yet
  implemented.
- `render_metrics()` intentionally receives no Resource. Callers that need
  `target_info` must choose `render_metrics_with_resource()` and provide the
  allowlist; bulk/default promotion is unsupported.
- The opt-in concurrent provider takes a defensive snapshot under its metric
  gate. Render after collection and use a reader per scraper when reader
  timestamps are needed. A lock timeout raises `TelemetryError`; the application
  should return a generic failure response.
- No timestamps are emitted. Prometheus assigns scrape time.
- OpenMetrics is unsupported.
- The real HTTP fixture serves a detached snapshot from the opt-in provider.
  The worker test renders a snapshot after recording starts and before writers
  can finish. NOX counts accepted connections when `serve()` receives a
  positional connection limit. Confirm handler quiescence before releasing
  an application-owned provider.

## Evidence

`scripts/run-phase3-tests.sh <llvm|qbe>` type-checks the renderer, runs behavioral
and failure tests, and compares byte-for-byte output against
`fixtures/prometheus/text-0.0.4.golden.txt`. The golden helper uses portable
`print` output. A separate exact-byte regression checks redirected
`nox.terminal.write_raw` on each core CI target (`NOX-IO-001`).

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
