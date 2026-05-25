# Victory Overlay

**Screen ID:** `OVL20001` — stable; do not reassign.
**SPEC/ui** — Full-screen overlay shown when a military victory is recorded. Implementation: `app/lib/features/game/flame/victory_overlay.dart`.
**Widgetbook:** `Victory` → `app/lib/widgetbook/catalog.dart`. Game model: [victory.md](../game/victory.md). Return target: [main-menu.md](main-menu.md). Host: [`game-screen.md`](game-screen.md).

---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `VictoryOverlay` | `StatefulWidget` | `game` (`Game`), `victory` (`VictoryState`), `bus` (`AppEventBus`) | Full-screen semi-transparent scrim with centered `VictoryPanel`. Owns `_dismissed` so “View final state” hides the overlay without a route change. |
| `VictoryPanel` | `StatelessWidget` | `game`, `victory`, `bus`, `onViewFinalState` (`VoidCallback?`, optional) | Presentational panel inside `CtPanel`; resolves winner display name and victory-type label. |

Implementation: `app/lib/features/game/flame/victory_overlay.dart`.

---

## Layout / wireframe

```text
+----------------------------------------------------------+
|  (full screen, Colors.black54 scrim)                     |
|                                                          |
|              +--------------------------------+          |
|              | CtPanel (padding 24)           |          |
|              |  <Victory type label>          |          |
|              |    headlineSmall               |          |
|              |                                |          |
|              |  <Winner> wins on turn <N>.    |          |
|              |    bodyLarge, centered         |          |
|              |                                |          |
|              |  [ Return to Main Menu ]       |          |
|              |  [ View Final State ]          |          |
|              |    Row, mainAxisSize: min      |          |
|              +--------------------------------+          |
|                                                          |
+----------------------------------------------------------+
```

- Outer: `Positioned.fill` → `Container(color: Colors.black54)` → `Center` → outer `Padding(24)` → `VictoryPanel`.
- Title: `appL10n(context).victory_military` when `victory.type == VictoryType.military` (only variant implemented).
- Body: `appL10n(context).victory_winnerOnTurn(winner.displayName, victory.turnNumber)`.
- Buttons: two `CtNinePatchButton`s in a `Row` with 12 dp spacing — “Return to Main Menu” (left), “View Final State” (right).
- No Material buttons.

Winner resolution: `game.playerById(victory.winnerPlayerId) ?? game.players.first`.

---

## Trigger conditions

- `GameScreen` renders `VictoryOverlay` when `game != null && game.victory != null` (see `game_screen.dart` build `Stack` children).
- The overlay is the topmost interactive layer above the Flame canvas / map area, next-turn control, and pause affordances.
- Turn advancement and full turn resolution are blocked while `Game.victory != null` via `GameMapAreaStateLogic.allowsFullTurnResolution` (returns `false` when victory is set). See [victory.md](../game/victory.md) § Victory Check and § Victory Screen (UI).

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Overlay visible (default) | `VictoryOverlay` mounted, `_dismissed == false` | Scrim + `VictoryPanel` shown. |
| Overlay dismissed | User tapped “View Final State”; `_dismissed == true` | `VictoryOverlay` returns `SizedBox.shrink()`; map/canvas remains visible; `Game.victory` stays set; further turns remain blocked. |
| Military victory | `victory.type == VictoryType.military` | Title uses `victory_military` l10n string. |
| Future types | `VictoryType.economic`, `VictoryType.scientific` | Not implemented ([victory.md](../game/victory.md) § Out of scope). Spec reserves extension: add l10n labels and `switch` arms when product adds types. |

Calendar campaign halt (`Game.calendarCampaignHalted == true` with `Game.victory == null`) does **not** use this overlay; see [victory.md](../game/victory.md) § Calendar campaign end.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `GameScreen` stack | `game.victory != null` and `VictoryOverlay` mounted | Full-screen scrim + `VictoryPanel`. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Return to Main Menu | Overlay visible | `NavigateToShellEvent` | Shell navigates per [main-menu.md](main-menu.md). |
| View Final State | Overlay visible | `onViewFinalState` callback | `_dismissed = true`; map remains; no route pop. |

---

## Components

- `CtPanel` (`app/lib/widgets/ct_panel.dart`).
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`).
- Localized strings: `victory_military`, `victory_winnerOnTurn`, `victory_returnToMainMenu`, `victory_viewFinalState` via `appL10n(context)`.

---

## Acceptance Criteria (Given–When–Then)

- Given `Game.victory` is a `VictoryState` with `type: VictoryType.military`, `turnNumber: 12`, and a resolvable `winnerPlayerId`,
  When `GameScreen` builds with that game,
  Then the UI layer renders `VictoryOverlay` above the game stack and shows the military victory label and a winner sentence containing turn `12`.

- Given `VictoryOverlay` is visible,
  When the user taps “View final state”,
  Then the overlay is removed from the widget tree (`Military victory` text is no longer found) and `Game.victory` remains non-null.

- Given `VictoryOverlay` is visible and an `AppEventBus` is wired,
  When the user taps “Return to main menu”,
  Then the UI layer emits exactly one `NavigateToShellEvent` on that bus.

- Given `Game.victory != null`,
  When the system evaluates `GameMapAreaStateLogic.allowsFullTurnResolution(game)`,
  Then the result is `false` (next-turn and full resolution paths stay disabled).

- Given `victory.winnerPlayerId` does not match any player in `game.players`,
  When `VictoryPanel` builds,
  Then the winner sentence uses `game.players.first.displayName` as the winner name (fallback).

- Given `VictoryPanel` is mounted in a test or Widgetbook harness,
  When the widget tree is built,
  Then there are zero Material `ElevatedButton`, `TextButton`, or `OutlinedButton` widgets and exactly two `CtNinePatchButton` instances.

---

## Widgetbook

Catalog folder: **Victory** (registered in `app/lib/widgetbook/catalog.dart` via `victoryUiDirectories`). Use cases:

1. **Victory panel — military (default):** `VictoryPanel` with `getDebugInitGameResult().game`, sample `VictoryState` (`VictoryType.military`, turn `45`, first player as winner), and a throwaway `AppEventBus`.
2. **Victory overlay — full scrim (optional):** `VictoryOverlay` inside a fixed-size `Stack` to show the dimmed full-screen presentation.

Automated widget tests: `app/test/victory_overlay_test.dart`.
