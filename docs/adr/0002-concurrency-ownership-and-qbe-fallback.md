# ADR-0002: Concurrency ownership and QBE fallback

- Status: Accepted for Phase 0
- Date: 2026-11-08

## Context

NOX 2.1.0 has materially different execution models. LLVM can schedule tasks across multiple workers; QBE uses cooperative scheduling. Module-level mutable state may be worker-local. Public threads, task channels, thread channels and scalar atomics exist, but their allowed argument and lifetime rules are narrower than arbitrary shared-object concurrency.

Phase 0 probes verified `spawn`/`await`, bounded task channels, cancellation delivered at an await point, joined worker threads, scalar `ThreadChannel` transfer, atomic handle sharing and compare-and-swap on both backends. They did not prove a portable implicit task-local context, a nonblocking bounded batch queue, or safe arbitrary object sharing.

## Decision

1. Pulse state has an explicit owner. Mutable aggregation, queue and lifecycle objects are never assumed to be process-global merely because they are module variables.
2. Explicit immutable `TelemetryContext` remains the only baseline context mechanism. Task-local convenience is a separately gated feature.
3. The first correct processor path is synchronous. A background batch processor is added only after bounded enqueue, flush barriers, cancellation and shutdown ownership pass dedicated LLVM and QBE tests.
4. QBE may use synchronous export or an explicitly polled cooperative worker. Pulse will not describe cooperative scheduling as parallel background execution.
5. LLVM worker/thread support may use channels or scalar atomics only behind typed ownership boundaries. Exporter I/O never runs while holding application recording state.
6. Every started worker handle is retained and joined before its queue, transport, atomic or backing storage is released. Atomic `free()` occurs only after all users have joined.
7. Cross-thread payloads are immutable snapshots or values copied through an audited channel. Arbitrary caller-owned mutable objects are not shared.
8. `force_flush()` and `shutdown()` require explicit finite deadlines and truthful result states; neither may wait indefinitely.

## Consequences

- QBE and LLVM may use different internal scheduling strategies while preserving the same public lifecycle results.
- “Thread-safe” is not a package-wide label. It is granted per type only after stress and race-oriented evidence.
- Module globals cannot own the default provider until an isolation and reconfiguration design is separately accepted.
- Phase 0 smoke evidence establishes primitives only; it does not establish the future batch processor's correctness.
