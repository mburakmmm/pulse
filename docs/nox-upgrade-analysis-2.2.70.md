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

The prior [2.2.38 audit](nox-upgrade-analysis-2.2.38.md) remains historical
evidence. Runtime design constraints and pending Collector tests stay in the
[limitation register](nox-limitations.md).
