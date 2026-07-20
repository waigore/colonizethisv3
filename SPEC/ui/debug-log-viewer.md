# Debug log viewer

**Screen ID:** `SYS10001` — stable; do not reassign.
**SPEC/ui** — Full-screen in-app session log viewer (developer/debug surface). Implementation: `app/lib/features/debug_log/debug_log_viewer_screen.dart`.
**Widgetbook:** `Debug Log Viewer` → `widgetbook_host/lib/catalogs/catalog_debug_log_viewer.dart`.
**TDD (buffer, filters, entry semantics):** [debug-log-viewer.md](../program/debug-log-viewer.md). Do **not** cite this screen in `docs/manual/**`.
---

## Widget contract

`DebugLogViewerScreen` is a `StatefulWidget` with no constructor parameters. It binds `static const screenId = UiScreenIds.debugLogViewer` (`SYS10001`). It reads `SessionLogBuffer.instance` for filtered rows and does not emit `AppEventBus` events.

| Name | Type | Required | Description |
|------|------|----------|-------------|
| _(none)_ | — | — | Screen is route-mounted via `Routes.debugLog` / `RoutePaths.debugLog`. |

---

## Trigger conditions

| Source | Condition | Result |
|--------|-----------|--------|
| Game side menu **Debug log** row | User taps row ([game-side-menu.md](game-side-menu.md)) | Emits `NavigateToRouteEvent(Routes.debugLog)`; `AppEventHandler` `pushNamed`s the screen |
| Desktop menubar | macOS (or other menubar host) **View → Debug log** | Pushes the same route (`app.dart` menubar wiring) |
| Pre-map pause / overflow | Optional pause-menu or overflow entry when map chrome is absent | Opens the same route when the host exposes it |

Close: `CtScreenShell` leading `CtBackButton` → `Navigator.maybePop` (local pop only; no bus event).

---

## Layout / wireframe

```text
+------------------------------------------+
| CtScreenShell                            |
|  CtTopBar: CtBackButton | "Debug log"    |
|  +--------------------------------------+|
|  | filters_region (horizontal scroll)   ||
|  |  "Package" + CtChoiceChip…           ||
|  |  "Level"   + CtChoiceChip…           ||
|  +--------------------------------------+|
|  Divider (1 dp)                          |
|  +--------------------------------------+|
|  | log_list_region (Expanded ListView)  ||
|  |  per entry: tinted first line + …    ||
|  +--------------------------------------+|
+------------------------------------------+
```

- **Chrome:** `CtScreenShell` + `CtTopBar` + `CtBackButton` — no Material `Scaffold` / `AppBar` / `IconButton`.
- **Filters:** package chips omit `ctdev`; level chips are `debug`, `info`, `warning`, `error`. Each toggle is `CtChoiceChip`.
- **Rows:** `SelectableText` monospace body; first line of each entry gets a `0.08`-alpha `BoxDecoration` wash from [program § Visual chrome](../program/debug-log-viewer.md).

---

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Route `Routes.debugLog` | `Routes.generate` | Builds `const DebugLogViewerScreen()` |
| Session buffer | `SessionLogBuffer.init` at app startup | Viewer reads live in-memory entries |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Package `CtChoiceChip` | Always | Local `setState` | Adds/removes prefix from `_selectedPrefixes`; list refilters |
| Level `CtChoiceChip` | Always | Local `setState` | Adds/removes level from `_selectedLevels`; list refilters |
| `CtBackButton` | Always | `Navigator.maybePop` | Pops route; buffer unchanged |
| Selectable log text | Always | — | Selection only; no copy/export requirement |

**Defaults on open:** selected packages = `{app}`; selected levels = `{info, warning, error}` (`debug` off). Filter semantics and capacity: [program § Filters / buffer](../program/debug-log-viewer.md).

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `SYS10001` | Empty buffer | No matching filtered entries | Filter chrome present; `ListView` empty |
| `SYS10001` | Populated | Buffer has entries matching defaults | Tinted first-line rows for visible levels |
| `SYS10001` | Filters changed | User toggles chips | Visible set updates; buffer unchanged |

No variant suffix letters — one layout for all viewports; narrow width uses horizontal scroll on the filter row ([mobile-adaptation.md](mobile-adaptation.md) § SYS10001 320 dp pins).

---

## Components

- `CtScreenShell` / `CtTopBar` / `CtBackButton` — screen chrome.
- `CtChoiceChip` — package and level multiselect toggles.
- `SessionLogBuffer` (`session_log_buffer`) — data source.
- l10n: `debugLog_title`, `debugLog_filter_package`, `debugLog_filter_level`.

---

## Widgetbook

Folder: **Debug Log Viewer** (`catalog_debug_log_viewer.dart`).

| Use case | Proves |
|----------|--------|
| `Default — empty buffer` | Shell + default filters with empty list |
| `Populated — warning rows` | Seeded `app:` warning lines and row tint wash |
| `Mobile viewport` | Same empty shell inside `mobileViewport` (360×640) |

---

## Acceptance criteria

- Given `SPEC/ui/screen-registry.md` lists `SYS10001`, when the registry row is read, then status is `active`, Spec points at `debug-log-viewer.md`, Implementation is `app/lib/features/debug_log/debug_log_viewer_screen.dart`, and Widgetbook is `Debug Log Viewer`.
- Given `DebugLogViewerScreen` source, when inspected, then it declares `static const screenId = UiScreenIds.debugLogViewer`.
- Given Widgetbook catalog parts, when loaded, then folder `Debug Log Viewer` registers use cases `Default — empty buffer`, `Populated — warning rows`, and `Mobile viewport`.
- Given numbered chapters under `docs/manual/`, when scanned, then none cite `SYS10001`.
- Given the viewer opens with an empty session buffer, when filters first render, then no `ctdev` package chip appears, `app` is selected, and `info` / `warning` / `error` are selected while `debug` is not.
- Given buffered `Level.warning` lines tagged `app:`, when the viewer builds with defaults, then those messages appear in the list with the first-line wash from [program § Visual chrome](../program/debug-log-viewer.md).
- Given the viewer is mounted at 320×640 dp (empty or populated), when the tree settles, then `WidgetTester.takeException()` is `null` and the `Debug log` title plus leading `CtBackButton` render ([mobile-adaptation.md](mobile-adaptation.md)).

### Automated verification

- Registry / Widgetbook / manual omission: `test/debug_log_viewer_activation_4099_test.dart`.
- Filter defaults, tint chrome, back affordance: `app/test/debug_log_viewer_test.dart`.
- 320 dp pins: `app/test/debug_log_viewer_320dp_min_viewport_test.dart`.
