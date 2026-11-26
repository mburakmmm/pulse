# Pulse

[![CI](https://github.com/mburakmmm/pulse/actions/workflows/ci.yml/badge.svg)](https://github.com/mburakmmm/pulse/actions/workflows/ci.yml)
[![NOX](https://img.shields.io/badge/NOX-2.2.70-6f42c1)](https://github.com/mburakmmm/nox-lang/releases/tag/v2.2.70)
[![Status](https://img.shields.io/badge/status-experimental-orange)](#project-status)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Bounded, framework-independent observability primitives for the NOX ecosystem.**

Pulse is being built as a NOX-first metrics and distributed-tracing SDK with
OpenTelemetry interoperability. Its design prioritizes semantic correctness,
privacy, bounded resource use and reproducible behavior across the LLVM and QBE
backends.

> [!WARNING]
> Pulse is pre-1.0 and experimental. Shared metric recording is opt-in via
> `ConcurrentMeterProvider`. Applications own their Prometheus listeners and
> can configure loopback with pinned NOX. Recording spans are experimental and
> support local in-memory and console exporters. Trace propagation and OTLP
> remain planned.

## Project status

The bounded cumulative metrics local exit gate (`v0.2.0`) is complete. Development
is now in `v0.3.0`, beginning with a bounded Prometheus text renderer.

| Capability | Current state |
|---|---|
| Typed attributes, resources, scopes, clocks and secure IDs | Implemented and tested on QBE + LLVM |
| No-op metrics and tracing API | Implemented; no import-time network or worker activity |
| Counter, UpDownCounter and explicit-boundary Histogram | Experimental single-owner and opt-in concurrent providers |
| Cardinality and aggregation-memory bounds | Implemented with deterministic overflow routing |
| Cumulative metric reader | Implemented with deterministic collection timestamps |
| In-memory and console metric exporters | Experimental, bounded and tested on QBE + LLVM |
| Prometheus exposition | Experimental text 0.0.4 renderer with pinned unit suffixes + pure scrape handler; real QBE/LLVM HTTP integration and promtool 3.16.0 pass, listener remains application-owned |
| Tracing | Experimental parent context, span kinds, status, events, links and bounded local snapshots |
| W3C propagation | Experimental `traceparent` parser, formatter and header adapter. Tracestate and baggage planned. |
| OTLP/HTTP traces and metrics | Planned for `v0.7.0`–`v0.8.0` |
| Concurrent recording provider | Experimental bounded gate, consistent snapshots and explicit post-join close |

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
[`noxc 2.2.70`](https://github.com/mburakmmm/nox-lang/releases/tag/v2.2.70)
release at source commit
[`4dc061f`](https://github.com/mburakmmm/nox-lang/commit/4dc061f8c8443f8575092c2652d1109b6f4697e9).

```sh
git clone https://github.com/mburakmmm/pulse.git
cd pulse
noxc run --backend llvm examples/hello_metrics.nox
noxc run --backend qbe examples/hello_metrics.nox
```

The example records real Counter and Histogram measurements, collects a
cumulative snapshot and renders Prometheus text with an explicitly allowlisted
service name. It deliberately does not start a listener or send telemetry.

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
meter: RecordingMeter = provider.get_recording_meter("checkout", "0.2.0", None)
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

Run the complete local gate with the pinned `noxc 2.2.70` on `PATH`:

```sh
bash scripts/run-ci-core.sh
bash scripts/run-runtime-capability-audit.sh llvm
bash scripts/run-runtime-capability-audit.sh qbe
bash scripts/run-type-capability-audit.sh
bash scripts/run-http-capability-audit.sh llvm
bash scripts/run-http-capability-audit.sh qbe
bash scripts/run-backend-transfer-audit.sh
```

The portable core command includes the Phase 3 renderer gate on both LLVM and
QBE. See [`docs/prometheus.md`](docs/prometheus.md) for its exact limitations.

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
NOX resolves Pulse modules from the repository root.
The dependency rules and rationale are documented in
[`docs/architecture.md`](docs/architecture.md) and enforced by CI.

## Roadmap

1. Complete the general concurrent recording-provider lifecycle.
2. Complete general concurrent collection and production listener deployment guidance.
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

Pulse is available under the [MIT License](LICENSE).
