# NOX compatibility audit

The current compiler pin is NOX 2.2.70. See the
[pin migration audit](nox-upgrade-analysis-2.2.70.md) for baseline evidence and
the [platform matrix](platform-support.md) for remote evidence.

## Selected baseline

| Item | Value | Evidence |
|---|---|---|
| Published NOX release | `2.2.70` | Official `v2.2.70` release |
| Exact source commit | `4dc061f8c8443f8575092c2652d1109b6f4697e9` | Release tag and compiler build identity |
| Compiler build identity | same commit | `noxc version --build-info` |
| Audited compiler SHA-256 | `902f7c439b861282c1f7ce50b301e531c3842a079e09e53fa2a8a4ecd2a10acb` | Installed macOS ARM64 binary |
| Compiler toolchain | Zig `0.16.0`, `aarch64-macos`, `ReleaseFast` | build-info output |
| Test installation | Existing compiler locally, checksum-verified release archives in CI | System installation untouched |
| Profile | `hosted` | Required for clock, network, filesystem and secure entropy |
| Locally tested backends | LLVM and QBE | 10-file smoke suite plus capability audits |
| CI targets | macOS ARM64, Linux x64, Linux ARM64, Windows x64 | See platform matrix for the tested revision |

## Verified public capabilities

| Capability | Exact public surface / observed behavior | Pulse decision |
|---|---|---|
| Package layout | repository-root modules import through dependency aliases; `__init__.nox` is not a Python-style facade | Keep `api/...`, `core/...` root modules |
| Build identity | `noxc version --build-info` returns exact commit | CI asserts version and commit, not version string alone |
| Types | classes, structural protocols, generic classes/functions, optionals, generic enums and exhaustive `match` compile | Use enum-based typed results/values; no `Any` shortcut |
| Wall clock | `nox.time.now_ns() -> int` | OTLP timestamps use real platform resolution |
| Monotonic clock | `nox.time.monotonic_ns() -> int` | Durations never use wall-clock subtraction |
| Clock precision | about 1 ns macOS/Linux, 100 ns Windows, 1 ms WebAssembly per pinned docs | Document actual target precision; never fabricate accuracy |
| Secure entropy | `nox.crypto.secure_random_hex(n_bytes)` | 16-byte trace IDs, 8-byte span IDs; reject all-zero |
| Numeric semantics | signed 64-bit `int`; binary64 `float`; NaN comparison parity across QBE/LLVM | Preserve integer paths and explicitly validate non-finite values |
| Binary strings | length-prefixed `str` preserves NUL/high bytes | Suitable for protobuf/HTTP bodies with explicit size limits |
| Byte bridges | `nox.bytes` supports list/Buffer/str conversions | Use public API; no private runtime ABI |
| JSON integer fidelity | `as_int`/`number_text` preserve int64 above 2^53; `JsonWriter.write_int` exact | Never route int64 through `as_number` |
| Protobuf | `nox.protobuf.Writer`/`Reader`, official wire types, nested/packed fields, byte-exact output | Use for OTLP after pinned-schema and independent-decoder gates |
| Gzip | byte-list compression/decompression round-trips exact bytes | Optional OTLP compression only after Collector integration |
| HTTP | binary POST, response headers, 3xx/5xx, gzip decode, timeout, method validation and TLS rejection pass | OTLP/HTTP primary transport; positive timeout and payload cap mandatory |
| UDP | `nox.udp`, POSIX only, bounded datagrams and timeout | Not required initially; platform-specific exporter only if later added |
| gRPC | h2c/TLS client, streaming, metadata, deadline, gzip, mTLS | Optional later; real Collector gate remains mandatory |
| Filesystem | atomic replace/append/binary I/O work; paths are unconstrained | Validate file exporter paths at the Pulse boundary |
| Environment | missing `getenv` raises `OsError` | Explicit safe config loader and precedence |
| Async | `spawn`/`await`, bounded channels and cancellation points | Explicit lifecycle; no indefinite exporter blocking |
| Threads/atomics | joined threads, atomics and `ThreadChannel` work; free after join | Ownership and shutdown order are explicit |
| TaskLocal | values release at fiber teardown; tasks do not inherit caller values | Explicit `TelemetryContext` remains the foundational API |

## Active design constraints and fallbacks

- Hosted QBE and LLVM support the M:N worker pool. Pulse still requires
  separate lifecycle and portability verification for background exporters.
- Both backends pass the targeted class, nested-dictionary and TaskLocal transfer
  probes. The shared provider uses the public scalar atomic handle and
  explicit post-join cleanup. See the provider concurrency gate in
  `scripts/run-phase2-tests.sh`.
- Module state is worker-local in `serve_multicore*` and `nox.thread.pool_run`.
  Plain hosted tasks can share heap-backed module values. Providers, readers
  and contexts are passed explicitly.
- TaskLocal values are not inherited by spawned tasks. Parent context handoff is
  explicit even though the old teardown leak is fixed.
- Default hosted fiber stacks are 192 KiB. Protobuf and propagation parsers
  are iterative and bounded.
- The optional float, imported enum iteration and pass-only formatter regressions
  pass on 2.2.70. The limitation register retains the original reproducers.
- Redirected `nox.terminal.write_raw()` has an exact-byte regression on the core
  matrix. Golden helpers continue to use portable `print`.
- `nox.http.request` buffers bodies. Pulse enforces request/response payload caps,
  positive deadlines and a credential-safe redirect policy.
- `nox.http.configure(bind_address="127.0.0.1")` selects IPv4 loopback before
  serving. The application owns its listener and access controls.
- `nox.http.serve(port, handler, max_connections)` counts accepted connections.
  Handler teardown requires quiescence. The graceful shutdown path uses a
  configured drain deadline.
- NOX 2.2.63 fixes match arm bindings, field context managers and cancellation
  while awaiting a channel receive. The portable suite runs all three probes.
- gRPC permits one active call/stream per connection and has no client-side read
  timeout. OTLP/gRPC remains optional until those lifecycle constraints are tested.
- No Zig/NNI glue is approved for the initial primitives; current required runtime
  features are public NOX APIs.

## Historical local evidence — NOX 2.1.64, 2026-11-16

| Command | Result |
|---|---|
| isolated `noxc version --build-info` | `2.1.64`, commit `be3458c...`, Zig `0.16.0`, ARM64 macOS ReleaseFast |
| `bash scripts/run-smoke.sh llvm` | 10/10 tests; check/build/run pass |
| `bash scripts/run-smoke.sh qbe` | 10/10 tests; check/build/run pass |
| `bash scripts/run-type-capability-audit.sh` | historical fixes pass; pass-only class, optional-float and imported-enum-payload defects are reproduced; QBE/LLVM containment builds pass |
| `bash scripts/run-runtime-capability-audit.sh llvm` | NaN parity, NUL and JSON escaping pass |
| `bash scripts/run-runtime-capability-audit.sh qbe` | NaN parity, NUL and JSON escaping pass |
| `bash scripts/run-http-capability-audit.sh llvm` | binary/status/header/redirect/gzip/timeout/TLS/method gates pass |
| `bash scripts/run-http-capability-audit.sh qbe` | same gates pass |
| `bash scripts/run-backend-transfer-audit.sh` | LLVM wider transfers pass; QBE restrictions remain explicit |
| `bash scripts/run-phase1-tests.sh llvm` | 12 Phase 1 modules, 11 regression unit files, security, seeded property and canonical golden fixture pass |
| `bash scripts/run-phase1-tests.sh qbe` | same Phase 1 gates pass |
| `bash scripts/run-phase2-tests.sh llvm` | single-owner provider, cumulative reader, memory/console exporters, aggregation properties, 10×1,000 worker counter, cardinality and 100k-label stress gates pass |
| `bash scripts/run-phase2-tests.sh qbe` | same Phase 2 gates pass |
| `bash scripts/run-phase3-tests.sh llvm` | pure Prometheus text 0.0.4 renderer, pinned unit suffix translation without value scaling, bounded Resource allowlist/`target_info`, handler behavior, real HTTP scrape, portable golden and terminal-redirect audit pass |
| `bash scripts/run-phase3-tests.sh qbe` | same Phase 3 renderer, handler and real scrape gates pass |
| `PROMTOOL=<official-3.16.0> bash scripts/run-prometheus-conformance.sh` | checksum-verified independent Prometheus parser accepts the text 0.0.4 golden fixture |
| `PROMTOOL=<official-3.16.0> bash scripts/run-prometheus-scrape-integration.sh llvm|qbe` | real NOX HTTP response has correct media type, exact values, privacy and graceful shutdown; promtool accepts the received body |
| `bash scripts/run-examples.sh llvm` | compiling single-owner metrics example passes with exact real totals |
| `bash scripts/run-examples.sh qbe` | same example and assertions pass |
| `bash scripts/run-ci-core.sh` | both backends, architecture/privacy/property/golden/stress/example/package-import gates pass |

`modern_stdlib_smoke_test.nox` directly exercises nanosecond clocks, exact JSON
int64 parsing, generic enums/match, byte bridges, gzip and protobuf encoding/decoding.
Importing gRPC/UDP proves the public modules type-checks; it is deliberately not
reported as Collector or network interoperability.

## Remote evidence — 2026-11-16

[GitHub Actions CI run #12](https://github.com/mburakmmm/pulse/actions/runs/43823208141)
passed on commit `6cf77920778029c927566c98edb5b268ede83a10`:

- portable QBE and LLVM core suite on macOS ARM64, Linux x64, Linux ARM64 and
  Windows x64;
- runtime, type/compiler-limit, HTTP/TLS and backend-transfer audits on macOS
  ARM64, Linux x64 and Linux ARM64;
- cumulative reader, bounded memory/console exporters, aggregation properties,
  privacy, 100,000-label stress and atomic 10×1,000 counter gates on both
  backends in every portable core target;
- Prometheus text 0.0.4 renderer/golden gates, bounded allowlisted `target_info`,
  Resource privacy tests and compiling example on QBE and LLVM for every core
  target;
- real NOX HTTP server/client scrape integration on QBE and LLVM for all four
  core targets, plus checksum-verified promtool 3.16.0 parsing of the golden and
  both received HTTP bodies on Linux x64;
- `NOX-IO-001` reproduced as an expected Windows LLVM/QBE capability failure,
  with the portable golden-output containment passing on both backends;
- final `CI success` job requiring every claimed matrix gate.

The Windows result is a portable core claim only. It does not imply that the
Unix-only HTTP/TLS or backend-transfer harnesses ran on Windows.

Phase 3 [CI run #9](https://github.com/mburakmmm/pulse/actions/runs/43744840230)
first exposed the redirected `write_raw` failure. Run #12 preserves that evidence
with a minimal expected-failure probe and proves the portable renderer/scrape
containment across the full matrix.

## Unit translation evidence — 2026-11-20

[GitHub Actions CI run #13](https://github.com/mburakmmm/pulse/actions/runs/44791381303)
passed on commit `8d01f51e6d1a6adb816c0e8cf5c24ac4830f17ec`. The pinned
OpenTelemetry unit table, annotation removal, rate naming, unit-before-type suffix
ordering, exact unscaled values and post-translation collision rejection passed
the portable QBE/LLVM core suite on macOS ARM64, Linux x64, Linux ARM64 and
Windows x64. The independent Linux x64 promtool 3.16.0 job accepted the updated
golden fixture; all three capability jobs and the final required-gates job also
passed. No new NOX compiler or runtime limitation was observed in this slice.

## Concurrent metrics evidence — 2026-11-22

The opt-in provider keeps the single-owner API available unchanged. On isolated
NOX 2.2.38, commit `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a`,
`bash scripts/run-ci-core.sh` passed locally on QBE and LLVM with `PROMTOOL`
set to the official 3.16.0 binary. The provider concurrency executable passed
ten consecutive runs per backend with `NOX_POOL_WORKERS=4`.

Three recording workers each run 1,000 iterations across a counter, an up/down
counter and a histogram. A checkpoint forces the first scrape after a histogram
write and before any recorder can finish. The test checks exact totals, cumulative histogram
invariants, finite series cardinality, lock timeout recovery and post-join
cleanup. A separate real loopback integration serves a detached provider
snapshot and independently validates the response with promtool. The
[limitation register](nox-limitations.md) records the context-manager codegen
and top-level HTTP lifecycle reproducers. Protocol pins remain unchanged.

[CI run #17](https://github.com/mburakmmm/pulse/actions/runs/45024714272)
passed all nine jobs on commit `443b49f4dd120d79da2e59db482aabffddafe6a3`.
The shared-provider and scrape gates passed on QBE and LLVM on macOS ARM64,
Linux x64, Linux ARM64 and Windows x64. Independent Prometheus conformance
passed on Linux x64. OTLP Collector coverage remains deferred.

## Recording tracing evidence — 2026-11-23

`NOXC="$(command -v noxc)" bash scripts/run-ci-core.sh` passed locally on
macOS ARM64 with QBE and LLVM on NOX 2.2.38, source commit
`7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a`. The compiler build identity was
verified before testing. Each backend passed 15 unit files, the two privacy
test files and both compiling examples.

`tests/unit/tracing_lifecycle_test.nox` checks parent ID validation, local
child identity, ended parent context, idempotent end, one-shot snapshot
delivery, defensive attribute copies, drop counts and clock regression.
The recording path has a single-owner contract. The
[NOX limitation register](nox-limitations.md) tracks the top-level optional
narrowing reproducer. Collector conformance remains deferred. The independent
promtool check ran in CI. The local run exercised the real scrape without
promtool because the binary was unavailable.

[CI run #18](https://github.com/mburakmmm/pulse/actions/runs/45118374787)
passed all nine jobs for `57f023d898eb1f72461e23665547e36683c494a2`.
The lifecycle test and tracing example ran under QBE and LLVM on macOS ARM64,
Linux x64, Linux ARM64 and Windows x64. The independent Prometheus 3.16.0
conformance job passed on Linux x64.

## Span details evidence

On NOX 2.2.38, the `tracing_details_test.nox` fixture builds and runs
under QBE and LLVM. It checks status precedence and descriptions, wall and
explicit event times, insertion order, malformed links, no-op and ended span
behavior, defensive copies, sensitive keys, per-record limits and the shared
span byte budget. The fixture also runs as part of `bash scripts/run-ci-core.sh`.
No new NOX compiler or runtime limitation was observed in this slice.

[CI run #19](https://github.com/mburakmmm/pulse/actions/runs/45119476289)
passed all nine jobs for `100724067f329bf586b85986965a5336d49b16b4`.
The span details regression passed under QBE and LLVM on macOS ARM64,
Linux x64, Linux ARM64 and Windows x64. The independent Prometheus 3.16.0
job passed on Linux x64. Trace exporter conformance remains deferred.

## Trace metadata and cancellation evidence

The metadata regression builds and runs on NOX 2.2.38 QBE and LLVM and verifies
Resource/scope copies, sensitive metadata filtering, shared byte accounting,
type-only exception events and cleanup on failure or early return. The
`NOXC="$(command -v noxc)" bash scripts/run-ci-core.sh` suite passed locally
on macOS ARM64 for both backends. The
task-await cancellation regression completed 20 consecutive local runs per
backend with `NOX_POOL_WORKERS=4`. The empty-channel cancellation reproducer
exits with the runtime deadlock diagnostic on both backends. See
[`NOX-ASYNC-001`](nox-limitations.md#nox-async-001--cancelling-a-task-waiting-on-an-empty-channel-can-deadlock).

[CI run #20](https://github.com/mburakmmm/pulse/actions/runs/45131489631)
passed all nine jobs for `f31f1f7de9517b1e1944abb85543abe0bfb8a6eb`.
Both new regressions ran on QBE and LLVM on macOS ARM64, Linux x64,
Linux ARM64 and Windows x64. Independent Prometheus conformance also passed.
Trace exporters and Collector conformance remain deferred.

## Local trace exporter evidence

NOX 2.2.38 QBE and LLVM built and ran the trace exporter regression and
the updated `hello_traces.nox` example on macOS ARM64.
`NOXC="$(command -v noxc)" bash scripts/run-ci-core.sh` passed on both
backends with 19 unit files per backend. The regression
checks one-shot SDK export, defensive copies, count and shared byte
limits, sanitized diagnostics, exact allowlisted JSON, sink recovery and
same-instance reentrancy. The NOX checker rejects using one name for
different match-payload types across arms. The minimal example is recorded
under [`NOX-TYPE-003`](nox-limitations.md#nox-type-003--match-arms-share-the-checker-scope-for-payload-bindings).

[CI run #21](https://github.com/mburakmmm/pulse/actions/runs/45132965158)
passed all nine jobs for `18b6be8e080e6c5654d592df212214e758c4c26b`.
The trace exporter and example passed under QBE and LLVM on macOS ARM64,
Linux x64, Linux ARM64 and Windows x64. The independent Prometheus 3.16.0
gate passed on Linux x64. Local trace JSON is diagnostic output. OTLP
encoding and Collector conformance remain deferred.

## Traceparent and project hook evidence

The traceparent regression builds and runs under QBE and LLVM with the
checksum-verified NOX 2.2.70 release on macOS ARM64. It checks version handling,
invalid headers, sampled-bit normalization, remote context, duplicate header
rejection and overwrite behavior.

The project hook policy passed its Python unit tests and direct checks with
RTK 1.2.1. Codex hook discovery and activation are separate from testing a
handler directly. See [agent tooling](agent-tooling.md) for trust review.

[CI run #23](https://github.com/mburakmmm/pulse/actions/runs/45762058875)
passed all nine jobs for `30844e3675cda184dc2d5c766ed6b18e45104f32`.
The traceparent and NOX framework regressions passed under QBE and LLVM
on macOS ARM64, Linux x64, Linux ARM64 and Windows x64. The Unix capability
jobs also passed the hook policy suite.

## Tracestate evidence

The paired W3C propagator and bounded tracestate parser passed regression tests
under QBE and LLVM on macOS ARM64 with the checksum-verified NOX 2.2.70 release.
The tests cover grammar, ordering, limits, preservation of a valid parent on
invalid state, duplicate fields and atomic injection on carrier overflow.

[CI run #24](https://github.com/mburakmmm/pulse/actions/runs/46146922607)
passed all nine jobs for `ba5faccf1204a527fcb6c9b920eace5ac76f58fe`.
The portable suite exercised QBE and LLVM on macOS ARM64, Linux x64,
Linux ARM64 and Windows x64.

## Baggage evidence

The Baggage codec, carrier policy and trace-context regressions built and ran
on macOS ARM64 with QBE and LLVM using the checksum-verified NOX 2.2.70 release.
The tests cover percent encoding, malformed UTF-8, member and wire limits,
ordered duplicates, and destination-specific filtering.

The [NUL comparison reproducer](nox-limitations.md#nox-str-002--string-equality-treats-nul-as-end-of-string)
fails the expected equality check on 2.2.70 and works on 2.2.107 on both backends.
Pulse uses byte length for empty header members and validates allowlist tokens
before comparing them.

[CI run #25](https://github.com/mburakmmm/pulse/actions/runs/46147965946)
passed all nine jobs for `826e996b0ac4b8147436b4a2bd6da929a8e994c7`.
The portable suite passed on QBE and LLVM across macOS ARM64, Linux x64,
Linux ARM64 and Windows x64.

## W3C propagation conformance evidence

The curated W3C fixtures run with the unit suite. The property suite adds
384 seeded cases for round-trips and canonicalization. The fuzz suite adds
704 seeded cases covering arbitrary wire bytes, raw control bytes and
padding that exceeds the raw header caps. See the
[fixture provenance](../fixtures/w3c/README.md) for the selected cases.

[CI run #26](https://github.com/mburakmmm/pulse/actions/runs/46173369982)
passed all nine jobs for `e761cddc3ce712f4cc631c47dce8e3692111fddd` on
NOX 2.2.70. The core matrix exercised QBE and LLVM on four platforms.
The same fixtures, property tests and fuzz cases passed on both backends
with NOX 2.2.107 on macOS ARM64.

The [optional elif narrowing issue](nox-limitations.md#nox-type-004--an-elif-guard-does-not-narrow-an-optional-argument)
reproduces with `noxc check` on 2.2.70 and 2.2.107. The fixture runner
uses a nested guard that compiles on both versions.

## Latest release audit — NOX 2.2.107

On 2026-11-28, the installed macOS ARM64 compiler reported the
[latest published release](https://github.com/mburakmmm/nox-lang/releases/tag/v2.2.107)
version and the exact tag commit `37e80cf9f0e273da4f612da0bb1f1c01c9473c6f`.
The installed executable SHA-256 was
`020e9a9e335c89231873b6047950e8ba28f7c6267814be326b3622adc7bd53a7`.
The [2.2.70–2.2.107 comparison](https://github.com/mburakmmm/nox-lang/compare/v2.2.70...v2.2.107)
identifies the NUL fix in the 2.2.77 tag. The hosted QBE and module-state
corrections reflect behavior that predates the current Pulse pin.

| Check | Local result |
|---|---|
| `run-smoke.sh`, `run-nox-framework-regressions.sh` | QBE and LLVM passed. Smoke includes TaskLocal child isolation. |
| `run-type-capability-audit.sh`, `run-backend-transfer-audit.sh` | QBE and LLVM passed, including historical formatter/codegen fixtures and class/TaskLocal transfer. |
| `run-runtime-capability-audit.sh`, `run-http-capability-audit.sh` | QBE and LLVM passed, including embedded binary bytes, NaN, binary HTTP, timeout and untrusted TLS rejection. |
| `nul_string_comparison.nox.txt` | Both backends reported `3 / False` on 2.2.107 and `3 / True` on 2.2.70. |
| `optional_raise_narrowing.nox.txt` and `TaskLocal[int]` | `noxc check` reports `OptionalNotNarrowed` and `TypeMismatch` respectively on 2.2.107. |
| `http_serve_return_order.nox.txt` | Both 2.2.107 backends returned `serve-returned` over loopback. |
| Upstream `divergence_pool_run.nox` and `mn_shared_list.nox` | Both backends passed on both pins. The shared-list output matches the upstream golden with four configured workers. |

This is local macOS ARM64 evidence. The four-platform CI matrix is still
pinned to 2.2.70. The [NOX limitation register](nox-limitations.md) records the
remaining design boundaries and the containment used with that pin.

## Remaining audit work

- System-trusted TLS success and isolated hostname mismatch in the CI matrix.
- Vendored OTLP schema checksum manifest and independent protobuf decoder fixtures.
- Real OpenTelemetry Collector integration.
- Optional gRPC and UDP integration only if Pulse elects to support those exporters.

See [`nox-limitations.md`](nox-limitations.md) for closed historical defects and
the active design limits that remain binding.
