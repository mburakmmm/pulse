# Security policy

## Supported versions

Pulse has not published a stable release. Security fixes are currently made on
the `main` branch only. Do not deploy the project as a production telemetry SDK
until the relevant phase and release gates are complete.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability, secret exposure or
privacy failure. Use GitHub's
[private vulnerability reporting](https://github.com/mburakmmm/pulse/security/advisories/new)
for this repository.

Include, where safe:

- the affected commit and NOX backend/platform;
- a minimal reproducer using synthetic data;
- expected and observed behavior;
- resource-exhaustion, confidentiality or integrity impact;
- whether credentials, personal data or customer telemetry may be involved.

Never attach real credentials, authorization headers, production payloads,
health information, user identifiers or customer telemetry. The maintainer will
acknowledge the report, assess severity and coordinate a fix and disclosure.
Timelines depend on impact and reproducibility; no fixed response SLA is claimed
for this pre-release project.

## Security design

Pulse treats inbound context, baggage and attributes as untrusted. Its contract
requires finite limits, TLS verification by default, secure IDs, bounded retries
and privacy filtering before records enter an export queue. The detailed threat
model and default-deny data classes are in [`docs/security.md`](docs/security.md).
