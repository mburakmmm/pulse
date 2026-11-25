# NOX 2.2.70 upgrade audit

Pulse pins the [published 2.2.70 release](https://github.com/mburakmmm/nox-lang/releases/tag/v2.2.70)
at source commit `4dc061f8c8443f8575092c2652d1109b6f4697e9`. The installed
macOS ARM64 compiler reports that commit. CI uses the official release
archives and validates their checksums and compiler build identity.

The [upstream framework audit](https://github.com/mburakmmm/nox-lang/blob/4dc061f8c8443f8575092c2652d1109b6f4697e9/project/framework-limitasyon-dogrulama-2026-11-24.md)
attributes the three confirmed Pulse fixes to 2.2.63. Re-run them with
`bash scripts/run-nox-framework-regressions.sh qbe` and
`bash scripts/run-nox-framework-regressions.sh llvm`. The portable CI
suite runs the same checks on each core platform.

The intermediate 2.2.43 and 2.2.45 releases corrected list alias growth and
module-global name collisions. In 2.2.61, payload-free enums changed to a
scalar representation. Pulse's public serializers use explicit enum
mappings. The removal of HPy in 2.2.69 requires no Pulse migration because
the package has no HPy imports. See the
[pinned NOX changelog](https://github.com/mburakmmm/nox-lang/blob/4dc061f8c8443f8575092c2652d1109b6f4697e9/CHANGELOG.md).

| Record | Local 2.2.70 result |
|---|---|
| `NOX-TYPE-003` | Match arm fixture builds and prints `3` on both backends |
| `NOX-CODEGEN-003` | Field context manager fixture builds and prints `42` on both backends |
| `NOX-ASYNC-001` | Cancelled channel receive wakes and prints `cancelled` on both backends |
| `NOX-TYPE-002` | Top-level raising guard still yields `OptionalNotNarrowed` |
| `NOX-HTTP-005` | The connection-limited listener returns `serve-returned` on both backends |

The tracing tests cover cleanup in `finally` and one-shot snapshot transfer
after cancellation of either a task await or a channel receive. The HTTP
fixture keeps its detached snapshot. A positional connection limit still
counts acceptance, and the documented graceful drain path is separate.
See the pinned [HTTP lifecycle contract](https://github.com/mburakmmm/nox-lang/blob/4dc061f8c8443f8575092c2652d1109b6f4697e9/docs/stdlib/http.md)
and [Optional guard scoping](https://github.com/mburakmmm/nox-lang/blob/4dc061f8c8443f8575092c2652d1109b6f4697e9/docs/language/types.md).

The full local `NOXC="$(command -v noxc)" bash scripts/run-ci-core.sh`
suite passed on macOS ARM64 under both backends. The tracing cancellation
test also passed 20 repeated runs per backend with `NOX_POOL_WORKERS=4`.

[CI run #22](https://github.com/mburakmmm/pulse/actions/runs/45588887236)
targets all four platforms at Pulse commit
`4921d3f619a191b57a515e236e13747df82de426`. Windows x64 core and the Linux
ARM64 capability job passed. The run link tracks the remaining matrix jobs.

The prior [2.2.38 audit](nox-upgrade-analysis-2.2.38.md) remains historical
evidence. Runtime design constraints and pending Collector tests stay in the
[limitation register](nox-limitations.md).
