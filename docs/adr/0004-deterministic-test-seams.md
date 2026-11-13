# ADR-0004: Deterministic test seams

- Status: Accepted for Phase 0; interfaces implemented incrementally
- Date: 2026-11-08

## Context

Pulse behavior depends on wall time, monotonic duration, secure identifiers, transport outcomes, scheduling and exported snapshots. Tests that use the real clock, entropy or network cannot reliably prove sampling, retry, temporality, shutdown and wire behavior. AGENTS.md requires injected clock, ID generator, transport and deterministic in-memory exporters.

NOX module state may be worker-local, so test doubles cannot depend on mutable process-global fixtures. QBE and LLVM also have different scheduling models.

## Decision

### Clock seam

- A typed `Clock` contract exposes wall milliseconds and a monotonic instant/duration operation as separate concepts.
- Production uses `nox.time.now_ms()` and `instant_now()`/`elapsed_ms()`.
- `TestClock` advances only through explicit test calls. Wall-clock jumps and monotonic progress can be controlled independently.
- OTLP conversion multiplies wall milliseconds to the required unit while retaining documented millisecond precision.

### ID seam

- A typed `IdGenerator` contract creates trace and span identity values.
- Production draws from `secure_random_hex` and validates length/all-zero boundaries.
- `SequenceIdGenerator` consumes a finite configured sequence and fails a test if exhausted; it never appears in production configuration.
- Tests provide canonical byte/text pairs and do not fabricate production entropy claims.

### Transport seam

- OTLP exporters depend on a typed transport interface, not directly on `nox.http`.
- A request snapshot includes method, endpoint, ordered/sanitized headers, exact body bytes, timeout and recursion-suppression marker.
- A response snapshot includes status, bounded headers and exact body bytes; failures use explicit timeout/transport/permanent categories.
- `ScriptedTransport` returns a finite sequence of responses/errors and records bounded immutable requests for assertions.
- No test transport performs network activity unless the test is explicitly classified as integration/conformance.

### In-memory sink seam

- Trace and metric memory exporters store defensive immutable snapshots in acceptance order.
- Capacity is finite and configured; overflow behavior is explicit and observable.
- Snapshot reads return copies in deterministic order and cannot mutate exporter state.
- Reset/clear exists only for test ownership between completed operations, never as production temporality behavior.

### Scheduling and lifecycle

- Concurrency tests coordinate with channels/barriers, not sleeps or assumed task order.
- Flush tests use an accepted-record barrier and injected deadlines.
- Shutdown tests retain/join every worker before freeing queues, atomics, transports or sinks.
- QBE and LLVM run the same behavioral fixtures; LLVM-only multi-worker stress is an additional suite, not a replacement.

## Test classification

- Unit: injected seams only, deterministic, no filesystem/network.
- Golden: deterministic canonical text/bytes compared with committed fixtures.
- Integration: loopback filesystem/network or real package loading, explicitly labelled.
- Conformance: independent parser/decoder or real Collector/Prometheus tooling.
- Concurrency: barriers, cancellation and multi-worker ownership.
- Security: malformed/untrusted inputs and default-deny capture.
- Benchmark: measured release configuration; never used as correctness evidence.

## Consequences

- Public SDK constructors accept explicit dependencies internally even when ergonomic factories supply production defaults.
- No test-only generator or transport can be selected through untrusted production environment variables.
- Retry, sampling, temporality and shutdown logic can be proven without waiting in real time.
- Interface syntax is implemented only after a compiling NOX Phase 1 spike; this ADR fixes behavior, not unverified source syntax.
