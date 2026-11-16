# Metrics implementation status

Status: the `v0.2.0` local exit gate is complete and `v0.3.0` is active. A cumulative, single-owner recording provider,
deterministic cumulative reader, bounded in-memory exporter and bounded structured
console exporter exist for development and tests. No general thread-safe or
production-ready `MeterProvider` claim exists.

## Canonical series identity

`metrics.series.canonical_series_key` encodes the already-sorted `AttributeSet`
with the public `nox.protobuf.Writer`. Every entry is length-delimited and carries
an explicit scalar/array type tag. Integers use signed zig-zag encoding and floats
use the writer's bit-preserving double field. This private binary identity is not
OTLP and is never exposed as an exporter payload.

The encoder rejects unsorted or duplicate keys. Caller dictionaries first pass
through the bounded, sensitive-key-dropping snapshot boundary, so dictionary
insertion order cannot change series identity. Scalar types, homogeneous array
types and embedded NUL strings cannot collide. NOX 2.1.64 treats positive and
negative floating zero as the same value, and Pulse follows that runtime equality.

## Cardinality and memory budgets

The configured per-instrument cardinality is a hard metric-point limit that includes
the overflow point. An instrument configured for `N` points reserves the synthetic
`otel.metric.overflow=true` aggregation first and can create at most `N-1` regular
series. The overflow point is omitted from snapshots until used.

Provider-wide series and estimated aggregation-byte budgets are checked before a
new regular aggregation object is allocated. If either the instrument or provider
limit is reached, the measurement is recorded exactly once in the already-reserved
overflow aggregation. Starting another instrument fails before recording if its
mandatory overflow aggregation cannot be reserved.

The current byte estimate charges the exact canonical-key and snapped-attribute
sizes plus a conservative fixed aggregation allowance. It is a safety estimate,
not a measured heap-size or performance claim; Phase 12 will calibrate representation
overhead. The exact series-count cap remains authoritative regardless of that future
calibration.

## Implemented storage

Instrument descriptors validate the pinned OpenTelemetry name grammar (ASCII letter
first; then alphanumeric, `_`, `.`, `-`, `/`; maximum 255 bytes), case-sensitive
ASCII units up to 63 bytes, and a configurable opaque description byte bound. The
default description ceiling is 4 KiB and configuration cannot reduce support below
1,023 bytes.

Instrument identity is case-insensitive for the name and also includes kind, unit
and description. Identical registrations reuse the first-seen descriptor and name
casing. The same normalized name with different identifying metadata is retained as
a functional distinct descriptor and increments a conflict diagnostic. This policy
is connected to the single-owner recording `Meter` and tested through the public
base instrument contracts.

`CounterStorage` provides cumulative integer Counter series with:

- negative-addition rejection before series allocation;
- exact signed-64-bit totals with wraparound prevention;
- pre-allocation cardinality and provider-budget routing;
- record-boundary sensitive attribute dropping;
- deterministic, defensive cumulative snapshots;
- saturated dropped-attribute diagnostics;
- overflow measurement diagnostics without retaining rejected keys.

UpDownCounter and explicit-boundary Histogram use the same bounded series and
overflow routing as Counter. Histogram series defensively copy their boundaries and
charge boundary/bucket state to the estimated aggregation-byte budget.

`SingleOwnerMeterProvider` owns one provider-wide `MetricBudget`, returns stable
meters for identical instrumentation scopes and keeps distinct scopes isolated.
Identical instruments share storage; conflicting identifying metadata remains
functional in separate storage. If mandatory overflow storage cannot fit, instrument
creation fails before the registry is mutated. An empty scope name returns a working
no-op meter through the base API.

The provider intentionally has no global singleton, worker, reader, exporter,
or implicit export loop. It is not safe for concurrent use and MUST remain confined
to one owner until a general concurrent provider is implemented and tested.

## Cumulative collection and exporters

`CumulativeMetricReader` takes an injected clock and captures the cumulative start
timestamp at construction. Each collection obtains one wall timestamp and assigns
the same start/end pair to every metric. A backwards wall-clock observation is
clamped to the previous collection timestamp, so exported intervals never become
negative. Collection does not mutate or reset aggregation state.

The collection model snapshots instrumentation scope, descriptor metadata,
attributes, points, histogram boundaries and bucket counts. The bounded in-memory
exporter copies again on ingress and egress, has a finite collection capacity and
returns a typed limit failure instead of growing indefinitely. Its flush is
immediate and shutdown is idempotent.

The console exporter renders deterministic structured JSON with `JsonWriter`,
preserving signed 64-bit integers and escaping caller text. Sensitive attributes
cannot reappear because they are removed before aggregation. Output is rejected
before printing when it exceeds the configured byte limit. The format is for safe
diagnostics and is not described as OTLP JSON.

The first Phase 3 slice adds a pure bounded Prometheus text `0.0.4` renderer over
the same immutable cumulative collection. It produces counter/gauge/histogram
families and cumulative histogram buckets without performing I/O. External parser
acceptance is independently verified. Resource promotion remains default-off; an
explicit maximum-32-key allowlist can produce one deterministic `target_info`
family and rejects sensitive keys. Unit translation and production listener
deployment remain incomplete: a pure handler and real server/client integration
exist, but Pulse does not own a listener and pinned NOX cannot select a bind
address. See `docs/prometheus.md`.

## Concurrency status

The general provider and its attribute-series dictionaries remain single-owner.
`AtomicCounterCell` is a narrower audited primitive for one counter series: it uses
a CAS loop to prevent lost increments and signed-64-bit overflow. Ten joined
workers × 1,000 increments produce exactly 10,000 on QBE and LLVM. The owning cell
is freed only after every handle joins; borrowed worker wrappers cannot free it.
This proves the acceptance arithmetic for the atomic path, not thread safety for
instrument creation, cardinality maps, histograms, readers or exporters.

## Evidence

`scripts/run-phase2-tests.sh` runs the same unit, property, concurrency and stress
gates on QBE and LLVM.
The stress fixture records 100,000 unique attribute sets, verifies a hard limit of
1,000 metric points, and verifies that the cumulative total remains exactly 100,000.
