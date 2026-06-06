# colonizethis-logger

**SPEC/program** — Prefixed logger utility for consistent log categorization in the debug log viewer. **Policy** (levels, prefixes, domain rules): [logging/logging.md](logging/logging.md).

---

## 1. Purpose

Provide a utility logger (`ct_logger`) that auto-prefixes all log messages with a known category prefix (e.g. `map:`, `logic:`, `ai:`). This ensures:

- All logs are properly categorized for filtering in the debug log viewer
- No developer forgets to add a prefix manually
- Consistent prefix format across the codebase

---

## 2. Design

### 2.1 Logger prefix constants

Package-scoped constants define valid prefixes matching `knownPrefixes` in `session_log_buffer.dart`:

```dart
const String kLogPrefixLogic = 'logic';
const String kLogPrefixAi = 'ai';
const String kLogPrefixData = 'data';
const String kLogPrefixMap = 'map';
const String kLogPrefixSave = 'save';
const String kLogPrefixGame = 'game';
```

### 2.2 CtLogger class

```dart
class CtLogger {
  final Logger _log;
  final String prefix;

  CtLogger(this.prefix)
      : _log = Logger(printer: CtLoggerConsolePrinter());

  void d(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.d('$prefix: $msg', error: error, stackTrace: stackTrace);
  // … other level helpers mirror `_log`, always prefixing `$prefix: ` on the message string.
}
```

- Uses `Logger(printer: CtLoggerConsolePrinter())` so **stdout / IDE console** lines carry the canonical operator timestamp (§2.4).
- Prepends `$prefix: ` to every message body
- Delegates filtering, printing, and output to the `logger` package via `_log`

### 2.3 Operator log timestamps (`formatOperatorLogTimestamp`)

- **Purpose:** Single source of truth for the **human-readable timestamp** on listener-formatted operator log lines across **session buffer**, **ctdev day file**, and **Sim Log UI**.
- **API:** [`formatOperatorLogTimestamp`](../../packages/colonizethis_logger/lib/src/operator_log_timestamp.dart) in package `colonizethis_logger` (exported from `colonizethis_logger.dart`).
- **Shape:** Local wall clock as `YYYY-MM-DDTHH:mm:ss.SSS±HH:MM`, or `...SSSZ` when the effective local offset is UTC. Milliseconds are **always** three digits (including `.000` on whole-second instants).

### 2.4 CtLogger console printer (`CtLoggerConsolePrinter`)

- **Purpose:** The `logger` package’s default `PrettyPrinter` does **not** emit the canonical operator timestamp on stdout / IDE console. `CtLogger` therefore wires `Logger(printer: CtLoggerConsolePrinter())`.
- **Behavior:** `CtLoggerConsolePrinter` delegates formatting to `PrettyPrinter` (same defaults as a bare `Logger()`), then injects **exactly one** `formatOperatorLogTimestamp(event.time)` segment on the **first message row** of each boxed event (after the leading `│ ` rule column). If boxing is disabled for a level such that no message row can be matched, the printer falls back to prefixing the first output line with the canonical timestamp so the event still carries one operator-facing segment.
- **Implementation:** `packages/colonizethis_logger/lib/src/ct_logger_console_printer.dart`.

### 2.5 Global instance factories (optional convenience)

For packages that use a single logger:

```dart
CtLogger logicLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('$kLogPrefixLogic.$subPrefix') : CtLogger(kLogPrefixLogic);

CtLogger aiLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('$kLogPrefixAi.$subPrefix') : CtLogger(kLogPrefixAi);

// etc.
```

### 2.6 Level-guard helpers (`debugEnabled` / `infoEnabled`)

- **Purpose:** Let hot-path callers skip building a `d(...)` / `i(...)` message argument when that level is currently filtered out by the active `Logger.level` threshold. The `logger` package evaluates the message string **before** applying the level filter, so a `_log.d('… ${list.map(...).toList()}')` call on a tight per-turn path pays the full interpolation/allocation cost even when debug output is suppressed. Guarding such calls aligns with the turn-resolution budget rule's "Control logging overhead" clause.
- **API:** `CtLogger` exposes two read-only getters that mirror the `logger` level threshold:

```dart
bool get debugEnabled => Logger.level.value <= Level.debug.value;
bool get infoEnabled => Logger.level.value <= Level.info.value;
```

- **Semantics:** `debugEnabled` is `true` iff a `Level.debug` event would currently pass the global `Logger.level` threshold; `infoEnabled` likewise for `Level.info`. The getters are **additive and side-effect free**; they do not change emission for unguarded calls. When a level is enabled the guarded call emits identically to the unguarded form, so existing log-capture tests at the default level are unaffected.
- **Usage:** Guard only calls whose message argument performs non-trivial work (collection mapping, list/map stringification) on per-turn or per-candidate paths; do not guard plain warn/error or one-off startup lines.

---

## 3. Package structure

```
packages/colonizethis_logger/
  lib/
    colonizethis_logger.dart      # exports
    src/
      ct_logger.dart                 # CtLogger class
      ct_logger_console_printer.dart # stdout PrettyPrinter + canonical timestamp
      prefixes.dart                  # prefix constants
      operator_log_timestamp.dart    # formatOperatorLogTimestamp
  pubspec.yaml
  test/
    ct_logger_test.dart
    operator_log_timestamp_test.dart
```

---

## 4. Adoption

### 4.1 Migration

Replace raw `Logger()` usage with `CtLogger(prefix)`:

| Before | After |
|--------|-------|
| `final _log = Logger();` | `final _log = CtLogger(kLogPrefixMap);` |
| `_log.i('Loading tileset');` | `_log.i('Loading tileset');` → outputs `map: Loading tileset` |

### 4.2 Packages to migrate (in order)

1. **colonizethis_logic** — prefix `logic`
2. **colonizethis_ai** — prefix `ai`
3. **colonizethis_map** — prefix `map`
4. **colonizethis_data** — prefix `data`
5. **colonizethis_save** — prefix `save`
6. **app/lib/features/game/flame/** — prefix `game` (Flame components)
7. **app/lib/features/debug_log/** — prefix `app`

**Ctdev** (`ctdev_log.dart`): **Must** format operator-facing log lines (file + Sim Log UI) using `formatOperatorLogTimestamp` (`colonizethis_logger`) — same timestamps as `SessionLogEntry.formattedLine` / session buffer convention. Ctdev MAY still use `CtLogger` where convenient; adopting `CtLogger` is orthogonal to timestamps. **Day file:** Use an `OutputLogger` with the same append/buffer contract as `basic_logger_file` 0.1.3 (see [ctdev-logging.md](ctdev-logging.md)); **message-only** disk lines so the canonical timestamp is not duplicated by a library prepend.

The Flutter app debug viewer consumes `session_log_buffer` (not ctdev’s sinks); timestamps still follow this API for consistency ([debug-log-viewer.md](debug-log-viewer.md)).

### 4.3 SessionLogBuffer knownPrefixes update

Add `game` to `knownPrefixes` in `session_log_buffer.dart`:

```dart
const List<String> knownPrefixes = [
  'ctdev',
  'logic',
  'ai',
  'data',
  'map',
  'save',
  'game',  // <-- Flame/UI components
];
```

---

## 5. Acceptance criteria

- **Prefix consistency:** All `CtLogger` instances auto-prefix messages with `prefix: ` format.
- **Debug viewer integration:** Logs from migrated packages appear in the debug viewer under the correct prefix filter.
- **No manual prefixing needed:** Developers call `_log.i('message')` not `_log.i('prefix: message')`.
- **Backward compatible:** Raw `Logger()` still works; `CtLogger` is additive.
- **Console timestamps:** Every `CtLogger` event printed through the `logger` package’s configured printer includes **exactly one** canonical `formatOperatorLogTimestamp` segment (local wall clock, fixed `.SSS`, explicit offset or `Z`), including whole-second instants (`.000`).
- **Level-guard helpers (§2.6):**
  - Given `Logger.level` is set to `Level.warning`, when a caller reads `CtLogger.debugEnabled` and `CtLogger.infoEnabled`, then both getters return `false`.
  - Given `Logger.level` is set to `Level.info`, when a caller reads the getters, then `infoEnabled` returns `true` and `debugEnabled` returns `false`.
  - Given `Logger.level` is set to `Level.debug` (or lower), when a caller reads `CtLogger.debugEnabled`, then it returns `true`.

---

## 6. References

- Debug log viewer: [SPEC/program/debug-log-viewer.md](debug-log-viewer.md)
- Session log buffer: `packages/session_log_buffer/lib/session_log_buffer.dart`
- Existing prefixes: `ctdev`, `logic`, `ai`, `data`, `map`, `save`, `game`, `app` (per `session_log_buffer.dart`)
