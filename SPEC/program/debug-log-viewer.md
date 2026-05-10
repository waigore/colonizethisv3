# Debug log viewer

**SPEC/program** — In-app viewer for all runtime logs from the current session. Available in the Flutter app. Coexists with existing Sim Log (ctdev); this viewer shows full debug traces from all packages, not just game events.

---

## 1. Purpose and scope

- **Purpose:** Let developers inspect all log output (debug and above) from the current run in one place, with simple filtering by package (prefix) and level.
- **Scope:** Flutter app (macOS + mobile). Session-only; no persistence or export.

---

## 2. Data source and buffer

- **Source:** The single global `Logger` (Dart `logger` package). All packages log via `Logger()`; they do not configure outputs.
- **Session buffer:** The app registers a **session log buffer** at startup. One `Logger.addLogListener` callback appends every `LogEvent` (debug and above) to an in-memory buffer for the lifetime of the process. Format per event: **local wall-clock timestamp** via `formatOperatorLogTimestamp` (`colonizethis_logger`; always `.SSS` milliseconds and explicit numeric offset or `Z` in UTC — see [colonizethis-logger.md](colonizethis-logger.md)), level name, message; when present, error and stackTrace on following lines (same convention as [ctdev-logging.md](ctdev-logging.md) `formatLogEvent`).
- **Capacity:** Buffer is bounded (e.g. last N lines or last M bytes). When full, oldest entries are dropped. Exact cap is implementation-defined; sufficient for a typical dev session.
- **No persistence:** Buffer is cleared on process exit. No file write, no export requirement in this spec.

---

## 3. Filters

- **Package (prefix):** Multiselect. Filter options use the known log prefixes from the session buffer (`knownPrefixes` in `session_log_buffer.dart`): **ctdev**, **logic**, **ai**, **data**, **map**, **save**, **game**, **app** (and dotted sub-tags such as `ctdev.running_game:` when the first segment matches a known prefix). A line is shown if its message or logger name matches any of the selected prefixes (prefix match).
- **App viewer UI (defaults and visibility):** The Flutter app debug log viewer focuses on app debugging: the **ctdev** prefix is **not** shown as a package filter chip (users cannot toggle it from this screen). **Default** selected package filter is **app** only (other visible chips start deselected). **ctdev**-tagged lines remain in the session buffer and are still emitted by loggers; only this viewer’s default selection and chip list change.
- **Level:** Multiselect. Options: **debug**, **info**, **warning**, **error** (names match `Level` from the Dart `logger` package). A line is shown if its level is in the selected set. **Default** selected levels in the app viewer are **info**, **warning**, and **error**; **debug** is off until the user selects it.
- Filtering is applied to the in-memory buffer when rendering; changing filters updates the visible list without altering the buffer.

---

## 4. Entry points

### 4.1 Flutter app

- **macOS:** Application menubar. One top-level or sub-menu item that opens the debug log viewer (e.g. **View → Debug log** or **Developer → Debug log**). Shown only when the app has a menubar (desktop).
- **In-game (pre-map):** When the game is running but the map view is not yet shown (Flame canvas only), a pause menu (e.g. bottom sheet) opened via a menu control offers **Debug log** and **Resume**.
- **In-game (map view):** When the in-game map is shown (region tabs, side menu), the **side menu** (opened via the top-left menu icon) includes a **Debug log** item that opens the viewer. This is the primary way to open the debug log on mobile and in narrow viewports when on the map.
- **Mobile:** In-game access is via the pause menu (pre-map) or the map side menu (map view). When the user does not have a pause menu (e.g. main menu only), the viewer is not required to be reachable from that context; implementation may also expose it from a main-menu or settings entry on mobile if desired.
- **Other platforms (e.g. web):** Optional; at least one way to open the viewer (e.g. from a menu or overflow) so that web dev sessions can use it.

---

## 5. Viewer behaviour

- **Content:** Scrollable list of log lines (newest at bottom or top per platform convention). Each line shows **canonical operator timestamp** (local `.SSS` + offset/`Z`), level, and message; error/stack lines follow their parent log line.
- **Filters:** UI controls for multiselect package and multiselect level; applied live to the visible list.
- **Close:** Obvious way to close the viewer and return to the previous screen (menubar closes window/overlay; pause menu returns to pause).

---

## 6. Coexistence with Sim Log

- The ctdev **Sim Log** (last 10 lines, info+, cleared each turn) is unchanged and remains on the Running Game screen. The debug log viewer is separate: it shows the full session buffer with no turn-based clear and includes debug level. No behavioural change to Sim Log.

---

## 7. Acceptance criteria (Given–When–Then)

- **Given** the Flutter app is running on macOS with a menubar, **when** the user chooses the Debug log menu item, **then** the debug log viewer opens and displays session logs with package and level filters available.
- **Given** the Flutter app is in-game on mobile (pre-map), **when** the user opens the pause menu and selects Debug log, **then** the debug log viewer opens and displays session logs with package and level filters available.
- **Given** the Flutter app is in-game with the map view shown (any viewport), **when** the user opens the side menu (menu icon) and selects Debug log, **then** the debug log viewer opens and displays session logs with package and level filters available.
- **Given** the debug log viewer has just opened in the Flutter app, **when** the package filter row is first rendered, **then** the UI layer shows no package chip whose label is **ctdev**, and exactly one package chip is in the selected state with label **app**.
- **Given** the debug log viewer has just opened in the Flutter app, **when** the level filter row is first rendered, **then** the UI layer shows the **debug**, **info**, **warning**, and **error** chips with **info**, **warning**, and **error** selected and **debug** not selected.
- **Given** the debug log viewer is open with default package and level filters, **when** the user selects the **debug** level chip, **then** the **debug** chip becomes selected and any buffered log line whose level is **debug** and whose prefix matches a currently selected package filter is shown in the list.
- **Given** the debug log viewer is open with every visible package filter (all package chips except the omitted **ctdev** chip) selected and all level filters selected, **when** the user deselects one package (e.g. **logic**), **then** lines whose prefix matches **logic** are hidden; when the user reselects **logic**, **then** those lines are shown again.
- **Given** the debug log viewer is open with all level filters selected, **when** the user deselects **debug**, **then** only info, warning, and error lines are shown.
- **Given** the app process exits, **when** the user starts a new process, **then** the new session’s viewer shows only logs from that process; no previous-session logs are shown.

---

## 8. References

- Logger policy and prefixes: [logging/logging.md](logging/logging.md). Ctdev sinks: [ctdev-logging.md](ctdev-logging.md). Session buffer prefixes: `packages/session_log_buffer/lib/session_log_buffer.dart` `knownPrefixes`.
- Flutter app shell/menus: [ctdev-app.md](ctdev-app.md); [SPEC/ui/main-menu.md](../ui/main-menu.md).
