# Game Side Menu

**SPEC/ui** — Slide-out hamburger drawer for the in-game shell. Hosts **Game Parameters** (read-only) and **Debug log**. Authority for the hamburger contract (240 dp width, content list, scrim/modal behaviour): [`in-game-shell-narrow.md`](in-game-shell-narrow.md). Related: [`pause-menu-panel.md`](pause-menu-panel.md) (the modal bottom-sheet variant emitted by `OpenPauseMenuPanelEvent`). Bus contract: [`app-event-bus.md`](../program/app-event-bus.md), [`app-ui-wiring.md`](../program/app-ui-wiring.md). Source: `app/lib/features/game/flame/game_side_menu.dart`.

---

## Widget contract

`GameSideMenu` is a `ConsumerWidget` (`app/lib/features/game/flame/game_side_menu.dart`). It animates in from the left edge using a `TweenAnimationBuilder<Offset>` and renders its body inside a `Positioned` slot so it overlays the map area as a drawer.

| Parameter | Type | Description |
|-----------|------|-------------|
| `sideMenuOpen` | `bool` | Required. Drives the open/close animation. `true` animates the menu in from offset `(-1, 0)` to `(0, 0)`; `false` animates it back out to `(-1, 0)`. The host is responsible for toggling this flag (typically via `GameMapArea` state). |
| `onClose` | `VoidCallback` | Required. Invoked when the user dismisses the menu via the close (×) button, horizontal-drag-left (`details.delta.dx < -5`), or via tapping a menu entry that closes-and-then-navigates (Debug log) or closes-and-then-opens-dialog (Game Parameters). |

Providers read inside `build`:

- `appEventBusProvider` (`ref.read`) — destination for `NavigateToRouteEvent(Routes.debugLog)` on the Debug log row.
- `currentGameProvider` (`ref.read`) — used by `_openGameParameters` to source `Game.infiniteMode` for the read-only dialog; if `null`, the row is a no-op (does not close the menu, does not open the dialog).

The widget is fixed width `_kSideMenuWidth = 240` (matches the [`in-game-shell-narrow.md`](in-game-shell-narrow.md) hamburger width). The animation duration is `Duration(milliseconds: 200)`.

---

## Trigger conditions

- **Open:** The host (`GameMapArea`) sets `sideMenuOpen: true` when the user taps the hamburger or swipes in from the left edge of the map (see [`in-game-shell-narrow.md`](in-game-shell-narrow.md) § Hamburger side menu). The widget animates in from the left.
- **Close:** Any of (a) tap on the in-menu close (×) button, (b) horizontal drag whose `delta.dx < -5`, (c) menu entry tap that calls `onClose()` before its navigation/dialog side effect. The widget itself only invokes `onClose`; the host clears its own `sideMenuOpen` flag.
- **Mounting:** The widget remains mounted while `sideMenuOpen` flips so the close animation runs; the host is expected to keep the widget in the tree until the close tween completes (drive the open/close via state changes, not insert/remove).

---

## Layout / wireframe

```text
+------------------------------------------+
| (overlay: Positioned left = offset.dx*W) |
|                                          |
|  +-----------------------+               |
|  | CtPanel               |               |
|  |   Row(end): [ × ]     |               |
|  |   SizedBox(h: 8)      |               |
|  |   CtNinePatchButton:  |               |
|  |     [tune] Game       |               |
|  |     Parameters        |               |
|  |   SizedBox(h: 8)      |               |
|  |   CtNinePatchButton:  |               |
|  |     [bug] Debug log   |               |
|  +-----------------------+               |
|  width = 240 dp                          |
|                                          |
+------------------------------------------+
```

The body is wrapped in a `GestureDetector(onHorizontalDragUpdate: ...)` so a horizontal drag-left of more than 5 logical pixels per frame fires `onClose()`. The body interior uses `CtPanel(padding: EdgeInsets.all(8))` with `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`.

Each menu row is a `CtNinePatchButton` whose child is a `Row` of `Icon(..., size: 20)` + `SizedBox(width: 8)` + `Expanded(child: Text(label, overflow: TextOverflow.ellipsis))`.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Open (idle) | `sideMenuOpen == true` after the open tween completes | Body is rendered at `left = 0`; Close (×), Game Parameters, Debug log are all interactive. |
| Opening | `sideMenuOpen` just flipped from `false` to `true` | `TweenAnimationBuilder` animates `Offset(-1,0) → Offset(0,0)` over 200 ms. |
| Closing | `sideMenuOpen` just flipped from `true` to `false` | `TweenAnimationBuilder` animates `Offset(0,0) → Offset(-1,0)` over 200 ms; rebuilds with a new `ValueKey(sideMenuOpen)` so the tween restarts. |
| Game absent | `currentGameProvider == null` and the user taps **Game Parameters** | The row is a no-op (`_openGameParameters` early-returns); `onClose` is not called and no dialog opens. |

The widget itself never reads `turnResolutionBlockingProvider`; the side menu remains usable while a turn is resolving because both its outputs (a local `showDialog` for Game Parameters and an `OpenDialogEvent`-free direct `NavigateToRouteEvent(Routes.debugLog)`) are not gated by [`app-ui-wiring.md`](../program/app-ui-wiring.md) (only typed dialog/panel `OpenDialogEvent` flows are gated).

---

## Navigation

- **Close (×) button** — Invokes `onClose()` once. No bus events are emitted by the widget itself.
- **Game Parameters row** — Reads `currentGameProvider`. If a game is present, calls `onClose()` first, then `showDialog<void>(context: context, builder: (ctx) => GameParametersDialog(infiniteMode: game.infiniteMode))`. The dialog is opened on the local `Navigator` (no `OpenDialogEvent` is emitted); this matches the read-only contract in [`in-game-shell-narrow.md`](in-game-shell-narrow.md) § Game Parameters (read-only) which describes a thin dialog that has no edit controls. The widget does **not** emit any bus event for this flow.
- **Debug log row** — Calls `onClose()` first, then emits `NavigateToRouteEvent(Routes.debugLog)` via `ref.read(appEventBusProvider)`. The bus handler in `AppEventHandler` performs the actual `pushNamed`.
- **Horizontal drag left** — When `GestureDetector.onHorizontalDragUpdate.details.delta.dx < -5`, invokes `onClose()`.
- **No direct `Navigator.pushNamed` / `pushReplacement` / `popUntil`** by this widget for cross-cutting navigation; the only direct navigator usage is the local `showDialog` for the Game Parameters read-only dialog, which is allowed by [`app-ui-wiring.md`](../program/app-ui-wiring.md) for component-local dialogs.

---

## Components

- `TweenAnimationBuilder<Offset>` — drives the open/close slide.
- `Positioned` — fixed `top: 0`, `bottom: 0`, `width: 240`; `left` is `offset.dx * 240`.
- `GestureDetector` — picks up drag-left close gesture.
- [`CtPanel`](buttons-nine-patch.md) — pixel-art frame around the body.
- [`CtNinePatchButton`](buttons-nine-patch.md) — every interactive row (close, Game Parameters, Debug log).
- `Icon(Icons.tune, size: 20)` (Game Parameters), `Icon(Icons.bug_report, size: 20)` (Debug log) — Material icons matching `app/lib/features/game/flame/game_side_menu.dart`.
- Localized strings: `appL10n(context).gameParameters_menuEntry`, `appL10n(context).debugLog_title`.
- Local dialog: `GameParametersDialog` (`app/lib/features/game/widgets/game_parameters_dialog.dart`) for the read-only Infinite mode display.

---

## Acceptance Criteria (Given–When–Then)

- Given `GameSideMenu` is mounted with `sideMenuOpen: true` and a non-null `currentGameProvider`,
  When the widget tree is inspected,
  Then it contains exactly one `CtPanel`, exactly one row with title `appL10n(context).gameParameters_menuEntry`, exactly one row with title `appL10n(context).debugLog_title`, and exactly one close (×) button (a `CtNinePatchButton` whose child text is `×`).

- Given `GameSideMenu` is mounted with `sideMenuOpen: true` and an `onClose` callback `C`,
  When the user taps the close (×) button,
  Then `C` is invoked exactly once and no bus events are emitted by the widget.

- Given `GameSideMenu` is mounted with `sideMenuOpen: true`, an `onClose` callback `C`, and a `currentGameProvider` returning a `Game` with `infiniteMode == true`,
  When the user taps the **Game Parameters** row,
  Then `C` is invoked exactly once and a `GameParametersDialog(infiniteMode: true)` is shown on the local `Navigator`. The widget does not emit `OpenDialogEvent` or any other bus event for this flow.

- Given `GameSideMenu` is mounted with `sideMenuOpen: true` and `currentGameProvider == null`,
  When the user taps the **Game Parameters** row,
  Then `onClose` is not invoked, no dialog is opened, and no bus event is emitted (the row is a no-op).

- Given `GameSideMenu` is mounted with `sideMenuOpen: true`, an `onClose` callback `C`, and a bus listener `L` attached to `appEventBusProvider`,
  When the user taps the **Debug log** row,
  Then `C` is invoked exactly once and `L` receives exactly one `NavigateToRouteEvent` whose `route == Routes.debugLog`. No `OpenDialogEvent` is emitted.

- Given `GameSideMenu` is mounted with `sideMenuOpen: true` and an `onClose` callback `C`,
  When the user performs a horizontal drag whose per-frame `details.delta.dx < -5`,
  Then `C` is invoked at least once during the drag.

- Given `GameSideMenu` is mounted with `sideMenuOpen` flipping from `true` to `false`,
  When the next frame is built,
  Then the `TweenAnimationBuilder` is reconstructed with a new `ValueKey(sideMenuOpen)` and animates `Offset(0,0) → Offset(-1,0)` over `Duration(milliseconds: 200)`, so the body translates to `left = -240` at the end of the tween.

- Given `GameSideMenu` is mounted,
  When the widget tree is inspected,
  Then it contains zero direct `Navigator.pushNamed` / `pushReplacement` / `popUntil` calls; the only allowed direct `Navigator` usage is the local `showDialog` inside `_openGameParameters` for the read-only `GameParametersDialog` (matches [`app-ui-wiring.md`](../program/app-ui-wiring.md) § Component-local dialogs).

---

## Widgetbook

Catalog directory: `Game Side Menu` (registered in `app/lib/widgetbook/catalog.dart`). Required use cases:

1. **Default — open, infinite mode off** — `sideMenuOpen: true`; `currentGameProvider` overridden with `getDebugInitGameResult().game`; `appEventBusProvider` overridden with `AppEventBus.create()` (disposed on scope dispose); `onClose: () {}`. Renders the slide-out drawer at rest in its open position with both menu rows visible.
2. **Default — closed** — `sideMenuOpen: false`; same overrides as above. Renders the drawer in its closed (off-screen) state so the catalog can preview the closing tween's end-state.

Each story uses a `ProviderScope` with `appEventBusProvider` overridden to a fresh `AppEventBus.create()` and is wrapped in `MaterialApp` so `appL10n` and `Navigator` are available. Stories must avoid raw `CircularProgressIndicator` (use [`CtLoadingIndicator`](../../app/lib/widgets/ct_loading_indicator.dart) where any loading affordance is needed) per repo lint `repo.app_ct_loading_indicator`.
