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

  const CtLogger(this.prefix) : _log = Logger(prefix);

  void d(String msg) => _log.d('$prefix: $msg');
  void i(String msg) => _log.i('$prefix: $msg');
  void w(String msg) => _log.w('$prefix: $msg');
  void e(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.e('$prefix: $msg', error: error, stackTrace: stackTrace);
}
```

- Uses `Logger(loggerName: prefix)` to set the logger name (useful for tooling that reads logger names)
- Prepends `$prefix: ` to every message
- Delegates all other `Logger` methods via `_log`

### 2.3 Operator log timestamps (`formatOperatorLogTimestamp`)

- **Purpose:** Single source of truth for the **human-readable timestamp** on listener-formatted operator log lines across **session buffer**, **ctdev day file**, and **Sim Log UI**.
- **API:** [`formatOperatorLogTimestamp`](../../packages/colonizethis_logger/lib/src/operator_log_timestamp.dart) in package `colonizethis_logger` (exported from `colonizethis_logger.dart`).
- **Shape:** Local wall clock as `YYYY-MM-DDTHH:mm:ss.SSS±HH:MM`, or `...SSSZ` when the effective local offset is UTC. Milliseconds are **always** three digits (including `.000` on whole-second instants).

### 2.4 Global instance factories (optional convenience)

For packages that use a single logger:

```dart
CtLogger logicLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('$kLogPrefixLogic.$subPrefix') : CtLogger(kLogPrefixLogic);

CtLogger aiLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('$kLogPrefixAi.$subPrefix') : CtLogger(kLogPrefixAi);

// etc.
```

---

## 3. Package structure

```
packages/colonizethis_logger/
  lib/
    colonizethis_logger.dart      # exports
    src/
      ct_logger.dart              # CtLogger class
      prefixes.dart               # prefix constants
      operator_log_timestamp.dart # formatOperatorLogTimestamp
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

---

## 6. References

- Debug log viewer: [SPEC/program/debug-log-viewer.md](debug-log-viewer.md)
- Session log buffer: `packages/session_log_buffer/lib/session_log_buffer.dart`
- Existing prefixes: `ctdev`, `logic`, `ai`, `data`, `map`, `save`, `game`, `app` (per `session_log_buffer.dart`)
