# Platform support

Pulse separates a configured CI target from a verified support claim. A target
is marked verified only after its workflow has completed against the pinned NOX
compiler and both required backends.

## Current matrix

| Target | Core suite | Extended capability audit | Remote evidence |
|---|---|---|---|
| macOS ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #7 |
| Linux x64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #7 |
| Linux ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | `PASS`, CI run #7 |
| Windows x64 | QBE + LLVM | Not yet claimed | Portable core `PASS`, CI run #7 |

The core suite includes module checking, smoke build/run, unit, property,
security, golden and cardinality stress tests, the compiling example and a
downstream dependency alias/lock probe.

The Windows job uses the official checksum-verified zip release and runs the
portable project suite. HTTP/TLS and backend-transfer capability scripts retain
POSIX test-harness dependencies and are not presented as Windows verification.
That distinction is a documented scope limit, not a passing result.

## Thread safety

The current `SingleOwnerMeterProvider` is explicitly not concurrency-safe. The
CI matrix validates its single-owner semantics on each target, but does not
convert that into a thread-safety claim. Phase `v0.2.0` remains open until the
concurrent provider design and exact 10-worker × 1,000-increment LLVM acceptance
test pass; QBE behavior will be reported independently.

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

The current evidence is [CI run #7](https://github.com/mburakmmm/pulse/actions/runs/43593764797),
completed successfully on 2026-11-14 for commit `8a81f3d272a3f5eae0937b0f7e0477ca178d7586`.
