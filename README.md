# Pulse

[![CI](https://github.com/mburakmmm/pulse/actions/workflows/ci.yml/badge.svg)](https://github.com/mburakmmm/pulse/actions/workflows/ci.yml)
[![NOX](https://img.shields.io/badge/NOX-2.1.64-6f42c1)](https://github.com/mburakmmm/nox-lang/releases/tag/v2.1.64)
[![Status](https://img.shields.io/badge/status-experimental-orange)](#project-status)

**Bounded, framework-independent observability primitives for the NOX ecosystem.**

Pulse is being built as a NOX-first metrics and distributed-tracing SDK with
OpenTelemetry interoperability. Its design prioritizes semantic correctness,
privacy, bounded resource use and reproducible behavior across the LLVM and QBE
backends.

> [!WARNING]
> Pulse is pre-1.0 and experimental. The current recording provider is
> single-owner only. Prometheus, tracing and OTLP exporters are planned, not
> implemented, and are not advertised as working features.

## Project status

The common telemetry primitives (`v0.1.0`) are complete locally. Development is
now in `v0.2.0`, the bounded cumulative metrics phase.

| Capability | Current state |
|---|---|
| Typed attributes, resources, scopes, clocks and secure IDs | Implemented and tested on QBE + LLVM |
| No-op metrics and tracing API | Implemented; no import-time network or worker activity |
| Counter, UpDownCounter and explicit-boundary Histogram | Experimental single-owner implementation |
| Cardinality and aggregation-memory bounds | Implemented with deterministic overflow routing |
| Prometheus exposition | Planned for `v0.3.0` |
| Tracing and W3C propagation | Planned for `v0.4.0`–`v0.5.0` |
| OTLP/HTTP traces and metrics | Planned for `v0.7.0`–`v0.8.0` |
| Concurrent recording provider | Not implemented; no thread-safety claim |

The evidence-gated roadmap is maintained in [`todo.md`](todo.md). Compiler and
platform evidence lives in [`docs/compatibility.md`](docs/compatibility.md), and
known NOX constraints are tracked in
[`docs/nox-limitations.md`](docs/nox-limitations.md).

## Why Pulse

- **NOX-first:** public contracts are typed NOX and avoid assumptions borrowed
  from Python, reflection-heavy runtimes or implicit thread locals.
- **Bounded by default:** attributes, series, aggregation memory, queues,
  retries, payloads and shutdown deadlines have explicit finite limits.
- **Privacy at record time:** sensitive values are rejected or sanitized before
  they can enter an export queue.
- **Portable semantics:** QBE and LLVM behavior is tested separately; backend
  differences are documented rather than hidden.
- **Protocol honest:** a feature is called OTLP only after real protobuf and
  Collector interoperability pass.
- **Framework independent:** core modules do not depend on web, database,
  logging or vendor-specific integrations.

## Quick start

Pulse currently targets the checksum-verified
[`noxc 2.1.64`](https://github.com/mburakmmm/nox-lang/releases/tag/v2.1.64)
release at source commit
[`be3458c`](https://github.com/mburakmmm/nox-lang/commit/be3458c332c8234baa8f3f8ac2ae9601db24321e).

```sh
git clone https://github.com/mburakmmm/pulse.git
cd pulse
noxc run --backend llvm examples/hello_metrics.nox
noxc run --backend qbe examples/hello_metrics.nox
```

The example records real Counter and Histogram measurements and reads the
current in-process snapshot. It deliberately does not start an HTTP endpoint or
export telemetry.

```nox
from api.metrics import Counter
from core.attributes import AttributeValue
from core.limits import default_attribute_limits, default_metric_limits, default_record_limits
from metrics.provider import RecordingMeter, SingleOwnerMeterProvider

provider: SingleOwnerMeterProvider = SingleOwnerMeterProvider(
    default_attribute_limits(),
    default_metric_limits(),
    default_record_limits(),
)
meter: RecordingMeter = provider.get_recording_meter("checkout", "0.1.0", None)
requests: Counter = meter.create_counter("checkout.requests", "1", "completed requests")
requests.add(1, {"route": AttributeValue.Text("/checkout")})
```

See [`examples/hello_metrics.nox`](examples/hello_metrics.nox) for the complete,
CI-compiled example and [`docs/api.md`](docs/api.md) for API status.

## Verification

GitHub Actions installs the official NOX archive, verifies its published
SHA-256 checksum and exact compiler source commit, then runs the current project
claims on:

| Target | Core QBE + LLVM | Extended capability audit |
|---|:---:|:---:|
| macOS ARM64 | CI | CI |
| Linux x64 | CI | CI |
| Linux ARM64 | CI | CI |
| Windows x64 | CI | Not yet claimed |

The extended audit exercises runtime divergence, HTTP/TLS behavior and known
backend transfer constraints. Windows runs the portable source, unit, property,
security, golden, stress, example and downstream package-import gates. See
[`docs/platform-support.md`](docs/platform-support.md) for the precise support
policy.

Run the complete local gate with an isolated `noxc 2.1.64` on `PATH`:

```sh
bash scripts/run-ci-core.sh
bash scripts/run-runtime-capability-audit.sh llvm
bash scripts/run-runtime-capability-audit.sh qbe
bash scripts/run-type-capability-audit.sh
bash scripts/run-http-capability-audit.sh llvm
bash scripts/run-http-capability-audit.sh qbe
bash scripts/run-backend-transfer-audit.sh
```

No test result is treated as a platform claim until its remote workflow has
actually completed. Unsupported and deferred capabilities remain explicit in
the compatibility documentation.

## Architecture

```text
instrumentation
      │
      ▼
typed API ──► bounded metrics / tracing SDK ──► processors / readers
      │                                             │
      └── explicit TelemetryContext                 ▼
                                               exporters

framework adapters (leaf packages only) ──► API/SDK
```

Public modules are resolved from repository-root paths such as `api.metrics`.
NOX `2.1.64` does not use a Python-style `pulse/__init__.nox` package facade.
The dependency rules and rationale are documented in
[`docs/architecture.md`](docs/architecture.md) and enforced by CI.

## Roadmap

1. Complete cumulative metric readers and deterministic in-memory export.
2. Add standards-validated Prometheus text exposition.
3. Implement tracing, explicit context and W3C propagation.
4. Add bounded processors, sampling and lifecycle control.
5. Implement pinned OTLP protobuf mapping and real Collector interoperability.
6. Add optional ecosystem adapters without creating dependency cycles.

Every milestone has behavioral, privacy, failure and resource-limit exit gates
in [`todo.md`](todo.md).

## Contributing

Contributions are welcome while the API is still taking shape. Read
[`CONTRIBUTING.md`](CONTRIBUTING.md), the engineering contract in
[`AGENTS.md`](AGENTS.md), and the security policy in
[`SECURITY.md`](SECURITY.md) before opening a pull request.

For usage questions, see [`SUPPORT.md`](SUPPORT.md). Please report security
issues privately instead of opening a public issue.

## License

No redistribution license has been selected yet. Until a license is added, the
repository is publicly readable but no permission to copy, modify or
redistribute it is granted. This section will be replaced when the maintainer
records the license decision.
