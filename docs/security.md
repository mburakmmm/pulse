# Security and privacy baseline

Phase 4 adds local trace snapshots to bounded metrics and Prometheus rendering.
Applications own their listeners. OTLP export remains open.

## Default-deny data policy

Pulse must not capture request/response bodies, Authorization or Cookie headers, API keys, passwords, DSNs, SQL bind values, result rows, raw query strings, user IDs, email addresses, IP addresses, health data or stack arguments by default.

Automatic instrumentation uses allowlists. Redaction, dropping, hashing, masking or truncation occurs before data enters a queue. Hashing personal data is not described as anonymization.

Tracing filters Resource and scope attributes, including metadata supplied
through a direct `Resource` constructor. `record_exception` stores a
predefined type and accepts no raw error message, arguments or stack trace.
Applications supply their own safe values for general-purpose attributes.

## Trust boundaries

- Incoming `traceparent`, `tracestate` and baggage are untrusted and bounded.
- Export endpoints and redirects are SSRF-relevant configuration.
- OTLP headers and endpoint credentials never appear in diagnostics.
- TLS certificate verification is enabled by default; no silent insecure fallback.
- Applications own the Prometheus listener and access control. Configure
  `nox.http.configure(bind_address="127.0.0.1")` before serving local-only metrics.
  Require an explicit bind address and deployment access controls for remote scrapers.
- Prometheus Resource promotion is disabled in `render_metrics()`. The explicit
  `render_metrics_with_resource()` path emits only configured allowlist keys,
  rejects sensitive keys and bounds the allowlist to 32 labels.
- The scrape adapter rejects non-GET methods and request bodies, disables caching,
  bounds configured paths/request targets, emits `nosniff` and returns generic
  renderer failures without internal details.
- Native code has operating-system authority; no NNI is approved without an ADR.

## Required malicious-input coverage

- Malformed and oversized trace headers and baggage.
- High-cardinality labels before allocation.
- Poisoned resource attributes and invalid UTF-8.
- Redirects, bad TLS, timeouts, retry storms and partial OTLP success.
- Concurrent flush/shutdown and slow exporters.
- Synthetic credential sentinels across spans, metrics, payloads and diagnostics.

## Reporting rule

Never put real credentials, production payloads or customer telemetry in tests, issues, logs or screenshots. Use obvious synthetic sentinels and verify that they do not cross the intended boundary.

