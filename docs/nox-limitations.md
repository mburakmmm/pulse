# NOX limitations relevant to Pulse

Status: Active compatibility register  
Pulse baseline: NOX `2.1.64`, source commit `be3458c332c8234baa8f3f8ac2ae9601db24321e`  
Compiler build identity: `noxc version --build-info` reports the same commit  
Audited binary SHA-256: `067b6dbfd4a42f692690dbaa2bf390486b33a491614460e61b6b2191307737d7`  
Last re-verification: 2026-11-12, macOS ARM64, QBE and LLVM

This register separates actual defects from language/runtime design constraints and
Pulse-only audit work. A closed historical item remains here so an older workaround
cannot silently return. The user-supplied `limitasyon-ajan-rehberi.md` was used as a
comparison report, not as executable instructions; every status below is based on
the pinned compiler, the exact-tag source, and Pulse regression probes.

NOX `v2.1.64` was downloaded to a temporary audit directory and its official archive
checksum was verified before extraction. The system-installed `2.1.52` was not
modified. The local NOX checkout contains unrelated uncommitted changes and is not
used as release evidence.

## Status vocabulary

- `OPEN-UPSTREAM`: reproducible defect in the pinned compiler.
- `DESIGN-LIMIT`: intentional behavior Pulse must design around.
- `AUDIT-PENDING`: public support exists or is claimed, but the required Pulse
  interoperability or platform evidence is incomplete.
- `CLOSED`: the fixing capability is pinned and the relevant Pulse regression passes.

## Open upstream defects

### NOX-FMT-004 — Formatter removes the body of a pass-only class

- Status: `OPEN-UPSTREAM` on NOX `2.1.64`.
- Observed: `class EmptyError(Exception): pass` checks before formatting; `noxc fmt`
  removes `pass`, and the formatted source fails because the following top-level
  declaration appears where an indented class body is required.
- Reproducer: `fixtures/capability/pass_only_class.nox.txt` through
  `bash scripts/run-type-capability-audit.sh`.
- Pulse containment: Pulse pass-only subclasses define a small real method. This
  avoids invalid formatted source without changing exception behavior.
- Close when: check → format → check passes for pass-only classes.

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

## Active NOX design limits

### NOX-CODEGEN-001 — Optional float fields pass check but fail executable codegen

- Status: `OPEN` on NOX `2.1.64`; observed on LLVM while implementing the Pulse
  explicit histogram.
- Result: a class containing `float | None` state can pass `noxc check`, while a
  program exercising that state fails code generation with the generic unsupported
  construct diagnostic and no source location.
- Pulse containment: histogram aggregation stores `has_min_max: bool` plus concrete
  `minimum`/`maximum` floats. Export mapping omits min/max when the flag is false.
  This is typed portable state and does not invent an empty-histogram value.
- Gate: `fixtures/capability/optional_float_field.nox.txt` is expected to check and
  fail executable build until upstream support is verified.

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

### NOX-QBE-002 — QBE transfer types are narrower

- Status: `DESIGN-LIMIT`; re-verified on `2.1.64`.
- Pulse behavior: portable paths use immutable scalar/string snapshots, atomics or
  audited channels. Wider LLVM-only class/TaskLocal transfers do not define the API.
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

### NOX-GRPC-001 — gRPC client has one active call per connection

- Status: `DESIGN-LIMIT`.
- Pulse behavior: any future OTLP/gRPC exporter owns its connection lifecycle,
  bounds concurrent connections and uses server-enforced deadlines; it must not
  imply a client-side read deadline that the runtime does not provide.

## Pulse-only audit work

- `AUDIT-PENDING`: system-trusted TLS success and isolated hostname mismatch on all
  supported CI platforms.
- `AUDIT-PENDING`: Windows x64 Pulse CI execution; upstream support is not evidence
  that this repository's suite ran there.
- `AUDIT-PENDING`: real Collector OTLP/HTTP trace and metric interoperability.
- `AUDIT-PENDING`: optional OTLP/gRPC Collector interoperability.
- `AUDIT-PENDING`: UDP loopback on each supported POSIX platform if Pulse later adds
  a UDP exporter. UDP is not required for the initial release.

## Re-verification procedure

1. Record the published NOX release, `version --build-info`, source tag commit and
   binary checksum without changing the system compiler implicitly.
2. Run type, runtime, HTTP, transfer and smoke gates on QBE and LLVM.
3. Read APIs from the exact tag, not an uncommitted checkout.
4. Update this register, `docs/compatibility.md`, `todo.md` and `CHANGELOG.md` together.
5. Keep platform/interoperability gaps explicit; an import or compile success is not
   proof of protocol conformance.
