# ADR-0001: Repository-root modules and explicit context

- Status: Accepted for Phase 0
- Date: 2026-11-07

## Context

The proposed `AGENTS.md` tree includes `pulse/__init__.nox`, but it explicitly requires checking the real NOX module loader. NOX 2.1.0 resolves a dependency alias to modules at the dependency repository root. A local probe confirmed that `import pulse` does not resolve `pulse/__init__.nox`, while a root `pulse.nox` does. Existing NOX ecosystem packages likewise expose root modules such as `app.nox` as `nyx.app`.

The compiler documentation also states that module-level mutable state may be copied per worker. A process-global current span would therefore be both concurrency-unsafe and semantically unreliable.

## Decision

1. Pulse source modules live at repository-root-relative paths such as `api/metrics.nox`, `core/attributes.nox` and `integrations/obsidian.nox`.
2. Consumers import them through their dependency alias, normally `pulse.api.metrics`.
3. No Python-style `__init__.nox` facade is created.
4. Explicit immutable `TelemetryContext` is the foundational propagation API.
5. No module-global current span is allowed.
6. Task-local convenience remains gated on executable QBE/LLVM lifecycle and isolation evidence.

## Consequences

- Physical layout differs from the illustrative tree in `AGENTS.md` but follows its instruction to use actual NOX conventions.
- Root-project tests may use local paths while downstream consumer probes verify dependency-alias paths.
- All documentation must name real import paths.
- Framework integrations stay in optional leaf modules and cannot affect core package resolution.

