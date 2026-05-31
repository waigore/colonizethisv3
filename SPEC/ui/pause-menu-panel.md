# Pause Menu Panel

**Screen ID:** `SHEL40001` — stable; do not reassign.
**SPEC/ui** — Modal pause menu shown by [`AppEventHandler`](../program/app-ui-wiring.md) in response to `OpenPauseMenuPanelEvent`. Hosts the in-game shell's primary pause flow: **Resume**, save/load, settings, and **Exit to Main Menu** (danger). Authority for visual chrome (dark editorial-monocle modal, brass divider, ordered button stack): [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) and the dialog/overlay restyling contract in issue #2867 § R1, R30. Related: [`game-side-menu.md`](game-side-menu.md) (the wide slide-out drawer that hosts the **Debug log** entry; Debug log is **not** rendered by the pause menu). Bus contract: [`app-event-bus.md`](../program/app-event-bus.md), [`app-ui-wiring.md`](../program/app-ui-wiring.md). Source: `app/lib/features/game/widgets/pause_menu_panel.dart`.

**Mockup:** [mockups/SHEL40001-pause-menu-panel.html](mockups/SHEL40001-pause-menu-panel.html) (legacy bottom-sheet two-row layout; superseded by the modal contract in this SPEC per issue #2867 § R30. A refreshed mockup will be filed alongside the next pass over `SHEL40001`.)
---

## Widget contract

`PauseMenuPanel` is a `StatelessWidget` (`app/lib/features/game/widgets/pause_menu_panel.dart`). It owns no state and emits all user actions on the supplied bus; it never calls `Navigator` directly.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bus` | `AppEventBus` | Required. The shell-wide bus instance; all user actions on this panel are emitted on this bus and never mutated through `BuildContext` / `Navigator` chains. |

The widget renders a centered modal frame using `CtDialogShell`. The body is a `Column(mainAxisSize: MainAxisSize.min)` containing the **Game Paused** title, a `CtBrassDivider`, then a vertical stack of exactly five `CtNinePatchButton` actions per [States and variants](#states-and-variants). The panel is shown via `showDialog<void>` by [`AppEventHandler`](../program/app-ui-wiring.md) when the in-game shell emits `OpenPauseMenuPanelEvent`; the host route uses `barrierColor: EditorialMonoclePalette.dialogScrim` (the canonical `--dialog-scrim` token) so the `CtDialogShell` chrome (gradient, 2 px `--accent-dim` border) reads against the dark scrim. The dialog uses `useRootNavigator: true` so the modal stacks above the game shell route.

The panel itself does not dismiss the dialog directly. It emits a `ClosePanelEvent` on the bus; the `AppEventHandler` calls `Navigator.pop` (the root navigator used by `showDialog`) so the modal closes consistently with other typed panel events per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Typed panel events.

---

## Trigger conditions

- **Open:** `GameScreen` (and any other in-game host) emits `OpenPauseMenuPanelEvent` on the bus. `AppEventHandler._openPauseMenuPanel` calls `showDialog<void>(useRootNavigator: true, barrierColor: EditorialMonoclePalette.dialogScrim, builder: (ctx) => PauseMenuPanel(bus: _bus))` per [`app-ui-wiring.md`](../program/app-ui-wiring.md).
- **Available during turn resolution:** `OpenPauseMenuPanelEvent` is one of the events allowed while `turnResolutionBlockingProvider == true` (alongside `ClosePanelEvent`); see [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Turn resolution in progress and the regression contract `app/test/turn_resolution_event_blocking_test.dart`.
- **Close:** Any action inside the panel that emits `ClosePanelEvent` on the bus causes the modal to dismiss via the bus handler. The user may also tap outside the modal (the standard `showDialog` scrim) to dismiss without firing any event.

---

## Layout / wireframe

```text
+----------------------------------------------+
| (showDialog modal; --dialog-scrim barrier)   |
| +------------------------------------------+ |
| | CtDialogShell                            | |
| | +--------------------------------------+ | |
| | | "Game Paused" (display, --accent)    | | |
| | | CtBrassDivider                       | | |
| | | CtNinePatchButton  Resume            | | |
| | | CtNinePatchButton  Save Game         | | |
| | | CtNinePatchButton  Load Game         | | |
| | | CtNinePatchButton  Settings          | | |
| | | CtNinePatchButton  Exit to Main Menu | | |
| | +--------------------------------------+ | |
| +------------------------------------------+ |
+----------------------------------------------+
```

The panel has no custom close button — dismissal goes through Resume, Exit to Main Menu, or the modal scrim. Each row is a `CtNinePatchButton` with a centered localized label `Text`; rows are vertically stacked with a small inter-row gap. Action order is normative: **Resume → Save Game → Load Game → Settings → Exit to Main Menu (danger)**.

---

## States and variants

| State | Trigger | Render / behaviour |
|-------|---------|--------------------|
| Default | Panel is opened by `OpenPauseMenuPanelEvent` while a game is active. | Title `Game Paused`, `CtBrassDivider`, then five `CtNinePatchButton` rows in declared order. **Resume** and **Exit to Main Menu** are enabled. **Save Game**, **Load Game**, and **Settings** render in a disabled state (`onPressed: null`, 0.4 opacity per the catalog disabled contract) because no backing flow is wired yet; a follow-up issue (referenced in the implementation TODO) will enable them. |
| Resume during turn resolution | Panel was opened while `turnResolutionBlockingProvider == true`. | Same five-button render. Tapping **Resume** emits a `ClosePanelEvent` only, which the bus handler always allows (see [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Turn resolution in progress). The next-turn handler in [`game-screen.md`](game-screen.md) is unaffected. |

Debug log is **not** rendered by the pause menu — it lives in [`game-side-menu.md`](game-side-menu.md) (the hamburger drawer). Adding it back here is a SPEC change (file a separate issue).

---

## Navigation

- **Resume** — Emits exactly one `ClosePanelEvent`. The bus handler dismisses the sheet; no other bus events fire.
- **Save Game / Load Game / Settings** — Disabled placeholders (`onPressed: null`). Tapping is a no-op; no bus events fire. Wiring is tracked in a follow-up issue per the Variants table.
- **Exit to Main Menu** — Emits `ClosePanelEvent` first (closing the pause sheet), then emits `RequestExitToMainMenuFlowEvent` on the bus in the same tap handler. The `AppEventHandler` reacts by showing `showExitToMainMenuConfirmDialog` and, when the player confirms, emitting `NavigateToShellEvent`; on cancel no further event fires. Emission order on the bus stream is `ClosePanelEvent` followed by `RequestExitToMainMenuFlowEvent`.
- **No direct `Navigator.pop` / `Navigator.pushNamed`** inside the widget. All cross-screen transitions go via the bus, matching [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Banned `Navigator` chains.

---

## Components

- `CtDialogShell` — outer modal frame (2 px `--accent-dim` border, surface-lite → surface → bg-deep gradient).
- `CtBrassDivider` — separates the title from the action stack.
- `CtNinePatchButton` — one per action; the Exit to Main Menu row uses the danger label colour token (`EditorialMonoclePalette.danger`) per `SPEC/ui/pixel-art-ui-catalog.md` § Destructive actions.
- Localized strings: `appL10n(context).game_pauseMenu_title`, `game_pauseMenu_resume`, `game_pauseMenu_saveGame`, `game_pauseMenu_loadGame`, `game_pauseMenu_settings`, `game_pauseMenu_exitToMainMenu`. These keys are added by this slice.
- `AppEventBus` (constructor-injected) — destination for `ClosePanelEvent` and `RequestExitToMainMenuFlowEvent`.

---

## Acceptance Criteria (Given–When–Then)

- Given the user is on `GameScreen` and the host emits `OpenPauseMenuPanelEvent` on the bus,
  When `AppEventHandler._openPauseMenuPanel` runs,
  Then `showDialog<void>` is called with `useRootNavigator: true`, `barrierColor: EditorialMonoclePalette.dialogScrim`, and a `builder` that returns exactly one `PauseMenuPanel` constructed with the same bus instance.

- Given `PauseMenuPanel` is mounted with a bus `B`,
  When the widget tree is inspected,
  Then the tree contains exactly one `CtDialogShell`, exactly one `CtBrassDivider`, and exactly five `CtNinePatchButton` rows. The button labels read, in stream order top-to-bottom, `appL10n(context).game_pauseMenu_resume`, `appL10n(context).game_pauseMenu_saveGame`, `appL10n(context).game_pauseMenu_loadGame`, `appL10n(context).game_pauseMenu_settings`, `appL10n(context).game_pauseMenu_exitToMainMenu`.

- Given `PauseMenuPanel` is mounted,
  When the **Save Game**, **Load Game**, and **Settings** buttons are inspected,
  Then each `CtNinePatchButton`'s `onPressed` is `null` and the surface renders at the disabled-opacity contract from `SPEC/ui/pixel-art-ui-catalog.md` (no taps are dispatched to the bus when interacted with).

- Given `PauseMenuPanel` is mounted with a bus `B` and a listener `L` is attached to `B.stream`,
  When the user taps the **Resume** button,
  Then `L` receives exactly one event: a `ClosePanelEvent`. No `RequestExitToMainMenuFlowEvent` or `NavigateToShellEvent` is emitted by this widget for the Resume tap.

- Given `PauseMenuPanel` is mounted with a bus `B` and a listener `L` is attached to `B.stream`,
  When the user taps the **Exit to Main Menu** button,
  Then `L` receives at least two events in stream order: a `ClosePanelEvent` followed by a `RequestExitToMainMenuFlowEvent`. The `ClosePanelEvent` is emitted **before** the `RequestExitToMainMenuFlowEvent`.

- Given `PauseMenuPanel` is mounted,
  When the widget tree is inspected,
  Then it contains zero direct `Navigator.pushNamed`, `Navigator.pushReplacement`, or `Navigator.pop` calls; cross-cutting transitions are bus events only (matches [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Banned `Navigator` chains).

- Given the in-game host is in turn resolution (`turnResolutionBlockingProvider == true`) and the user opens the pause panel via `OpenPauseMenuPanelEvent`,
  When the panel is rendered,
  Then the **Resume** button is enabled (`onPressed != null`), matching the gating rule that `OpenPauseMenuPanelEvent` and `ClosePanelEvent` are allowed during turn resolution per [`app-ui-wiring.md`](../program/app-ui-wiring.md).

- Given `PauseMenuPanel` is mounted,
  When the widget tree is inspected,
  Then no Material `ListTile`, `Card`, `AlertDialog`, `AppBar`, or `Divider` widget is present, in accordance with `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban. (The single `Dialog` mounted internally by `CtDialogShell` is sanctioned chrome and is the only `Dialog` permitted in the tree.)

---

## Widgetbook

Catalog directory: `Pause Menu Panel` (registered in `app/lib/widgetbook/catalog.dart`). Required use cases:

1. **Default — centered modal** — Renders `PauseMenuPanel` with a freshly-created `AppEventBus.create()` inside a `MaterialApp` so localization is available. The story does not host the panel inside a real `showDialog`; instead it places the panel inside a `Scaffold` whose body fills with `EditorialMonoclePalette.dialogScrim` so the catalog can preview the centered `CtDialogShell` modal against the canonical `--dialog-scrim` barrier used by `AppEventHandler` in production. Tap targets remain functional and emit on the supplied bus.

The story disposes the per-use-case bus on widget unmount (e.g. via a `StatefulWidget` wrapper) so repeated story switches do not leak stream subscriptions.
