# NOX limitations relevant to Pulse

- Status: Active compatibility register
- Pulse baseline: NOX `2.2.38`, source commit `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a`
- Compiler build identity: `noxc version --build-info` reports the same commit
- Audited binary SHA-256: `26b63bdefef53584f87c34bc8b427197fc29ade1428317a7568028c960a87dce`

See the [2.2.38 upgrade audit](nox-upgrade-analysis-2.2.38.md) for current
verification. Entries retain the old reproductions where applicable.

This register separates actual defects from language/runtime design constraints and
Pulse-only audit work. A closed historical item remains here so an older workaround
cannot silently return. The user-supplied `limitasyon-ajan-rehberi.md` was used as a
comparison report, not as executable instructions; every status below is based on
the pinned compiler, the exact-tag source, and Pulse regression probes.

The current audit uses an isolated official archive verified before extraction.

## Status vocabulary

- `OPEN-UPSTREAM`: reproducible defect in the pinned compiler.
- `DESIGN-LIMIT`: intentional behavior Pulse must design around.
- `AUDIT-PENDING`: public support exists or is claimed, but the required Pulse
  interoperability or platform evidence is incomplete.
- `CLOSED`: the fixing capability is pinned and the relevant Pulse regression passes.

## Regressions re-evaluated on the current pin

### NOX-FMT-004 — Formatter removes the body of a pass-only class

- Status: `CLOSED` on 2.2.38. The check → format → check regression passes.
- Observed: `class EmptyError(Exception): pass` checks before formatting; `noxc fmt`
  removes `pass`, and the formatted source fails because the following top-level
  declaration appears where an indented class body is required.
- Reproducer: `fixtures/capability/pass_only_class.nox.txt` through
  `bash scripts/run-type-capability-audit.sh`.
- Pulse containment: Pulse pass-only subclasses define a small real method. This
  avoids invalid formatted source without changing exception behavior.
- Close when: check → format → check passes for pass-only classes.

### NOX-IO-001 — Redirected `nox.terminal.write_raw` fails on Windows

- Status: `CLOSED` on 2.2.38. The Windows x64 core job in
  [CI run #16](https://github.com/mburakmmm/pulse/actions/runs/44891047883/job/136806805128)
  passed exact redirected bytes on QBE and LLVM. The defect was confirmed on 2.1.64.
- Observed: a program using the public `nox.terminal.write_raw()` API throws
  `nox_terminal_TerminalError` when standard output is redirected to a file on
  Windows. The same operation succeeds on macOS and Linux. This was first
  isolated from the Phase 3 golden helper in
  [CI run #9](https://github.com/mburakmmm/pulse/actions/runs/43744840230/job/132905745139);
  the renderer unit suite itself passed before the helper failed.
- Reproducer: `tests/capability/terminal_redirect_probe.nox`, built and executed
  through `bash scripts/run-terminal-redirect-audit.sh <llvm|qbe>`.
- Pulse containment: telemetry renderers remain pure string functions. Portable
  golden helpers use `print(nox.strings.trim_end(payload))` and normalize CRLF;
  they do not use the raw terminal API.
- Gate: every core target now requires exact redirected bytes on both backends.
- Remote evidence: [CI run #12](https://github.com/mburakmmm/pulse/actions/runs/43823208141)
  observed `write_raw=known-incompatible` on Windows x64 LLVM and QBE, while the
  portable golden renderer test passed on both backends.

## Closed historical defects

### NOX-FLOAT-001 — NaN comparison backend mismatch

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: parsed and computed NaN values satisfy `x != x` on QBE and LLVM;
  ordered comparisons remain false.
- Gate: `bash scripts/run-runtime-capability-audit.sh llvm|qbe`.

### NOX-FMT-001 — Generic class parameters deleted by formatter

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: `class Box[T]` survives check → format → check.
- Gate: `bash scripts/run-type-capability-audit.sh`.

### NOX-FMT-002 — NUL escape materialized as a source byte

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: formatted source remains text and contains no literal zero byte.
- Gate: `bash scripts/run-type-capability-audit.sh`.

### NOX-FMT-003 — Large finite float formatting failed with `NoSpaceLeft`

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: accepted exponent literals survive check → format → check.
- Gate: `bash scripts/run-type-capability-audit.sh`.

### NOX-PARSER-001 — Direct signed-int minimum literal rejected

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: `-9223372036854775808` checks, formats and runs exactly.
- Gates: type capability audit and `modern_stdlib_smoke_test.nox`.

### NOX-TASKLOCAL-001 — Uncleared TaskLocal values leaked at fiber teardown

- Status: `CLOSED` upstream in NOX `2.1.2`.
- Upstream evidence: pinned changelog and tagged source regression cover class,
  `str`, `list` and `dict` release on normal return, exception and cancellation.
- Pulse decision: this fix does not change `NOX-TASKLOCAL-002`; explicit immutable
  `TelemetryContext` remains the foundational API and automatic inheritance is not
  advertised.

### NOX-PROVENANCE-001 — Compiler did not identify its source revision

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: `noxc version --build-info` reports version, exact commit, Zig version,
  target and optimization mode. The reported commit equals tag `v2.1.64`.

### NOX-HTTP-003 — GET body was silently discarded

- Status: `CLOSED` in NOX `2.1.2`; re-verified on `2.1.64`.
- Result: a non-empty GET body raises `HttpError` on QBE and LLVM.
- Gate: `bash scripts/run-http-capability-audit.sh llvm|qbe`.

### NOX-TYPE-001 — No tagged union / enum declaration

- Status: `CLOSED` by NOX `2.1.21`–`2.1.31`; re-verified on `2.1.64`.
- Result: typed generic enums, exhaustive `match`, nested patterns, literals and
  guards are public language features.
- Gate: `modern_stdlib_smoke_test.nox`.
- Pulse consequence: Phase 1 may use enums for result/error and typed attribute
  representations; ADR-0003 must be superseded where it assumed enums were absent.

### NOX-CLOCK-001 — Only millisecond clocks were public

- Status: `CLOSED` in NOX `2.1.13`; re-verified on `2.1.64`.
- Result: `nox.time.now_ns()` and `monotonic_ns()` are public.
- Precision caveat: platform resolution remains honest—about 1 ns on macOS/Linux,
  100 ns on Windows and 1 ms on WebAssembly. Pulse records the platform precision
  and never invents accuracy.

### NOX-JSON-001 — Exact JSON int64 parsing unavailable

- Status: `CLOSED` in NOX `2.1.7`; re-verified on `2.1.64`.
- Result: `nox.json.as_int` and `number_text` preserve
  `9007199254740993`; `dump` retains its text.
- Caveat: `as_number` is still binary64 and remains unsuitable for exact integers.

### NOX-STR-001 — `char_from_byte(0)` returned an empty string

- Status: `CLOSED` in NOX `2.1.30`; re-verified on `2.1.64`.
- Result: it returns one zero byte; length-prefixed `str` remains byte-exact.

### NOX-CAP-PROTOBUF-001 — No public protobuf encoder/decoder

- Status: `CLOSED` in NOX `2.1.18`; re-verified on `2.1.64`.
- Result: `nox.protobuf.Writer` and `Reader` implement official wire types,
  malformed-input errors and byte-exact `to_str`/`to_bytes` paths.
- Remaining Pulse work: pin OTLP schemas and prove emitted OTLP with an independent
  decoder and real Collector before advertising interoperability.

### NOX-CAP-GRPC-001 — No public gRPC client

- Status: `CLOSED` as a language capability by NOX `2.1.33`–`2.1.42`.
- Result: public h2c/TLS client, metadata, deadlines, streaming, gzip and mTLS exist.
- Remaining Pulse work: OTLP/gRPC is optional and stays `AUDIT-PENDING` until a real
  Collector conformance suite passes. OTLP/HTTP remains the initial stable transport.

### NOX-CAP-UDP-001 — No public UDP API

- Status: `CLOSED` in NOX `2.1.15`; import/query re-verified on `2.1.64`.
- Result: `nox.udp` supports POSIX datagrams with bounded receive size and timeout.
- Platform caveat: Windows and WebAssembly report unsupported by design.

### NOX-CAP-BYTES-001 — No Buffer/list-to-str binary bridge

- Status: `CLOSED` in NOX `2.1.13`; re-verified on `2.1.64`.
- Result: `str_from_list`, `list_from_str`, `to_str`, `to_list` and `from_list`
  preserve NUL and high bytes.

### NOX-CAP-COMPRESSION-001 — Binary gzip request path unproven

- Status: `CLOSED` for the local byte path on `2.1.64`.
- Result: `compress_bytes`/`decompress_bytes` and `nox.bytes` round-trip exact bytes.
- Protocol caveat: OTLP compressed export is not advertised until the Collector
  integration test verifies headers, payload limits and failure handling.

## Code generation regressions

### NOX-CODEGEN-001 — Optional float fields pass check but fail executable codegen

- Status: `CLOSED` on 2.2.38. The fixture builds on QBE and LLVM. The
  original error was observed on LLVM with 2.1.64.
- Result: a class containing `float | None` state can pass `noxc check`, while a
  program exercising that state fails code generation with the generic unsupported
  construct diagnostic and no source location.
- Pulse containment: histogram aggregation stores `has_min_max: bool` plus concrete
  `minimum`/`maximum` floats. Export mapping omits min/max when the flag is false.
  This is typed portable state and does not invent an empty-histogram value.
- Gate: `fixtures/capability/optional_float_field.nox.txt` checks and builds on both backends.

### NOX-CODEGEN-002 — Imported enum payload list iteration loses codegen support

- Status: `CLOSED` for the original build failure. The fixture builds on
  2.2.38 QBE and LLVM. The Phase 2 console exporter exposed the error on 2.1.64.
- Observed: a function can type-check when it matches an imported enum whose
  payload is an imported snapshot class and directly iterates the payload's
  `list[T]` field, but executable build fails with the generic unsupported-
  construct diagnostic and no source location.
- Reproducer: `fixtures/capability/imported_metric_data_iterable.nox.txt`.
  The type audit builds the direct fixture and the existing helper path.
- Pulse containment: enum matching only dispatches to concrete-typed helper
  functions. Each helper accepts the exact snapshot class and performs the list
  iteration outside the pattern-bound payload scope. The same audit builds this
  containment on QBE and LLVM, and the console exporter behavioral suite passes
  on both backends.
## Active NOX design limits and capability boundaries

### NOX-TYPE-003 — Match arms share the checker scope for payload bindings

- Status: `DESIGN-LIMIT` on NOX 2.2.38.
- Evidence: copy `fixtures/capability/match_case_binding_scope.nox.txt` to a
  temporary `.nox` file and run `noxc check`. Using `payload` for both a
  string and an integer in distinct match arms yields `TypeMismatch`.
- Containment: use distinct binding names for payloads of different types.
  The trace snapshot copier uses different bindings for string and boolean arrays.

### NOX-ASYNC-001 — Cancelling a task waiting on an empty channel can deadlock

- Status: `OPEN-UPSTREAM` on NOX 2.2.38, commit
  `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a`.
- Evidence: copy `fixtures/capability/cancel_blocked_channel_receive.nox.txt`
  to a temporary `.nox` file. Build it using `noxc build --backend qbe`
  and `noxc build --backend llvm`. On macOS ARM64 both executables exit
  with code 1 and `deadlock detected — all tasks are blocked, none can make progress`.
- Containment: design an explicit wakeup path for channel consumers and
  avoid using `Task.cancel()` as their only shutdown signal. The tracing
  cancellation regression exercises a worker waiting on another task.
  Its `finally` closes the span before cancellation reaches the owner.

### NOX-TYPE-002 — Top-level raising guard does not narrow an optional

- Status: `DESIGN-LIMIT` on NOX 2.2.38.
- Evidence: copy `fixtures/capability/optional_raise_narrowing.nox.txt`
  to a temporary `.nox` file. `noxc check` reports
  `OptionalNotNarrowed` at the field read following an `is None` branch
  that unconditionally raises.
- Containment: keep the field access inside the `is not None` branch.
  The tracing test checks the parent ID inside that branch.

### NOX-CODEGEN-003 — Context manager on a class field fails executable codegen

- Status: `OPEN-UPSTREAM` on NOX 2.2.38, verified locally on macOS ARM64.
- Evidence: copy `fixtures/capability/context_manager_field.nox.txt` to a
  temporary `.nox` file. `noxc check` succeeds. Both
  `noxc build --backend qbe` and `noxc build --backend llvm` return the
  generic unsupported-construct diagnostic for `with self.guard as held`.
- Containment: acquire explicitly and unlock in `finally`. The provider
  regression verifies both normal returns and recovery after a rejected record.

### NOX-HTTP-005 — Top-level `serve()` is not a handler join barrier

- Status: `OPEN-UPSTREAM` on NOX 2.2.38, verified locally on macOS ARM64.
- Evidence: compile `fixtures/capability/http_serve_return_order.nox.txt`
  as a temporary `.nox` on either backend. Run the binary with an unused
  loopback port and issue a GET to that port. Both backends return
  `serve-returned`, so code following top-level `serve()` has executed
  before the handler. Closing a Pulse provider at that point made the live
  handler reject collection with `metric provider is closed`.
- Containment: the HTTP fixture hands the handler a detached snapshot. Users
  must establish quiescence through explicit worker ownership before freeing
  a provider shared with live handlers.

### NOX-TASKLOCAL-002 — Spawned tasks do not inherit TaskLocal values

- Status: `DESIGN-LIMIT`.
- Pulse behavior: pass immutable `TelemetryContext` explicitly. A scoped current-span
  convenience may be added only with explicit spawn handoff and cleanup tests.

### NOX-TASKLOCAL-003 — TaskLocal element types are restricted

- Status: `DESIGN-LIMIT`.
- Pulse behavior: if a convenience layer is added, store one typed context class;
  do not attempt primitive or scheduler-bound payload tricks.

### NOX-QBE-001 — QBE scheduling is cooperative

- Status: `DESIGN-LIMIT`.
- Pulse behavior: exporter work is synchronous or explicitly cooperatively polled;
  it is never marketed as background parallelism.

### NOX-QBE-002 — QBE rejected audited class and TaskLocal transfers

- Status: `CLOSED` for the three original probes on 2.2.38. QBE and LLVM
  accept class arguments via spawn/thread and preserve TaskLocal isolation.
- Scope: a worker can mutate a nested dictionary and the parent observes it
  after join. Test shared provider state, runtime memory ownership and races
  separately before advertising concurrent collection.
- Evidence: [CI run #16](https://github.com/mburakmmm/pulse/actions/runs/44891047883)
  passed the joined and locked dictionary probes on both backends in all three
  Unix capability jobs. See the upgrade audit for the original ARM64 assertion
  failure and the bounded contention probe used in the follow-up.
- Gate: `bash scripts/run-backend-transfer-audit.sh`.

### NOX-MODULE-001 — Mutable module state is worker-local

- Status: `DESIGN-LIMIT`.
- Pulse behavior: no module-global current span or aggregation map is assumed to be
  process-global. Providers and ownership are explicit.

### NOX-FS-001 — Filesystem paths are not confined

- Status: `DESIGN-LIMIT`.
- Pulse behavior: file exporter destinations are canonicalized and checked against
  configured roots before opening; untrusted paths are rejected.

### NOX-FIBER-001 — Fiber stacks are fixed at 192 KiB

- Status: `DESIGN-LIMIT`.
- Pulse behavior: parsers and encoders are iterative and enforce message/depth limits.
  Compression is whole-buffer and therefore receives explicit payload bounds.

### NOX-HTTP-001 — `nox.http.request` is buffered and method-bounded

- Status: `DESIGN-LIMIT`.
- Pulse behavior: OTLP/HTTP uses POST, positive timeouts, bounded payloads and an
  explicit redirect/credential policy. Export failures never log full headers/body.

### NOX-HTTP-004 — Public HTTP server bind address was not configurable

- Status: `CLOSED` for public API availability. NOX 2.2.38 exposes
  `nox.http.configure(bind_address="127.0.0.1")`. The real scrape uses this
  setting on both backends.
- Evidence: public `nox.http.serve`, `serve_fd`, `serve_multicore` and `listen`
  accept a port/ip-family but no host or bind-address value. The pinned upstream
  changelog documents that server listeners bind `0.0.0.0` on all interfaces
  since NOX `1.7.1`.
- Pulse behavior: the Prometheus package exposes a pure `HttpRequest` →
  `HttpResponse` adapter. Applications select loopback or an explicit remote
  address with deployment access controls.
- Gate: `scripts/run-prometheus-scrape-integration.sh` proves real HTTP response,
  bounds and graceful shutdown; it is a protocol integration test, not proof of
  loopback confinement.
- Remote evidence: [CI run #12](https://github.com/mburakmmm/pulse/actions/runs/43823208141)
  passed the real scrape fixture on QBE and LLVM across all four core targets;
  the Linux conformance job independently parsed both HTTP bodies with promtool.

### NOX-GRPC-001 — gRPC client has one active call per connection

- Status: `DESIGN-LIMIT`.
- Pulse behavior: any future OTLP/gRPC exporter owns its connection lifecycle,
  bounds concurrent connections and uses server-enforced deadlines; it must not
  imply a client-side read deadline that the runtime does not provide.

## Pulse-only audit work

- `AUDIT-PENDING`: system-trusted TLS success and isolated hostname mismatch on all
  supported CI platforms.
- `AUDIT-PENDING`: real Collector OTLP/HTTP trace and metric interoperability.
- `AUDIT-PENDING`: optional OTLP/gRPC Collector interoperability.
- `AUDIT-PENDING`: UDP loopback on each supported POSIX platform if Pulse later adds
  a UDP exporter. UDP is not required for the initial release.

## Phase evidence ledger

Every implementation phase must record newly observed NOX behavior here before
the phase gate can close. An item is added only after a minimal compiling or
failing probe distinguishes a compiler/runtime limitation from a Pulse defect.

| Pulse phase | Newly evidenced NOX items | Permanent gate / containment |
|---|---|---|
| Phase 0 — audit | `NOX-FMT-004`; QBE/task-local/module/thread design limits; historical fixes re-verified | Type/runtime/transfer/smoke audit scripts |
| Phase 1 — primitives | No new upstream defect; exact int64, clocks, IDs, protobuf and typed enums remained verified | QBE + LLVM primitive unit/property/security/golden suites |
| Phase 2 — metrics core | `NOX-CODEGEN-001`, `NOX-CODEGEN-002` | Explicit histogram presence flag; concrete snapshot helpers; expected-failure fixtures plus two-backend positive tests |
| Phase 3 — Prometheus MVP slices | `NOX-IO-001`, `NOX-HTTP-004`; no new compiler/runtime issue in allowlisted `target_info` or pinned unit translation | Pure renderer/handler and unit table/rate/annotation logic pass QBE + LLVM across the [run #13 matrix](https://github.com/mburakmmm/pulse/actions/runs/44791381303); redirected `write_raw` has an expected-failure probe; listener ownership stays with the application because public NOX cannot bind loopback explicitly |
| Phase 3 — NOX 2.2.38 baseline | Formatter, two codegen cases, audited QBE transfer and explicit bind API restrictions lifted | Positive regressions on QBE and LLVM. Windows redirected output requires exact bytes. Shared metric-provider safety remains Pulse audit work. |

Future phases append a row or explicitly record “no new NOX limitation observed”
with the exact capability and behavioral commands used for that conclusion.

## Re-verification procedure

1. Record the published NOX release, `version --build-info`, source tag commit and
   binary checksum without changing the system compiler implicitly.
2. Run type, runtime, HTTP, transfer and smoke gates on QBE and LLVM.
3. Read APIs from the exact tag, not an uncommitted checkout.
4. Update this register, `docs/compatibility.md`, `todo.md` and `CHANGELOG.md` together.
5. Keep platform/interoperability gaps explicit; an import or compile success is not
   proof of protocol conformance.
