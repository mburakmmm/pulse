# Security and privacy baseline

Status: Phase 0 threat-model seed. Telemetry collection and exporters are not implemented.

## Default-deny data policy

Pulse must not capture request/response bodies, Authorization or Cookie headers, API keys, passwords, DSNs, SQL bind values, result rows, raw query strings, user IDs, email addresses, IP addresses, health data or stack arguments by default.

Automatic instrumentation uses allowlists. Redaction, dropping, hashing, masking or truncation occurs before data enters a queue. Hashing personal data is not described as anonymization.

## Trust boundaries

- Incoming `traceparent`, `tracestate` and baggage are untrusted and bounded.
- Export endpoints and redirects are SSRF-relevant configuration.
- OTLP headers and endpoint credentials never appear in diagnostics.
- TLS certificate verification is enabled by default; no silent insecure fallback.
- Prometheus listeners default to loopback or require an explicit bind decision.
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

