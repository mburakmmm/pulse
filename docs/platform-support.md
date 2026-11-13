# Platform support

Pulse separates a configured CI target from a verified support claim. A target
is marked verified only after its workflow has completed against the pinned NOX
compiler and both required backends.

## Current matrix

| Target | Core suite | Extended capability audit | Status before first remote run |
|---|---|---|---|
| macOS ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | Locally verified; remote pending |
| Linux x64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | Remote pending |
| Linux ARM64 | QBE + LLVM | runtime, type, HTTP/TLS, transfer | Remote pending |
| Windows x64 | QBE + LLVM | Not yet claimed | Remote pending |

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
