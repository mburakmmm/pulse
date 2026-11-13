# Standards matrix

Status: Standards selected on 2026-11-07; NOX baseline refreshed and locally verified on 2026-11-11. Schema vendoring, checksums and executable fixtures remain Phase 7 work.

| Contract | Exact version / commit | Pulse surface | Status |
|---|---|---|---|
| NOX language and stdlib | `2.1.64`, `be3458c332c8234baa8f3f8ac2ae9601db24321e` | All modules | Pinned; isolated QBE/LLVM local gates pass |
| OpenTelemetry specification | `v1.62.0`, `18c5c1706e346fec3bdb5e135a6e3a78f461e586` | API/SDK semantics | Pinned |
| OTLP protocol/protobuf | `v1.11.1`, `b3f75588eb23c5fca62264edd05d382de49beb1a` | Traces and metrics encoding | Pinned; schema checksum pending |
| OpenTelemetry semantic conventions | `v1.45.0`, `fb30ca17193b551473b1f43c315482918ab6987c` | HTTP/DB/resource attributes | Pinned |
| W3C Trace Context | Recommendation, 23 November 2021 | `traceparent`, `tracestate` | Pinned; fixtures pending |
| W3C Baggage | Candidate Recommendation Snapshot, 30 May 2024 | Baggage propagation | Pinned with maturity disclosed; fixtures pending |
| Prometheus text exposition | `0.0.4` | Metrics renderer | Pinned |
| OpenMetrics | `1.0.0` is reference-only | Optional future renderer | Unsupported in initial release |

## Pinned primary sources

- OpenTelemetry specification: <https://github.com/open-telemetry/opentelemetry-specification/tree/18c5c1706e346fec3bdb5e135a6e3a78f461e586>
- OTLP protobuf schema: <https://github.com/open-telemetry/opentelemetry-proto/tree/b3f75588eb23c5fca62264edd05d382de49beb1a>
- Semantic conventions: <https://github.com/open-telemetry/semantic-conventions/tree/fb30ca17193b551473b1f43c315482918ab6987c>
- W3C Trace Context: <https://www.w3.org/TR/2021/REC-trace-context-1-20211123/>
- W3C Baggage: <https://www.w3.org/TR/2024/CR-baggage-20240530/>
- Prometheus text exposition: <https://prometheus.io/docs/instrumenting/exposition_formats/>
- OpenMetrics 1.0.0: <https://github.com/prometheus/OpenMetrics/releases/tag/v1.0.0>

## Selection notes

- OpenTelemetry specification `v1.62.0` was the latest immutable release observed on 2026-11-07. Pulse will implement only the stable portions it explicitly advertises; pinning a repository version does not promote development features to supported status.
- OTLP protobuf `v1.11.1` was the latest immutable release observed on 2026-11-07. Only traces and metrics messages required by Pulse are in scope.
- Semantic conventions versioning is independent from the core specification and is pinned separately.
- W3C Baggage is a Candidate Recommendation Snapshot, not a W3C Recommendation. Pulse must preserve this maturity distinction in documentation.
- Initial Prometheus output targets text format `0.0.4`. OpenMetrics remains unsupported until its own renderer and conformance tests exist.

## Feature-to-test matrix

This table will expand with each phase. No feature is advertised merely because a module exists.

| Feature | Unit | Golden | Property/fuzz | Concurrency | External conformance |
|---|---:|---:|---:|---:|---:|
| Package/module loading | Pass | N/A | N/A | N/A | Downstream consumer pass on LLVM/QBE |
| Clock and secure IDs | Pass | N/A | Planned | N/A | N/A |
| Metrics | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |
| Tracing | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |
| W3C propagation | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |
| Prometheus | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |
| OTLP protobuf/HTTP | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |

