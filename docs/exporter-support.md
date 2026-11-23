# Exporter support

Pulse separates an internal diagnostic exporter from a standards-interoperable
exporter. A compiling serializer is not automatically OTLP or Prometheus support.

| Exporter | Signals | Status | Bounds and lifecycle |
|---|---|---|---|
| In-memory | Metrics | Experimental, QBE + LLVM tested | Fixed collection capacity; defensive ingress/egress copies; idempotent shutdown |
| Console | Metrics | Experimental, QBE + LLVM tested | Structured sanitized JSON; fixed output-byte limit; synchronous |
| In-memory | Traces | Experimental local snapshots | Span-count and estimated-byte limits, defensive copies, drop-newest admission |
| Console | Traces | Experimental diagnostic summaries | JSON line byte limit, explicit field allowlist, same-instance reentrancy guard |
| Prometheus text renderer | Metrics | Experimental Phase 3 slice, QBE + LLVM tested | Pure cumulative snapshot render; pinned unit suffix translation without value scaling; explicit bounded Resource allowlist/`target_info`; output-byte bound; no listener |
| Prometheus HTTP scrape | Metrics | Experimental pure handler adapter | Real QBE/LLVM loopback response and promtool pass. Applications own bind and lifecycle. |
| OTLP/HTTP | Metrics + traces | Planned for Phase 8 | Not implemented; no Collector claim |
| OTLP/gRPC | Metrics + traces | Optional | Unsupported until real Collector conformance |
| File | Metrics + traces | Optional | Not implemented |

The console formats are Pulse diagnostic records. OTLP encoding is a separate
planned feature. The in-memory and
console exporters and the Prometheus renderer start no worker, listener or network
connection. They remain single-owner until the relevant concurrency lifecycle is
implemented and tested. The Prometheus renderer targets text format `0.0.4`; its
current bounds and explicit limitations are documented in `docs/prometheus.md`.
The HTTP adapter returns a response but never starts or configures a process-global
listener. Applications own bind exposure and server lifecycle.

## Trace exporter contract

`SpanExporter.export_span(snapshot)` submits an ended snapshot synchronously.
`export_ended_span(span, exporter)` consumes the recording span's one-shot
snapshot. A second call fails with `InvalidState`. A rejected export also
consumes that one-shot snapshot. Call `take_snapshot()` yourself when you need
to retain ownership after rejection. Submitting an already detached snapshot is
explicit and does not deduplicate it.

`InMemorySpanExporter(max_spans, max_bytes=1048576)` rejects the newest record
when count or estimated bytes would exceed capacity. Configured bytes must be
within 1–67,108,864. Admission accounts for strings, attribute values, contexts
and fixed record charges. This estimate does not measure process heap use.
Drop counts cover capacity refusals. Ingress and readback both copy nested
data. Ingress filters sensitive attribute keys even on caller-edited snapshots.
Keep retained data and internal fields private to the owner. Readback remains
available after shutdown.

`ConsoleSpanExporter(max_output_bytes)` emits one JSON line per accepted
snapshot. The limit applies to JSON bytes before the line terminator. Only
validated trace, span and parent IDs, kind, status, timestamps, duration and
event/link counts are emitted. Names, tracestate, Resource, attributes and
error descriptions are omitted. The default sink writes synchronously to
stdout. An injected `TraceLineSink` is caller-owned and must return promptly.
The same exporter rejects reentrant writes. Sink exceptions return a generic
failure without the underlying message.

Both trace exporters have single-owner semantics and idempotent shutdown.
Flush is immediate on idle exporters. The console reports `Timeout` for
reentrant lifecycle requests during an active sink call. No background export,
batching, retries or network delivery are started by these exporters.
