# NOX 2.1.52 → 2.1.64 upgrade analysis

Date: 2026-11-12  
Decision: pin Pulse CI to `2.1.64`; do not modify the user's system compiler  
Release commit: `be3458c332c8234baa8f3f8ac2ae9601db24321e`

## Verification method

The official macOS ARM64 release archive was downloaded into an isolated temporary
directory. Its published SHA-256 (`d20b38293161ab7d776320d3eed4dd78ee4f4b54729e31c29b78cebf4633ea29`)
was verified before extraction. The contained compiler reported the release commit
through `noxc version --build-info`; its binary SHA-256 was
`067b6dbfd4a42f692690dbaa2bf390486b33a491614460e61b6b2191307737d7`.

The system-installed `noxc 2.1.52` was not replaced or modified.

## Pulse-relevant changes

### JSON (`2.1.61`)

Parsing and dumping moved to faster Zig-backed paths. The parser explicitly rejects
duplicate object keys and enforces depth ≤ 32 while preserving the prior accepted
grammar. Pulse treats configuration input as untrusted and bounded, so duplicate-key
rejection is desirable. Exact int64 gates (`as_int`, `number_text`) still pass.

### Zero-copy FFI (`2.1.62`)

`lowlevel ptr_of(list)` exposes a list data pointer for native calls. Pulse does not
adopt it in the initial implementation: it crosses the full native trust boundary,
its lifetime ends when a list grows or is released, and current public protobuf and
HTTP paths already pass without private ABI or NNI. It may be reconsidered only with
a measured exporter bottleneck and a dedicated ADR/security review.

### Gzip (`2.1.63`)

Hosted macOS/Linux builds use vendored libdeflate and retain standard gzip output;
other targets keep the Zig implementation. This improves the future OTLP compression
path but does not by itself satisfy Collector interoperability, payload-bound or
shutdown tests. Compression remains optional until Phase 8 conformance.

### Base64 and general performance (`2.1.56`–`2.1.63`)

Base64, string, allocation, JSON, regex and CSV paths received performance work.
These changes do not alter the current Pulse public model. Freestanding fixes are
valuable upstream but Pulse's initial network exporters require the hosted profile.

### Release CI (`2.1.64`)

This release fixes invalid workflow YAML introduced in `2.1.63`. Pulse pins the
fixed release rather than the immediately preceding one.

## Regression results

On the isolated `2.1.64` compiler:

- LLVM smoke: 10/10 passed; check/build/run passed.
- QBE smoke: 10/10 passed; check/build/run passed.
- Phase 1 LLVM: 12 modules, 3 unit files, security and seeded property suites passed.
- Phase 1 QBE: the same set passed.
- Runtime NaN/NUL/JSON parity passed on both backends.
- Binary HTTP, headers, redirect, status, gzip, timeout, TLS rejection and method/body validation passed on both backends.
- LLVM wider transfer behavior and QBE restricted-transfer diagnostics passed.
- Historical formatter/parser capability fixes still pass.
- `NOX-FMT-004` remains reproducible: formatting a pass-only class removes its body.

## Decision and constraints

- CI and compatibility documents pin `2.1.64` plus exact commit.
- The developer machine's system `noxc` remains untouched.
- Pulse continues to use only public NOX APIs; `ptr_of`/NNI is not approved.
- JSON depth/duplicate behavior is recorded as a bounded input contract.
- Gzip performance is not advertised as exporter correctness.
