# Pause Menu Panel

**SPEC/ui** — Bottom-sheet content shown by [`AppEventHandler`](../program/app-ui-wiring.md) in response to `OpenPauseMenuPanelEvent`. Used during in-game play to give the player access to the **Debug log** route and a quick **Resume** action. Authority: [`in-game-shell-narrow.md`](in-game-shell-narrow.md) (hamburger menu). Bus contract: [`app-event-bus.md`](../program/app-event-bus.md), [`app-ui-wiring.md`](../program/app-ui-wiring.md). Related: [`game-side-menu.md`](game-side-menu.md) (the wide slide-out drawer that hosts the hamburger entries during normal play; the pause panel is the **modal bottom-sheet** variant reachable from [`game-screen.md`](game-screen.md)). Source: `app/lib/features/game/widgets/pause_menu_panel.dart`.

---

## Widget contract

`PauseMenuPanel` is a `StatelessWidget` (`app/lib/features/game/widgets/pause_menu_panel.dart`). It owns no state and emits all user actions on the supplied bus; it never calls `Navigator` directly.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bus` | `AppEventBus` | Required. The shell-wide bus instance; all user actions on this panel are emitted on this bus and never mutated through `BuildContext` / `Navigator` chains. |

The widget renders a `SafeArea` wrapping a `Column(mainAxisSize: MainAxisSize.min)` whose children are `ListTile`s. Each tile maps to a single user-visible action listed under [States and variants](#states-and-variants). The panel is shown via `showModalBottomSheet` by [`AppEventHandler`](../program/app-ui-wiring.md) when the in-game shell emits `OpenPauseMenuPanelEvent`.

The panel itself does not dismiss the bottom sheet directly. It emits a `ClosePanelEvent` on the bus; the `AppEventHandler` calls `Navigator.pop` (the root navigator used by `showModalBottomSheet`) so the sheet closes consistently with other typed panel events per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Typed panel events.

---

## Trigger conditions

- **Open:** `GameScreen` (and any other in-game host) emits `OpenPauseMenuPanelEvent` on the bus. `AppEventHandler._openPauseMenuPanel` calls `showModalBottomSheet<void>(builder: (ctx) => PauseMenuPanel(bus: _bus))` per [`app-ui-wiring.md`](../program/app-ui-wiring.md).
- **Available during turn resolution:** `OpenPauseMenuPanelEvent` is one of the two events allowed while `turnResolutionBlockingProvider == true` (the other is `ClosePanelEvent`); see [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Turn resolution in progress and the regression contract `app/test/turn_resolution_event_blocking_test.dart`.
- **Close:** Any action inside the panel that emits `ClosePanelEvent` on the bus causes the sheet to dismiss via the bus handler. The user may also tap outside the sheet (the standard `showModalBottomSheet` scrim) to dismiss without firing any event.

---

## Layout / wireframe

```text
+---------------------------------------------+
| (modal bottom sheet; rounded top corners)   |
| +-----------------------------------------+ |
| | SafeArea                                | |
| | +-------------------------------------+ | |
| | | Column(mainAxisSize: min)           | | |
| | |   ListTile(Icons.list)  Debug log   | | |
| | |   ListTile(Icons.play_arrow) Resume | | |
| | +-------------------------------------+ | |
| +-----------------------------------------+ |
+---------------------------------------------+
```

The panel has no header, no close button, and no scrim chrome of its own — those are owned by `showModalBottomSheet`. Each row is a leading `Icon` + localized title `Text`, vertically stacked, sized to fit the contained tiles.

---

## States and variants

| State | Trigger | Render / behaviour |
|-------|---------|--------------------|
| Default | Panel is opened by `OpenPauseMenuPanelEvent` while a game is active. | Two enabled tiles in declared order: **Debug log** then **Resume**. No disabled states exist; both tiles are always enabled while the panel is mounted. |
| Resume during turn resolution | Panel was opened while `turnResolutionBlockingProvider == true`. | The panel still renders both tiles; tapping **Resume** emits a `ClosePanelEvent` only, which the bus handler always allows (see [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Turn resolution in progress). The next-turn handler in [`game-screen.md`](game-screen.md) is unaffected. |

The panel never renders a Game Parameters, Exit to Main Menu, or Quit to Desktop entry — those flows are owned by [`game-side-menu.md`](game-side-menu.md) (Game Parameters) and the [`game-screen.md`](game-screen.md) Android-back exit confirm dialog. Adding them here is a SPEC change (file a separate issue).

---

## Navigation

- **Debug log row** — Emits in declared order: `ClosePanelEvent`, then `NavigateToRouteEvent(Routes.debugLog)`. The close event must be emitted **before** the navigation event so the sheet dismisses cleanly while the new route is pushed by `AppEventHandler` per [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Routes.
- **Resume row** — Emits exactly one `ClosePanelEvent`. The bus handler dismisses the sheet; no other bus events fire.
- **No direct `Navigator.pop` / `Navigator.pushNamed`** inside the widget. All cross-screen transitions go via the bus, matching [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Banned `Navigator` chains.

---

## Components

- `SafeArea`, `Column(mainAxisSize: MainAxisSize.min)` — outer layout primitives.
- `ListTile` — one per row; leading `Icon`, title `Text` from `appL10n(context)`.
- `Icons.list` (Debug log), `Icons.play_arrow` (Resume) — Material icons matching `app/lib/features/game/widgets/pause_menu_panel.dart`.
- Localized strings: `appL10n(context).debugLog_title`, `appL10n(context).game_pauseMenu_resume`.
- `AppEventBus` (constructor-injected) — destination for `ClosePanelEvent` and `NavigateToRouteEvent`.

---

## Acceptance Criteria (Given–When–Then)

- Given the user is on `GameScreen` and the host emits `OpenPauseMenuPanelEvent` on the bus,
  When `AppEventHandler._openPauseMenuPanel` runs,
  Then `showModalBottomSheet<void>` is called with a `builder` that returns exactly one `PauseMenuPanel` constructed with the same bus instance.

- Given `PauseMenuPanel` is mounted with a bus `B`,
  When the widget tree is inspected,
  Then it contains exactly two `ListTile`s: one with leading `Icons.list` and title equal to `appL10n(context).debugLog_title`, and one with leading `Icons.play_arrow` and title equal to `appL10n(context).game_pauseMenu_resume`.

- Given `PauseMenuPanel` is mounted with a bus `B` and a listener `L` is attached to `B.stream`,
  When the user taps the Debug log `ListTile`,
  Then `L` receives at least two events in stream order: a `ClosePanelEvent` followed by a `NavigateToRouteEvent` whose `route == Routes.debugLog`, and the `ClosePanelEvent` is emitted **before** the `NavigateToRouteEvent`.

- Given `PauseMenuPanel` is mounted with a bus `B` and a listener `L` is attached to `B.stream`,
  When the user taps the Resume `ListTile`,
  Then `L` receives exactly one event: a `ClosePanelEvent`. No `NavigateToRouteEvent` is emitted by this widget.

- Given `PauseMenuPanel` is mounted,
  When the widget tree is inspected,
  Then it contains zero direct `Navigator.pushNamed`, `Navigator.pushReplacement`, or `Navigator.pop` calls; cross-cutting transitions are bus events only (matches [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Banned `Navigator` chains).

- Given the in-game host is in turn resolution (`turnResolutionBlockingProvider == true`) and the user opens the pause panel via `OpenPauseMenuPanelEvent`,
  When the panel is rendered,
  Then both Debug log and Resume tiles are enabled (`onTap != null`), matching the gating rule that `OpenPauseMenuPanelEvent` and `ClosePanelEvent` are allowed during turn resolution per [`app-ui-wiring.md`](../program/app-ui-wiring.md).

---

## Widgetbook

Catalog directory: `Pause Menu Panel` (registered in `app/lib/widgetbook/catalog.dart`). Required use cases:

1. **Default** — Renders `PauseMenuPanel` with a freshly-created `AppEventBus.create()` inside a `MaterialApp` so localization is available. The story does not host the panel inside a real `showModalBottomSheet`; instead it places the panel directly in a `Scaffold` body so the catalog can show the row layout without the bottom-sheet scrim. Tap targets remain functional and emit on the supplied bus.

The story disposes the per-use-case bus on widget unmount (e.g. via a `StatefulWidget` wrapper) so repeated story switches do not leak stream subscriptions.
