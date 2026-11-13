# Metrics implementation status

Status: `v0.2.0` active. A cumulative, single-owner recording provider exists for
development and deterministic tests. No thread-safety, reader, exporter or
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
`force_flush` or shutdown lifecycle yet. It is not safe for concurrent use and MUST
remain confined to one owner until the LLVM multi-worker design and QBE behavior are
implemented and tested.

## Evidence

`scripts/run-phase2-tests.sh` runs the same unit and stress gates on QBE and LLVM.
The stress fixture records 100,000 unique attribute sets, verifies a hard limit of
1,000 metric points, and verifies that the cumulative total remains exactly 100,000.
