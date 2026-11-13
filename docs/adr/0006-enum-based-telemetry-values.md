# ADR-0006: Enum-based telemetry values on pinned NOX 2.1.x

- Status: Accepted
- Date: 2026-11-11
- Supersedes: the storage-shape portion of ADR-0003

## Context

ADR-0003 was written against NOX 2.1.0, where arbitrary tagged unions and enum
declarations were unavailable. The pinned NOX 2.1.64 provides generic enums, exhaustive
`match`, nested patterns and formatter support on QBE and LLVM.

## Decision

Pulse uses typed enums for closed telemetry domains:

- `AttributeValue` variants for bool, int, float, string and each allowed
  homogeneous array kind;
- lifecycle/export result variants where a closed set of outcomes is appropriate;
- internal validation decisions that callers must handle exhaustively.

Integer values remain `int` end-to-end and are never converted through `float`.
Constructors copy list inputs before a record becomes observable. Public helpers
return copies where exposing an owned mutable list would allow retroactive mutation.

Enums do not remove the need for limits. Attribute key length, string byte length,
array length, attribute count and aggregate cardinality are validated before the
value enters an aggregation or export queue.

## Consequences

- The public model is more explicit and exhaustive than the optional-field class
  fallback described by ADR-0003.
- Pattern matching stays statically checked as new variants are introduced.
- This is a pre-1.0 API; adding a variant remains a reviewed compatibility change
  and receives a changelog entry.
- TaskLocal, QBE transfer and module-global constraints are unchanged. An enum
  value is not automatically safe to share across workers.
