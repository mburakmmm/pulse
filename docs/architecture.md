# Architecture

Status: Phase 2 active; pre-1.0 public contracts are implemented but not frozen.

## Dependency direction

```text
application / optional adapter
              ↓
           pulse.api
              ↓
       core telemetry model
        ↙             ↘
 metrics SDK        tracing SDK
        ↘             ↙
 readers / processors / bounded runtime
              ↓
      exporter interfaces
              ↓
 memory / console / Prometheus / OTLP
```

Core may depend only on the pinned NOX standard library and separately reviewed minimal utilities. Aether, Nyx, Nova, Feather, Atlas, Quartz, Obsidian, Aura and VAULT are optional leaf integrations and must never be imported by core modules.

`scripts/check-import-boundaries.sh` enforces this direction in CI: framework packages are forbidden from API/core/SDK/runtime/exporter roots, and the stable `api`/`core` roots cannot import SDK, OTLP, runtime, exporter or integration layers.

## Module layout decision

NOX 2.1.64 continues to resolve package modules from the repository root. A consumer dependency aliased as `pulse` loads `api/metrics.nox` as `pulse.api.metrics`. The proposed Python-style `pulse/__init__.nox` tree in `AGENTS.md` is therefore not executable under the audited loader and will not be used.

Planned physical layout:

```text
api/             Stable instrumentation-facing types
core/            Shared attributes, resource, scope, clock, IDs and limits
metrics/         SDK aggregation and readers
tracing/         SDK spans, propagation, sampling and processors
otlp/            Pinned mapping and encoding
exporters/       Exporter implementations
runtime/         Bounded queues, retry, shutdown and diagnostics
integrations/    Optional framework/Obsidian leaves
```

There is no `__init__.nox` facade convention. Public entry points will be documented by their actual module paths.

## Context and state

`TelemetryContext` will be an explicitly passed immutable value. No module-global current span is permitted. A scoped convenience API can be added only after task spawn, cancellation, cross-thread handoff and restoration behavior pass on both backends.

Module globals may be worker-local under the multi-core runtime, so shared aggregation must use an audited ownership strategy: explicit snapshots, worker-local aggregation with synchronized merge, atomics for suitable scalars or channel ownership. The choice must be recorded before metrics implementation.

## Lifecycle boundaries

- Caller-owned attributes are copied and limited before recording.
- Sensitive data is removed before enqueueing.
- Application recording locks are never held during exporter I/O.
- Queues, retries, payloads and shutdown deadlines are finite.
- `force_flush` uses an acceptance barrier and returns a truthful result.
- `shutdown` rejects new data, joins workers and releases storage exactly once.

## Protocol boundaries

Prometheus and OTLP have independent reader semantics. OTLP support requires real pinned protobuf encoding plus independent decoding and Collector acceptance. OTLP/gRPC remains unsupported until a real NOX-compatible gRPC/HTTP2 transport is proven.

`scripts/check-private-abi.sh` rejects `__nox_*` references and direct linkage to the private `noxrt.o` object. Any future native glue requires a documented public NNI contract and a separate reviewed ADR before an allowlist can be introduced.

