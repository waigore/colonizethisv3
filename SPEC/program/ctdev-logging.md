# ctdev logging

**SPEC/program** — File-based and in-memory logging for the ctdev dev app. End-to-end coverage: init game, map generation, load/save, and sim (orders, resolve, phases). All code in the listed areas must log key operations (start/end of flows, rejections, errors) as described below.

---

## Session and file

- **Log directory:** `logs/` under the **project root** (colonizethisv3). Project root is the repo root when running from `ctdev/` or from the repo root. Created if missing.
- **File naming:** Implemented with `basic_logger_file`. One file per calendar day: `logs/YYYY-MM-DD.log`. Multiple sim sessions on the same day append to the same file.
- **Session ID:** Generated when the user presses **Start Game (Sim)** (e.g. short UUID or timestamp-based id). Displayed on the Running Game screen for reference. **Log:** on the same screen shows the path to the current day's log file.
- **Pre-sim logs:** From app start until **Start Game (Sim)**, log events are buffered in memory. When the user starts a sim session, the buffer is replayed into the file logger, then all subsequent log events go to the same day file.
- **File I/O:** Handled by `basic_logger_file` (buffered; no manual flush in ctdev code).

---

## Logger package and configuration

- **Dart `logger` package:** Used for all logging. Ctdev configures a single global log listener; packages use `Logger()` and do not configure outputs.
- **Levels:** Standard levels: debug, info, warn, error.
  - **File:** Logs at **debug** and above (default).
  - **In-memory Sim Log (UI):** Logs at **info** and above; shows the **last 10 lines** only; **cleared at the start of every turn** (when resolving a turn or stepping a full turn).
  - **AI:** **Info** for major decisions (e.g. selected goal, chosen order type, economy plan summary); **debug** for full evals (candidate lists, scores, weights, snapshot, dossier).
- **Exception capture:** All log calls use `error` and `stackTrace` parameters where applicable. Uncaught errors are handled in `runZonedGuarded` and logged with stack trace. The file format appends error and stack trace when present (e.g. on following lines).
  - **CLI tools:** Init-game, map generation, and sim tools use the same logger configuration for **operational and diagnostic** output (`logic:`, `map:`, etc.). They may still write **usage, help text, and human-readable reports** to `stdout`/`print` as part of their CLI contract; these are exempt from the “no print for logging” rule.

---

## Logger naming

- **Prefix:** By package / subpackage-or-file (class): e.g. `ai/strategic_ai`, `ai/goal_manager`, `ai/domain_planners`, `ai/economy_planner`, `ai/perception`, `ai/dossier`, `logic/order_suggestion`. Enables grep-friendly logs (e.g. `ai/goal_manager: selected primaryGoal=conquer`).
- Packages: **ctdev**, **logic**, **ai**, **data**, **map**, **save**. No models logger.

---

## Scope (everything logged)

- **ctdev:** App lifecycle, init game submit, start sim (session id), turn steps, exceptions in turn handlers.
- **logic:** Turn resolution (phases), order engine (validation, rejections), order suggestion API (all suggestion functions and results), movement, combat, naval, extraction, production, consumption, research, diplomacy, init game orchestration, game setup.
- **ai:** Order generation, planner, goals/candidates. Info = major decisions; debug = full evals (goal weights, candidate scores, perception snapshot, dossier, economy recipe scores).
- **data:** Catalog/config lookups; fallbacks and defaults.
- **map:** Map generation (tile map, topology), init game map view build, load savegame view build.
- **save:** Save/load calls (path, gameId, success); errors on failure.

See [ctdev-app.md](ctdev-app.md) for UI behaviour (session ID display, Sim Log panel).

---

## Acceptance criteria

- **Log directory:** `logs/` under project root (repo root when run from ctdev or root); created if missing.
- **Log file:** One per calendar day: `logs/YYYY-MM-DD.log`; multiple sim sessions on the same day append.
- **Session ID:** Generated at Start Game (Sim); displayed on Running Game screen; **Log:** shows path to the current day file.
- **Pre-sim:** Events before Start Game buffered in memory; on Start Game replayed to the day file, then all subsequent events go to file.
- **Levels:** File at debug and above; in-memory Sim Log at info and above, last 10 lines, cleared at start of every turn (resolve/step).
- **Exceptions:** Log calls use `error` and `stackTrace` where applicable; uncaught errors in `runZonedGuarded` logged with stack.
- **Scope:** ctdev, logic, ai, data, map, save each log key operations (start/end of flows, rejections, errors) with the specified prefixes; no `print` for operational/diagnostic output in ctdev and in-scope flows (or document exemptions).
