# NOX limitations relevant to Pulse

- Status: Active compatibility register
- Pulse baseline: NOX `2.2.70`, source commit `4dc061f8c8443f8575092c2652d1109b6f4697e9`
- Latest published NOX audited: `2.2.107` on 2026-11-28, source commit `37e80cf9f0e273da4f612da0bb1f1c01c9473c6f`
- Compiler build identity: `noxc version --build-info` reports the same commit
- Audited macOS ARM64 binary SHA-256: `902f7c439b861282c1f7ce50b301e531c3842a079e09e53fa2a8a4ecd2a10acb`

See the [2.2.107 local verification](compatibility.md#latest-release-audit--nox-22107)
and the [2.2.70 pin migration](nox-upgrade-analysis-2.2.70.md). Entries retain
the original reproducers and identify any behavior specific to the CI pin.

This register separates actual defects from language/runtime design constraints and
Pulse-only audit work. A closed historical item remains here so an older workaround
cannot silently return. The user-supplied `limitasyon-ajan-rehberi.md` was used as a
comparison report, not as executable instructions; every status below is based on
the pinned compiler, the exact-tag source, and Pulse regression probes.

The local audit uses the existing compiler. CI verifies the release archive
checksum before extraction and checks the executable's source commit.

## Status vocabulary

- `OPEN-UPSTREAM`: confirmed defect that still reproduces on the latest audited release.
- `DESIGN-LIMIT`: intentional behavior Pulse must design around.
- `AUDIT-PENDING`: public support exists or is claimed, but the required Pulse
  interoperability or platform evidence is incomplete.
- `CLOSED`: the defect or capability gap is resolved upstream. An entry states
  separately whether Pulse's compiler pin includes the fix.

## Upstream triage for 2.2.107

**No registered compiler defect currently reproduces as an open upstream bug.**
The top-level optional guard still fails with `OptionalNotNarrowed`. The
connection-limited HTTP server still returns before the handler, and TaskLocal
still isolates children and rejects bare scalar types. These are recorded as
design boundaries below. The gRPC read deadline is a capability gap if Pulse
needs a hard client-side deadline for a future exporter.

## Regressions re-evaluated on the current pin

### NOX-STR-002 — String equality treats NUL as end of string

- Status: `CLOSED` upstream in the [v2.2.77 tag commit](https://github.com/mburakmmm/nox-lang/commit/3509c4a37d6dd7f5f8286724e3ebaac320c1cbad).
  Re-verified locally on 2.2.107. Pulse's 2.2.70 pin still reproduces it.
- Evidence: copy `fixtures/capability/nul_string_comparison.nox.txt` to a
  temporary `.nox` file, build with `noxc build --backend qbe` and repeat
  with `--backend llvm`. On macOS ARM64, both 2.2.70 executables report
  byte length `3` followed by `True` for equality to an empty string.
  Both 2.2.107 executables report `3` followed by `False`.
- Pulse containment: inspect byte length when recognizing empty W3C header
  members and reject NUL bytes in tokens before comparing baggage keys.
  The Baggage and tracestate regressions cover NUL-prefixed members.
- Pulse can review removing the version-specific workaround after advancing
  its pin and passing the probe on the supported platform matrix.

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

- Status: `CLOSED` in 2.2.63 and re-verified on 2.2.70.
- Evidence: copy `fixtures/capability/match_case_binding_scope.nox.txt` to a
  temporary `.nox` file. The old checker rejected different types sharing
  a binding name in distinct match arms. The current fixture compiles and
  prints `3` on both backends.

### NOX-ASYNC-001 — Cancelling a task waiting on an empty channel can deadlock

- Status: `CLOSED` in 2.2.63 and re-verified on 2.2.70.
- Evidence: copy `fixtures/capability/cancel_blocked_channel_receive.nox.txt`
  to a temporary `.nox` file. Build it using `noxc build --backend qbe`
  and `noxc build --backend llvm`. Both executables print `cancelled`.
  On 2.2.38 they exited with a runtime deadlock diagnostic.
- The tracing regression separately proves that `finally` closes the span
  during cancellation of a channel receiver and during task-await cancellation.

### NOX-TYPE-002 — Top-level raising guard does not narrow an optional

- Status: `DESIGN-LIMIT`, re-verified on NOX 2.2.70 and 2.2.107.
- Evidence: copy `fixtures/capability/optional_raise_narrowing.nox.txt`
  to a temporary `.nox` file. `noxc check` reports
  `OptionalNotNarrowed` at the field read following an `is None` branch
  that unconditionally raises.
- Containment: keep the field access inside the `is not None` branch.
  The tracing test checks the parent ID inside that branch.

### NOX-CODEGEN-003 — Context manager on a class field fails executable codegen

- Status: `CLOSED` in 2.2.63 and re-verified on 2.2.70.
- Evidence: copy `fixtures/capability/context_manager_field.nox.txt` to a
  temporary `.nox` file. On 2.2.38, the field-expression form failed in
  executable codegen. The current fixture compiles and prints `42` on QBE
  and LLVM. Pulse retains the existing explicit gate release in `finally`.

### NOX-HTTP-005 — Top-level `serve()` is not a handler join barrier

- Status: `DESIGN-LIMIT`, re-verified on NOX 2.2.70 and 2.2.107. The optional third
  `serve` argument counts accepted connections. Upstream documents a
  separate graceful shutdown path that waits up to the drain deadline.
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

- Status: `DESIGN-LIMIT`, reproduced on 2.2.107 with the two-backend
  `tests/smoke/task_local_smoke_test.nox` gate.
- Pulse behavior: pass immutable `TelemetryContext` explicitly. A scoped current-span
  convenience may be added only with explicit spawn handoff and cleanup tests.

### NOX-TASKLOCAL-003 — TaskLocal element types are restricted

- Status: `DESIGN-LIMIT` on 2.2.107. `noxc check` rejects
  `local: TaskLocal[int] = TaskLocal[int]()` with `TypeMismatch`.
  Supported payloads include classes, strings, lists and dictionaries.
- Pulse behavior: if a convenience layer is added, store one typed context class;
  do not attempt primitive or scheduler-bound payload tricks.

### NOX-QBE-001 — Hosted QBE previously had a single-threaded scheduler

- Status: `CLOSED` in [NOX 2.1.112](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/CHANGELOG.md#21112)
  for hosted targets. QBE and LLVM both support the M:N worker pool. Freestanding
  targets and explicitly single-worker configurations remain cooperative.
- Evidence: upstream `divergence_pool_run.nox` passes on 2.2.70 and 2.2.107
  with `NOX_POOL_WORKERS=2` on QBE and LLVM. The
  [tagged concurrency docs](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/language/concurrency.md#the-scheduler)
  describe both backends.
- Pulse behavior: background exporters still need bounded lifecycle and
  portable behavior tests before being advertised.

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

### NOX-MODULE-001 — Module state depends on the worker entry point

- Status: `DESIGN-LIMIT`, narrowed to `serve_multicore*` and
  `nox.thread.pool_run` worker entry points. Plain hosted tasks can share
  heap-backed module values. Compound mutations still require synchronization.
- Evidence: upstream `mn_shared_list.nox` matches golden output on 2.2.70 and
  2.2.107 with four configured workers on QBE and LLVM. The
  [tagged module docs](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/language/modules.md#module-level-state-and-the-multi-core-runtime)
  describe the entry-point distinction.
- Pulse behavior: providers and context ownership remain explicit.

### NOX-FS-001 — Filesystem paths are not confined

- Status: `DESIGN-LIMIT` in [2.2.107's filesystem API](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/fs.md).
  Applications can opt into `nox.path.safe_join` for path validation.
- Pulse requirement: a future file exporter must validate destinations against
  configured roots before opening files.

### NOX-FIBER-001 — The default hosted fiber stack is 192 KiB

- Status: `DESIGN-LIMIT` confirmed by [2.2.107's runtime source](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/runtime/async_rt/fiber.zig).
  Internal workers may use explicitly sized stacks.
- Pulse behavior: parsers and encoders are iterative and enforce message/depth limits.
  Compression is whole-buffer and therefore receives explicit payload bounds.

### NOX-HTTP-001 — `nox.http.request` is buffered and method-bounded

- Status: `DESIGN-LIMIT`, verified by the 2.2.107 QBE and LLVM HTTP audits.
  The restriction describes `request`; the public API also offers
  `stream` and `stream_upload` for chunked I/O.
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

- Status: `DESIGN-LIMIT` in the [2.2.107 gRPC client contract](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/grpc.md).
  The connection handles one call at a time and `timeout_ms` asks the
  server to enforce a deadline. An independent client-side read timeout
  remains unavailable in this API.
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
| Phase 5 — W3C Baggage | `NOX-STR-002` on 2.2.70, fixed upstream and verified on 2.2.107 | NUL comparison fixture and byte-length based header validation |

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
