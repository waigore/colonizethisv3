# ctdev logging

**SPEC/program** — **Ctdev-only** log **sinks**: file layout, session id, pre-sim buffer, and Sim Log UI. **What** to log and **info vs debug** semantics are defined in **[SPEC/program/logging/logging.md](logging/logging.md)** and its annexes ([map-generation](logging/map-generation.md), [turn-resolution](logging/turn-resolution.md), [ai-actions](logging/ai-actions.md), [events](logging/events.md)).

---

## Session and file

- **Log directory:** `logs/` under the **project root** (colonizethisv3). Project root is the repo root when running from `ctdev/` or from the repo root. Created if missing.
- **File naming:** Implemented with `basic_logger_file`. One file per calendar day: `logs/YYYY-MM-DD.log`. Multiple sim sessions on the same day append to the same file.
- **Session ID:** Generated when the user presses **Start Game (Sim)** (e.g. short UUID or timestamp-based id). Displayed on the Running Game screen for reference. **Log:** on the same screen shows the path to the current day's log file.
- **Pre-sim logs:** From app start until **Start Game (Sim)**, log events are buffered in memory. When the user starts a sim session, the buffer is replayed into the file logger, then all subsequent log events go to the same day file.
- **File I/O:** Handled by `basic_logger_file` (buffered; no manual flush in ctdev code).

---

## Logger package and ctdev outputs

- **Dart `logger` package:** Used for all logging. Ctdev configures a single global log listener; packages do not configure outputs (see [colonizethis-logger.md](colonizethis-logger.md)).
- **Levels (ctdev sinks):**
  - **File:** Logs at **debug** and above (default).
  - **In-memory Sim Log (UI):** Logs at **info** and above; shows the **last 10 lines** only; **cleared at the start of every turn** (when resolving a turn or stepping a full turn).
- **Semantic levels** (what belongs in info vs debug): [logging.md](logging/logging.md).
- **Exception capture:** Log calls use `error` and `stackTrace` where applicable. Uncaught errors are handled in `runZonedGuarded` and logged with stack trace. The file format appends error and stack trace when present (e.g. on following lines).
- **CLI tools:** Init-game, map generation, and sim tools use the same logger configuration for **operational and diagnostic** output. They may still write **usage, help text, and human-readable reports** to `stdout`/`print` as part of their CLI contract; these are exempt from the “no print for logging” rule.

---

## Land combat and turn logging

Structured **land** combat log lines and **Given–When–Then** criteria: [logging/turn-resolution.md](logging/turn-resolution.md) § Land combat.

---

## Acceptance criteria (ctdev sinks)

- **Log directory:** `logs/` under project root (repo root when run from ctdev or root); created if missing.
- **Log file:** One per calendar day: `logs/YYYY-MM-DD.log`; multiple sim sessions on the same day append.
- **Session ID:** Generated at Start Game (Sim); displayed on Running Game screen; **Log:** shows path to the current day file.
- **Pre-sim:** Events before Start Game buffered in memory; on Start Game replayed to the day file, then all subsequent events go to file.
- **Levels:** File at debug and above; in-memory Sim Log at info and above, last 10 lines, cleared at start of every turn (resolve/step).
- **Exceptions:** Uncaught errors in `runZonedGuarded` logged with stack; log calls use `error` and `stackTrace` where applicable.

See [ctdev-app.md](ctdev-app.md) for UI behaviour (session ID display, Sim Log panel).
