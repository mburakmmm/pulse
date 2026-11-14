# Exporter support

Pulse separates an internal diagnostic exporter from a standards-interoperable
exporter. A compiling serializer is not automatically OTLP or Prometheus support.

| Exporter | Signals | Status | Bounds and lifecycle |
|---|---|---|---|
| In-memory | Metrics | Experimental, QBE + LLVM tested | Fixed collection capacity; defensive ingress/egress copies; idempotent shutdown |
| Console | Metrics | Experimental, QBE + LLVM tested | Structured sanitized JSON; fixed output-byte limit; synchronous |
| Prometheus | Metrics | Planned for Phase 3 | Not implemented |
| OTLP/HTTP | Metrics + traces | Planned for Phase 8 | Not implemented; no Collector claim |
| OTLP/gRPC | Metrics + traces | Optional | Unsupported until real Collector conformance |
| File | Metrics + traces | Optional | Not implemented |

The console format is a Pulse diagnostic record, not OTLP JSON. Neither current
exporter starts a worker, listener or network connection. Both are single-owner
until the relevant concurrency lifecycle is implemented and tested.
