# Trade Screen

**Screen ID:** `GAME60001` — stable; do not reassign.
**SPEC/ui** — Full-screen World Market trade surface. Implementation: `app/lib/features/game/screens/trade_screen.dart`.
**Widgetbook:** `Trade Screen` → `app/lib/widgetbook/catalog.dart`. Game rules: [world-market.md](../game/world-market.md); resolution algorithm: [world-market-resolution.md](../program/world-market-resolution.md); core data model deferred to issue [#2989](https://github.com/waigore/colonizethisv3/issues/2989); UI scope tracked in issue [#2993](https://github.com/waigore/colonizethisv3/issues/2993). Parent design: [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988).

> **Status:** Draft. This document records the contract for the scaffold slices: E1+E2+E3 ship the route, screen ID, left-rail button, and dark editorial-monocle chrome; E4 lands the durable two-tab body structure (Market + Deal Book). The Market tab now renders the **read-only commodity table** (`#2993` E5a) sourced from `Game.worldMarketState` — one row per tradeable commodity with last market price + previous-turn aggregate `Bids / Offers` volumes. The interactive Market controls (bid/offer toggle, quantity stepper, priority dropdown, cargo-remaining indicator) ship in follow-up `#2993` E5 slices, and the Deal Book live ledger ships in `#2993` E6 once a per-player ledger surface lands on top of #2989 / #2990's `MarketActivity` + world-market turn phase.

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
- `TradeScreen.marketTabBodyKey` — `ValueKey<String>('tradeScreenMarketTabBody')` (Market tab body root; visible by default; spans the placeholder, the read-only commodity table from `#2993` E5a, and the future interactive controls).
- `TradeScreen.marketCommodityListKey` — `ValueKey<String>('tradeScreenMarketCommodityList')` (scrollable container inside the Market tab body hosting the per-commodity rows; introduced by `#2993` E5a).
- `TradeScreen.marketCommodityRowKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<commodityId>')` (per-row key so widget tests can pin a specific commodity without text matching; introduced by `#2993` E5a).
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

### Body (current — `_TradeScreenTabsBody`)

```
Padding (16 dp)
└── CtPanel (padding 16 dp)            // dark editorial-monocle surface
    └── CtTabStrip                     // SPEC § Pixel-art component catalog → CtTabStrip
        ├── tabLabels: ['Market', 'Deal Book']
        └── tabViews (IndexedStack)
            ├── _MarketTabContent      // keyed `tradeScreenMarketTabBody`
            │   └── SingleChildScrollView (keyed `tradeScreenMarketCommodityList`)
            │       └── Column (one row per tradeable commodity, 22 rows)
            │           └── Padding (keyed `tradeScreenMarketRow:<id>`)
            │               └── _MarketCommodityRow
            │                   ├── Row
            │                   │   ├── Text <displayName> (titleSmall, --accent)
            │                   │   └── Text <price | "—"> (titleSmall, --accentBright)
            │                   └── Text 'Bids N / Offers M' (bodySmall, --muted)
            └── _DealBookTabPlaceholder // keyed `tradeScreenDealBookTabBody`
                └── CtPanel
                    ├── Text 'Deal Book' (titleMedium, --accent)
                    └── Text muted scaffold copy (bodyMedium, --muted)
```

The two-tab body is the durable structure each follow-up Market slice (E5b interactive controls, E5c cargo indicator) and Deal Book slice (E6) keep building inside. The `CtTabStrip` widget owns the dark-chrome label band (selected = `--accentBright` text on `--accentDim` 25 % alpha background; unselected = `--muted` text on `--surface` 50 % alpha background; 1 px `--accent` / `--accentDim` border per `pixel-art-ui-catalog.md` § `CtTabStrip`) and the `IndexedStack` that mounts both tab bodies so widget tests can reach either tab via `find.byKey` regardless of which is currently visible. Default selection is the **Market** tab (index 0).

The Market tab body is the read-only commodity table (`#2993` E5a). It iterates `CommodityCatalog.all` filtered to the tradeable subset — every commodity whose `CommodityCategory` is **not** `riches` and whose id is **not** `spices` (22 rows total per [`world-market.md`](../game/world-market.md) §Tradeable commodities). Rows are sorted alphabetically by display name (case-insensitive) so the order is deterministic for widget tests and Widgetbook stories. Each row reads:

- the **commodity display name** in `--accent` (`titleSmall`),
- the **last market price** from `Game.worldMarketState.prices[commodityId]` in `--accentBright` (`titleSmall`), formatted to one decimal place; the canonical em-dash glyph `—` renders when the commodity is absent from `prices` (typically only in tests / Widgetbook stories that instantiate `WorldMarketState.empty`),
- the **previous-turn aggregate volume** line `Bids X / Offers Y` from `Game.worldMarketState.lastTurnActivity[commodityId]` in `--muted` (`bodySmall`); commodities absent from `lastTurnActivity` default to `Bids 0 / Offers 0` so the column reads consistently.

The Deal Book placeholder body uses canonical palette tokens only and carries copy naming the parent and depending issues (`#2989`, `#2990`, `#2993` E6) so reviewers can see which follow-up unlocks its live ledger.

### Body (planned — follow-up `#2993` E5 + E6)

The Market read-only table above is the foundation. Follow-up slices extend each commodity row in place inside the same tab strip:

- **Market tab — interactive controls (`#2993` E5b):** bid/offer toggle (segmented control), quantity stepper, priority dropdown bound to `#2989 kMaxTradePriority`. The toggle, stepper, and dropdown extend each row in place; the row keying and ordering contract above is preserved so tests pinning row keys continue to resolve.
- **Market tab — cargo indicator (`#2993` E5c):** persistent header strip above the commodity list shows `Cargo remaining: X` and clamps any bid stepper that would exceed the cross-commodity cap.
- **Deal Book tab (E6):** two-panel ledger of the previous turn's filled / partial / unfilled bids and offers, with treasury totals.

When E5b / E5c / E6 land, replace the relevant subsections of this document (row content, header strip, ledger layout) without changing the surrounding tab strip / `CtPanel` / padding chrome — the tab structure stays the same.

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
| `GAME60001` | Default — Market tab (a) | Human player active; Market tab selected (initial state) | Dark chrome + `_TradeScreenTabsBody` with the Market tab (`tradeScreenMarketTabBody`) foregrounded; the body is the read-only commodity table keyed `tradeScreenMarketCommodityList` with one `tradeScreenMarketRow:<id>` per tradeable commodity (`#2993` E5a). |
| `GAME60001` | Default — Deal Book tab (b) | Human player active; user has tapped the `Deal Book` tab label | Dark chrome + `_TradeScreenTabsBody` with the Deal Book tab (`tradeScreenDealBookTabBody`) foregrounded; the body remains the placeholder `CtPanel` until `#2993` E6 lands the live ledger. |
| `GAME60001` | Observe mode (c) | `shellPanelsNotDefined(ref) == true` | Body switches to `ObserveModeNotDefinedPanel(title: 'Trade')`; the tab strip (and both tab bodies) are not mounted under this branch. |

When the follow-up E5b/E5c/E6 slices land, the variant table stays as is — only each tab body's render description changes from "placeholder" / "read-only commodity table" to the live interactive Market controls / Deal Book ledger.

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

Use cases for the current slice (E1+E2+E3+E4+E5a):

| Use case | Proves |
|----------|--------|
| `Scaffold (Market tab)` | Default mount of `TradeScreen` with the dark `CtTopBar` and `_TradeScreenTabsBody` showing the Market tab read-only commodity table selected (the initial state visited by every gameplay session). |
| `Scaffold (mobile)` | Same default story inside `mobileViewport` (360 × 640 dp) to satisfy the per-spec mobile use case (`SPEC/ui/mobile-adaptation.md`). |

Follow-up E5b/E5c/E6 slices append `Market tab — interactive controls`, `Market tab — cargo warning`, `Deal Book tab — mixed fills`, etc. as the bodies land. The tab structure remains the same; only each tab body's content advances.

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

### Market tab — read-only commodity table (`#2993` E5a)

- **Given** the `TradeScreen` is mounted with a human player, observe mode is **not** active, and `Game.worldMarketState` is otherwise unconstrained, **then** the Market tab body keyed `tradeScreenMarketTabBody` contains exactly one `tradeScreenMarketCommodityList` widget that hosts exactly 22 rows keyed `tradeScreenMarketRow:<commodityId>` — one row for every `Commodity` in `CommodityCatalog.all` whose `category` is not `CommodityCategory.riches` and whose `id` is not `'spices'`.
- **Given** the same conditions, **then** the row order inside `tradeScreenMarketCommodityList` is the deterministic alphabetical order of the tradeable commodities by display name (case-insensitive; falling back to commodity id when the display name is null) — every row's `Offset.dy` is strictly greater than the previous row's `Offset.dy`.
- **Given** the same conditions and `Game.worldMarketState.prices` contains an entry `{'timber': 30.0}` (and no entry for `'iron'`), **when** the Market tab body renders, **then** the `tradeScreenMarketRow:timber` row contains the text `30.0` (one decimal place) and the `tradeScreenMarketRow:iron` row contains the canonical em-dash glyph `—` as the price text.
- **Given** the same conditions and `Game.worldMarketState.lastTurnActivity` contains `{'timber': MarketActivity(totalBidQuantity: 12, totalOfferQuantity: 8)}` (and no entry for `'fabric'`), **when** the Market tab body renders, **then** the `tradeScreenMarketRow:timber` row contains the text `Bids 12 / Offers 8` and the `tradeScreenMarketRow:fabric` row contains the text `Bids 0 / Offers 0` (zero-default for commodities absent from the activity map).
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **then** the `tradeScreenMarketCommodityList` widget is present **only** under the `tradeScreenMarketTabBody` subtree (not under the off-stage `tradeScreenDealBookTabBody` subtree, even when reached via `find.byKey(..., skipOffstage: false)`).

### Full screen (follow-up `#2993` E5b / E5c / E6 — implement when bodies land)

Migrate the remaining parent-issue ACs from `#2988` § Acceptance criteria — UI into Given–When–Then rows under this section as each follow-up slice ships (bid/offer toggle, mutual exclusion, Deal Book ledger, cargo warning, observe-mode disabling).
