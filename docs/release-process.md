# Release process

Pulse has not published a stable release. A release may be cut only when its
matching section in `todo.md` satisfies every mandatory item and exit gate.

## Checklist

1. Confirm the exact NOX version, source commit and release checksums.
2. Run the complete QBE/LLVM local suite and required interoperability gates.
3. Require green remote CI for every platform claimed by the release.
4. Confirm unsupported and skipped capabilities are documented explicitly.
5. Review public API compatibility, privacy defaults and finite resource limits.
6. Update `CHANGELOG.md`, version fields, examples and compatibility evidence.
7. Confirm a redistribution license is present before publishing artifacts.
8. Create an immutable signed or annotated version tag only after the reviewed
   commit is on `main`.
9. Build release artifacts from that tag; verify checksums and package contents.
10. Never replace an existing tag or artifact. Publish a new patch release for
    corrections.

Exporter-related releases additionally require independent protocol validation:
Prometheus parser/scrape evidence for Prometheus support and real OpenTelemetry
Collector evidence for OTLP support.
