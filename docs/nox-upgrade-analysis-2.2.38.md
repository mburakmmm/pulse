# NOX 2.2.38 upgrade audit

Audit date: 2026-11-21. Local target: macOS ARM64, QBE and LLVM.

Pulse CI pins the [official NOX 2.2.38 release](https://github.com/mburakmmm/nox-lang/releases/tag/v2.2.38)
and checks commit `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a` from
`noxc version --build-info`. The macOS ARM64 archive was extracted only
after checking SHA-256
`7e973be6020fb908fed3d5194b87bff59ce5b4a0194cb81dee78fd7ff6abfcca`.
All local checks used the isolated release. The system installation was left
untouched.

Run these commands with `NOXC` set to the isolated binary. Set `PROMTOOL`
to the checksum-verified Prometheus 3.16.0 binary for the independent parser.

| Command | Scope and result |
|---|---|
| `bash scripts/run-ci-core.sh` | Core, existing concurrency and cardinality gates, examples, package import, real loopback scrape and redirected raw output on QBE and LLVM |
| `bash scripts/run-type-capability-audit.sh` | Pass-only class survives formatter round-trip. Optional float and imported enum payload iteration build on QBE and LLVM. |
| `bash scripts/run-backend-transfer-audit.sh` | Class transfer and TaskLocal isolation pass on both backends. A joined worker's nested dictionary write is visible to its caller. Two worker handles each complete 1,000 CAS-protected writes and the resulting total is exactly 2,000. The probe frees its atomic after both joins. |
| `bash scripts/run-runtime-capability-audit.sh llvm` and `qbe` | NaN parity and embedded NUL/JSON round-trip pass |
| `bash scripts/run-http-capability-audit.sh llvm` and `qbe` | Binary body, headers, redirects, status, gzip, timeout, untrusted TLS rejection and input validation pass |
| `bash scripts/run-prometheus-conformance.sh` | Prometheus 3.16.0 independently accepts the text 0.0.4 golden fixture. The core run also passes each real HTTP body to the parser. |

The Prometheus fixture now configures IPv4 loopback through the public HTTP
API. This removes the need for a wildcard listener in the fixture. Pulse's
public API and the pinned Prometheus and OpenTelemetry protocol versions are
unchanged.

The dictionary probes exercise one small shared graph. Provider-wide safety
still requires a bounded ownership and cleanup design plus race coverage for
registration, cardinality budgets, histograms, reader state and simultaneous
scrapes. The existing `SingleOwnerMeterProvider` remains single-owner.
Windows terminal redirection and the remote Linux targets are tracked in the
[platform matrix](platform-support.md). The OTLP Collector gate is deferred to
the OTLP phases.

The first [Linux ARM64 capability job](https://github.com/mburakmmm/pulse/actions/runs/44890897228/job/136806248345)
built the QBE locked-dictionary probe and then raised `nox_test_AssertionError`.
Its original busy-loop budget and output did not distinguish acquisition
exhaustion from an incorrect total. The probe now uses a five-second monotonic
deadline, pauses for 1 ms after a failed acquisition, and prints both worker
totals and the shared total before checking the same exact values.
The updated probe passed 100 runs per backend on macOS ARM64. The Linux ARM64
capability job also passed in [CI run #16](https://github.com/mburakmmm/pulse/actions/runs/44891047883),
alongside the Linux x64 and macOS ARM64 capability jobs and the independent
Prometheus conformance job. The four core jobs and the final required-gates
job passed in the same run. Windows x64 passed the exact-byte terminal
redirection check on QBE and LLVM, closing `NOX-IO-001` on the current pin.
The original ARM64 assertion failure remains documented because its exact
cause was not observable in the first run.
