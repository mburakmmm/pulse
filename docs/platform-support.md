# Platform support

Pulse separates a configured CI target from a verified support claim. A target
is marked verified only after its workflow has completed against the pinned NOX
compiler and both required backends.

## Current matrix

NOX 2.2.38 passed all required jobs in
[CI run #16](https://github.com/mburakmmm/pulse/actions/runs/44891047883)
on commit `ecee56a24d552390a3679c3824656f2dee8937e9`.

| Target | Core suite | Extended capability audit | Remote evidence |
|---|---|---|---|
| macOS ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS` |
| Linux x64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, including independent promtool conformance |
| Linux ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS` |
| Windows x64 | QBE + LLVM | Unix capability jobs outside Windows scope | `PASS`, including exact redirected raw output and real scrape |

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
golden helper uses portable `print` output. CI run #12 passed that containment,
the allowlisted Resource slice and real scrape integration on Windows while
preserving the expected upstream failure evidence.

## Thread safety

`SingleOwnerMeterProvider` requires caller isolation. The opt-in
`ConcurrentMeterProvider` has a separate QBE/LLVM gate for concurrent
registration, bounded aggregation and scrape snapshots. CI run #16 predates
that gate. Readers, clocks and exporters remain caller-owned.

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

The historical evidence is [CI run #12](https://github.com/mburakmmm/pulse/actions/runs/43823208141),
completed successfully on 2026-11-16 for commit `6cf77920778029c927566c98edb5b268ede83a10`.
