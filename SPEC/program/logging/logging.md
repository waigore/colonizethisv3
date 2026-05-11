# Logging (policy)

**SPEC/program/logging** — Host-agnostic rules for **what** to log and **at which level**. Applies to **packages** (`colonizethis_logic`, `colonizethis_ai`, `colonizethis_map`, `colonizethis_data`, `colonizethis_save`, `colonizethis_models` where relevant), **app**, and **ctdev**. **Where** logs are written (file, UI buffer, session viewer) is defined per host; see [ctdev-logging.md](../ctdev-logging.md) for ctdev sinks and [debug-log-viewer.md](../debug-log-viewer.md) for in-app viewing.

---

## Source of truth

| Topic | Document |
|--------|-----------|
| Map generation | [map-generation.md](map-generation.md) |
| Turn resolution (phases, per-player work, land combat tokens) | [turn-resolution.md](turn-resolution.md) |
| AI decisions and candidate evaluation | [ai-actions.md](ai-actions.md) |
| Game and package events | [events.md](events.md) |
| Ctdev file / Sim Log / pre-sim buffer | [ctdev-logging.md](../ctdev-logging.md) |
| Test runs (suppress logger) | [test-logging.md](../test-logging.md) |
| Prefix helper (`CtLogger`, factories) | [colonizethis-logger.md](../colonizethis-logger.md) |
| Flutter timeline + startup log tokens (new-game → game screen) | [flutter-performance-tracing.md](../flutter-performance-tracing.md) |

---

## Levels (mandatory split)

- **Info:** **Outcomes and events** — phase boundaries, summaries, final decisions, emitted domain events (with payload summary), map run completion lines, save/load success, rejections at the order/API boundary when they represent a **result** for operators.
- **Debug:** **Intermediate process** — per-step internals, candidate lists and scores, per-pass map metrics, validation branches before a final accept/reject, engagement-level combat detail where the annex specifies debug.

**Warn / error:** Use **warn** for recoverable anomalies; **error** for failures, always with `error` and `stackTrace` when an exception exists. Do not use `print` for operational or diagnostic output except documented CLI contracts (see [ctdev-logging.md](../ctdev-logging.md)).

---

## Prefixes and package ownership

Each package is the owner of its own logging prefix and must define exactly one
package-local constant file at `lib/package_log_prefix.dart` containing
`kPackageLogPrefix`.

Each package must expose exactly one package-local logging API at
`lib/package_logger.dart` with signature `CtLogger packageLogger([String? subPrefix])`.
Package code must use this API for all logger acquisition. Direct/naked
`Logger(...)` construction in package code is forbidden.

Message text must **not** repeat the top-level prefix (avoid `logic: logic: …`).

| Prefix | Typical ownership |
|--------|-------------------|
| `logic` | Turn resolution, orders, combat, economy phases, diplomacy resolver, setup orchestration |
| `ai` | Strategic AI, planners, perception, dossier |
| `map` | Tile generation, topology, map views |
| `data` | Catalog/config load, fallbacks |
| `save` | Persistence adapter |
| `app` | Flutter shell, setup flows not in packages |
| `game` | Flame / in-game components |
| `ctdev` | Ctdev app lifecycle, sim controller |
| package-defined | Any other first-party package not listed above must define its own package prefix in `lib/package_log_prefix.dart` |

Sub-areas may use dot sub-prefixes via package-local `packageLogger` factories
(e.g. `packageLogger('combat')` -> `logic.combat` in logger naming; message body
still uses stable tokens such as `combat battle_start` for grep). Align session
log filter lists with [session_log_buffer](../../../packages/session_log_buffer/lib/session_log_buffer.dart) `knownPrefixes`.

---

## Message shape

- Prefer **`key=value`** segments separated by spaces on one line.
- Include **turn**, **playerId** / **nationId**, **regionId** / **provinceId** when the operation is scoped (province ids **prefixed** per [world-model.md](../../game/world-model.md)).
- For long structures, **truncate** or **summarize** per [events.md](events.md) and [ai-actions.md](ai-actions.md); do not log unbounded lists at info.

---

## Hosts (summary)

All hosts consume the **same** `Logger` stream from packages; hosts only differ in **outputs**:

- **ctdev:** Day file + Sim Log (info+, capped); see [ctdev-logging.md](../ctdev-logging.md).
- **app:** Session buffer for debug viewer; configure listeners at startup per [debug-log-viewer.md](../debug-log-viewer.md).
- **stdout / IDE console:** `CtLogger`-backed `Logger` output (boxed `flutter:` lines from Flutter, or plain stdout from Dart CLI hosts) uses `CtLoggerConsolePrinter` per [colonizethis-logger.md](../colonizethis-logger.md) §2.4 so each emitted event carries one canonical operator timestamp.

Operator-facing **timestamp formatting** on listener-driven lines and on the `CtLogger` console printer (`formatOperatorLogTimestamp`) is normative in [colonizethis-logger.md](../colonizethis-logger.md).

---

## Acceptance criteria

- **Given** code in packages, app, or ctdev that implements a feature described in an annex, **when** that feature runs in a dev configuration with file/debug logging enabled, **then** emitted lines follow the **info vs debug** split and **prefix** rules in this document and the relevant annex.
- **Given** a new PR that touches logging behavior, **when** reviewers use [CONTRIBUTING.md](../../../CONTRIBUTING.md) checklist, **then** they confirm alignment with **SPEC/program/logging/** and linked sink specs.
- **Given** any first-party package in this repository, **when** package logging setup is reviewed, **then** the package contains `lib/package_log_prefix.dart` defining `kPackageLogPrefix` and `lib/package_logger.dart` defining `packageLogger`.
- **Given** CI quality checks run for a pull request, **when** any package code uses naked `Logger(...)` instead of the package API, **then** CI fails with a blocking convention error.

---

## References

- Core principles: project rules (`colonizethis-core-principles.mdc`) — `logger` package, prefixes, no cross-panel `Navigator` for log UX.
- Land combat **Given–When–Then** lines: [turn-resolution.md](turn-resolution.md) § Land combat.
