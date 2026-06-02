# Shell Screen

**Screen ID:** `SHEL10001` — stable; do not reassign.
**SPEC/ui** — App shell. Hosts [`CtMainMenu`](main-menu.md) on the `Routes.shell` route and acts as the navigation choke point between the main menu and gameplay. Source of truth for the menu surface itself: [`main-menu.md`](main-menu.md). Implementation: `app/lib/features/shell/shell_screen.dart`.
**Widgetbook:** `Shell Screen` → `app/lib/widgetbook/catalog.dart`. App-screen / route table: [`ctdev-app.md`](../program/ctdev-app.md). Routes: `app/lib/config/routes.dart`. Bus events: [`app-event-bus.md`](../program/app-event-bus.md). Bus wiring rules: [`app-ui-wiring.md`](../program/app-ui-wiring.md). Auto-save / resume contract: [`save-load.md`](../program/save-load.md).

---

## Widget contract

`ShellScreen` is a `ConsumerWidget` (`app/lib/features/shell/shell_screen.dart`). It takes no constructor parameters: state is derived from Riverpod providers and the user-facing widget is always [`CtMainMenu`](main-menu.md).

| Aspect | Value | Description |
|--------|-------|-------------|
| `variant` | `MainMenuVariant.plain` | Always passes `plain` — the pixel-art variant is owned by the menu spec. |
| `state` | `MainMenuState.default_` | Always passes `default_`; the post-victory subtitle is owned by [`victory-overlay.md`](victory-overlay.md) follow-up flow, not by this shell. |
| `version` | `appDisplayVersion()` | Reads `appDisplayVersion()` from `app/lib/config/app_display_strings.dart` so `CT_DEBUG_CONSOLE` formatting works unchanged. |
| `resumeGameVisible` | `mainMenuAutoSaveAvailableProvider` | Watches `mainMenuAutoSaveAvailableProvider` from `app/lib/providers/games_provider.dart`; recomputes whenever the games box changes per [`save-load.md`](../program/save-load.md). |

The shell does not own the menu UI: visual layout, asset choices, and per-state behaviour are specified by [`main-menu.md`](main-menu.md). This screen owns only the **callback wiring** and **navigation side effects**.

---

## Trigger conditions

- **Initial route:** `Routes.shell` (`/`) per `app/lib/config/routes.dart`. After the splash/init phase, the app navigator pushes this screen as the home route.
- **Return-from-game:** Reached via `NavigateToShellEvent` (handled by `AppEventHandler` per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Routes); the shell rebuilds and re-evaluates `mainMenuAutoSaveAvailableProvider`, so a freshly-written auto-save makes Resume game appear immediately without an app restart.
- **Post-victory return:** [`victory-overlay.md`](victory-overlay.md) emits `NavigateToShellEvent`; this screen displays without a special "after victory" state — that pointer is local to the menu spec.

---

## Layout / wireframe

```text
+------------------------------------------------------+
| Shell (Routes.shell)                                 |
| +--------------------------------------------------+ |
| | CtMainMenu                                       | |
| |   variant: plain                                 | |
| |   state:   default                               | |
| |   version: appDisplayVersion()                   | |
| |   resumeGameVisible: <auto-save available?>      | |
| |   onNewGame / onResumeGame / onLoadGame /        | |
| |   onSettings / onQuit  -> shell callbacks below  | |
| +--------------------------------------------------+ |
+------------------------------------------------------+
```

The shell does not paint chrome around the menu; it returns the `CtMainMenu` widget directly so the menu fills the route.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Default (no auto-save) | `mainMenuAutoSaveAvailableProvider == false` | `CtMainMenu` is built with `resumeGameVisible: false`; the menu omits Resume game per [`main-menu.md`](main-menu.md) AC2. |
| Auto-save available | `mainMenuAutoSaveAvailableProvider == true` (a valid auto-save exists per [`save-load.md`](../program/save-load.md) § Auto-save slot) | `CtMainMenu` is built with `resumeGameVisible: true`; Resume game appears between New Game and Load Game. |
| In-game return | After a `NavigateToShellEvent` pop | The shell rebuilds (route re-shown) and re-reads `mainMenuAutoSaveAvailableProvider`; `currentGameProvider` cleanup is performed by `AppEventHandler` per [`app-event-bus.md`](../program/app-event-bus.md), not here. |

The shell never renders an "afterVictory" subtitle by itself — that detail is part of [`main-menu.md`](main-menu.md) when (or if) the human player elects to surface it.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Initial route | App navigator at `Routes.shell` (`/`) after splash/init | `ShellScreen` mounts and renders [`CtMainMenu`](main-menu.md) with shell-supplied callbacks. |
| `NavigateToShellEvent` | Post-game return from [`victory-overlay.md`](victory-overlay.md) or pause exit | `AppEventHandler` pops to shell; shell rebuilds and re-reads `mainMenuAutoSaveAvailableProvider`. |
| Provider refresh | `mainMenuAutoSaveAvailableProvider` changes while shell is visible | `resumeGameVisible` on `CtMainMenu` updates without app restart. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| New Game (`onNewGame`) | Always | `OpenDialogEvent(newGameLeaderSelectionDialogId)` on `AppEventBus` | Opens leader-selection dialog per [`app-ui-wiring.md`](../program/app-ui-wiring.md); no `Navigator.pushNamed` from shell. |
| Resume game (`onResumeGame`) | `resumeGameVisible == true` | `NavigateToRouteEvent(Routes.game)` after `loadAutoSaveGame()` | Resets `observeSessionProvider`; sets `currentGameProvider`. |
| Load game (`onLoadGame`) | Menu enables when saves exist | `NavigateToRouteEvent(Routes.game)` when `listGameIds()` non-empty | Same observe-session + `currentGameProvider` sequence as resume; no-op when `ids.isEmpty`. |
| Settings (`onSettings`) | Always (stub) | — | No-op today; reserved for Settings flow. |
| Quit (`onQuit`) | Always | `SystemNavigator.pop()` | Exits app; no bus events. |

All cross-screen transitions use `AppEventBus` per [`app-ui-wiring.md`](../program/app-ui-wiring.md) (no `Navigator.pushNamed` from this widget).

---

## Components

- [`CtMainMenu`](main-menu.md) — the only direct child widget.
- `AppEventBus` (read via `appEventBusProvider`) — for `OpenDialogEvent`, `NavigateToRouteEvent`, `NavigateToShellEvent`.
- Providers: `appEventBusProvider`, `mainMenuAutoSaveAvailableProvider`, `gameServiceProvider`, `currentGameProvider`, `observeSessionProvider`.
- `appDisplayVersion()` — debug-aware version string.
- No Material buttons, dialogs, or `Navigator.push` calls live in this widget.

---

## Acceptance Criteria (Given–When–Then)

- Given the app navigator is at `Routes.shell` and `mainMenuAutoSaveAvailableProvider` returns `false`,
  When `ShellScreen.build` runs,
  Then the widget tree contains exactly one `CtMainMenu` with `variant == MainMenuVariant.plain`, `state == MainMenuState.default_`, and `resumeGameVisible == false`.

- Given the app navigator is at `Routes.shell` and `mainMenuAutoSaveAvailableProvider` returns `true`,
  When `ShellScreen.build` runs,
  Then the widget tree contains exactly one `CtMainMenu` with `resumeGameVisible == true`.

- Given `ShellScreen` is mounted with a bus listener subscribed to `OpenDialogEvent`,
  When the user taps the New Game control,
  Then the shell emits exactly one `OpenDialogEvent(newGameLeaderSelectionDialogId)` on the supplied bus and does not call `Navigator.pushNamed` from the widget itself.

- Given `ShellScreen` is mounted, an auto-save game exists, and `mainMenuAutoSaveAvailableProvider == true`,
  When the user taps Resume game,
  Then the shell calls `gameServiceProvider.loadAutoSaveGame()`, resets `observeSessionProvider`, sets the loaded game on `currentGameProvider`, and emits exactly one `NavigateToRouteEvent(Routes.game)` on the bus.

- Given `ShellScreen` is mounted and `gameServiceProvider.listGameIds()` returns at least one id,
  When the user taps Load game,
  Then the shell loads the first id via `gameServiceProvider.loadGame(id)`, resets `observeSessionProvider`, sets the loaded game on `currentGameProvider`, and emits exactly one `NavigateToRouteEvent(Routes.game)`.

- Given `ShellScreen` is mounted and `gameServiceProvider.listGameIds()` returns an empty list,
  When the user taps Load game,
  Then the shell does not load any game and does not emit `NavigateToRouteEvent` (no-op).

- Given `ShellScreen` is mounted,
  When the user taps Quit,
  Then the shell calls `SystemNavigator.pop()` exactly once and does not emit any bus events.

- Given `ShellScreen` has been popped to (post-game) via `NavigateToShellEvent` and an auto-save was written during play,
  When the shell rebuilds,
  Then `mainMenuAutoSaveAvailableProvider` is re-read and the menu shows Resume game (visibility refreshes without an app restart, matching [`main-menu.md`](main-menu.md) § Shell behaviour).

- Given `ShellScreen` is mounted,
  When the widget tree is inspected,
  Then there are zero direct `Navigator.pushNamed` / `pushReplacement` / `popUntil` calls inside the widget — cross-screen transitions are emitted as `AppEvent`s only (matches [`app-ui-wiring.md`](../program/app-ui-wiring.md) ban on `Navigator` chains for cross-cutting UI).

---

## Widgetbook

Catalog directory: `Shell Screen` (registered in `app/lib/widgetbook/catalog.dart`). Required use cases:

1. **Default — no auto-save** — `mainMenuAutoSaveAvailableProvider` overridden to return `false`; renders the shell with Resume game omitted.
2. **Auto-save available** — `mainMenuAutoSaveAvailableProvider` overridden to return `true`; renders the shell with Resume game visible.

Each story uses a `ProviderScope` that overrides `appEventBusProvider` with a fresh `AppEventBus.create()` (disposed on scope dispose) and the auto-save flag, so the catalog does not require a real Hive store.
