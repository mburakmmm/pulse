# NOX compatibility audit

The current compiler pin is NOX 2.2.38. See the
[upgrade audit](nox-upgrade-analysis-2.2.38.md) for current local evidence and
the [platform matrix](platform-support.md) for remote evidence.

## Selected baseline

| Item | Value | Evidence |
|---|---|---|
| Published NOX release | `2.2.38` | Official `v2.2.38` release |
| Exact source commit | `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a` | Release tag and compiler build identity |
| Compiler build identity | same commit | `noxc version --build-info` |
| Audited compiler SHA-256 | `26b63bdefef53584f87c34bc8b427197fc29ade1428317a7568028c960a87dce` | Isolated macOS ARM64 binary |
| Release archive SHA-256 | `7e973be6020fb908fed3d5194b87bff59ce5b4a0194cb81dee78fd7ff6abfcca` | Official macOS ARM64 archive checksum |
| Compiler toolchain | Zig `0.16.0`, `aarch64-macos`, `ReleaseFast` | build-info output |
| Test installation | Isolated archive | System installation untouched |
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

- QBE scheduling is cooperative. Pulse uses synchronous or explicitly polled
  export there and does not advertise background parallelism.
- Both backends pass the targeted class, nested-dictionary and TaskLocal transfer
  probes. The joined dictionary probe has a single writer. Provider-wide
  concurrent mutation, ownership and cleanup still need dedicated tests.
- Mutable module state is worker-local. Providers, readers and contexts are passed
  explicitly; there is no module-global current span.
- TaskLocal values are not inherited by spawned tasks. Parent context handoff is
  explicit even though the old teardown leak is fixed.
- Fiber stacks are 192 KiB. Protobuf/propagation parsers are iterative and bounded.
- The optional float, imported enum iteration and pass-only formatter regressions
  pass on 2.2.38. The limitation register retains the original reproducers.
- Redirected `nox.terminal.write_raw()` has an exact-byte regression on the core
  matrix. Golden helpers continue to use portable `print`.
- `nox.http.request` buffers bodies. Pulse enforces request/response payload caps,
  positive deadlines and a credential-safe redirect policy.
- `nox.http.configure(bind_address="127.0.0.1")` selects IPv4 loopback before
  serving. The application owns its listener and access controls.
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

## Remaining audit work

- System-trusted TLS success and isolated hostname mismatch in the CI matrix.
- Vendored OTLP schema checksum manifest and independent protobuf decoder fixtures.
- Real OpenTelemetry Collector integration.
- Optional gRPC and UDP integration only if Pulse elects to support those exporters.

See [`nox-limitations.md`](nox-limitations.md) for closed historical defects and
the active design limits that remain binding.
