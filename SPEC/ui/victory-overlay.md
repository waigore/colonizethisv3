# Victory Overlay

**Screen ID:** `OVL20001` — stable; do not reassign.
**SPEC/ui** — Full-screen overlay shown when a military victory is recorded. Implementation: `app/lib/features/game/flame/victory_overlay.dart`.
**Widgetbook:** `Victory` → `app/lib/widgetbook/catalog.dart`. Game model: [victory.md](../game/victory.md). Return target: [main-menu.md](main-menu.md). Host: [`game-screen.md`](game-screen.md).

**Mockup:** [mockups/OVL20001-game-victory-overlay.html](mockups/OVL20001-game-victory-overlay.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `VictoryOverlay` | `StatefulWidget` | `game` (`Game`), `victory` (`VictoryState`), `bus` (`AppEventBus`) | Full-screen `--dialog-scrim` wash with centered `VictoryPanel`. Owns `_dismissed` so "View final state" hides the overlay without a route change. |
| `VictoryPanel` | `StatelessWidget` | `game`, `victory`, `bus`, `onViewFinalState` (`VoidCallback?`, optional) | Presentational brass-bordered panel (2px `--accent` border + asymmetric corner brackets + `surface-lite → bg-deep` vertical gradient). Resolves winner display name and victory-type label. |

Implementation: `app/lib/features/game/flame/victory_overlay.dart`.

---

## Layout / wireframe

```text
+--------------------------------------------------------------+
|  (full screen, --dialog-scrim wash: oklch(8% 0.01 30 / 0.70)) |
|                                                              |
|     ┌─                                                       |
|     |  +----------------------------------------+            |
|     |  | top-left corner bracket (1.5px brass)  |            |
|     |  |                                        |            |
|     |  |   ☜  ☆  ☞    (laurel row, --accent)     |            |
|     |  |    Military Victory                    |            |
|     |  |       display, --accent, upper-case    |            |
|     |  |  ─── CtBrassDivider ───                |            |
|     |  |   <Winner> wins on turn <N>.           |            |
|     |  |       display, --fg + --accent-bright  |            |
|     |  |   [ Return to Main Menu ] (primary)    |            |
|     |  |   [ View Final State ]    (secondary)  |            |
|     |  |               bottom-right corner bracket |          |
|     |  +----------------------------------------+            |
|     └─                                                       |
|         2px solid --accent border, panelGradient (surface-lite -> bg-deep)|
|                                                              |
+--------------------------------------------------------------+
```

- Outer: `Positioned.fill` → `Container(color: EditorialMonoclePalette.dialogScrim)` → `Center` → outer `Padding(24)` → `VictoryPanel`.
- Scrim color resolves through `EditorialMonoclePalette.dialogScrim` (canonical `--dialog-scrim` token; see [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Dialog scrim).
- Panel container: 2px solid `--accent` border, `surface-lite → bg-deep` vertical gradient (`CtGradients.victoryPanelGradient`), inner padding `24` logical px, max-width `460`, intrinsic-min height. Two `--accent` asymmetric corner brackets — top-left (1.5px borders, ~20x24 box, 4px inset) and bottom-right (1.5px borders, ~20x24 box, 4px inset) at 0.7 alpha.
- Laurel row: three Unicode glyphs in `--accent` at 0.6 alpha — `☜` `☆` `☞` (or visually equivalent decorative cluster) rendered with the display font.
- Title: `appL10n(context).victory_military` when `victory.type == VictoryType.military` (only variant implemented). Display font (Cinzel slot — `headlineSmall`), color `--accent`, letter-spacing 0.06em, upper-cased.
- Brass divider: `CtBrassDivider` between title and body.
- Body: `appL10n(context).victory_winnerOnTurn(winner.displayName, victory.turnNumber)`. Display font, color `--fg`. Winner name highlighted in `--accent-bright` is reserved for a future enhancement (the localized line is rendered as a single span until the winner-substring helper lands).
- Buttons: two `CtNinePatchButton`s in a `Row` with 12 logical-px spacing — "Return to Main Menu" (primary, default styling), "View Final State" (secondary; rendered with the muted/secondary text variant — label color `--muted`).
- No Material buttons.

Winner resolution: `game.playerById(victory.winnerPlayerId) ?? game.players.first`.

### Narrow viewport (`< kNarrowBreakpoint`)

Below the canonical in-game shell narrow breakpoint (`kNarrowBreakpoint = 600` dp; see [mobile-adaptation.md](mobile-adaptation.md) § In-game shell) the panel **compacts** to mirror the mockup's `clamp()`-driven behaviour at small viewport widths. The change is one-shot at the breakpoint (no progressive `clamp` in Flutter):

| Element            | Narrow (`< 600` dp)           | Default (`≥ 600` dp)                  | Source                                                                                                |
|--------------------|-------------------------------|---------------------------------------|-------------------------------------------------------------------------------------------------------|
| Laurel font size   | 24 logical px                 | 28 logical px                         | `OVL20001-game-victory-overlay.html` `.laurel { font-size:clamp(24px,5vw,36px) }` (lower-bound pin)   |
| Title style        | Theme `titleMedium` (`~16-18` px) + `--accent`, upper-cased | Theme `headlineSmall` + `--accent`, upper-cased | Mockup `.victory-type { font-size:clamp(16px,3vw,22px) }` (lower-bound pin) |
| Body style         | Theme `bodyMedium` (`~14` px) + `--fg` | Theme `bodyLarge` + `--fg` | Mockup `.victory-body { font-size:clamp(14px,2.2vw,18px) }` (lower-bound pin) |
| Action row layout  | Vertical `Column` (full-width buttons stacked top-to-bottom, 8 dp gap) | `Wrap` row (`12` dp spacing, runs wrap when needed) | Mockup `.victory-actions { display:flex; flex-wrap:wrap }` collapses to a single column at narrow widths because each `.victory-btn` keeps `min-width:clamp(120px,25vw,170px)` |

Wide chrome (corner brackets, brass border, scrim wash, gradient) is unchanged. Padding (`28 px`), max-width (`460` dp), and the `CtBrassDivider` row remain identical so the panel's structural shape stays stable across the breakpoint.

Implementers MUST drive the narrow flag from `MediaQuery.sizeOf(context).width < kNarrowBreakpoint` (the same source the rest of the in-game shell uses) so that one viewport rebuild flips every measurement together.

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

- `CtBrassDivider` (`app/lib/widgets/ct_brass_divider.dart`).
- `CtGradients.victoryPanelGradient` (`app/lib/widgets/ct_gradients.dart`).
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`).
- `EditorialMonoclePalette` (`app/lib/config/editorial_monocle_palette.dart`) — `accent`, `accentBright`, `fg`, `muted`, `dialogScrim`, `surfaceLite`, `bgDeep` tokens.
- Localized strings: `victory_military`, `victory_winnerOnTurn`, `victory_returnToMainMenu`, `victory_viewFinalState` via `appL10n(context)`.

---

## Acceptance Criteria (Given–When–Then)

- Given `Game.victory` is a `VictoryState` with `type: VictoryType.military`, `turnNumber: 12`, and a resolvable `winnerPlayerId`,
  When `GameScreen` builds with that game,
  Then the UI layer renders `VictoryOverlay` above the game stack and shows the military victory label and a winner sentence containing turn `12`.

- Given `VictoryOverlay` is visible,
  When the user taps "View final state",
  Then the overlay is removed from the widget tree (`Military victory` text is no longer found) and `Game.victory` remains non-null.

- Given `VictoryOverlay` is visible and an `AppEventBus` is wired,
  When the user taps "Return to main menu",
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

- Given `VictoryOverlay` is mounted,
  When the underlying widget tree is built,
  Then the scrim background color resolves to `EditorialMonoclePalette.dialogScrim` (the canonical `--dialog-scrim` token; no `Colors.black54` literal in the widget code).

- Given `VictoryPanel` is mounted,
  When the panel surface is built,
  Then the surface paints `CtGradients.victoryPanelGradient` (`surface-lite → bg-deep` top-to-bottom) under a 2px solid `--accent` border, and renders both the top-left and bottom-right `--accent` corner brackets as decorative overlays.

- Given `VictoryPanel` is mounted,
  When the title row is built,
  Then a `CtBrassDivider` instance is present in the widget tree between the victory-type label and the winner sentence.

- Given `VictoryPanel` is mounted with a viewport width strictly below `kNarrowBreakpoint` (`600` dp),
  When the panel is built,
  Then the action row renders as a vertical `Column` containing both `CtNinePatchButton`s (no `Wrap` widget on the action row), and the laurel row renders its three glyphs at `24` logical-px font size.

- Given `VictoryPanel` is mounted with a viewport width greater than or equal to `kNarrowBreakpoint` (`600` dp),
  When the panel is built,
  Then the action row renders inside a `Wrap` widget (regression guard for the wide-layout `flex-wrap:wrap` mockup behaviour), and the laurel row renders its three glyphs at `28` logical-px font size.

---

## Widgetbook

Catalog folder: **Victory** (registered in `app/lib/widgetbook/catalog.dart` via `victoryUiDirectories`). Use cases:

1. **Victory panel — military (default):** `VictoryPanel` with `getDebugInitGameResult().game`, sample `VictoryState` (`VictoryType.military`, turn `45`, first player as winner), and a throwaway `AppEventBus`.
2. **Victory overlay — full scrim (optional):** `VictoryOverlay` inside a fixed-size `Stack` to show the dimmed full-screen presentation.

Automated widget tests: `app/test/victory_overlay_test.dart`.
