# Common telemetry data model

Status: Phase 1 local gate complete.

## Attributes

`core.attributes.AttributeValue` is an exhaustive NOX enum with scalar boolean,
integer, float and text variants plus homogeneous arrays of those four types.
Integers remain signed 64-bit NOX `int` values and never pass through `float`.

`snapshot_attributes` performs the record-boundary snapshot:

1. sort keys for deterministic output;
2. reject empty/oversized keys;
3. drop configured sensitive-key classes before queueing;
4. validate finite floats and array/string limits;
5. copy every array;
6. enforce both attribute-count and estimated-owned-byte limits;
7. retain a dropped count.

The current pre-1.0 policy drops invalid, sensitive or over-limit entries while
retaining `dropped_count`. Invalid limit configuration raises `TelemetryError`.
String sizes are UTF-8 byte lengths, not code-point counts. Default limits follow
ADR-0005.

The built-in sensitive-key classifier is defense in depth, not a complete privacy
policy. Automatic instrumentation will additionally use explicit allowlists; that
work remains open.

## Resource and scope

`Resource` owns a snapped `AttributeSet`. Layer merge precedence is deterministic:

```text
explicit configuration > environment-derived metadata > safe defaults
```

No production service identity is guessed. `InstrumentationScope` requires a
non-empty name and carries optional version/schema URL plus snapped attributes.

## Identity and time

`TraceId` validates exactly 16 nonzero bytes and `SpanId` exactly 8, represented at
boundaries as lowercase hex. Each object also stores a distinct immutable byte-exact
raw `str` for future protobuf mapping. Production generation uses
`nox.crypto.secure_random_hex`; `SequenceIdGenerator` exists only as a deterministic
test seam.

The `Clock` contract separates wall-clock timestamps from monotonic duration time.
`SystemClock` uses `now_ns` and `monotonic_ns`; `TestClock` advances only explicitly.
Target precision is reported honestly as documented in `compatibility.md`.

## Bounded configuration

The centralized configuration covers attributes, events, links, event/link
attributes, span snapshots, histogram boundaries, per-instrument and provider-wide
metric cardinality, aggregation memory, queue records/bytes, batches, payloads,
scheduling, export/flush/shutdown timeouts and retry elapsed/attempt limits. All
defaults are finite and validated; no unlimited sentinel is supported.

Actual event/link enforcement belongs to the tracing implementation and actual
cardinality enforcement belongs to the metrics implementation. Having a validated
configuration value is not presented as enforcement before those phases land.

`tests/golden/attribute_snapshot.expected` locks deterministic ordering, JSON
escaping, homogeneous arrays, int64 fidelity above 2^53 and pre-record sensitive
key dropping on QBE and LLVM. It is a model snapshot fixture, not OTLP JSON.
