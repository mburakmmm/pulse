# AGENTS.md — PULSE

> **Project:** Pulse — metrics, distributed tracing, OpenTelemetry interoperability and telemetry exporters for the NOX ecosystem.  
> **Status:** Planned / experimental. This file is an implementation contract, **not** a statement that the APIs or integrations already exist.  
> **Implementation language:** NOX 2.x by default; narrowly scoped Zig/NNI glue only after a documented capability audit.  
> **Audience:** AI coding agents, maintainers, contributors, reviewers, CI and release automation.  
> **Normative keywords:** MUST / MUST NOT = mandatory; SHOULD = recommended with documented exception; MAY = optional.  
> **Reference implementation:** `https://github.com/mburakmmm/nox-lang`. Pin the tested NOX compiler revision in CI.  
> **Standards:** OpenTelemetry specifications and OTLP protocol specifications; pin the exact versions and generated protocol schema in `docs/standards-matrix.md`.

---

## 0. Mission

Build **Pulse**, the framework-independent observability library for NOX. Its original role is a Prometheus-client-like metrics/performance library; extend it to production-grade **OpenTelemetry-compatible traces, metrics and exporters**, with a clean bridge to **Obsidian** structured logging.

Pulse MUST enable a trace to follow one operation across, for example:

`Aether incoming HTTP → Nyx handler → Feather/Atlas database → Nova outbound HTTP → response`

The same trace ID and relevant span ID MUST be available to Obsidian logs without making Obsidian depend on Pulse's implementation internals. The integration MUST be optional, avoid circular dependencies, and work in non-web NOX applications.

**Priority:** semantic correctness → security/privacy → bounded resources → interoperable telemetry → reliability → portable NOX implementation → ergonomic API → performance.

**Do not** build an APM SaaS, telemetry database, log-search engine, or OpenTelemetry Collector inside Pulse. Pulse is an **instrumentation SDK and export client**, not a collection backend.

### Non-negotiable principles

1. **NOX-first:** public API is typed NOX. Never assume Python's contextvars, decorators, reflection, generators, or threading behavior exists in NOX.
2. **Framework-independent:** Pulse core MUST NOT depend on Nyx, Aether, Nova, Feather, Atlas, Aura, Quartz, Obsidian or VAULT. Optional adapters may depend on their corresponding integration.
3. **OpenTelemetry interoperability:** match the semantics of the pinned specifications. Do not market a custom JSON format as OTLP.
4. **Real metrics:** counters, histograms, rates and quantiles must derive from real measurements, not synthetic or fabricated values.
5. **Correct context propagation:** `traceparent`, `tracestate` and baggage must be parsed, validated and propagated according to pinned W3C specifications.
6. **Security by default:** no raw credentials, authorization headers, SQL parameter values, request bodies, health data or user-identifying attributes are captured by default.
7. **Bounded by design:** span buffers, queues, attribute sizes, cardinality, batches, retries, payload sizes and shutdown time are bounded and configurable.
8. **Never block an application indefinitely** because an exporter is slow or unavailable.
9. **Graceful degradation:** no-op providers and disabled telemetry must be safe, cheap and predictable.
10. **Portable correctness:** LLVM and QBE may differ in concurrency. Advertise thread safety only after multi-worker LLVM tests and correct QBE behavior.
11. **Honest feature status:** mark unimplemented and partially implemented functionality explicitly; no mock exporter may be advertised as production OTLP.
12. **Reproducibility:** tests use injected clock, ID generator, transport, and deterministic in-memory exporters.
13. **No undocumented internal ABI:** do not use NOX runtime's private object layout or `__nox_*` symbols; use public NOX APIs or documented NNI.
14. **No silent API breakage:** stable public interfaces require compatibility review and changelog entries.
15. **Every feature needs behavioral tests**, including failure, cancellation, concurrency, resource limits and shutdown.
16. **Do not change `noxc` or NOX standard library** to implement Pulse unless a separate, reviewed upstream proposal is approved.

---

## 1. Source of truth and mandatory compatibility audit

Before implementing or refactoring, inspect the **actual pinned** NOX compiler and standard library. At planning time, upstream documentation indicates:

| Capability | Known NOX interface | Important constraint |
|---|---|---|
| Monotonic timing | `nox.time.instant_now()`, `Instant.elapsed_ms()` | Resolution is milliseconds in documented API; avoid claiming nanosecond precision |
| Wall clock | `nox.time.now_ms()` | Clock can jump; do not use for durations |
| Secure IDs | `nox.crypto.secure_random_hex(n_bytes)` | Use for unpredictable trace/span IDs; never `nox.random` |
| HTTP transport | `nox.http.request(method, url, body, headers, timeout_ms)` | Supports HTTP methods, timeouts and binary-preserving string bodies; verify needed content encoding |
| JSON | `nox.json.parse`, `dump`, `JsonWriter` | Use proper JSON escaping; do not hand-concatenate untrusted values |
| File I/O | `nox.fs.open_append`, `write_string_atomic`, etc. | Paths are not sandboxed; validate file destinations |
| Environment | `nox.os.getenv(name)` | Missing variable raises `OsError` |
| Async | `spawn`, `await`, `Task[T]`, channels | QBE cooperative; LLVM multi-worker |
| Explicit threads | `nox.thread.start`, `await ThreadHandle.join()` | QBE worker argument restrictions; join before freeing shared state |
| Atomics | `nox.atomic.AtomicInt`, `AtomicBool` | `free()` only after all users finish |
| Logging | `nox.log` | Obsidian is separate; Pulse must not replace logging |
| Native interface | public NNI / `extern def` | Native code has OS authority; audit all boundary crossings |

**Required audit output:** `docs/compatibility.md` MUST list:
- exact NOX version, commit SHA, QBE/LLVM combinations and supported OS targets;
- verified API names/signatures with a compiling smoke test for each used capability;
- missing features (e.g. context-local storage, high-resolution monotonic clock, protobuf encoder, gzip, UDP) and approved fallback;
- supported exporter transports, payload formats and limitations;
- dependency versions and runtime capabilities.

If the public clock has only millisecond resolution, convert honestly to the required OTLP timestamp unit (e.g. multiply ms to ns) and document the **precision limit**. Never invent sub-millisecond accuracy.

---

## 2. Scope and boundaries

### In scope

- **Metrics:** counter, up/down counter, histogram, observable instruments when supported, views, attributes, aggregation, temporality, exemplars when implemented.
- **Tracing:** tracer provider, tracer, spans, events, links, status, span kinds, attributes, span processors, context propagation and sampling.
- **OpenTelemetry:** resource metadata, instrumentation scope, W3C Trace Context and baggage, OTLP encoding/transport, spec-aligned semantic conventions.
- **Exporters:** in-memory, console, Prometheus scrape, OTLP/HTTP (traces and metrics), optional OTLP/gRPC and file exporters.
- **Runtime:** bounded batch processor, retry/backoff, flush, shutdown, diagnostics, SDK self-observability.
- **Integrations:** optional Obsidian context bridge; Aether, Nyx, Nova, Feather, Atlas, Quartz, Chronos, Rune, Aura adapters as relevant.

### Explicitly out of scope for the initial stable release

- Full OTLP log ingestion/export pipeline (may be a later adapter with Obsidian).
- Implementing an OpenTelemetry Collector, Jaeger, Tempo, Prometheus or Grafana.
- Building a telemetry storage/query database, UI, alert manager or billing platform.
- Automatic monkey-patching or implicit instrumentation of every NOX function.
- Default capture of HTTP bodies, SQL values, credentials, PII, medical data or stack dumps.
- Claiming universal automatic cross-task context inheritance without an implementation and test.

### Ownership boundary with Obsidian

- **Pulse owns:** trace/span lifecycle, context, propagation, metrics, sampling, exporters.
- **Obsidian owns:** structured log events, formatting, redaction, sinks, rotation, log delivery.
- **Bridge owns:** passing a safe, immutable snapshot of `trace_id`, `span_id`, `trace_flags`, optional request ID into Obsidian event context.
- The bridge MUST NOT create a tracing engine inside Obsidian or a logging framework inside Pulse.
- Avoid dependency cycles using a tiny neutral context contract, explicit adapters or callbacks.

---

## 3. Proposed repository layout

```text
pulse/
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── LICENSE
├── nox.json
├── nox.lock
├── docs/
│   ├── architecture.md
│   ├── compatibility.md
│   ├── standards-matrix.md
│   ├── api.md
│   ├── telemetry-data-model.md
│   ├── exporter-support.md
│   ├── performance.md
│   ├── security.md
│   ├── migration.md
│   └── adr/
├── pulse/
│   ├── __init__.nox
│   ├── api/
│   │   ├── metrics.nox
│   │   ├── tracing.nox
│   │   └── context.nox
│   ├── core/
│   │   ├── attributes.nox
│   │   ├── resource.nox
│   │   ├── scope.nox
│   │   ├── clock.nox
│   │   ├── ids.nox
│   │   ├── errors.nox
│   │   └── limits.nox
│   ├── metrics/
│   │   ├── provider.nox
│   │   ├── instruments.nox
│   │   ├── aggregator.nox
│   │   ├── histogram.nox
│   │   ├── views.nox
│   │   ├── reader.nox
│   │   ├── temporality.nox
│   │   ├── exemplars.nox
│   │   └── prometheus.nox
│   ├── tracing/
│   │   ├── provider.nox
│   │   ├── tracer.nox
│   │   ├── span.nox
│   │   ├── context.nox
│   │   ├── propagators.nox
│   │   ├── sampler.nox
│   │   ├── processor.nox
│   │   └── limits.nox
│   ├── otlp/
│   │   ├── model.nox
│   │   ├── protobuf.nox
│   │   ├── json_encoding.nox
│   │   ├── http_transport.nox
│   │   ├── mapping_traces.nox
│   │   └── mapping_metrics.nox
│   ├── exporters/
│   │   ├── interface.nox
│   │   ├── memory.nox
│   │   ├── console.nox
│   │   ├── prometheus.nox
│   │   ├── otlp_http.nox
│   │   └── file.nox
│   ├── runtime/
│   │   ├── queue.nox
│   │   ├── batch.nox
│   │   ├── retry.nox
│   │   ├── shutdown.nox
│   │   └── diagnostics.nox
│   └── integrations/
│       ├── obsidian.nox
│       ├── aether.nox
│       ├── nyx.nox
│       ├── nova.nox
│       ├── feather.nox
│       ├── atlas.nox
│       └── quartz.nox
├── tests/
│   ├── unit/
│   ├── golden/
│   ├── integration/
│   ├── conformance/
│   ├── concurrency/
│   ├── security/
│   ├── fuzz/
│   └── benchmarks/
├── fixtures/
│   ├── w3c/
│   ├── otlp/
│   └── prometheus/
├── examples/
│   ├── hello_metrics.nox
│   ├── hello_traces.nox
│   ├── http_instrumentation.nox
│   ├── otlp_collector.nox
│   └── obsidian_correlation.nox
└── .github/workflows/
    ├── ci.yml
    ├── compatibility.yml
    └── release.yml
```

**Layout is proposed**, not proof of existing files. Use the repository's actual package/import naming conventions after checking NOX module loading.

---

## 4. Public API design contract

### 4.1 Separate API and SDK

- `pulse.api` MUST expose stable, minimal types/interfaces that instrumentation code can depend on without an exporter.
- `pulse.sdk` or equivalent internal provider implementation MUST implement aggregation, sampling and export.
- The public API MUST permit a no-op implementation with no network activity.
- Initialization MUST be explicit and idempotent; no surprise network calls on import.
- Global/default provider MAY exist only after a concurrency and isolation design; prefer explicit provider injection.
- Reconfiguration MUST be atomic from the caller's perspective or documented as requiring quiescence.

### 4.2 Proposed ergonomic surface (illustrative; verify syntax and types)

```nox
# PSEUDOCODE — design target, not guaranteed to compile yet.
provider = PulseProvider(PulseConfig(service_name="checkout-api"))
meter = provider.get_meter("checkout")
requests = meter.create_counter("http.server.requests", "1")
requests.add(1, {"http.request.method": "GET"})

tracer = provider.get_tracer("checkout")
span = tracer.start_span("GET /orders", kind="SERVER")
try:
    span.set_attribute("http.response.status_code", 200)
finally:
    span.end()
provider.force_flush()
provider.shutdown()
```

**Implementation rule:** do not copy this example into executable tests until checked against the actual NOX parser, type checker and runtime. Supply compiling, minimal examples in `examples/` once implemented.

### 4.3 Public type contracts

Specify and test:
- `Resource`, `InstrumentationScope`, `Attributes`, `AttributeValue`, `AttributeLimits`.
- `MeterProvider`, `Meter`, `Counter`, `UpDownCounter`, `Histogram`, optional `ObservableGauge`.
- `TracerProvider`, `Tracer`, `Span`, `SpanContext`, `TraceFlags`, `SpanKind`, `SpanStatus`.
- `Sampler`, `SpanProcessor`, `MetricReader`, `MetricExporter`, `SpanExporter`, `Propagator`.
- `ExportResult`, `FlushResult`, `ShutdownResult`, `TelemetryError`.
- `NoopMeterProvider`, `NoopTracerProvider`.

Prefer explicit interfaces and typed constructors. Avoid `Any`-style dynamic payloads unless a NOX-compatible tagged union is necessary and documented.

---

## 5. Common telemetry data model

### 5.1 Attributes

- Supported value types MUST match the pinned OpenTelemetry data model and protocol: booleans, integers, floats, strings and allowed homogeneous arrays.
- Preserve integer fidelity. **Never silently convert 64-bit integer attributes to float** for JSON convenience.
- Validate attribute keys; reject or truncate invalid/oversized entries according to a documented policy.
- Attribute key ordering MUST be deterministic for snapshots and exported JSON where order is otherwise unconstrained.
- Apply limits: per-record attribute count, value length, array length, event/link counts, and aggregate cardinality.
- Use a typed representation and defensive copy/snapshot at record time; later caller mutation must not retroactively alter recorded data.
- Reject NaN/infinity where exporter format or instrument semantics disallow them; document handling.
- Drop or sanitize sensitive values before enqueueing; export-time redaction alone is insufficient.

### 5.2 Resource and instrumentation scope

- `Resource` represents service/process/environment metadata and is attached consistently to all telemetry.
- Default service name is configurable; do not guess a production service identity.
- Support documented `service.name`, `service.namespace`, `service.version`, `deployment.environment.name` and other pinned semantic-convention keys.
- Merge precedence MUST be deterministic: explicit configuration > environment-derived metadata > safe defaults, unless the pinned spec requires otherwise.
- `InstrumentationScope` includes name, version, schema URL and optional attributes.
- Avoid global mutation of resources after telemetry is recorded.

### 5.3 Time and identity

- Wall-clock timestamps for OTLP events; monotonic clock for duration measurement.
- Span start/end timestamps MUST be internally consistent and nonnegative.
- Record and document clock skew and precision behavior.
- IDs MUST use secure entropy when available: 16-byte trace ID and 8-byte span ID, valid lowercase hex when serialized as W3C headers.
- Reject all-zero trace/span IDs; never use timestamps, counters alone, or predictable PRNGs for IDs.
- Deterministic ID generators are allowed **only in tests** through explicit injection.
- Keep internal ID bytes distinct from hex textual representation; validate length at boundaries.

---

## 6. Metrics API and instrument semantics

### 6.1 Instrument kinds

Implement in this order:

1. **Counter:** monotonically increasing; negative additions are rejected or handled per pinned spec.
2. **UpDownCounter:** signed changes; tracks positive and negative deltas.
3. **Histogram:** records measurements into explicit bucket boundaries with count, sum, min/max when supported.
4. **ObservableGauge:** asynchronous callback collection; implement only when callbacks and lifecycle are safe in both backends.
5. **ObservableCounter / ObservableUpDownCounter:** later if required by supported spec and tested.

Instruments MUST declare name, unit, description and scope. Duplicate instrument creation with conflicting metadata MUST follow a documented conflict policy.

### 6.2 Aggregation correctness

- Maintain exact integer counts where possible; avoid lossy `float` conversions for counter totals.
- Histogram bucket boundaries MUST be strictly increasing and finite.
- Define inclusive/exclusive boundary behavior and test exact-boundary observations.
- Histogram count MUST equal the sum of bucket counts; sum/min/max must reflect the same recorded set.
- Negative measurements: follow instrument-specific OpenTelemetry rules, including sum handling.
- Empty histogram export MUST be explicitly defined.
- Cardinality limiting MUST be enforced before allocating a new attribute series.
- Never allow a malicious attribute stream to create unbounded unique series.
- On cardinality overflow use a deterministic overflow series or drop strategy consistent with the pinned spec; expose an internal diagnostic counter.
- Prefer preaggregated per-series state to storing every observation in memory.

### 6.3 Views and configuration

- Allow selecting instruments by name/scope and overriding aggregation, attribute allowlist and histogram boundaries.
- Views MUST be resolved deterministically and before measurements are accumulated.
- Invalid views MUST fail configuration validation, not silently corrupt aggregation.
- Define policy for overlapping views and duplicated exported metric names.
- Distinguish SDK-internal metrics from user metrics to avoid self-instrumentation loops.

### 6.4 Temporality

- Support cumulative temporality first, then delta temporality with independently tracked collection state.
- Delta reader MUST NOT reset data before a successful collection snapshot is secured.
- Multiple readers MUST NOT steal/reset each other's observations.
- Define collection timestamps, start timestamps, reset behavior and process restart semantics.
- Failed export MUST NOT silently change the semantic meaning of the next delta export.
- A restart must not produce negative counters or an invalid start timestamp.
- State exactly which temporality each exporter supports.

### 6.5 Exemplars

- Optional later feature; exemplar links a measurement to valid trace/span IDs and sampled context when permitted.
- Must respect attribute/size limits and privacy policy.
- No fake trace IDs or fabricated exemplar timestamps.
- Exemplar reservoir and filtering behavior MUST be documented and tested.

---

## 7. Tracing and span lifecycle

### 7.1 Span model

A span MUST contain, where appropriate:
- trace ID, span ID, parent span ID;
- name and kind: `INTERNAL`, `SERVER`, `CLIENT`, `PRODUCER`, `CONSUMER`;
- start/end timestamp, attributes, events, links, status;
- resource and instrumentation scope;
- trace flags and tracestate;
- dropped attribute/event/link counters.

### 7.2 State machine

- `start_span()` creates a recording or non-recording span according to sampling decision.
- `end()` is idempotent: a second call MUST NOT export twice.
- Mutating an ended span MUST NOT change its exported snapshot.
- A span MUST NOT end before it starts; clock anomalies handled deterministically.
- Parent-child relationships MUST use validated span contexts, not mutable global variables.
- Record exception events only after privacy sanitization; no automatic raw stack/argument dumps.
- Status semantics MUST follow pinned OpenTelemetry rules; don't infer ERROR solely from every HTTP non-2xx without semantic convention guidance.
- Always end spans in `finally` or equivalent guaranteed cleanup; support early returns and exceptions.
- Parent context remains valid for propagation even if the parent span has ended, where permitted by spec.

### 7.3 Span events and links

- Events have name, timestamp, attributes and dropped-count metadata.
- Links refer to valid remote/local span contexts and carry optional attributes.
- Enforce max events/links and max attributes per event/link.
- Ensure links are added early enough for head sampling where needed.
- Snapshot mutable event/link attributes on record.

---

## 8. Context management and propagation

### 8.1 NOX task context strategy

**Do not assume implicit task-local propagation.** Before coding, audit documented `TaskLocal[T]` behavior, explicit `spawn` semantics, `nox.thread` behavior and QBE/LLVM differences.

Implement an explicit `TelemetryContext` value as the foundational API:
- `context.with_span(span_context) -> TelemetryContext` or equivalent immutable constructor;
- `tracer.start_span(..., parent=context)` to establish parent explicitly;
- `inject(context, carrier)` and `extract(carrier)` with no hidden global state.

An ergonomic scoped `current_span()` or context manager MAY be added only if a real task-local mechanism is verified and tests cover:
- nested scopes;
- task spawn/inheritance;
- concurrent requests on different workers;
- cancellation/exception cleanup;
- cross-thread handoff;
- context restoration after scope exit.

**Prohibited:** one module-global `current_span` shared across concurrent requests.

### 8.2 W3C Trace Context

Implement `traceparent` parsing/formatting with:
- supported version syntax, separators, exact lengths, lowercase hex formatting;
- nonzero IDs and valid flags;
- strict rejection of malformed/truncated headers;
- preservation of valid remote trace context and sampling flag;
- spec-defined handling of unknown versions;
- validated, bounded `tracestate` (entries, lengths, allowed characters, ordering).
- case-insensitive HTTP header-name lookup, because NOX HTTP headers preserve caller spelling.

Inject MUST NOT overwrite user-supplied tracing headers without an explicit policy; extraction MUST NOT trust arbitrary remote flags as authorization or business logic.

### 8.3 W3C Baggage

- Implement parsing, percent-encoding/decoding, duplicate-key handling and bounded key/value sizes according to pinned spec.
- Treat baggage as **untrusted input**; no secrets or personal data by default.
- Baggage is not a replacement for metric attributes or span attributes.
- Propagation MUST be configurable/disableable across trust boundaries.
- Document whether baggage is dropped or sanitized for external destinations.

### 8.4 Sampling

Implement:
- `AlwaysOn`, `AlwaysOff`, `TraceIdRatioBased`, `ParentBased`.
- Ratio must be deterministic for a trace ID and a fixed probability.
- Validate ratio range `[0, 1]`; 0 means never, 1 means always.
- ParentBased must honor remote/local parent sampled decisions according to pinned spec.
- A non-recording span must still support valid context propagation where appropriate.
- Document `DROP`, `RECORD_ONLY`, `RECORD_AND_SAMPLE` decisions and their export effects.
- No sampling based on secret data or unstable process-specific hash.

---

## 9. Span processors and lifecycle

### 9.1 Simple processor

- Synchronously submit ended spans to exporter; intended for tests/debugging or low-volume usage.
- Respect exporter timeout; never permit indefinite network blocking.
- Export failures MUST be observable via safe diagnostics.

### 9.2 Batch processor

- Bounded queue capacity, max batch size, scheduled delay, export timeout and shutdown timeout.
- Nonblocking or explicitly bounded enqueue on request hot paths.
- Define overflow policy (`drop_newest`, `drop_oldest`, bounded wait); default must be safe and documented.
- Exporter work MUST NOT run while holding a lock required by application recording.
- `force_flush()` must account for records accepted before the flush barrier; clearly define timeout result.
- `shutdown()` must reject new telemetry and drain or explicitly drop outstanding records within deadline.
- `shutdown()` and `force_flush()` MUST be idempotent or return documented states.
- No worker may access freed queues, atomics, buffers or transport after shutdown.
- Retain and join worker handles before freeing shared resources.
- Never simulate concurrency with `Generator.send()` and claim parallel execution.
- QBE may require cooperative export/poll or synchronous fallback; do not invent background parallelism.

### 9.3 Export error classification

- Distinguish retryable failures (transport outage, selected HTTP 429/5xx) from permanent failures (invalid payload, auth/config errors, unsupported media type).
- Retry with exponential backoff and bounded jitter, maximum attempts, maximum elapsed time and total queue limits.
- Respect `Retry-After` where supported and safe.
- No infinite retries, no unbounded disk spooling.
- Handle partial success explicitly per OTLP response semantics; don't report full success when some data was rejected.
- Expose dropped/failed/retried counts through internal diagnostics, avoiding recursion.

---

## 10. Exporter contract and matrix

Each exporter MUST implement a documented, typed interface:

- `export(batch) -> ExportResult`
- `force_flush(deadline) -> FlushResult` when applicable
- `shutdown(deadline) -> ShutdownResult`
- capabilities: signal kind, transport, temporality, encoding, compression, authentication and resource limits.

| Exporter | Signal | MVP status | Acceptance criteria |
|---|---|---|---|
| In-memory | traces + metrics | Required first | Deterministic snapshots, thread-safe or explicitly isolated |
| Console | traces + metrics | Required | Structured, sanitized, no recursion |
| Prometheus scrape | metrics | Required before metrics stable | Correct exposition format, labels, types, units and endpoint behavior |
| OTLP/HTTP | traces + metrics | Required before OTEL stable | Real Collector interoperability, correct encoding and response handling |
| OTLP/gRPC | traces + metrics | Optional later | Real gRPC transport and protobuf framing, not HTTP mislabeled gRPC |
| File | traces + metrics | Optional | Atomic/append semantics, safe permissions, size limits |
| OTLP logs bridge | logs | Deferred | Separate ADR with Obsidian; preserve ownership boundaries |

No exporter may depend on the user deploying a specific observability vendor.

---

## 11. OpenTelemetry OTLP encoding and transport

### 11.1 Protocol-first development

- Pin exact OTLP protobuf definitions and semantic conventions versions in `docs/standards-matrix.md`.
- Maintain canonical fixtures generated independently from official schema/tooling.
- Use official field numbers, wire types, nested messages and enum values.
- **Never** invent a lookalike JSON schema and call it OTLP.
- Preserve 64-bit integers without rounding; pay attention to JSON mapping of protobuf `int64`, bytes and enum values.
- Preserve trace/span IDs as raw bytes in protobuf; apply required encoding for JSON and W3C headers.
- Distinguish `ResourceSpans` / `ScopeSpans` / `Span`, and `ResourceMetrics` / `ScopeMetrics` / metric data points.
- Correctly encode timestamps, dropped counts, attributes, events, links, aggregation temporality and exemplars when supported.
- Reject unsupported signal/encoding combinations at configuration time.

### 11.2 OTLP/HTTP

- Implement traces and metrics with the pinned protocol's correct paths and media types.
- Support protocol-defined `/v1/traces` and `/v1/metrics` routing; define precedence for full endpoint vs base endpoint configuration.
- Support `application/x-protobuf` with real protobuf bytes before claiming standard OTLP/HTTP support.
- JSON encoding MAY be supported if fully compliant with the protocol's JSON mapping; do not treat JSON as a shortcut.
- Handle success, retryable status, permanent status, invalid response, timeout, redirect and partial success.
- Define request headers and credentials via explicit safe configuration.
- TLS verification MUST be enabled by default. No silent insecure fallback.
- Do not log full request headers or payload on export failure.
- Respect explicit max payload and per-request timeout.
- Avoid accidentally instrumenting Pulse's own OTLP HTTP client (recursive telemetry).
- Support compression only if implemented correctly and covered by round-trip tests.
- Use a transport abstraction so tests do not require a live external service.

### 11.3 OTLP/gRPC (optional)

- Implement only after confirming a real NOX-compatible gRPC/HTTP2 transport.
- Do not implement a custom TCP protocol and call it gRPC.
- gRPC status mapping, deadlines, TLS and streaming framing require independent conformance tests.
- If unavailable, document "OTLP/gRPC unsupported"; OTLP/HTTP remains the supported path.

---

## 12. Prometheus exporter and scrape endpoint

Pulse originated as a Prometheus-style metrics library; **Prometheus exposition is a first-class feature**, not a wrapper around OTLP.

- Provide a pull/scrape endpoint via a safe HTTP server adapter or a `render_metrics()` function that an application can expose.
- Explicitly document supported Prometheus text exposition version and, if implemented, OpenMetrics version.
- Correctly escape metric names/label names/label values/help text.
- Implement correct naming for counters, units, histogram `_bucket`, `_sum`, `_count` and cumulative `le` buckets.
- Include `+Inf` bucket and ensure it equals total observation count.
- Correctly expose resource attributes only through a configured allowlist or target-info mechanism; never promote all resource attributes to metric labels.
- No unbounded label cardinality; reject or collapse dynamic URL paths, user IDs, session IDs and arbitrary error messages.
- Scrape snapshots must be internally consistent while concurrent measurements occur.
- The scrape handler must not generate recursive application metrics.
- Respect scrape timeouts and avoid network calls during rendering.
- Keep metrics output stable/deterministic for golden tests.
- Validate output with an external Prometheus/OpenMetrics parser where feasible.
- If histogram temporality differs from OTLP readers, maintain independent reader state.

---

## 13. Framework integrations

Integrations are **optional leaf packages**, never dependencies of `pulse/core`.

### Aether / Nyx (incoming HTTP)
- Extract W3C context from inbound headers; create `SERVER` span with validated parent.
- Name spans using low-cardinality route templates, **not** raw URLs containing IDs.
- Record HTTP method, route, response status and duration according to pinned semantic conventions.
- Inject trace context into request scope explicitly or via proven task-local mechanism.
- Always end spans on success, error, cancellation and timeout.
- Expose request count, duration histogram and active request gauge when correct.

### Nova (outbound HTTP)
- Create `CLIENT` span; inject `traceparent`, `tracestate`, optional baggage.
- Never overwrite `Authorization`, `Cookie`, or user headers incorrectly.
- Exclude OTLP exporter requests from instrumentation to avoid recursion.
- Distinguish transport errors from HTTP non-2xx responses.
- Propagate context across retries without creating duplicate parent relationships.

### Feather / Atlas (database)
- Create `CLIENT` spans around DB operations; report database system/operation and sanitized statement metadata.
- **Do not capture raw SQL bind values**, credentials, DSNs or query result rows.
- Use low-cardinality operation labels for metrics.
- Measure connection pool and query durations without per-query-text label explosion.

### Obsidian (logging)
- Bridge `trace_id`, `span_id`, `trace_flags`, optional request ID into Obsidian's structured event context.
- Obsidian MUST continue to work when Pulse is absent or disabled.
- Never log baggage or trace attributes wholesale.
- No double logging and no recursive exporter/logging loop.
- Define a stable, small bridge contract and tests for mismatched version/disabled providers.

### Quartz (testing)
- Provide an in-memory exporter, deterministic clock and IDs for assertions.
- Offer helpers to assert span hierarchy, metric totals, histogram boundaries, resource attributes and propagation.
- Quartz MUST NOT be required by Pulse at runtime; tests can use Quartz.

### Chronos / Rune / Aura / other
- Optional job/command/UI instrumentation with explicit privacy defaults.
- No hidden mandatory integrations, no importing heavyweight UI/server modules from core.
- Mobile and WASM support must be separately tested and capability-gated.

---

## 14. Configuration and environment

Provide explicit typed `PulseConfig` plus optional environment loader. Suggested variables, subject to pinned OTel environment-variable specification:

- `OTEL_SERVICE_NAME`
- `OTEL_RESOURCE_ATTRIBUTES`
- `OTEL_TRACES_EXPORTER`
- `OTEL_METRICS_EXPORTER`
- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`
- `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`
- `OTEL_EXPORTER_OTLP_PROTOCOL`
- `OTEL_EXPORTER_OTLP_HEADERS`
- `OTEL_EXPORTER_OTLP_TIMEOUT`
- `OTEL_TRACES_SAMPLER`
- `OTEL_TRACES_SAMPLER_ARG`
- `OTEL_METRIC_EXPORT_INTERVAL`
- `OTEL_METRIC_EXPORT_TIMEOUT`
- `OTEL_BSP_MAX_QUEUE_SIZE`
- `OTEL_BSP_MAX_EXPORT_BATCH_SIZE`
- `OTEL_BSP_SCHEDULE_DELAY`
- `OTEL_BSP_EXPORT_TIMEOUT`
- `OTEL_PROPAGATORS`
- `OTEL_SDK_DISABLED`

**Rules:**
- Follow the pinned spec for exact variable names, units and precedence. These names are design targets until verified.
- Precedence: explicit config > signal-specific env > generic env > safe defaults, unless specification says otherwise.
- Parse units strictly (milliseconds versus seconds); reject invalid/negative values with actionable errors.
- Never print configured endpoint credentials or OTLP headers.
- Disabled SDK must not start worker threads, listeners or network connections.
- VAULT integration MAY supply secrets/configuration through a narrow optional provider; core must not depend on VAULT.
- Provide a validated configuration summary with secret fields redacted.
- Support safe reconfiguration only with explicit lifecycle semantics; do not mutate live providers in place without synchronization.

---

## 15. Concurrency and memory safety

### 15.1 Fundamental model

- NOX LLVM supports multi-worker execution; QBE uses cooperative scheduling. Both must produce equivalent telemetry semantics.
- Module-level mutable state may be per worker; **never assume** a module global is shared across workers.
- Choose one of: explicit immutable context, worker-local aggregation with synchronized merge, atomic counters, or channel-based ownership.
- Document ownership and lifecycle for every shared buffer, exporter, queue and atomic cell.
- No thread may access freed state; all worker handles joined or safely drained before release.
- Avoid locks around exporter network I/O.
- Preserve measurement correctness under concurrent record/export/flush/shutdown.

### 15.2 Required race scenarios

Test with multiple workers simultaneously:
1. Record the same counter series.
2. Create distinct series and hit cardinality limit.
3. End the same span twice.
4. Flush while recording.
5. Shutdown while exporter is slow.
6. Exporter times out while other workers finish.
7. Cancel a worker during batch export.
8. Reconfigure provider while no active worker / reject unsafe live reconfigure.
9. Use a trace context on two tasks without cross-contamination.
10. Exporter error triggers diagnostics without recursive instrumentation.

### 15.3 Queue and backpressure

- Queue must have a finite capacity and a visible drop count.
- Memory budget must include queued spans, attributes, strings and exporter copies.
- Define maximum payload bytes, batch size, event count and export concurrency.
- High-cardinality attributes must be rejected or aggregated before memory allocation.
- Queue ownership transfer must be explicit: no mutable reference to caller-owned data.
- Backpressure MUST NOT deadlock an HTTP request or the exporter itself.
- All shutdown paths must release resources exactly once.

---

## 16. Security and privacy

### 16.1 Safe defaults

- No request/response bodies.
- No authorization/cookie headers, API keys, passwords, DSNs or secret environment variables.
- No user IDs, email addresses, IP addresses, health data or raw query strings by default.
- No arbitrary SQL bind values or database result contents.
- No stack traces containing private arguments unless explicitly opted in and sanitized.
- No baggage forwarding to untrusted destinations without explicit policy.

### 16.2 Redaction and attribute policy

- Implement allowlist-first collection for HTTP headers and resource attributes.
- Apply per-key classification and value redaction **before** data enters the export queue.
- Avoid recording unknown arbitrary user attributes by default in automatic instrumentation.
- Configurable drop, hash, truncate or mask policies must be deterministic and documented.
- Hashing personal data does not automatically make it anonymous; do not claim it does.
- Never place secrets in metric labels or trace IDs.
- Log/export error messages must redact credentials in URLs and headers.

### 16.3 Network and local exposure

- OTLP HTTPS certificate validation enabled by default.
- Export endpoint allowlist/validation recommended for untrusted configuration.
- Protect against SSRF if endpoint can be influenced by users.
- Prometheus scrape endpoint MUST default to loopback or require explicit bind configuration; document access control responsibility.
- Bound inbound HTTP header sizes and malformed `traceparent`/baggage input.
- File exporters must avoid path traversal and symlink escape; canonicalize against configured root.
- Exporter dependencies must be pinned in `nox.lock` and reviewed for native authority.

### 16.4 Threat-model tests

Include malicious trace headers, oversized baggage, high-cardinality label floods, exporter redirects, poisoned resource attributes, partial OTLP responses, endpoint timeout, retry storms, bad TLS, invalid UTF-8, and shutdown races.

---

## 17. Performance and operational budgets

Record baseline benchmarks before optimization; **never invent results**.

Measure:
- `counter.add()` overhead with one series and many series;
- histogram observation overhead;
- `start_span()` / `end()` with sampling on/off;
- propagation parse/inject throughput;
- exporter throughput (spans/sec, datapoints/sec);
- p50/p95/p99 hot-path latency;
- peak heap size at max queue and cardinality limits;
- CPU use when exporter unavailable;
- lost/dropped telemetry count under overload;
- flush/shutdown completion time.

Benchmarks MUST distinguish:
- NOX backend (LLVM vs QBE);
- platform/CPU/compiler commit;
- synchronous vs batch exporter;
- sampling probability and attribute count;
- warmup, repetitions and sample count.

**Suggested design budgets (not measured promises):**
- bounded queues with configurable default;
- bounded attribute counts and string sizes;
- no network I/O in metric recording hot path;
- disabled/no-op provider avoids allocations when feasible;
- export retry budget finite;
- no unbounded per-request context or label cache.

Optimize only after correctness, race and interoperability tests pass.

---

## 18. Testing strategy and conformance matrix

### 18.1 Unit tests

- IDs: lengths, nonzero, entropy source injection, malformed input.
- Attributes: type fidelity, arrays, limits, deterministic ordering, privacy.
- Metrics: negative counter rejection, up/down behavior, bucket boundaries, sum/count consistency, temporality.
- Tracing: lifecycle, parent-child, events/links, sampling, idempotent end, clock anomalies.
- Context: nested scopes, explicit propagation, task isolation, cancellation.
- Configuration: precedence, units, missing env, invalid endpoint, disabled mode.
- Exporter: retryability, timeout, partial success, queue drops, flush/shutdown.
- Prometheus: correct escaping, HELP/TYPE, histogram `+Inf`, cumulative buckets.
- OTLP: protobuf wire format, JSON mapping when supported, integer and byte fidelity.

### 18.2 Golden tests

Store fixed expected outputs for:
- W3C `traceparent`, `tracestate`, baggage;
- deterministic span/metric serialization;
- OTLP protobuf fixtures generated from pinned official definitions;
- Prometheus exposition;
- resource/scope mapping;
- cross-backend output equivalence where deterministic.

Do not snapshot nondeterministic timestamps/IDs without injecting fixed providers.

### 18.3 Real interoperability tests

At least one integration job MUST:
1. Start a pinned OpenTelemetry Collector in a container.
2. Send a real trace batch via OTLP/HTTP.
3. Send real metric data via OTLP/HTTP.
4. Assert the Collector received correct resource/scope/trace/span/metric fields.
5. Exercise rejection and retry paths with a controllable test server.
6. Confirm no credentials or request bodies appear in captured payloads.

Prometheus integration MUST scrape a real endpoint and parse/validate exposition. If no container runtime is available, report `SKIPPED` with reason; **do not mark unexecuted tests PASS**.

### 18.4 Differential and concurrency tests

- Run pure behavior tests under QBE and LLVM.
- Run multi-worker stress tests under LLVM with forced worker count.
- Test repeated startup/shutdown cycles and no leaked worker handles.
- Test slow exporter + fast producer + bounded queue.
- Test `force_flush` barrier correctness under concurrent recording.
- Test two simultaneous HTTP requests with different trace IDs and assert zero cross-contamination.
- Test context injection/extraction across two NOX processes where possible.
- Test worker shutdown and atomic lifetime using real joins, not synthetic concurrency counters.

### 18.5 Fuzz and property tests

Fuzz:
- W3C header parsers and baggage;
- OTLP protobuf/JSON decoders if any;
- Prometheus label escaping;
- configuration/env parser;
- attribute cardinality and array nesting;
- malformed exporter responses.

Properties:
- parse(format(valid_context)) = equivalent context;
- histogram bucket sum = total count;
- counter never decreases under valid additions;
- no telemetry after shutdown is accepted;
- accepted batch is exported, dropped with explicit reason, or pending within bounded deadline;
- repeated `end()` exports at most once.

### 18.6 Coverage policy

A release MUST have behavioral coverage for each advertised feature, not merely line coverage. Record a feature-to-test matrix in `docs/standards-matrix.md`.

---

## 19. CI, build and release gates

### 19.1 Mandatory CI

- NOX typecheck and build for all library modules.
- Unit/golden/property tests under both supported backends.
- Linux x64, Linux ARM64, macOS ARM64 and Windows x64 where toolchain is supported.
- Separate real multi-worker LLVM job.
- Exporter interoperability job with Collector.
- Prometheus parser validation.
- Security/privacy regression suite.
- Lint/format, lockfile reproducibility and dependency audit.
- Documentation examples compiled and executed.
- Artifact packaging smoke test.

If a platform lacks a capability, record it as `unsupported` or `skipped`, not success. Do not let optional network services make ordinary unit tests flaky.

### 19.2 Versioning and compatibility

- Semantic versioning once public API stabilizes.
- Before 1.0, label unstable surfaces clearly.
- Keep changelog with added/changed/fixed/removed/security sections.
- Pin NOX compiler compatibility and protocol schema version.
- A released Git tag MUST be immutable; fixes get a new patch release.
- No release while CI is red or conformance test is weakened to make it green.
- Registry submission status `awaiting approval` is not the same as registry availability.

### 19.3 Definition of Done

A feature is DONE only if:
1. Its public contract is documented.
2. It compiles under pinned NOX.
3. Unit and failure-path tests pass.
4. Resource bounds and privacy policy are enforced.
5. Concurrency and shutdown behavior are tested where relevant.
6. Real protocol interoperability is demonstrated if an exporter is claimed.
7. Both backend behavior and platform matrix are accurately reported.
8. No regression, unsupported claim or hidden placeholder remains.

---

## 20. Implementation roadmap: Phase 0–13

### Phase 0 — Repository, compiler and standards audit
**Deliver:** scaffold, pinned NOX version, compatibility report, architecture ADRs, standards matrix, minimal CI.  
**Gate:** real NOX smoke program builds under QBE and LLVM; missing capabilities listed explicitly.

### Phase 1 — Common telemetry primitives
**Deliver:** typed attributes, resources, scopes, IDs, clocks, limits, errors, no-op providers.  
**Gate:** deterministic tests for type fidelity, limits, IDs, time and safe defaults.

### Phase 2 — Metrics core
**Deliver:** meter provider, counters, up/down counters, explicit-boundary histograms, cumulative aggregation.  
**Gate:** math and concurrency tests pass; bounded cardinality verified.

### Phase 3 — Prometheus exporter
**Deliver:** renderer and optional scrape handler, exposition fixtures, label escaping.  
**Gate:** external parser accepts output; real scrape works; no high-cardinality blowup.

### Phase 4 — Tracing core
**Deliver:** tracer provider, spans, status, events, links, parent context, span kinds.  
**Gate:** parent-child and lifecycle tests; no double export; deterministic timestamps.

### Phase 5 — W3C propagation
**Deliver:** traceparent, tracestate, baggage, explicit context, validated carrier API.  
**Gate:** W3C fixtures and two-request isolation tests pass.

### Phase 6 — Sampling and span processors
**Deliver:** head samplers, simple processor, bounded batch processor, flush/shutdown.  
**Gate:** deterministic sampling, queue overflow, slow exporter and worker lifetime tests.

### Phase 7 — OTLP data mapping and encoding
**Deliver:** pinned protobuf model, compliant serialization, resource/scope mapping, golden fixtures.  
**Gate:** independent protobuf decoder accepts bytes; no integer/ID precision loss.

### Phase 8 — OTLP/HTTP exporters
**Deliver:** traces and metrics exporters, HTTP transport, auth config, retries, deadlines.  
**Gate:** real Collector accepts both signals; partial-success and timeout tests pass.

### Phase 9 — Metrics advanced
**Deliver:** views, reader independence, delta temporality, optional observable instruments and exemplars.  
**Gate:** temporality reset and multiple-reader tests; documented unsupported features.

### Phase 10 — Obsidian correlation bridge
**Deliver:** optional trace/span ID adapter and context binding.  
**Gate:** correlated logs across one trace; disabled/absent Pulse works; no circular imports.

### Phase 11 — Ecosystem adapters
**Deliver:** Aether/Nyx inbound HTTP, Nova outbound HTTP, Feather/Atlas DB, Quartz test helpers.  
**Gate:** one real multi-hop trace and metrics integration test with privacy assertions.

### Phase 12 — Reliability and performance
**Deliver:** load benchmarks, bounded queue proof, memory/race checks, shutdown torture suite, docs.  
**Gate:** no leaks/deadlocks in repeated stress runs; measured budgets documented.

### Phase 13 — Release readiness
**Deliver:** API freeze proposal, migration docs, compatibility matrix, changelog, security review.  
**Gate:** all claimed features pass conformance and cross-platform CI; no P0/P1 defects.

**Milestones:**
- **MVP A:** Phase 0–3 = Prometheus-style metrics.
- **MVP B:** Phase 4–6 = tracing + propagation.
- **OTel beta:** Phase 7–10 = real OTLP traces/metrics + Obsidian correlation.
- **Stable candidate:** Phase 11–13 after interoperability, safety and CI gates.

No phase may be declared complete solely because a source file or test function exists.

---

## 21. Agent execution protocol

Every coding agent MUST follow this order:

1. **Inspect:** read this `AGENTS.md`, current repository tree, pinned compiler docs, relevant ADRs and tests.
2. **State scope:** describe the exact phase/task, affected modules and success criteria.
3. **Verify capability:** compile a minimal NOX spike for any unfamiliar syntax, API or concurrency primitive.
4. **Design types:** write explicit data model and ownership/lifecycle notes before implementation.
5. **Implement smallest vertical slice:** public API → core logic → in-memory test → failure path → exporter integration.
6. **Test immediately:** run targeted tests on each change; then full suites and both backends.
7. **Prove protocol claims:** use independent fixtures and real Collector/Prometheus tests, not only internal round trips.
8. **Check privacy:** inspect every new attribute, header, exporter payload and diagnostic for secret/PII leakage.
9. **Check bounds:** prove queue, cardinality, attribute, batch, retry and shutdown limits.
10. **Report evidence:** exact commands, platform/backend, test counts, failures, skipped tests and commit SHA.
11. **Update docs:** API, standards matrix, compatibility, examples, changelog, ADR when decisions change.
12. **Stop on blocker:** do not silently weaken assertions, remove failing tests, disable safety checks or fake success.

### Mandatory change report template

```text
Feature / phase:
Files changed:
NOX compiler SHA:
Public API changes:
Standards/spec versions:
Tests run (exact commands):
QBE results:
LLVM results:
Collector/Prometheus conformance:
Concurrency/security results:
Known limitations:
Deferred items:
Release impact:
```

### Prohibited agent behaviors

- Inventing NOX standard-library functions or importing Python packages.
- Claiming OTLP support from a custom JSON blob.
- Calling a synchronous generator loop "parallel."
- Marking `peak_concurrency >= 1` as proof of two concurrent requests.
- Releasing atomics or queue storage while a worker can still access them.
- Adding unbounded buffers, unbounded retry loops or user-ID metric labels.
- Capturing auth headers, passwords, raw SQL values or request bodies by default.
- Hard-coding exporter credentials or production endpoints.
- Changing the pinned protocol semantics without updating fixtures and documentation.
- Weakening a failing conformance test to make CI green.
- Requiring Obsidian, Nyx or Aether in the Pulse core package.
- Claiming a released registry package is approved merely because submission succeeded.
- Silently changing published tags or overwriting released artifacts.

---

## 22. Acceptance scenarios

All scenarios below are release-level behavioral specifications.

**A. Metrics:** 10 concurrent workers each record 1,000 counter increments; exported count equals 10,000 exactly, without a race or dropped measurement (subject to explicitly configured overflow policy).

**B. Histogram:** values exactly on bucket boundaries are placed in the correct bucket; `+Inf` count equals total observations; Prometheus and OTLP agree on count/sum.

**C. Cardinality:** recording 100,000 distinct untrusted labels under a configured 1,000-series limit never allocates more than the documented budget and increments overflow diagnostics.

**D. Distributed trace:** incoming Aether request with valid `traceparent` produces a server span; Nova outbound call injects same trace ID and a new child span ID; downstream extractor reconstructs correct parentage.

**E. Obsidian correlation:** a structured log emitted inside Feather SQL span carries the active trace ID and span ID without capturing SQL bind values.

**F. Sampling:** 0% produces no exported recording spans; 100% exports all valid spans; parent-based sampling respects sampled/unsampled parent decisions.

**G. Exporter outage:** Collector unavailable for 60 seconds does not deadlock request handling, cause unbounded memory growth or print secrets; retries stop within configured budget.

**H. Shutdown:** force flush returns a truthful result; after shutdown no worker uses freed memory and no new records are accepted; repeated shutdown is safe.

**I. Protocol:** independently decoded OTLP/HTTP protobuf traces and metrics match pinned fixtures and are accepted by a real OpenTelemetry Collector.

**J. Portability:** the same deterministic metrics/tracing fixtures pass under QBE and LLVM; multi-worker races are tested separately on LLVM.

**K. Privacy:** Authorization, Cookie, passwords, raw bodies, email addresses and SQL parameters do not appear in any default span, metric label, exporter payload or diagnostic.

**L. Disabled mode:** no network calls, worker threads or listeners are started; instrument operations remain safe no-ops.

**M. Baggage:** malformed/oversized baggage is rejected or sanitized, not allowed to poison metrics or leak to unrelated destinations.

**N. Partial success:** OTLP response that rejects some data is surfaced as partial failure; Pulse does not silently count all records as delivered.

**O. Resource fidelity:** service name/version and instrumentation scope survive an OTLP encode/decode round trip without incorrect merging.

---

## 23. Final architectural decisions

1. Pulse is the **single NOX observability instrumentation SDK** for metrics and distributed tracing.
2. Prometheus metrics and OpenTelemetry traces/metrics/exporters are **both first-class**, with distinct reader/exporter semantics.
3. OTLP/HTTP with **real protobuf encoding** is the required interoperable export path; gRPC is optional and must not be falsely claimed.
4. Context propagation begins with **explicit context passing**; implicit task-local conveniences require proven runtime support.
5. Obsidian remains the independent logging library; correlation is an optional bridge.
6. The library MUST work without Nyx, Aether, Obsidian, VAULT or any hosted collector.
7. QBE and LLVM semantic differences are respected; thread safety requires real LLVM multi-worker testing.
8. Privacy and bounded resource usage are **release blockers**, not enhancements.
9. Public API, wire compatibility, CI evidence and versioned standards are maintained as contracts.
10. Nightly experimentation is welcome, but stable support is claimed **only after end-to-end conformance**.

**End of AGENTS.md — Pulse**
