# Pulse API status

Status: pre-1.0, Phase 1 local gate complete and Phase 2 active. A bounded
single-owner recording metrics provider, cumulative reader and bounded in-memory
and console metric exporters exist for development and tests. No general
concurrent metrics provider, tracing SDK or network exporter is implemented yet.

## Stable direction

Instrumentation depends on root modules under `api/`; runtime implementation will
live outside that layer. The current compiling surface contains:

- `api.context`: `TraceFlags`, validated `SpanContext`, explicit immutable-style
  `TelemetryContext` replacement via `with_span`, and `empty_context`;
- `api.metrics`: `Counter`, `UpDownCounter`, `Histogram`, `Meter`,
  `MeterProvider` contracts and no-op variants;
- `api.tracing`: `Span`, `Tracer`, `TracerProvider` contracts and no-op variants.

NOX 2.1.64 cannot use a structural protocol as a value type when one protocol
method returns another protocol. The API therefore uses ordinary base classes for
these nested factory contracts. Implementations subclass them; callers type against
the base classes. This is a public-language constraint, not private runtime ABI.

Initialization is explicit. Importing these modules starts no worker, listener or
network request. The no-op providers retain no telemetry, create no identifiers and
preserve an explicitly supplied valid parent `SpanContext` for propagation.

## Current example

```nox
from api.context import TelemetryContext, empty_context
from api.tracing import NoopTracerProvider, Span, Tracer

tracer: Tracer = NoopTracerProvider().get_tracer("example", None, None)
context: TelemetryContext = empty_context()
span: Span = tracer.start_span("disabled-operation", context)
span.end()
```

The no-op example is intentionally not presented as real tracing. Recording SDK
providers and instrument registration arrive later in Phase 2/4.

The Phase 2 recording slice rejects negative Counter additions, detects signed
64-bit overflow/underflow, supports signed UpDownCounter changes and implements
finite explicit-boundary Histogram state. `metrics.provider.SingleOwnerMeterProvider`
connects these implementations to the public base contracts without changing the
safe no-op providers. It is explicitly not concurrency-safe.

`metrics.reader.CumulativeMetricReader` takes an injected `Clock`, captures one
start timestamp and uses one nondecreasing wall timestamp for every point in a
collection. Collection is cumulative: failed or successful export never resets
instrument state. `metrics.model` snapshots scope, descriptors, attributes,
histogram arrays and points defensively.

`exporters.memory.InMemoryMetricExporter` retains at most its configured number
of collections, copies input and output snapshots, reports a typed limit failure
when full and has idempotent shutdown. `exporters.console.ConsoleMetricExporter`
emits one JsonWriter-escaped structured metrics record only when it fits the
configured byte limit. This JSON is a diagnostic console format, not OTLP JSON.
Both exporters are synchronous and single-owner; neither creates a worker,
listener or network request.

`metrics.concurrency.AtomicCounterCell` is an internal concurrency proof for one
attribute-free counter series. Ten real workers recording 1,000 increments each
produce exactly 10,000 on QBE and LLVM. It uses public `nox.atomic`, rejects
negative values and overflow, and may be freed only after every worker joins.
This evidence does not make `SingleOwnerMeterProvider` thread-safe.

`sdk.config.PulseConfig` validates a non-empty service name and finite attribute,
event, link, span, histogram-boundary, metric-cardinality, aggregation-memory,
queue, batch, payload, timeout and retry limits. The only provider implementation
with full SDK lifecycle is `DisabledPulseProvider`; it rejects `enabled=True`
instead of pretending exporters or workers exist. Its flush is immediate and its
shutdown is idempotent. The separate metrics-only `SingleOwnerMeterProvider` is
collected explicitly by a reader and remains intentionally experimental; it has
no concurrent mutation or provider-owned exporter lifecycle.

## Compatibility policy

Everything is unstable before `v1.0.0`. Breaking changes still require a changelog
entry and tests. Exporter/network behavior is never triggered by module import.
