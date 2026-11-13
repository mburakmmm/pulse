# ADR-0005: Bounded defaults and memory budget

- Status: Accepted as pre-release defaults; measurements may tighten them before v1.0
- Date: 2026-11-08

## Context

Independent count limits are insufficient: a queue of records that each contain the maximum number of maximum-sized attributes can still exhaust memory. Pulse needs both structural limits and aggregate byte budgets before telemetry is allocated or enqueued. Defaults must fail safely under malicious cardinality, baggage, event and exporter traffic.

## Decision

All limits are explicit typed configuration, validated before provider startup. Negative values, zero where work is required, overflow-prone products and internally inconsistent combinations fail configuration. Unlimited sentinel values are not supported in the stable configuration.

### Attribute and record defaults

| Limit | Default |
|---|---:|
| Attributes per span/metric point/resource/scope | 64 |
| Attribute key UTF-8 bytes | 128 |
| Scalar string UTF-8 bytes | 1,024 |
| Array elements | 32 |
| String-array element UTF-8 bytes | 256 |
| Total accepted attribute bytes per record | 32 KiB |
| Span events | 64 |
| Span links | 32 |
| Attributes per event/link | 32 |
| Total event/link attribute bytes each | 8 KiB |
| Span snapshot hard ceiling | 256 KiB |
| Histogram explicit boundaries | 64 |

Sizes are measured in exact UTF-8/binary bytes, not code points. Limits run before defensive copies and before series/queue allocation. Dropped counts are retained where the telemetry model supports them.

### Metrics cardinality defaults

| Limit | Default |
|---|---:|
| Metric points per instrument/view, including overflow | 2,000 |
| Total active series per provider | 20,000 |
| Total estimated aggregation memory | 64 MiB |
| Instrument description UTF-8 bytes | 4 KiB |

The first reached boundary wins. For synchronous cumulative instruments, one point
inside the configured hard limit is reserved for the deterministic
`otel.metric.overflow=true` aggregation. Measurements are not dropped on cardinality
overflow; they are recorded exactly once without their original attributes. Dynamic
path, user, session and arbitrary error-message attributes are not accepted by
automatic instrumentation defaults.

### Processor/export defaults

| Limit | Default |
|---|---:|
| Accepted queue records | 2,048 |
| Queue-owned snapshot bytes | 32 MiB |
| Batch records | 512 |
| Encoded request body | 4 MiB |
| Scheduled batch delay | 5,000 ms |
| Per-export timeout | 10,000 ms |
| `force_flush` timeout | 10,000 ms |
| Shutdown deadline | 30,000 ms |
| Retry attempts after initial request | 4 |
| Retry total elapsed time | 30,000 ms |
| Backoff jitter | bounded to ±20% |

Queue overflow defaults to `drop_newest`. Application recording never waits indefinitely and exporter work never holds an application recording lock. Retry reuses the bounded queue budget; it cannot create a second unbounded copy or disk spool.

### Propagation and transport

- `traceparent`, `tracestate` and baggage first obey the pinned W3C protocol maxima and grammar.
- Pulse may configure stricter trust-boundary baggage limits, but never looser ones.
- OTLP endpoints, headers and payloads have explicit byte caps. Diagnostic output never includes authorization headers or payload bodies.
- HTTP always uses a positive timeout. Redirect following is disabled unless a future explicit policy is reviewed.

## Budget accounting

Every queued snapshot carries an estimated owned-byte cost calculated with checked integer arithmetic. Enqueue succeeds only when both conditions remain true:

```text
queued_records + 1 <= max_queue_records
queued_owned_bytes + snapshot_owned_bytes <= max_queue_bytes
```

The estimate includes copied strings, array elements, events, links and queue/batch ownership. Shared immutable resource/scope objects are counted once per owning provider plus any encoded copy. Implementations must prefer conservative over-counting to hidden under-counting.

Metric series allocation applies the same pattern at instrument and provider scope. Cardinality checks happen before a new attribute-key snapshot or aggregation object is allocated.

## Configuration invariants

- `batch_records <= queue_records`.
- Batch estimated bytes and encoded payload cannot exceed their configured ceilings.
- Every timeout/deadline is finite and positive.
- Shutdown deadline is not silently extended by retries.
- Retry elapsed budget cannot exceed shutdown's remaining deadline.
- Histogram boundaries are finite, strictly increasing and within the boundary-count limit.
- A reconfiguration that changes ownership limits requires a quiescent provider or an atomic validated swap; partial application is forbidden.

## Diagnostics

Bounded internal counters record dropped attributes, events, links, measurements, series, queue records, oversized payloads, retries and permanent failures. Diagnostics must not recursively emit through the failing exporter.

## Consequences

- Defaults are intentionally conservative and may reject high-cardinality workloads until explicitly tuned.
- Count and byte limits make worst-case memory finite even when individual records are adversarial.
- Phase 12 stress/benchmark evidence must measure actual representation overhead. Defaults may be lowered without weakening compatibility; raising stable defaults requires a memory-budget review.
- No value in this ADR is a performance claim until measured on supported targets.
