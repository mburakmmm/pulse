# Platform support

Pulse separates a configured CI target from a verified support claim. A target
is marked verified only after its workflow has completed against the pinned NOX
compiler and both required backends.

## Current matrix

| Target | Core suite | Extended capability audit | Remote evidence |
|---|---|---|---|
| macOS ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #10 |
| Linux x64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #10 |
| Linux ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #10 |
| Windows x64 | QBE + LLVM | Not yet claimed | Portable core and Phase 3 containment `PASS`, CI run #10; `NOX-IO-001` reproduced as expected |

The core suite includes module checking, smoke build/run, unit, property,
security, golden and cardinality stress tests, the compiling example and a
downstream dependency alias/lock probe.

The Windows job uses the official checksum-verified zip release and runs the
portable project suite. HTTP/TLS and backend-transfer capability scripts retain
POSIX test-harness dependencies and are not presented as Windows verification.
That distinction is a documented scope limit, not a passing result.

CI run #9 passed the Phase 3 renderer tests on Unix but exposed a Windows-only
failure in redirected `nox.terminal.write_raw()`. The pure renderer was not the
failing component. `NOX-IO-001` now has a minimal QBE/LLVM platform audit, and the
golden helper uses portable `print` output. CI run #10 passed that containment on
Windows while preserving the expected upstream-failure evidence.

## Thread safety

The current `SingleOwnerMeterProvider` is explicitly not concurrency-safe. The
CI matrix validates its single-owner semantics on each target, but does not
convert that into a thread-safety claim. The narrower atomic same-series path
produces exactly 10,000 from 10 workers × 1,000 increments on QBE and LLVM. The
instrument registry, cardinality maps, histograms, readers and exporters remain
outside that concurrency proof.

## Result vocabulary

- `PASS`: the named command completed on the named target.
- `FAIL`: the named command ran and did not satisfy its assertions.
- `SKIPPED`: the gate was applicable but intentionally not executed, with a
  recorded reason.
- `UNSUPPORTED`: Pulse or the pinned toolchain does not support the capability
  on that target.
- `PENDING`: no remote evidence exists yet.

GitHub Actions logs are the source of truth for remote runs. Documentation is
updated only after those results are observed.

The current evidence is [CI run #10](https://github.com/mburakmmm/pulse/actions/runs/43745579223),
completed successfully on 2026-11-15 for commit `57ed3eabc553a212c7911384196b8d9d12a75e6b`.
