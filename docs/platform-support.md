# Platform support

Pulse separates a configured CI target from a verified support claim. A target
is marked verified only after its workflow has completed against the pinned NOX
compiler and both required backends.

## Current matrix

| Target | Core suite | Extended capability audit | Remote evidence |
|---|---|---|---|
| macOS ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #8 |
| Linux x64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #8 |
| Linux ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #8 |
| Windows x64 | QBE + LLVM | Not yet claimed | Last complete core `PASS`, CI run #8; Phase 3 containment pending remote rerun after run #9 exposed `NOX-IO-001` |

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
golden helper uses portable `print` output; Windows Phase 3 remains pending until
that containment passes remotely.

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

The current evidence is [CI run #8](https://github.com/mburakmmm/pulse/actions/runs/43627076879),
completed successfully on 2026-11-14 for commit `190d154041bf8c317471bb52404ff46426761af1`.
