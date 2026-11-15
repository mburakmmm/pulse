# Prometheus exposition

Status: Phase 3 is active. Pulse has an experimental, pure renderer for the
Prometheus text exposition format `0.0.4`. It does not yet provide an HTTP scrape
endpoint, resource-label promotion or a complete OpenTelemetry-to-Prometheus unit
translation policy. Its golden output is accepted by the independently installed
Prometheus `promtool` 3.16.0 parser.

## Implemented slice

`exporters.prometheus.render_metrics(collection, max_output_bytes)` renders an
already-collected cumulative `MetricCollection`. It performs no network, file,
clock or provider calls. The caller supplies a positive byte ceiling; output over
that ceiling fails with `TelemetryError`.

Current mappings are:

- Counter → Prometheus `counter`, with an idempotent `_total` suffix;
- UpDownCounter → Prometheus `gauge`;
- explicit-boundary Histogram → cumulative `_bucket`, `_sum` and `_count`
  samples, including a mandatory `le="+Inf"` bucket equal to total count.

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
- The renderer receives no Resource today, so it cannot expose `target_info` or
  an allowlisted resource-label set.
- Scrape-time concurrent consistency is limited by the current single-owner
  provider. An immutable collection is consistent after it has been collected;
  concurrent provider collection is not yet supported.
- No timestamps are emitted. Prometheus assigns scrape time.
- OpenMetrics is unsupported.
- Golden fixtures pass QBE and LLVM and checksum-verified `promtool` 3.16.0. A
  real HTTP scrape integration test is still required before the Phase 3 exit
  gate closes.

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
