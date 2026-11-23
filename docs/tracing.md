# Experimental tracing core

The recording provider supports explicit parent context and a one-shot ended
span snapshot. Each provider, tracer and span has a single owner. Applications
can pass copies of span context between operations. The existing no-op API
remains available.

Use the base `Tracer.start_span` for internal spans. Use a
`RecordingTracer.start_recording_span` to choose a `SpanKind`. Both return
spans that implement `end()` and `take_snapshot()`. The latter transfers
the snapshot to the caller. No queue or network I/O is involved.

`RecordingTracerProvider` accepts an injected clock and ID source for
deterministic tests. Use `new_recording_tracer_provider` for system time and
secure random IDs. A recording child reuses its parent's trace ID, flags and
tracestate and gets a new local span ID. Root flags default to unsampled until
the sampling phase. W3C header and tracestate parsing are separate work. Pass
only application-owned or already validated context into this recording API.
The retained opaque tracestate is capped at 512 bytes.

A span uses wall time for start and end timestamps and monotonic time for
duration. Clock regressions clamp the wall end to the start and a regressed
monotonic duration to zero. `end()` is idempotent. `take_snapshot()` returns
an ended snapshot once and never returns an open span's data. Span context
remains available after ending.

Span names are bounded to 255 bytes. Use static operation names or route
templates. Attributes use the existing sensitive-key filter and deep value
copies. The budget includes a fixed metadata estimate plus configured string
and attribute bytes. Dropped writes leave the previous value unchanged.
Resource metadata,
events, links, status, exception capture, sampling and exporter integration
remain separate Phase 4 or later work.
