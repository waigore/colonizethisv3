# Trade Screen

**Screen ID:** `GAME60001` — stable; do not reassign.
**SPEC/ui** — Full-screen World Market trade surface. Implementation: `app/lib/features/game/screens/trade_screen.dart`.
**Widgetbook:** `Trade Screen` → `app/lib/widgetbook/catalog.dart`. Game rules: [world-market.md](../game/world-market.md); resolution algorithm: [world-market-resolution.md](../program/world-market-resolution.md); core data model deferred to issue [#2989](https://github.com/waigore/colonizethisv3/issues/2989); UI scope tracked in issue [#2993](https://github.com/waigore/colonizethisv3/issues/2993). Parent design: [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988).

> **Status:** Draft. This document records the contract for the scaffold slices: E1+E2+E3 ship the route, screen ID, left-rail button, and dark editorial-monocle chrome; E4 (this slice) lands the durable two-tab body structure (Market + Deal Book) with placeholder panels inside each tab. The Market tab's live commodity rows + cargo indicator and the Deal Book tab's live ledger arrive in follow-up slices once #2989 introduces `WorldMarketState` / `TradeOrder` (#2993 E5 + E6).

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
- `TradeScreen.tabsBodyKey` — `ValueKey<String>('tradeScreenTabsBody')` (root of the two-tab Market + Deal Book body; replaces the prior `placeholderBodyKey` from the E1+E2+E3 scaffold and remains stable when E5/E6 swap each tab's body for the live content).
- `TradeScreen.marketTabBodyKey` — `ValueKey<String>('tradeScreenMarketTabBody')` (Market tab body root; visible by default).
- `TradeScreen.dealBookTabBodyKey` — `ValueKey<String>('tradeScreenDealBookTabBody')` (Deal Book tab body root; visible after the user taps the `Deal Book` label).

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

### Body (current scaffold — `_TradeScreenTabsBody`)

```
Padding (16 dp)
└── CtPanel (padding 16 dp)            // dark editorial-monocle surface
    └── CtTabStrip                     // SPEC § Pixel-art component catalog → CtTabStrip
        ├── tabLabels: ['Market', 'Deal Book']
        └── tabViews (IndexedStack)
            ├── _MarketTabPlaceholder  // keyed `tradeScreenMarketTabBody`
            │   └── CtPanel
            │       ├── Text 'Market' (titleMedium, --accent)
            │       └── Text muted scaffold copy (bodyMedium, --muted)
            └── _DealBookTabPlaceholder // keyed `tradeScreenDealBookTabBody`
                └── CtPanel
                    ├── Text 'Deal Book' (titleMedium, --accent)
                    └── Text muted scaffold copy (bodyMedium, --muted)
```

The two-tab body is the durable structure E5 (Market) and E6 (Deal Book) replace the placeholder panels in. The `CtTabStrip` widget owns the dark-chrome label band (selected = `--accentBright` text on `--accentDim` 25 % alpha background; unselected = `--muted` text on `--surface` 50 % alpha background; 1 px `--accent` / `--accentDim` border per `pixel-art-ui-catalog.md` § `CtTabStrip`) and the `IndexedStack` that mounts both placeholder bodies so widget tests can reach either tab via `find.byKey` regardless of which is currently visible. Default selection is the **Market** tab (index 0).

Each placeholder body uses canonical palette tokens only and carries copy naming the parent and depending issues (`#2989`, `#2990`, `#2993` E5 / E6) so reviewers can see which follow-up unlocks each tab's live content.

### Body (planned — `#2993` E5 + E6)

The interactive layout per parent design (`#2988` § UI Design) replaces the placeholder bodies inside the same tab strip once #2989 data types are available:

- **Market tab (E5):** scrollable list of all 22 tradeable commodities (28 total minus 5 riches minus spices) — each row a commodity name + icon, last market price, bid/offer toggle, quantity stepper, priority dropdown, and inline previous-turn aggregate volumes (`Bids N / Offers M`). Persistent header strip shows `Cargo remaining: X` and clamps any bid stepper that would exceed the cross-commodity cap.
- **Deal Book tab (E6):** two-panel ledger of the previous turn's filled / partial / unfilled bids and offers, with treasury totals.

When E5 / E6 land, replace each placeholder block in this document with the live wireframe (commodity row, ledger row, cross-commodity cargo behaviour, priority-dropdown source `#2989 kMaxTradePriority`) without changing the surrounding tab strip / `CtPanel` / padding chrome — the tab structure stays the same.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Left rail Trade button | `kEmpireTradeButtonKey` tapped | `NavigateToRouteEvent(Routes.trade, …)` → push `TradeScreen`. |
| Direct route (deep link / test harness) | Caller supplies `RoutePaths.trade` settings with `game` + `humanPlayerId` args | `_buildGameRoute` resolves player and mounts `TradeScreen`. |

### User actions → outcomes (scaffold slice — E1+E2+E3+E4)

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| `CtTopBar` back affordance | Always | `Navigator.maybePop()` | Returns to the previous route (in-game shell). |
| Tab label `Market` | Always (default selection) | `CtTabStrip` internal `setState(selectedIndex = 0)` | `IndexedStack` foregrounds the Market tab body keyed `tradeScreenMarketTabBody`. |
| Tab label `Deal Book` | Always | `CtTabStrip` internal `setState(selectedIndex = 1)` | `IndexedStack` foregrounds the Deal Book tab body keyed `tradeScreenDealBookTabBody`. |

No bid/offer/priority controls render in this slice — they ship with E5/E6.

### Future user actions (`#2993` E5 + E6)

The interactive contract is documented in `#2988` § UI Design (Market tab toggles, quantity steppers, priority dropdowns, cargo indicator behaviour, Deal Book read-only ledger, observe-mode disabling). Mirror those rows into this **Behavior** table when E5/E6 land — the tab-switch rows above stay untouched because the tab structure does not change.

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `GAME60001` | Default — Market tab (a) | Human player active; Market tab selected (initial state) | Dark chrome + `_TradeScreenTabsBody` with the Market tab (`tradeScreenMarketTabBody`) foregrounded inside `CtTabStrip.IndexedStack`. |
| `GAME60001` | Default — Deal Book tab (b) | Human player active; user has tapped the `Deal Book` tab label | Dark chrome + `_TradeScreenTabsBody` with the Deal Book tab (`tradeScreenDealBookTabBody`) foregrounded inside `CtTabStrip.IndexedStack`. |
| `GAME60001` | Observe mode (c) | `shellPanelsNotDefined(ref) == true` | Body switches to `ObserveModeNotDefinedPanel(title: 'Trade')`; the tab strip (and both placeholder bodies) are not mounted under this branch. |

When E5/E6 land, the variant table stays as is — only each tab body's render description changes from "placeholder" to the live commodity list / Deal Book ledger.

---

## Components

- `TradeScreen` (`app/lib/features/game/screens/trade_screen.dart`) — top-level shell host.
- `CtGameFeatureScreenShell` (`app/lib/widgets/ct_game_feature_screen_shell.dart`) — opt-in dark chrome wrapper that owns the `GameToUIBusListener` and live `currentGameProvider` swap.
- `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtTopBar`) — dark editorial-monocle top bar carrying the back affordance, icon, and title.
- `StrictAssetIcon` (`app/lib/widgets/strict_asset_icon.dart`) — renders the 32 × 32 source PNG at the 18 × 18 top-bar size.
- `CtPanel` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtPanel`) — outer surface for the tabs body and inner surface for each tab placeholder.
- `CtTabStrip` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtTabStrip`) — dark editorial-monocle tab strip hosting the `Market` and `Deal Book` labels above the `IndexedStack` of tab bodies.
- `ObserveModeNotDefinedPanel` (`app/lib/features/game/widgets/observe_mode_not_defined_panel.dart`) — shared observe-mode sentinel.

---

## Widgetbook

Folder name **Trade Screen** in `app/lib/widgetbook/catalog.dart` (registered via `tradeScreenDirectories`).

Use cases for the scaffold slices (E1+E2+E3+E4):

| Use case | Proves |
|----------|--------|
| `Scaffold (Market tab)` | Default mount of `TradeScreen` with the dark `CtTopBar` and `_TradeScreenTabsBody` showing the Market tab placeholder selected (the initial state visited by every gameplay session). |
| `Scaffold (mobile)` | Same default story inside `mobileViewport` (360 × 640 dp) to satisfy the per-spec mobile use case (`SPEC/ui/mobile-adaptation.md`). |

E5+ slices append `Market tab — live commodity list`, `Market tab — cargo warning`, `Deal Book tab — mixed fills`, etc. as the bodies land. The tab structure remains the same; only each tab body's content advances.

---

## Acceptance criteria

### Scaffold slice (`#2993` E1+E2+E3)

- **Given** the game screen with the left rail visible, **when** the player taps the `kEmpireTradeButtonKey` button (positioned directly below the Production button and above Civilian Units), **then** the in-game shell emits `NavigateToRouteEvent(Routes.trade, {'game', 'humanPlayerId'})` so the route table mounts `TradeScreen`.
- **Given** the app route registry, **when** the framework receives `RouteSettings(name: RoutePaths.trade, arguments: {'game', 'humanPlayerId'})`, **then** `Routes.generate` returns a `MaterialPageRoute<void>` whose builder constructs `TradeScreen(game: game, player: game.playerById(humanPlayerId)!)`.
- **Given** the `TradeScreen` is mounted and `shellPanelsNotDefined(ref)` returns `true` (global observe mode), **then** the body widget tree contains an `ObserveModeNotDefinedPanel` whose `title` is `Trade` and **does not** contain the `tradeScreenTabsBody` key.
- **Given** the screen registry, **when** the trade row is read, **then** the ID is `GAME60001`, the spec link is `trade-screen.md`, the code path is `app/lib/features/game/screens/trade_screen.dart`, and the status is `draft` until E5+ lands.

### Tab scaffold slice (`#2993` E4)

- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **then** the widget tree contains the `tradeScreenTopBar` key (an instance of `CtTopBar` with title `Trade` and back-label `Map`) and the `tradeScreenTabsBody` body keyed widget that hosts a single `CtTabStrip`.
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **then** the `CtTabStrip` inside the `tradeScreenTabsBody` widget renders exactly two tab labels in order: the literal `Market` followed by the literal `Deal Book`.
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active and no tab has been tapped since mount, **then** the Market tab body keyed `tradeScreenMarketTabBody` is the on-stage (foregrounded) child of the `CtTabStrip` `IndexedStack` (default selection is index 0) and its `Text 'Market'` title renders in `EditorialMonoclePalette.accent`.
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **when** the user taps the `Deal Book` tab label, **then** the `CtTabStrip` `IndexedStack` foregrounds the Deal Book tab body keyed `tradeScreenDealBookTabBody` and its `Text 'Deal Book'` title renders in `EditorialMonoclePalette.accent`.
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **then** the off-stage tab body (Deal Book by default; Market after the user taps `Deal Book`) is still present in the element tree behind a `Visibility(visible: false)` wrapper inserted by `IndexedStack` (`find.byKey(<key>, skipOffstage: false)` resolves to one widget) so the inactive tab keeps its state and E5/E6 can swap each body in place without remounting the strip.
- **Given** the `TradeScreen` is mounted and `shellPanelsNotDefined(ref)` returns `true` (global observe mode), **then** neither the `tradeScreenTabsBody`, `tradeScreenMarketTabBody`, nor `tradeScreenDealBookTabBody` keys appear in the widget tree (only the `ObserveModeNotDefinedPanel` and the dark `CtTopBar` are mounted).

### Minimum viewport pin (`#2870` S10 — extends to GAME60001)

- **Given** the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, **when** `TradeScreen` is rendered against the `getDebugInitGameResult()` fixture under the default `shellPlayerContextProvider` (`showPlayerChrome: true`), **then** `WidgetTester.takeException()` returns `null`, the dark `CtTopBar` keyed `TradeScreen.topBarKey` renders with literal title `Trade` and back label `Map`, and the tabs body keyed `TradeScreen.tabsBodyKey` renders the Market / Deal Book tab strip within the 320 dp column without horizontal overflow (per [mobile-adaptation.md](mobile-adaptation.md) § 7).
- **Given** the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, **when** `TradeScreen` is rendered against the same fixture under a `shellPlayerContextProvider` override whose `showPlayerChrome` is `false` (global observe), **then** `WidgetTester.takeException()` returns `null`, the dark `CtTopBar` still paints, the `ObserveModeNotDefinedPanel` sentinel with literal title `Trade` renders, and the tabs body keyed `TradeScreen.tabsBodyKey` is absent (the observe override only swaps the body; the chrome keeps its 320 dp overflow contract per [mobile-adaptation.md](mobile-adaptation.md) § 7).

### Full screen (`#2993` E5–E8 — implement when bodies land)

Migrate the parent-issue ACs from `#2988` § Acceptance criteria — UI into Given–When–Then rows under this section as each follow-up slice ships (bid/offer toggle, mutual exclusion, Deal Book ledger, cargo warning, observe-mode disabling).
