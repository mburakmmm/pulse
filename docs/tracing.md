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
Treat the provider's limit objects as read-only.

## Status, events and links

Status starts at `Unset`. `set_status` ignores attempts to set `Unset`,
replaces an earlier `Error` with the latest error, and treats `Ok` as final.
Only `Error` can retain an optional description. Supply a predefined, safe
description. Pulse does not derive one from exceptions or request data.
Descriptions over 255 bytes or outside the span byte budget are omitted.

`add_event` preserves recording order. It uses the current wall clock by
default. An explicit nonnegative timestamp can fall outside the interval
of the span. Event names must be 1–255 bytes.

`add_link` copies an existing context and rejects malformed IDs or tracestate
over 512 bytes. Full tracestate validation remains part of W3C propagation.
These links are added after span creation. Links supplied to head sampling
remain Phase 6 work.

Each event and link uses its own count and byte limits for attributes. Only
the first configured number of input entries are considered. Retained keys
are sorted and sensitive keys and invalid values are dropped. Snapshots
report attribute drops per event or link, and dropped events and links per
span. Existing records are kept when a later one exceeds its limit.

Span attributes, event and link records, and the error description share
the estimated span byte budget. The estimate includes fixed charges for
records and their retained string and attribute bytes. Ended and no-op
spans ignore all detail operations.

Status and event semantics follow the
[pinned OpenTelemetry trace API](https://github.com/open-telemetry/opentelemetry-specification/blob/18c5c1706e346fec3bdb5e135a6e3a78f461e586/specification/trace/api.md).

## Resource and safe exception records

Supply an optional `Resource` to `RecordingTracerProvider` or
`new_recording_tracer_provider`. For layered configuration use
`resource_from_layers`, which gives explicit configuration priority over
environment and safe defaults. An omitted Resource is empty. The provider
copies and filters Resource data at configuration time. Each snapshot owns
independent Resource and scope copies. Their retained attribute bytes count
toward the span budget. Metadata that cannot fit rejects span creation.
Use dedicated service metadata values and keep the tracer's internal state
read-only.

`record_exception(ExceptionKind.ValueError)` adds an `exception` event
with only `exception.type`. The caller classifies a caught error as
`ValueError`, `CancelledError` or generic `Exception`. The method accepts
no raw exception, message, argument or stack trace. It does not assign span
status. If the event cannot retain the type within its limits, it is dropped
and counted. This explicit method follows the event name and type key in the
[pinned exception conventions](https://github.com/open-telemetry/semantic-conventions/blob/fb30ca17193b551473b1f43c315482918ab6987c/docs/exceptions/exceptions-spans.md).

End spans in `finally` around the work they describe. Early returns, caught
errors and cancellation delivered while awaiting a task are covered by tests.
Cancelling a task that waits on an empty channel can deadlock on the pinned
runtime. Use an explicit wakeup path for those workers. See
[`NOX-ASYNC-001`](nox-limitations.md#nox-async-001--cancelling-a-task-waiting-on-an-empty-channel-can-deadlock).
Sampling and exporters remain open.
