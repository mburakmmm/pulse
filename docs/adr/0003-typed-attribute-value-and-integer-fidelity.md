# ADR-0003: Typed AttributeValue and integer fidelity

- Status: Accepted for Phase 0; implementation starts in Phase 1
- Date: 2026-11-08

## Context

OpenTelemetry attributes require booleans, signed integers, floating-point numbers, strings and allowed homogeneous arrays. Pulse must preserve signed 64-bit integers without silently converting them to float.

NOX 2.1.0 provides `T | None` but no arbitrary tagged union or enum declaration. Generic classes are also unavailable to Pulse-authored source while the pinned formatter removes their type parameters. A dynamic `Any` payload would weaken the public contract and move type errors into exporters.

## Decision

1. `AttributeValue` is one non-generic, typed class with an explicit integer kind discriminator and optional typed storage fields.
2. Scalar storage fields are `bool | None`, `int | None`, `float | None` and `str | None`.
3. Array storage fields are optional homogeneous `list[bool]`, `list[int]`, `list[float]` and `list[str]` values. Mixed arrays and nested arrays are rejected.
4. Exactly one storage field must be populated and it must match the kind. Construction happens through typed factory functions; the raw all-fields constructor is not part of the stable API.
5. Kind values are class constants in a non-instantiated `AttributeKind` namespace. They are internal model tags, not OTLP wire enum values.
6. Every array and string is defensively copied or normalized at record time, after limits and privacy policy run. Caller mutation cannot alter a recorded value.
7. Integer values remain NOX `int` throughout the model. JSON output uses `JsonWriter.write_int`; protobuf mapping writes the signed 64-bit representation required by the pinned field. No integer-to-float storage shortcut is allowed.
8. Float constructors reject disallowed NaN/infinity according to the instrument/export contract. Implementation is gated on resolving or safely working around `NOX-FLOAT-001`; self-inequality is forbidden as a validator.
9. Invalid kind/storage combinations fail immediately with `TelemetryError`; exporters never guess or coerce them.
10. Attribute maps snapshot keys and values, apply count/value/array limits before enqueueing and sort keys explicitly for canonical output.

## Illustrative shape

This is a design sketch, not executable API until Phase 1 compiling tests exist:

```text
AttributeValue
  kind: int
  bool_value: bool | None
  int_value: int | None
  float_value: float | None
  string_value: str | None
  bool_array: list[bool] | None
  int_array: list[int] | None
  float_array: list[float] | None
  string_array: list[str] | None
```

## Rejected alternatives

- Float-only numeric storage: loses integers above `2^53` and violates OTLP fidelity.
- Stringifying every value: destroys type semantics and metric aggregation correctness.
- Base-class subclasses with runtime downcasts: NOX has no audited general runtime type-test/downcast surface suitable for exporter mapping.
- Protocol methods that encode directly: couples the core data model to exporters and makes new encodings invasive.
- Generic `AttributeValue[T]`: currently formatter-unsafe and does not solve heterogeneous attribute maps.
- Dynamic `Any`: not a verified NOX public type and contradicts the typed API contract.

## Consequences

- The flat representation trades some object size for portable, explicit type safety.
- Factories and invariant tests are mandatory before any public exposure.
- Array limits, copying cost and per-record memory budget must be measured in Phase 1/12.
- If NOX later gains a stable tagged union, migration requires a compatibility ADR and changelog entry; it is not an automatic rewrite.
