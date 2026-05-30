# Trade Screen

**Screen ID:** `GAME60001` — stable; do not reassign.
**SPEC/ui** — Full-screen World Market trade surface. Implementation: `app/lib/features/game/screens/trade_screen.dart`.
**Widgetbook:** `Trade Screen` → `app/lib/widgetbook/catalog.dart`. Game rules: [world-market.md (planned)](../game/world-market.md); core data model deferred to issue [#2989](https://github.com/waigore/colonizethisv3/issues/2989); UI scope tracked in issue [#2993](https://github.com/waigore/colonizethisv3/issues/2993). Parent design: [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988).

> **Status:** Draft. This document records the contract for the scaffold slice that ships the route, screen ID, left-rail button, and dark editorial-monocle chrome. The full Market and Deal Book tabs land in follow-up slices once #2989 introduces `WorldMarketState` / `TradeOrder`; this spec is the canonical location to extend when they do.

---

## Widget contract

`TradeScreen` is a thin `ConsumerWidget` that mounts `CtGameFeatureScreenShell` with a dark `CtTopBar` and a body that switches on the shared observe-mode predicate:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `game` | `Game` | yes | Display game (the shell upgrades to the live `currentGameProvider` value when the listener is attached). |
| `player` | `Player` | yes | Human player whose treasury / stockpile / cargo capacity the Market tab will surface in follow-up slices. |

The screen exposes static keys consumed by widget tests:

- `TradeScreen.screenId` — `UiScreenIds.tradeScreen` (`GAME60001`).
- `TradeScreen.topBarKey` — `ValueKey<String>('tradeScreenTopBar')`.
- `TradeScreen.placeholderBodyKey` — `ValueKey<String>('tradeScreenScaffoldPlaceholder')` (current scaffold body; will be replaced when E4+ Market/Deal-Book bodies ship).

---

## Trigger conditions

- **Left rail icon (in-game shell):** `GameMapEmpireLeftRail` renders an `_EmpireRailButton` keyed `kEmpireTradeButtonKey` directly below the Production button and above Civilian Units. Tapping emits `NavigateToRouteEvent(Routes.trade, {'game', 'humanPlayerId'})`.
- **Route table:** `Routes.generate(RouteSettings)` dispatches `RoutePaths.trade` (`/game/trade`) into `_buildGameRoute`, which resolves the human `Player` from the route arguments and instantiates `TradeScreen(game, player)`.
- **Observe mode:** When `shellPanelsNotDefined(ref)` is true the body short-circuits to `ObserveModeNotDefinedPanel(title: 'Trade')` — matching the production / diplomacy / technology behaviour.

The screen is **not** opened from a Flame canvas overlay, the side menu, or any other route in this scope. Cross-screen orchestration uses `AppEventBus` per `SPEC/program/app-ui-wiring.md`.

---

## Layout / wireframe

### Top bar (every viewport)

`CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog → `CtTopBar`):

- **Back affordance:** `CtBackButton` chevron-left glyph followed by the literal label `Map` so the affordance reads `← Map`. Tapping pops via `Navigator.maybePop()`.
- **Icon + title:** 18 × 18 logical-px pixel-art trade icon `assets/icons/32/ui_icon_trade.png` rendered between the back affordance and the title. Title literal `Trade`, dark-theme `titleMedium` slot (Cinzel display family per `AppThemes.editorialMonocle`).
- **Height + chrome:** Fixed 36 px high (`CtTopBar.height`), filled with `CtGradients.topBarGradient`, 1 px `--accent-dim` bottom border. No hardcoded colours; all chrome resolves through `EditorialMonoclePalette`.

### Body (current scaffold slice — `_TradeScreenScaffoldPlaceholder`)

```
Padding (24 dp)
└── CtPanel (padding 24 dp)
    └── Column (start-aligned)
        ├── Text 'World Market' (titleMedium, --accent)
        ├── SizedBox 12
        └── Text scaffold copy (bodyMedium, --muted)
```

The placeholder paints the standard dark `CtPanel` chrome and uses canonical palette tokens only. It carries the placeholder copy that names the parent and depending issues (`#2989`, `#2993`) so reviewers can see at a glance which follow-up unlocks the real body.

### Body (planned — `#2993` E4–E6)

The interactive layout per parent design (`#2988` § UI Design) will replace the placeholder once #2989 data types are available:

- **Market tab:** scrollable list of all 22 tradeable commodities (28 total minus 5 riches minus spices) — each row a commodity name + icon, last market price, bid/offer toggle, quantity stepper, priority dropdown, and inline previous-turn aggregate volumes (`Bids N / Offers M`). Persistent header strip shows `Cargo remaining: X` and clamps any bid stepper that would exceed the cross-commodity cap.
- **Deal Book tab:** two-panel ledger of the previous turn's filled / partial / unfilled bids and offers, with treasury totals.

When that layout lands, replace the **Layout / wireframe** placeholder block in this document with the full wireframe, the cross-commodity cargo behaviour, the priority-dropdown source (#2989 `kMaxTradePriority`), and the Widgetbook story names.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Left rail Trade button | `kEmpireTradeButtonKey` tapped | `NavigateToRouteEvent(Routes.trade, …)` → push `TradeScreen`. |
| Direct route (deep link / test harness) | Caller supplies `RoutePaths.trade` settings with `game` + `humanPlayerId` args | `_buildGameRoute` resolves player and mounts `TradeScreen`. |

### User actions → outcomes (scaffold slice)

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| `CtTopBar` back affordance | Always | `Navigator.maybePop()` | Returns to the previous route (in-game shell). |

No bid/offer/priority controls render in this slice — they ship with E4+.

### Future user actions (`#2993` E4–E6)

The interactive contract is documented in `#2988` § UI Design (Market tab toggles, quantity steppers, priority dropdowns, cargo indicator behaviour, Deal Book read-only ledger, observe-mode disabling). Mirror those rows into this **Behavior** table when E4+ lands.

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `GAME60001` | Default | Human player active | Dark chrome + scaffold body (or Market/Deal-Book tabs once E4+ lands). |
| `GAME60001` | Observe mode | `shellPanelsNotDefined(ref) == true` | Body switches to `ObserveModeNotDefinedPanel(title: 'Trade')`. |

When E4+ lands, add explicit `a` / `b` variant rows for the Market and Deal Book tabs (each `WidgetbookUseCase` should map to one row).

---

## Components

- `TradeScreen` (`app/lib/features/game/screens/trade_screen.dart`) — top-level shell host.
- `CtGameFeatureScreenShell` (`app/lib/widgets/ct_game_feature_screen_shell.dart`) — opt-in dark chrome wrapper that owns the `GameToUIBusListener` and live `currentGameProvider` swap.
- `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtTopBar`) — dark editorial-monocle top bar carrying the back affordance, icon, and title.
- `StrictAssetIcon` (`app/lib/widgets/strict_asset_icon.dart`) — renders the 32 × 32 source PNG at the 18 × 18 top-bar size.
- `CtPanel` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtPanel`) — surface for the scaffold placeholder body.
- `ObserveModeNotDefinedPanel` (`app/lib/features/game/widgets/observe_mode_not_defined_panel.dart`) — shared observe-mode sentinel.

---

## Widgetbook

Folder name **Trade Screen** in `app/lib/widgetbook/catalog.dart` (registered via `tradeScreenDirectories`).

Use cases for the scaffold slice:

| Use case | Proves |
|----------|--------|
| `Scaffold (placeholder)` | Default mount of `TradeScreen` with the dark `CtTopBar`, scaffold body, and editorial-monocle palette. |
| `Scaffold (mobile)` | Same scaffold inside `mobileViewport` (360 × 640 dp) to satisfy the per-spec mobile use case (`SPEC/ui/mobile-adaptation.md`). |

E4+ slices append `Market tab — default`, `Market tab — cargo warning`, `Deal Book tab — mixed fills`, etc. as the bodies land.

---

## Acceptance criteria

### Scaffold slice (`#2993` E1+E2+E3)

- **Given** the game screen with the left rail visible, **when** the player taps the `kEmpireTradeButtonKey` button (positioned directly below the Production button and above Civilian Units), **then** the in-game shell emits `NavigateToRouteEvent(Routes.trade, {'game', 'humanPlayerId'})` so the route table mounts `TradeScreen`.
- **Given** the app route registry, **when** the framework receives `RouteSettings(name: RoutePaths.trade, arguments: {'game', 'humanPlayerId'})`, **then** `Routes.generate` returns a `MaterialPageRoute<void>` whose builder constructs `TradeScreen(game: game, player: game.playerById(humanPlayerId)!)`.
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **then** the widget tree contains the `tradeScreenTopBar` key (an instance of `CtTopBar` with title `Trade` and back-label `Map`) and the `tradeScreenScaffoldPlaceholder` body keyed widget.
- **Given** the `TradeScreen` is mounted and `shellPanelsNotDefined(ref)` returns `true` (global observe mode), **then** the body widget tree contains an `ObserveModeNotDefinedPanel` whose `title` is `Trade` and **does not** contain the `tradeScreenScaffoldPlaceholder` key.
- **Given** the screen registry, **when** the trade row is read, **then** the ID is `GAME60001`, the spec link is `trade-screen.md`, the code path is `app/lib/features/game/screens/trade_screen.dart`, and the status is `draft` until E4+ lands.

### Full screen (`#2993` E4–E8 — implement when bodies land)

Migrate the parent-issue ACs from `#2988` § Acceptance criteria — UI into Given–When–Then rows under this section as each follow-up slice ships (bid/offer toggle, mutual exclusion, Deal Book ledger, cargo warning, observe-mode disabling).
