# Changelog

All notable changes to Pulse will be recorded here. The project is pre-release and its public API is not stable.

## [Unreleased]

### Added

- A professional repository landing page with an honest capability matrix,
  quick start, architecture, roadmap and verification instructions.
- Contributor, security, support and conduct policies; CODEOWNERS, structured
  issue forms, pull-request checklist and GitHub Actions dependency updates.
- A four-target core CI matrix for macOS ARM64, Linux x64, Linux ARM64 and
  Windows x64 using checksum-verified official NOX release archives.
- SHA-pinned `actions/checkout` v6.1.0, avoiding the retired Node.js 20 action
  runtime.
- Separate Unix capability jobs for runtime divergence, compiler limitations,
  HTTP/TLS behavior and backend transfer semantics, with explicit skipped and
  unsupported scope summaries.
- A compiling `hello_metrics.nox` example and a portable core-suite entry point
  that execute under both LLVM and QBE.
- Cross-platform filesystem smoke paths and Windows executable discovery for
  build/run and golden-test harnesses.
- Portable core scripts that use baseline `find`/`grep` instead of assuming
  `rg` exists on every runner, plus CRLF-normalized golden text comparison on
  Windows.
- Package-resolution smoke metadata aligned with the manifest's `0.1.0`
  version.
- Evidence-gated Phase 0 roadmap.
- Initial NOX manifest, package-layout probe and LLVM/QBE smoke harness.
- Compatibility, architecture, standards and security audit documents.
- Exact OpenTelemetry specification, OTLP protobuf, semantic-convention, W3C propagation and Prometheus exposition pins.
- Runtime capability probes for numeric fidelity, binary strings, JSON, environment access, task cancellation, channels, threads and atomics.
- Filesystem atomic/append/binary round-trip and type-system capability probes.
- TaskLocal isolation/non-inheritance smoke coverage and a central NOX limitation register with upstream-ready reproducers.
- Loopback HTTP capability harness covering binary bodies, headers, redirects, non-2xx, gzip and deadlines on QBE/LLVM.
- Self-signed TLS rejection and backend-specific class/TaskLocal transfer matrices.
- CI guards for framework leaf-import direction and forbidden private NOX runtime ABI usage.
- ADRs for typed attribute values with int64 fidelity and deterministic clock/ID/transport/sink test seams.
- Conservative count-plus-byte resource defaults and memory-budget invariants in ADR-0005.
- Concurrency ownership and QBE fallback decision in ADR-0002.
- NOX baseline refresh to published `2.1.64` with checksum-verified isolated compiler and exact build provenance; the system compiler was not changed.
- Positive regressions for formatter, minimum int, NaN parity, NUL byte and HTTP method/body validation fixes.
- QBE/LLVM smoke coverage for generic enums, nanosecond clocks, exact JSON int64, public protobuf, gzip and byte bridges.
- ADR-0006 selecting enum-based typed telemetry values now that NOX supports exhaustive generic enums.
- Phase 1 typed errors/results, bounded attribute snapshots, resource/scope merge, nanosecond clock seam and secure IDs.
- Explicit no-op metrics/tracing API providers with parent-context preservation and no import-time I/O.
- Phase 1 API and telemetry data-model documentation plus QBE/LLVM unit coverage.
- Bounded queue/batch/payload/timeout/retry configuration and an honest disabled provider with idempotent lifecycle.
- A separate two-backend default-privacy security suite wired into CI.
- Seeded two-backend property checks for bounded attribute snapshots and fixed-width deterministic IDs.
- NOX 2.1.52→2.1.64 upgrade analysis covering JSON bounds, zero-copy FFI trust, gzip changes and isolated regression evidence.
- Validated record budgets for events, links, span snapshots and histogram boundaries.
- Validated metric budgets for per-instrument/provider cardinality and total aggregation memory.
- A two-backend canonical attribute golden fixture covering deterministic order, escaping, homogeneous arrays, int64 fidelity and sensitive-key dropping.
- Phase 2 exact Counter/UpDownCounter aggregation with checked signed-64-bit overflow behavior.
- Finite, strictly increasing explicit-boundary Histogram aggregation with lower-bucket exact-boundary semantics and defensive snapshots.
- Public no-op `UpDownCounter` and `Histogram` contracts, without pretending a recording MeterProvider exists.
- Type-tagged binary canonical attribute-series identities using the public NOX protobuf writer; this internal key is not OTLP.
- Provider-wide series/estimated-byte reservation and a hard per-instrument point limit with a pre-reserved `otel.metric.overflow=true` aggregation.
- Cumulative bounded Counter storage with deterministic defensive snapshots and no measurement loss during cardinality overflow.
- A QBE/LLVM stress gate proving 100,000 unique attribute sets remain bounded to 1,000 points while preserving an exact total of 100,000.
- OpenTelemetry-aligned instrument name/unit validation, configurable description bounds and a case-insensitive duplicate/conflict registry with first-seen casing.
- Bounded cumulative UpDownCounter and Histogram series storage with the same provider budget and overflow guarantees as Counter.
- An experimental single-owner recording MeterProvider/Meter connecting all three synchronous instruments, scopes and duplicate descriptors without claiming thread safety.
- Transactional instrument creation: failure to reserve mandatory overflow storage leaves no partial registry entry.

### Changed

- Historical NOX 2.1.0 workarounds were retired after 2.1.64 regression verification.
- A formatter defect still present in NOX 2.1.64 for pass-only classes is recorded as `NOX-FMT-004`; Pulse uses real method bodies as containment.
- TaskLocal non-inheritance, QBE cooperative scheduling, worker-local module state and bounded fiber stacks remain explicit design constraints.
- OTLP/protobuf support remains unimplemented and unclaimed until pinned-schema mapping, independent decoding and Collector integration pass.
- The manifest advances to `0.1.0` after the common-primitives local gate; active work moves to the unreleased `v0.2.0` metrics core.
- `NOX-CODEGEN-001` records that optional float class fields type-check but fail executable codegen on 2.1.64; histograms use an explicit `has_min_max` representation.

### Security

- No telemetry implementation or network exporter is enabled.

