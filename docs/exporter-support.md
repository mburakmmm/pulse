# Exporter support

Pulse separates an internal diagnostic exporter from a standards-interoperable
exporter. A compiling serializer is not automatically OTLP or Prometheus support.

| Exporter | Signals | Status | Bounds and lifecycle |
|---|---|---|---|
| In-memory | Metrics | Experimental, QBE + LLVM tested | Fixed collection capacity; defensive ingress/egress copies; idempotent shutdown |
| Console | Metrics | Experimental, QBE + LLVM tested | Structured sanitized JSON; fixed output-byte limit; synchronous |
| Prometheus text renderer | Metrics | Experimental Phase 3 slice, QBE + LLVM tested | Pure cumulative snapshot render; output-byte bound; no listener |
| Prometheus HTTP scrape | Metrics | Planned for Phase 3 | Renderer passes promtool 3.16.0; real scrape endpoint pending |
| OTLP/HTTP | Metrics + traces | Planned for Phase 8 | Not implemented; no Collector claim |
| OTLP/gRPC | Metrics + traces | Optional | Unsupported until real Collector conformance |
| File | Metrics + traces | Optional | Not implemented |

The console format is a Pulse diagnostic record, not OTLP JSON. The in-memory and
console exporters and the Prometheus renderer start no worker, listener or network
connection. They remain single-owner until the relevant concurrency lifecycle is
implemented and tested. The Prometheus renderer targets text format `0.0.4`; its
current bounds and explicit limitations are documented in `docs/prometheus.md`.
