# Standards matrix

Status: Standards selected on 2026-11-07; NOX baseline refreshed and locally verified on 2026-11-11. Schema vendoring, checksums and executable fixtures remain Phase 7 work.

| Contract | Exact version / commit | Pulse surface | Status |
|---|---|---|---|
| NOX language and stdlib | `2.2.38`, `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a` | All modules | Pinned with QBE/LLVM regressions and exact build identity |
| OpenTelemetry specification | `v1.62.0`, `18c5c1706e346fec3bdb5e135a6e3a78f461e586` | API/SDK semantics and Prometheus unit translation | Pinned; metric-name unit table/rate/annotation rules implemented |
| OTLP protocol/protobuf | `v1.11.1`, `b3f75588eb23c5fca62264edd05d382de49beb1a` | Traces and metrics encoding | Pinned; schema checksum pending |
| OpenTelemetry semantic conventions | `v1.45.0`, `fb30ca17193b551473b1f43c315482918ab6987c` | HTTP/DB/resource attributes | Pinned |
| W3C Trace Context | Recommendation, 23 November 2021 | `traceparent`, `tracestate` | Pinned; fixtures pending |
| W3C Baggage | Candidate Recommendation Snapshot, 30 May 2024 | Baggage propagation | Pinned with maturity disclosed; fixtures pending |
| Prometheus text exposition | `0.0.4` | Metrics renderer | Pinned |
| Prometheus validation tool | `v3.16.0`, `e2e28adeee2c5883d000fc82aca6008cfbf7e96d` | Independent text parser | Pinned; checksum-verified promtool golden gate passes |
| OpenMetrics | `1.0.0` is reference-only | Optional future renderer | Unsupported in initial release |

## Pinned primary sources

- OpenTelemetry specification: <https://github.com/open-telemetry/opentelemetry-specification/tree/18c5c1706e346fec3bdb5e135a6e3a78f461e586>
- OTLP protobuf schema: <https://github.com/open-telemetry/opentelemetry-proto/tree/b3f75588eb23c5fca62264edd05d382de49beb1a>
- Semantic conventions: <https://github.com/open-telemetry/semantic-conventions/tree/fb30ca17193b551473b1f43c315482918ab6987c>
- W3C Trace Context: <https://www.w3.org/TR/2021/REC-trace-context-1-20211123/>
- W3C Baggage: <https://www.w3.org/TR/2024/CR-baggage-20240530/>
- Prometheus text exposition: <https://prometheus.io/docs/instrumenting/exposition_formats/>
- Prometheus validation tool: <https://github.com/prometheus/prometheus/releases/tag/v3.16.0>
- OpenMetrics 1.0.0: <https://github.com/prometheus/OpenMetrics/releases/tag/v1.0.0>

## Selection notes

- OpenTelemetry specification `v1.62.0` was the latest immutable release observed on 2026-11-07. Pulse will implement only the stable portions it explicitly advertises; pinning a repository version does not promote development features to supported status.
- OTLP protobuf `v1.11.1` was the latest immutable release observed on 2026-11-07. Only traces and metrics messages required by Pulse are in scope.
- Semantic conventions versioning is independent from the core specification and is pinned separately.
- W3C Baggage is a Candidate Recommendation Snapshot, not a W3C Recommendation. Pulse must preserve this maturity distinction in documentation.
- Initial Prometheus output targets text format `0.0.4`. OpenMetrics remains unsupported until its own renderer and conformance tests exist.
- Prometheus unit suffixes follow the pinned compatibility specification at
  `specification/compatibility/prometheus_and_openmetrics.md`: known UCUM atoms
  become words, annotations are dropped, rates use `_per_`, and the unit suffix
  precedes the type suffix. Pulse does not rescale metric values.

## Feature-to-test matrix

This table will expand with each phase. No feature is advertised merely because a module exists.

| Feature | Unit | Golden | Property/fuzz | Concurrency | External conformance |
|---|---:|---:|---:|---:|---:|
| Package/module loading | Pass | N/A | N/A | N/A | Downstream consumer pass on LLVM/QBE |
| Clock and secure IDs | Pass | N/A | Planned | N/A | N/A |
| Metrics | Pass | Pass | Pass | Atomic 10×1,000 and shared provider registration, overflow and snapshot tests | N/A |
| Tracing | Lifecycle, ancestry, clock regression, attribute privacy and bounds | Pending | Pending | Single-owner | Export deferred |
| W3C propagation | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |
| Prometheus | Pure renderer/handler + allowlisted `target_info` pass | Text 0.0.4 pass | Malformed/bound/sensitive-resource/HTTP checks pass | Shared recording and snapshot rendering gate | promtool 3.16.0 golden + real HTTP body pass; listener exposure application-owned |
| OTLP protobuf/HTTP | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |

