# Debug log viewer

**SPEC/program** — In-app viewer for all runtime logs from the current session. Available in the Flutter app and in ctterm. Coexists with existing Sim Log (ctdev); this viewer shows full debug traces from all packages, not just game events.

---

## 1. Purpose and scope

- **Purpose:** Let developers inspect all log output (debug and above) from the current run in one place, with simple filtering by package (prefix) and level.
- **Scope:** Flutter app (macOS + mobile) and ctterm. Session-only; no persistence or export. Same data source contract in both UIs.

---

## 2. Data source and buffer

- **Source:** The single global `Logger` (Dart `logger` package). All packages log via `Logger()`; they do not configure outputs.
- **Session buffer:** Each host (app, ctterm) registers a **session log buffer** at startup. One `Logger.addLogListener` callback appends every `LogEvent` (debug and above) to an in-memory buffer for the lifetime of the process. Format per event: timestamp (UTC ISO8601), level name, message; when present, error and stackTrace on following lines (same convention as [ctdev-logging.md](ctdev-logging.md) `formatLogEvent`).
- **Capacity:** Buffer is bounded (e.g. last N lines or last M bytes). When full, oldest entries are dropped. Exact cap is implementation-defined; sufficient for a typical dev session.
- **No persistence:** Buffer is cleared on process exit. No file write, no export requirement in this spec.

---

## 3. Filters

- **Package (prefix):** Multiselect. Options are the known log prefixes used in the project: **ctdev**, **logic**, **ai**, **data**, **map**, **save**, and for ctterm **tui** (and sub-prefixes such as `tui:menu:`, `tui:nav:`). A line is shown if its message or logger name matches any of the selected prefixes (prefix match). Default: all selected (show all).
- **Level:** Multiselect. Options: **debug**, **info**, **warn**, **error**. A line is shown if its level is in the selected set. Default: all selected (show all).
- Filtering is applied to the in-memory buffer when rendering; changing filters updates the visible list without altering the buffer.

---

## 4. Entry points

### 4.1 Flutter app

- **macOS:** Application menubar. One top-level or sub-menu item that opens the debug log viewer (e.g. **View → Debug log** or **Developer → Debug log**). Shown only when the app has a menubar (desktop).
- **Mobile:** In-game pause menu. One menu item (e.g. **Debug log**) that opens the viewer. When the user does not have a pause menu (e.g. main menu only), the viewer is not required to be reachable from that context; implementation may also expose it from a main-menu or settings entry on mobile if desired.
- **Other platforms (e.g. web):** Optional; at least one way to open the viewer (e.g. from a menu or overflow) so that web dev sessions can use it.

### 4.2 ctterm

- **Main Menu:** One selectable item (e.g. **Debug log**) that navigates to the Debug log viewer screen. Available even when no game is loaded.
- **Pause/Options:** One menu item (e.g. **Debug log**) that navigates to the Debug log viewer screen. When the user leaves the viewer (Back), they return to Pause/Options (or in-game shell if that is the defined back target). See [SPEC/tui/screens/pause-options.md](../tui/screens/pause-options.md); add the new item to the table in §4.
- **Screen ID:** Assign a 6-digit screen ID for the Debug log viewer in ctterm (e.g. 100020); register in `CttermRoute` and the screen-ID extension per [SPEC/tui/ctterm.md](../tui/ctterm.md).

---

## 5. Viewer behaviour

- **Content:** Scrollable list of log lines (newest at bottom or top per platform convention). Each line shows timestamp, level, and message; error/stack lines follow their parent log line.
- **Filters:** UI controls for multiselect package and multiselect level; applied live to the visible list.
- **Close:** Obvious way to close the viewer and return to the previous screen (menubar closes window/overlay; pause menu returns to pause; ctterm Back returns to Pause or Main Menu as appropriate).

---

## 6. Coexistence with Sim Log

- The ctdev **Sim Log** (last 10 lines, info+, cleared each turn) is unchanged and remains on the Running Game screen. The debug log viewer is separate: it shows the full session buffer with no turn-based clear and includes debug level. No behavioural change to Sim Log.

---

## 7. Acceptance criteria (Given–When–Then)

- **Given** the Flutter app is running on macOS with a menubar, **when** the user chooses the Debug log menu item, **then** the debug log viewer opens and displays session logs with package and level filters available.
- **Given** the Flutter app is in-game on mobile, **when** the user opens the pause menu and selects Debug log, **then** the debug log viewer opens and displays session logs with package and level filters available.
- **Given** ctterm is at the Main Menu, **when** the user selects Debug log and confirms, **then** the Debug log viewer screen is shown and displays session logs.
- **Given** ctterm is at the Pause/Options screen, **when** the user selects Debug log and confirms, **then** the Debug log viewer screen is shown; when the user exits the viewer, **then** the app returns to the Pause/Options screen.
- **Given** the debug log viewer is open with all packages and all levels selected, **when** the user deselects one package (e.g. **logic**), **then** lines whose prefix matches **logic** are hidden; when the user reselects **logic**, **then** those lines are shown again.
- **Given** the debug log viewer is open with all levels selected, **when** the user deselects **debug**, **then** only info, warn, and error lines are shown.
- **Given** the app or ctterm process exits, **when** the user starts a new process, **then** the new session’s viewer shows only logs from that process; no previous-session logs are shown.

---

## 8. References

- Logger and prefixes: [ctdev-logging.md](ctdev-logging.md). Ctterm prefixes: [ctterm.md](../tui/ctterm.md) §5 (tui:, tui:menu:, etc.).
- Flutter app shell/menus: [ctdev-app.md](ctdev-app.md); [SPEC/ui/main-menu.md](../ui/main-menu.md).
- Ctterm Pause/Options: [SPEC/tui/screens/pause-options.md](../tui/screens/pause-options.md). Screen IDs: [SPEC/tui/ctterm.md](../tui/ctterm.md).
