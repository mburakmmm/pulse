# Contributing to Pulse

Pulse is an experimental NOX observability SDK. Contributions are welcome, but
all behavior and support claims must be backed by reproducible evidence.

## Before you start

1. Read [`AGENTS.md`](AGENTS.md); it is the implementation contract.
2. Check [`todo.md`](todo.md) for the active phase and its exit gate.
3. Review [`docs/compatibility.md`](docs/compatibility.md) and
   [`docs/nox-limitations.md`](docs/nox-limitations.md).
4. Discuss large API, protocol, concurrency or dependency changes in an issue
   before implementation.

Do not modify `noxc` or the NOX standard library as part of a Pulse change.
Compiler workarounds must be documented, narrowly scoped and reproducible.

## Development setup

Use the official NOX `2.1.64` release pinned to source commit
`be3458c332c8234baa8f3f8ac2ae9601db24321e`. Keep it isolated if your system
uses another NOX version.

```sh
git clone https://github.com/mburakmmm/pulse.git
cd pulse
noxc version --build-info
bash scripts/run-ci-core.sh
```

The output must identify `noxc 2.1.64` and the pinned commit. The core script
runs both QBE and LLVM paths, source/module checks, unit/property/security/golden
tests, stress tests, examples and the downstream package-import probe.

For capability-sensitive changes, also run:

```sh
bash scripts/run-runtime-capability-audit.sh llvm
bash scripts/run-runtime-capability-audit.sh qbe
bash scripts/run-type-capability-audit.sh
bash scripts/run-http-capability-audit.sh llvm
bash scripts/run-http-capability-audit.sh qbe
bash scripts/run-backend-transfer-audit.sh
```

## Change requirements

- Keep the public API typed and explicit.
- Preserve integer fidelity and deterministic snapshots.
- Enforce resource and cardinality limits before allocation.
- Sanitize sensitive values before queueing or snapshotting.
- Add success, failure, boundary and regression tests for every behavior change.
- Test both backends unless the capability is explicitly backend-specific.
- Never label custom JSON, mock transport or an unverified endpoint as OTLP.
- Do not claim thread safety before the required LLVM multi-worker test passes.
- Update documentation, `CHANGELOG.md` and `todo.md` when their facts change.

Use conventional, focused commit messages such as `metrics: bound reader
snapshots` or `ci: add Windows x64 verification`.

## Pull requests

A pull request should explain the behavior being changed, the limits and privacy
impact, exact commands run and any intentionally unsupported platform. Keep
unrelated refactors separate. CI must remain green without weakening a test or
turning an unexecuted gate into a pass.

By participating, you agree to follow [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
