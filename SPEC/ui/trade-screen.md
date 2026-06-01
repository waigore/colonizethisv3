# Trade Screen

**Screen ID:** `GAME60001` — stable; do not reassign.
**SPEC/ui** — Full-screen World Market trade surface. Implementation: `app/lib/features/game/screens/trade_screen.dart`.
**Widgetbook:** `Trade Screen` → `app/lib/widgetbook/catalog.dart`. Game rules: [world-market.md](../game/world-market.md); resolution algorithm: [world-market-resolution.md](../program/world-market-resolution.md); core data model deferred to issue [#2989](https://github.com/waigore/colonizethisv3/issues/2989); UI scope tracked in issue [#2993](https://github.com/waigore/colonizethisv3/issues/2993). Parent design: [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988).

> **Status:** Draft. This document records the contract for the scaffold slices: E1+E2+E3 ship the route, screen ID, left-rail button, and dark editorial-monocle chrome; E4 lands the durable two-tab body structure (Market + Deal Book). The Market tab now renders the **commodity table with interactive bid/offer/none direction selector + quantity stepper + cross-commodity cargo indicator and warning** (`#2993` E5a + E5b + E5c) sourced from `Game.worldMarketState`, `Game.worldState.fleets` (via `cargoHoldsForHomeFleet`), and `currentOrdersProvider`. Each row shows last market price + previous-turn aggregate `Bids / Offers` volumes alongside the interactive controls; the controls write `Orders.tradeOrdersByPlayerId[player.id]` via the pure helpers `applyTradeOrderForPlayer` / `removeTradeOrderForPlayer` in `colonizethis_logic`, and the cross-commodity bid total is clamped to the player's trade cargo capacity. The **Deal Book tab now renders the live two-panel ledger** (`#2993` E6) sourced from `Game.worldMarketState.lastTurnActivity[*].deals` (per-commodity `FilledDeal` ledger emitted by the world-market phase handler — `SPEC/program/world-market-resolution.md` § Step F) and `WorldMarketState.carryForward{Bids,Offers}ByFactionId[playerId]`. **Widgetbook coverage is now complete for the live ledger** (`#2993` E7) — the recommended *Deal Book tab — empty / mixed fills + carry-forwards / mobile (stacked)* use cases are registered under `tradeScreenDirectories` and opt into the Deal Book tab via the new `TradeScreen.initialTabIndex` parameter (forwarded to `CtTabStrip.initialTabIndex`). The remaining Market control (priority dropdown) ships when the data API in #2989 exposes `kMaxTradePriority`.

---

## Widget contract

`TradeScreen` is a thin `ConsumerWidget` that mounts `CtGameFeatureScreenShell` with a dark `CtTopBar` and a body that switches on the shared observe-mode predicate:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `game` | `Game` | yes | Display game (the shell upgrades to the live `currentGameProvider` value when the listener is attached). |
| `player` | `Player` | yes | Human player whose treasury / stockpile / cargo capacity the Market tab will surface in follow-up slices. |
| `initialTabIndex` | `int` | no | Initially-selected tab index for the body's `CtTabStrip` (`0` = Market, `1` = Deal Book). Defaults to `0` so the production route preserves the E4 contract (Market on first mount). Widgetbook stories and tests opt into the Deal Book tab (`1`) without simulating a label tap; the parameter forwards to `CtTabStrip.initialTabIndex` (Refs `#2993` E7). |

The screen exposes static keys consumed by widget tests:

- `TradeScreen.screenId` — `UiScreenIds.tradeScreen` (`GAME60001`).
- `TradeScreen.topBarKey` — `ValueKey<String>('tradeScreenTopBar')`.
- `TradeScreen.tabsBodyKey` — `ValueKey<String>('tradeScreenTabsBody')` (root of the two-tab Market + Deal Book body; replaces the prior `placeholderBodyKey` from the E1+E2+E3 scaffold and remains stable when E5/E6 swap each tab's body for the live content).
- `TradeScreen.marketTabBodyKey` — `ValueKey<String>('tradeScreenMarketTabBody')` (Market tab body root; visible by default; spans the placeholder, the read-only commodity table from `#2993` E5a, and the future interactive controls).
- `TradeScreen.marketCommodityListKey` — `ValueKey<String>('tradeScreenMarketCommodityList')` (scrollable container inside the Market tab body hosting the per-commodity rows; introduced by `#2993` E5a).
- `TradeScreen.marketCommodityRowKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<commodityId>')` (per-row key so widget tests can pin a specific commodity without text matching; introduced by `#2993` E5a).
- `TradeScreen.marketRowNoneChipKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<id>:none')` (per-row `None` direction chip; tap removes any staged trade order for the commodity — Refs `#2993` E5b).
- `TradeScreen.marketRowBidChipKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<id>:bid')` (per-row `Bid` direction chip; tap stages a `TradeOrderType.bid` for the commodity, replacing any prior offer — Refs `#2993` E5b).
- `TradeScreen.marketRowOfferChipKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<id>:offer')` (per-row `Offer` direction chip; tap stages a `TradeOrderType.offer` for the commodity, replacing any prior bid — Refs `#2993` E5b).
- `TradeScreen.marketRowDecrementKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<id>:decrement')` (per-row stepper `−` button; decrements `TradeOrder.quantity` by 1, clamped at `marketRowQuantityMin = 1` — Refs `#2993` E5b).
- `TradeScreen.marketRowIncrementKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<id>:increment')` (per-row stepper `+` button; increments `TradeOrder.quantity` by 1 — Refs `#2993` E5b).
- `TradeScreen.marketRowQuantityTextKey(CommodityId)` — `ValueKey<String>('tradeScreenMarketRow:<id>:quantity')` (per-row quantity readout; renders the staged `TradeOrder.quantity` or `marketRowQuantityIdleGlyph` (`—`) when no direction is staged — Refs `#2993` E5b).
- `TradeScreen.marketCargoIndicatorKey` — `ValueKey<String>('tradeScreenMarketCargoIndicator')` (persistent header strip above the commodity list; renders the `Cargo remaining: X` text where `X = max(0, tradeCargoCapacity − totalStagedBidQuantity)` for the human player — Refs `#2993` E5c).
- `TradeScreen.marketCargoWarningKey` — `ValueKey<String>('tradeScreenMarketCargoWarning')` (per-screen warning row rendered immediately below the cargo indicator when `remainingCargo == 0` AND `totalStagedBidQuantity > 0`; absent otherwise — Refs `#2993` E5c).
- `TradeScreen.dealBookTabBodyKey` — `ValueKey<String>('tradeScreenDealBookTabBody')` (Deal Book tab body root; visible after the user taps the `Deal Book` label; key remained stable when `#2993` E6 swapped the placeholder for the live ledger).
- `TradeScreen.dealBookContentKey` — `ValueKey<String>('tradeScreenDealBookContent')` (root of the live Deal Book two-panel ledger content sitting directly under `dealBookTabBodyKey` — Refs `#2993` E6).
- `TradeScreen.dealBookBidsPanelKey` — `ValueKey<String>('tradeScreenDealBookBidsPanel')` (left/top container for the player's previous-turn buying activity panel; always mounted under the live ledger root — Refs `#2993` E6).
- `TradeScreen.dealBookOffersPanelKey` — `ValueKey<String>('tradeScreenDealBookOffersPanel')` (right/bottom container for the player's previous-turn selling activity panel; always mounted under the live ledger root — Refs `#2993` E6).
- `TradeScreen.dealBookBidsTotalsKey` — `ValueKey<String>('tradeScreenDealBookBidsTotals')` (per-panel totals row inside the bids panel; renders `Total spent: N` where `N = Σ (deal.quantity × deal.pricePerUnit).round()` across the player's filled bids only — carry-forwards excluded; always mounted — Refs `#2993` E6).
- `TradeScreen.dealBookOffersTotalsKey` — `ValueKey<String>('tradeScreenDealBookOffersTotals')` (per-panel totals row inside the offers panel; renders `Total received: N` with the same aggregation rule applied to the player's filled sales; always mounted — Refs `#2993` E6).
- `TradeScreen.dealBookBidsEmptyKey` — `ValueKey<String>('tradeScreenDealBookBidsEmpty')` (per-panel empty-state copy mounted only when the player has zero filled buys **and** zero carry-forward bids — Refs `#2993` E6).
- `TradeScreen.dealBookOffersEmptyKey` — `ValueKey<String>('tradeScreenDealBookOffersEmpty')` (per-panel empty-state copy mounted only when the player has zero filled sales **and** zero carry-forward offers — Refs `#2993` E6).
- `TradeScreen.dealBookFilledRowKey(side, index)` — `ValueKey<String>('tradeScreenDealBookFilledRow:<side>:<index>')` where `side` is `dealBookSideBids` (`'bids'`) or `dealBookSideOffers` (`'offers'`) and `index` is the zero-based position in the per-side filled-deals list (Refs `#2993` E6).
- `TradeScreen.dealBookUnfilledRowKey(side, index)` — `ValueKey<String>('tradeScreenDealBookUnfilledRow:<side>:<index>')` per-row key for a carry-forward (unfilled) order on the per-side carry-forward list (Refs `#2993` E6).

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
            │   └── (Opacity + IgnorePointer when `canMutateViaUi == false`)
            │       └── Column
            │           ├── Text 'Cargo remaining: X' (`tradeScreenMarketCargoIndicator`,
            │           │     bodySmall, --accent — Refs #2993 E5c)
            │           ├── Text 'Cargo limit reached …' (`tradeScreenMarketCargoWarning`,
            │           │     bodySmall, --danger — only when remainingCargo == 0
            │           │     AND totalStagedBidQuantity > 0)
            │           └── SingleChildScrollView (keyed `tradeScreenMarketCommodityList`)
            │               └── Column (one row per tradeable commodity, 22 rows)
            │                   └── Padding (keyed `tradeScreenMarketRow:<id>`)
            │                       └── _MarketCommodityRow
            │                           ├── Row
            │                           │   ├── Text <displayName> (titleSmall, --accent)
            │                           │   └── Text <price | "—"> (titleSmall, --accentBright)
            │                           ├── Text 'Bids N / Offers M' (bodySmall, --muted)
            │                           └── Wrap (per-row interactive controls — Refs #2993 E5b)
            │                               ├── CtChoiceChip 'None'  (`...:none`)
            │                               ├── CtChoiceChip 'Bid'   (`...:bid`)
            │                               ├── CtChoiceChip 'Offer' (`...:offer`)
            │                               ├── _StepperButton '−'   (`...:decrement`)
            │                               ├── Text <quantity | '—'> (`...:quantity`)
            │                               └── _StepperButton '+'   (`...:increment`)
            └── _DealBookTabContent // keyed `tradeScreenDealBookTabBody`
                └── Container (keyed `tradeScreenDealBookContent`)
                    └── LayoutBuilder
                        ├── (constraints.maxWidth >= dealBookTwoPanelMinWidth)
                        │   Row
                        │       ├── Expanded → _DealBookPanel (bids)
                        │       ├── SizedBox(width: 12)
                        │       └── Expanded → _DealBookPanel (offers)
                        └── (otherwise)
                            Column
                                ├── _DealBookPanel (bids)
                                ├── SizedBox(height: 12)
                                └── _DealBookPanel (offers)

_DealBookPanel (keyed `tradeScreenDealBookBidsPanel` / `tradeScreenDealBookOffersPanel`)
└── CtPanel (padding 12 dp)
    └── Column
        ├── Text <panel title> (titleMedium, --accent)
        │   panel titles: 'Your bids' | 'Your offers'
        ├── (if filled.isEmpty AND unfilled.isEmpty)
        │   Text <empty-state copy> (bodySmall, --muted,
        │                            keyed dealBook{Side}EmptyKey)
        ├── (otherwise)
        │   ├── Text 'Filled' (labelMedium, --accentDim)
        │   ├── (if filled.isEmpty)
        │   │   Text 'No deals filled this turn.' (bodySmall, --muted)
        │   ├── (otherwise) for each filled deal at index i:
        │   │   _DealBookFilledRow (keyed
        │   │     dealBookFilledRowKey(side, i))
        │   │       └── Row
        │   │           ├── Expanded Text '<commodityId> — qty Q × P = N'
        │   │           │     (bodyMedium, --fg)
        │   │           └── Text <FRR | FTP tags> (bodySmall, --muted)
        │   ├── Text 'Unfilled (carry-forward)' (labelMedium, --accentDim)
        │   ├── (if unfilled.isEmpty)
        │   │   Text 'No orders carrying forward.' (bodySmall, --muted)
        │   └── (otherwise) for each carry-forward order at index i:
        │       _DealBookUnfilledRow (keyed
        │         dealBookUnfilledRowKey(side, i))
        │           └── Text '<commodityId> — qty Q (priority P)'
        │                 (bodyMedium, --fg)
        └── Text '<totals label>: <total>' (titleSmall, --accentBright,
              keyed dealBook{Side}TotalsKey)
            totals labels: 'Total spent' | 'Total received'
            totals total = Σ (deal.quantity × deal.pricePerUnit).round()
                           across filled rows only (carry-forwards excluded)
```

The two-tab body is the durable structure each follow-up Market slice (E5b interactive controls, E5c cargo indicator) and Deal Book slice (E6) keep building inside. The `CtTabStrip` widget owns the dark-chrome label band (selected = `--accentBright` text on `--accentDim` 25 % alpha background; unselected = `--muted` text on `--surface` 50 % alpha background; 1 px `--accent` / `--accentDim` border per `pixel-art-ui-catalog.md` § `CtTabStrip`) and the `IndexedStack` that mounts both tab bodies so widget tests can reach either tab via `find.byKey` regardless of which is currently visible. Default selection is the **Market** tab (index 0).

The Market tab body is the read-only commodity table (`#2993` E5a). It iterates `CommodityCatalog.all` filtered to the tradeable subset — every commodity whose `CommodityCategory` is **not** `riches` and whose id is **not** `spices` (22 rows total per [`world-market.md`](../game/world-market.md) §Tradeable commodities). Rows are sorted alphabetically by display name (case-insensitive) so the order is deterministic for widget tests and Widgetbook stories. Each row reads:

- the **commodity display name** in `--accent` (`titleSmall`),
- the **last market price** from `Game.worldMarketState.prices[commodityId]` in `--accentBright` (`titleSmall`), formatted as a whole integer (prices on `Game.worldMarketState.prices` are integer treasury units per [`world-market.md`](../game/world-market.md) § Price discovery). When the commodity is absent from `prices`, the row falls back to the published default market price from `ResourceRules.defaultRules.defaultMarketPriceForCommodityId(commodityId)` so first-load Market tab sessions never render the em-dash for raw resources whose catalog default price is known. The canonical em-dash glyph `—` renders only when neither the market state nor the catalog has a value (manufactured commodities and other commodities whose first market price is discovered in-game),
- the **previous-turn aggregate volume** line `Bids X / Offers Y` from `Game.worldMarketState.lastTurnActivity[commodityId]` in `--muted` (`bodySmall`); commodities absent from `lastTurnActivity` default to `Bids 0 / Offers 0` so the column reads consistently.

### Deal Book ledger content (`#2993` E6)

The Deal Book tab body is now the live two-panel ledger described in the wireframe above. Each panel reads from `Game.worldMarketState`:

- **Filled rows** are sourced from `lastTurnActivity[*].deals`, scoped per panel:
  - Bids panel includes every `FilledDeal` whose `buyerFactionId == playerId`.
  - Offers panel includes every `FilledDeal` whose `sellerFactionId == playerId`.
  - Encounter order is the iteration order of `lastTurnActivity.entries` followed by the per-commodity `deals` list — deterministic for a given resolved-turn state because the world-market phase handler writes the per-commodity `deals` list in matcher emission order (FRR pre-pass → priority tiers → FTP → fallback per `SPEC/program/world-market-resolution.md` § Step F).
- **Unfilled rows** are sourced from `carryForwardBidsByFactionId[playerId]` (bids panel) and `carryForwardOffersByFactionId[playerId]` (offers panel) in their stored list order.
- **FRR / FTP tags** render on filled rows when `FilledDeal.isFirstRightOfRefusalMatch` / `isFtpMatch` is true, separated by a space (`FRR FTP` when both are true), in `--muted` `bodySmall` so the chrome reads as an audit annotation rather than a primary control.
- **Totals row** sums `(deal.quantity × deal.pricePerUnit).round()` across the panel's filled rows only — carry-forwards have not cleared and so do not move treasury yet (per `SPEC/program/world-market-resolution.md` § Step C Treasury). The totals row is always mounted (`Total spent: 0` / `Total received: 0` when no filled deals exist) so widget tests can pin the affordance regardless of activity.
- **Empty state** mounts the per-side empty-text only when both `filledRows.isEmpty` **and** `unfilledRows.isEmpty`; the totals row remains mounted underneath. When one side is populated and the other empty, each subsection renders its own "No deals filled this turn." / "No orders carrying forward." inline placeholder so the panel structure stays consistent.
- **Cross-side coexistence:** When the world-market phase emits both `deals` and `MarketActivityNote` drop notes on the same commodity, the Deal Book reads only `deals` for filled rows; drop notes are owned by future observer/Deal Book surfaces (Refs `#2990` B3 follow-up) and are intentionally out of scope for this slice.

The ledger is read-only: there are no interactive controls inside `_DealBookTabContent`, so the observe-mode `IgnorePointer` wrap that protects the Market tab is unnecessary here. The Deal Book content renders identically regardless of `shellPlayerContextProvider.canMutateViaUi`.

### Responsive layout (`#2993` E6)

`_DealBookTabContent` wraps the two panels in a `LayoutBuilder`:

- When the inherited `BoxConstraints.maxWidth >= TradeScreen.dealBookTwoPanelMinWidth` (600 dp), the panels render in a `Row` with `Expanded(child: bidsPanel)`, a 12 dp `SizedBox`, and `Expanded(child: offersPanel)` — both panels share the same top anchor.
- Below the threshold the panels stack vertically inside a `Column` (`mainAxisSize: MainAxisSize.min`, `crossAxisAlignment: CrossAxisAlignment.stretch`) with a 12 dp `SizedBox` between them. This keeps the Deal Book overflow-safe at the 320 dp minimum viewport per `SPEC/ui/mobile-adaptation.md` § 7.

The 600 dp threshold matches the `kMinViewportWidth` (320 dp) + extra breathing room: between 320–599 dp the panels stack; at 600 dp+ they sit side-by-side.

### Cargo indicator + per-stepper cap + warning (`#2993` E5c)

Above the commodity list the Market tab body renders a persistent header column with two text rows:

- `tradeScreenMarketCargoIndicator` — `Cargo remaining: X` where `X = max(0, tradeCargoCapacity − totalStagedBidQuantity)`. `tradeCargoCapacity` is `cargoHoldsForHomeFleet(game, player.id)` (the home-fleet cargo holds, falling back to `defaultCargoHoldsStub = 24` when the player has no home fleet yet). `totalStagedBidQuantity` is the sum of `TradeOrder.quantity` across all staged `TradeOrderType.bid` orders for `player.id` in `currentOrdersProvider`. The text is live: as bids are incremented / decremented / toggled to offers / removed via the `None` chip, the indicator updates immediately. Offers do not consume cargo (per `#2988` § Cargo Constraint Model) and are excluded from the sum.
- `tradeScreenMarketCargoWarning` — only mounted when `remainingCargo == 0` AND `totalStagedBidQuantity > 0`. Renders the literal `Cargo limit reached — increase your fleet capacity or reduce bids.` in `EditorialMonoclePalette.danger` (`bodySmall`). When `remainingCargo > 0` or `totalStagedBidQuantity == 0`, this widget is **absent** from the tree (`find.byKey(marketCargoWarningKey)` resolves to zero widgets).

The per-row bid stepper and direction chips honour the cross-commodity cap:

- **Increment a staged bid:** allowed only when `remainingCargo > 0`. When `remainingCargo == 0`, the increment tap is a silent no-op (`currentOrdersProvider` is not mutated) so the cross-commodity bid total never exceeds `tradeCargoCapacity`. Decrement and offer-side increment / decrement are unaffected by the cap (offers do not consume cargo and decrementing a bid only frees cargo).
- **Toggle a row to `Bid` from `None` / `Offer`:** allowed only when at least 1 unit fits — i.e. the row's `maxAllowedBidQuantity = remainingCargo + priorBidContribution > 0`, where `priorBidContribution` is the row's prior `TradeOrder.quantity` when its prior direction was already `Bid` (and 0 otherwise). The new staged `TradeOrder.quantity` is `min(desiredQuantity, maxAllowedBidQuantity)` where `desiredQuantity` is the prior `TradeOrder.quantity` (preserved across direction changes) when it exists, otherwise `marketRowQuantityDefault` (1). When `maxAllowedBidQuantity <= 0` the toggle is a silent no-op and the row remains in its prior direction.
- **Toggle a row to `Offer` / `None`:** never blocked by cargo (offers and `None` free or don't consume cargo).

`tradeCargoCapacity == 0` is a valid state: the indicator renders `Cargo remaining: 0`, no bids can be staged via direction toggle or increment, and the warning row is absent until at least one bid is staged (which itself is impossible at capacity 0, so the warning row never mounts at capacity 0 — the indicator alone communicates the no-cargo state).

### Market tab — sellable readout + offer-side clamp (`#3093` slice)

Each Market row exposes the player's **per-commodity sellable headroom** so the Offer chip and offer-side `+` stepper never exceed the player's available stock (the offer-side mirror of the cross-commodity bid cap in [§ Cargo indicator + per-stepper cap + warning (`#2993` E5c)](#cargo-indicator--per-stepper-cap--warning-2993-e5c)). The headroom is computed by the logic-side helpers in `colonizethis_logic` (`offerCapByCommodityId`, `stagedOfferQuantitiesByCommodityId`, `sellableHeadroomByCommodityId`; exported via `colonizethis_logic.dart`) and equals `max(0, offerCap − stagedOfferQuantity)`, where:

- `offerCap = Player.stockpile.quantities[commodityId]` for tradeable commodities, **excluding** all commodities in the riches set. Production-input projection / industry-allocation reservations — the post-production projected stockpile minus industry allocations described in [`world-market.md`](../game/world-market.md) § Validation rules — is a planned refinement and is currently a no-op in this slice (`offerCap == raw stockpile`); the helper signature already takes `Game` and `playerId` so wiring projection in is a backwards-compatible follow-up.
- `stagedOfferQuantity` is the sum of every staged `TradeOrder` with `type == offer` for the row's commodity, read from `currentOrdersProvider`.

UI surface:

- A **sellable readout** keyed `TradeScreen.marketRowSellableReadoutKey(commodityId)` renders `(N)` next to the commodity display name, where `N` is the live headroom. The readout updates immediately as offers are staged / decremented / removed. When `offerCap == 0` the readout renders `(0)` and the row's Offer chip is rendered in the **disabled** visual state (muted background + border + label) via `CtChoiceChip(onSelected: null)`; the chip is still mounted and discoverable for widget tests but taps do not mutate `currentOrdersProvider`. Bids on the same row are unaffected by the sellable headroom (bids consume cargo, not stockpile).
- **Toggle a row to `Offer` from `None` / `Bid`:** allowed only when `offerCap > 0`. The new staged `TradeOrder.quantity` is `min(desiredQuantity, offerCap)` where `desiredQuantity` is the prior `TradeOrder.quantity` when it exists, otherwise `marketRowQuantityDefault` (1). When `offerCap <= 0` the toggle is a silent no-op and the row stays in its prior direction.
- **Increment a staged offer:** allowed only when the current `TradeOrder.quantity < offerCap`. At saturation (`quantity == offerCap`) the `marketRowIncrementKey` tap is a silent no-op (`currentOrdersProvider` is **not** mutated). Decrement and `None` are unaffected (decrementing only frees headroom).
- The bid-side clamp from E5c continues to apply unchanged. Mutual exclusion still wins: toggling `Offer` on a row that already has a staged `Bid` replaces the bid (subject to the offer-side clamp), and toggling `Bid` on a row that already has a staged `Offer` replaces the offer (subject to the cargo cap).

### Market tab — treasury bid cap (`#3093` slice)

Each Market row's Bid toggle / bid-side `+` stepper is gated against the player's **treasury budget for bids** so the cross-commodity sum of bid spend (`Σ quantity × effectiveMarketPrice`) never exceeds the player's available treasury (the bid-side mirror of the cross-commodity cargo cap in [§ Cargo indicator + per-stepper cap + warning (`#2993` E5c)](#cargo-indicator--per-stepper-cap--warning-2993-e5c)). The cap is computed by the logic-side helpers in `colonizethis_logic` (`treasuryAvailableForBidsByPlayer`, `stagedBidTotalSpendByPlayer`, `effectiveMarketPriceForCommodityId`; exported via `colonizethis_logic.dart`) and equals `treasuryAvailableForBidsByPlayer − (stagedBidTotalSpendByPlayer − rowPriorBidSpend)`, where:

- `treasuryAvailableForBidsByPlayer` is the player's raw `treasury` field today. Subtracting other pending costs (production / recruit-train / civilian work / subsidies) per [`world-market.md`](../game/world-market.md) § Treasury budget for bids is a planned refinement; the UI clamp landing first only subtracts the player's own already-staged bid spend.
- `stagedBidTotalSpendByPlayer` sums `quantity × effectiveMarketPrice` across every staged `TradeOrderType.bid` for the player.
- `rowPriorBidSpend` is `prior.quantity × effectiveMarketPrice` when the row already has a staged bid (and 0 otherwise) — subtracted so the row's *replacement* quantity is measured against the fresh headroom, mirroring the cargo-cap `priorBidContribution` rule.
- `effectiveMarketPrice` is the integer price on `Game.worldMarketState.prices[commodityId]` when present, falling back to `ResourceRules.defaultMarketPriceForCommodityId(commodityId)` (the catalog default). When neither source returns a value, the bid clamp refuses the toggle (no spend can be evaluated for a row whose price text reads as the em-dash).

UI surface:

- **Toggle a row to `Bid` from `None` / `Offer`:** allowed only when the treasury headroom for the row fits at least one unit at `rowPrice`. The new staged `TradeOrder.quantity` is `min(desiredQuantity, cargoMaxAllowedBidQuantity, treasuryQuantityCap)` where `treasuryQuantityCap = treasuryHeadroom ~/ rowPrice`. When `treasuryHeadroom < rowPrice` (and `rowPrice > 0`) the toggle is a silent no-op (`currentOrdersProvider` is not mutated) and the row stays in its prior direction.
- **Increment a staged bid:** allowed only when `stagedBidTotalSpendByPlayer + delta × rowPrice ≤ treasuryAvailableForBidsByPlayer`. At treasury saturation the `marketRowIncrementKey` tap is a silent no-op. Decrement is unaffected (decrementing only frees treasury).
- **Unpriced commodities (`rowPrice == null`):** when the row has no effective per-unit price (manufactured commodity whose first market price is discovered in-game and no catalog default — the row's price text reads as the em-dash), the treasury clamp is **skipped** so the cargo cap from E5c remains the only constraint on the row's Bid toggle / `+` increment. The validator-side enforcement landing in a follow-up rejects over-spend bids for unpriced commodities at order submission time.
- The cargo cap from E5c continues to apply unchanged — both caps are checked and the **stricter** of the two governs the row's increment / toggle outcome. Offers do not consume treasury and are not gated by this cap.

### Body (planned — follow-up `#2993` E5b cont.)

The Market interactive table above plus the E5c cargo indicator are the foundation. The remaining follow-up slice extends the per-row Market controls inside the same tab strip:

- **Market tab — priority dropdown (`#2993` E5b cont.):** integer dropdown bounded by the `kMaxTradePriority` (or equivalent) value exposed by the data API in `#2989`. The current slice defaults staged trade orders to priority 1 and flags the integration for the follow-up bound.

The Deal Book tab body's live two-panel ledger ships in this commit (Refs `#2993` E6) — see [§ Deal Book ledger content (`#2993` E6)](#deal-book-ledger-content-2993-e6) above for the layout, sources, and totals contract.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Left rail Trade button | `kEmpireTradeButtonKey` tapped | `NavigateToRouteEvent(Routes.trade, …)` → push `TradeScreen`. |
| Direct route (deep link / test harness) | Caller supplies `RoutePaths.trade` settings with `game` + `humanPlayerId` args | `_buildGameRoute` resolves player and mounts `TradeScreen`. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| `CtTopBar` back affordance | Always | `Navigator.maybePop()` | Returns to the previous route (in-game shell). |
| Tab label `Market` | Always (default selection) | `CtTabStrip` internal `setState(selectedIndex = 0)` | `IndexedStack` foregrounds the Market tab body keyed `tradeScreenMarketTabBody`. |
| Tab label `Deal Book` | Always | `CtTabStrip` internal `setState(selectedIndex = 1)` | `IndexedStack` foregrounds the Deal Book tab body keyed `tradeScreenDealBookTabBody`. |
| Per-row `None` chip (`marketRowNoneChipKey`) | `canMutateViaUi == true` | `removeTradeOrderForPlayer(orders, playerId, commodityId)` written to `currentOrdersProvider`. | Removes any staged `TradeOrder` for the row's commodity from `Orders.tradeOrdersByPlayerId[player.id]`. |
| Per-row `Bid` chip (`marketRowBidChipKey`) | `canMutateViaUi == true` | `applyTradeOrderForPlayer(...TradeOrder(commodityId, type: bid, quantity: prior?.quantity ?? marketRowQuantityDefault, priority: prior?.priority ?? marketRowDefaultPriority))` written to `currentOrdersProvider`. | Stages a bid for the commodity. If a prior offer exists for the same commodity, it is replaced (mutual exclusion: one staged `TradeOrder` per `(player, commodityId)`). |
| Per-row `Offer` chip (`marketRowOfferChipKey`) | `canMutateViaUi == true` | `applyTradeOrderForPlayer(...TradeOrder(commodityId, type: offer, quantity: prior?.quantity ?? marketRowQuantityDefault, priority: prior?.priority ?? marketRowDefaultPriority))` written to `currentOrdersProvider`. | Stages an offer for the commodity. Mutual exclusion: replaces any prior bid. |
| Per-row stepper `+` (`marketRowIncrementKey`) | `canMutateViaUi == true` AND a direction is staged | `applyTradeOrderForPlayer(...prior.copyWith(quantity: prior.quantity + 1))`. | Increments the staged `TradeOrder.quantity` by 1. No-op when no direction is staged. |
| Per-row stepper `−` (`marketRowDecrementKey`) | `canMutateViaUi == true` AND staged direction has `quantity > marketRowQuantityMin` | `applyTradeOrderForPlayer(...prior.copyWith(quantity: prior.quantity − 1))`. | Decrements the staged `TradeOrder.quantity` by 1. Clamped at `marketRowQuantityMin` (1); going below 1 is reached via the `None` chip. |
| Per-row stepper `+` on a `Bid` row when `remainingCargo == 0` | `canMutateViaUi == true` AND staged `TradeOrderType.bid` AND `remainingCargo == 0` | No-op — `currentOrdersProvider` is **not** mutated. | Cross-commodity bid total stays at `tradeCargoCapacity`; the `tradeScreenMarketCargoWarning` row remains mounted (it was already mounted at saturation). |
| Per-row `Bid` chip when toggle would exceed cargo (`maxAllowedBidQuantity > 0` AND `desiredQuantity > maxAllowedBidQuantity`) | `canMutateViaUi == true` | `applyTradeOrderForPlayer(... TradeOrder(type: bid, quantity: maxAllowedBidQuantity, …))`. | Staged bid is clamped to the remaining cargo (`desiredQuantity` falls back from the prior `quantity` to the remaining cargo when it is smaller). |
| Per-row `Bid` chip when no bid fits (`maxAllowedBidQuantity <= 0`) | `canMutateViaUi == true` | No-op — `currentOrdersProvider` is **not** mutated. | Row stays in its prior direction; cross-commodity bid total stays at `tradeCargoCapacity`; the `tradeScreenMarketCargoWarning` row remains mounted. |

Observe-mode (`canMutateViaUi == false`, distinct from the global-observe / panels-not-defined sentinel covered by variant `c`): the Market tab body is wrapped in `IgnorePointer` and dimmed by an `Opacity` of `0.7`; the chips and stepper buttons remain mounted (so the static read-only data renders) but taps are blocked and `currentOrdersProvider` is not mutated. This matches the production-screen read-only pattern (`canEdit ? panel : IgnorePointer(child: panel)`).

### Future user actions (`#2993` E5b cont.)

The interactive contract for the priority dropdown (bound to `kMaxTradePriority` once #2989 exposes it) is documented in `#2988` § UI Design. Mirror those rows into this **Behavior** table when the follow-up slice lands — the tab-switch, direction-chip, and cargo-indicator rows above stay untouched because the tab + row + header structure does not change. The Deal Book ledger ships in this commit (Refs `#2993` E6) and is purely read-only: there are no interactive controls on `_DealBookTabContent`, so the User actions table above already covers every input on the screen.

---

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `GAME60001` | Default — Market tab (a) | Human player active; Market tab selected (initial state) | Dark chrome + `_TradeScreenTabsBody` with the Market tab (`tradeScreenMarketTabBody`) foregrounded; the body is the read-only commodity table keyed `tradeScreenMarketCommodityList` with one `tradeScreenMarketRow:<id>` per tradeable commodity (`#2993` E5a). |
| `GAME60001` | Default — Deal Book tab (b) | Human player active; user has tapped the `Deal Book` tab label | Dark chrome + `_TradeScreenTabsBody` with the Deal Book tab (`tradeScreenDealBookTabBody`) foregrounded; the body is now the live `_DealBookTabContent` two-panel ledger (`tradeScreenDealBookContent`) with `tradeScreenDealBookBidsPanel` / `tradeScreenDealBookOffersPanel` containers and `tradeScreenDealBook{Bids,Offers}Totals` rows always mounted (Refs `#2993` E6). |
| `GAME60001` | Observe mode (c) | `shellPanelsNotDefined(ref) == true` | Body switches to `ObserveModeNotDefinedPanel(title: 'Trade')`; the tab strip (and both tab bodies) are not mounted under this branch. |

The Market tab body's cargo indicator + warning state described in [§ Cargo indicator + per-stepper cap + warning (`#2993` E5c)](#cargo-indicator--per-stepper-cap--warning-2993-e5c) is an internal substate of variant `a` (Default — Market tab): the indicator row is always mounted under `tradeScreenMarketTabBody`; the warning row mounts and dismounts as the staged-bid total saturates / desaturates the player's `tradeCargoCapacity`.

The Deal Book ledger described in [§ Deal Book ledger content (`#2993` E6)](#deal-book-ledger-content-2993-e6) is an internal substate of variant `b` (Default — Deal Book tab): the bids and offers panel containers + per-side totals rows are always mounted under `tradeScreenDealBookContent`; the per-side empty-state, filled, and unfilled rows mount or dismount based on the player's `lastTurnActivity[*].deals` / `carryForward{Bids,Offers}ByFactionId[playerId]` content. Switching back and forth between the Market and Deal Book tabs preserves the IndexedStack state per the E4 contract.

---

## Components

- `TradeScreen` (`app/lib/features/game/screens/trade_screen.dart`) — top-level shell host.
- `CtGameFeatureScreenShell` (`app/lib/widgets/ct_game_feature_screen_shell.dart`) — opt-in dark chrome wrapper that owns the `GameToUIBusListener` and live `currentGameProvider` swap. Composite contract: [`components/ct-game-feature-screen-shell.md`](components/ct-game-feature-screen-shell.md).
- `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtTopBar`) — dark editorial-monocle top bar carrying the back affordance, icon, and title.
- `StrictAssetIcon` (`app/lib/widgets/strict_asset_icon.dart`) — renders the 32 × 32 source PNG at the 18 × 18 top-bar size.
- `CtPanel` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtPanel`) — outer surface for the tabs body and inner surface for each tab placeholder.
- `CtTabStrip` (`SPEC/ui/pixel-art-ui-catalog.md` § `CtTabStrip`) — dark editorial-monocle tab strip hosting the `Market` and `Deal Book` labels above the `IndexedStack` of tab bodies.
- `ObserveModeNotDefinedPanel` (`app/lib/features/game/widgets/observe_mode_not_defined_panel.dart`) — shared observe-mode sentinel.
- `_DealBookTabContent` (`app/lib/features/game/screens/trade_screen.dart`) — read-only two-panel ledger (Refs `#2993` E6) hosting both `_DealBookPanel` instances under a `LayoutBuilder` that picks `Row` vs `Column` based on `dealBookTwoPanelMinWidth`.
- `_DealBookPanel` (`app/lib/features/game/screens/trade_screen.dart`) — single ledger panel; renders panel title, optional empty-state copy, the Filled / Unfilled sections, and the always-mounted totals row.
- `_DealBookFilledRow` / `_DealBookUnfilledRow` (`app/lib/features/game/screens/trade_screen.dart`) — per-row widgets keyed by `dealBookFilledRowKey(side, index)` / `dealBookUnfilledRowKey(side, index)`.

---

## Widgetbook

Folder name **Trade Screen** in `app/lib/widgetbook/catalog.dart` (registered via `tradeScreenDirectories`).

Use cases for the current slice (E1+E2+E3+E4+E5a+E5b+E5c+E6+E7):

| Use case | Proves |
|----------|--------|
| `Scaffold (Market tab)` | Default mount of `TradeScreen` with the dark `CtTopBar` and `_TradeScreenTabsBody` showing the Market tab read-only commodity table selected (the initial state visited by every gameplay session). The cargo indicator renders `Cargo remaining: 24` (home-fleet stub capacity, no staged bids). |
| `Scaffold (mobile)` | Same default story inside `mobileViewport` (360 × 640 dp) to satisfy the per-spec mobile use case (`SPEC/ui/mobile-adaptation.md`). |
| `Market tab — staged bid + offer (Refs #2993 E5b)` | Story Game with `currentOrdersProvider` pre-seeded so reviewers see an active `Bid` (timber, qty 4) and `Offer` (fabric, qty 7) without needing to drive the chips themselves. Cargo indicator reads `Cargo remaining: 20` (`24 − 4`). |
| `Market tab — cargo saturated (Refs #2993 E5c)` | Story Game with `currentOrdersProvider` pre-seeded to stage bids whose total quantity equals `tradeCargoCapacity` so the cargo indicator reads `Cargo remaining: 0` and the warning row `tradeScreenMarketCargoWarning` is mounted. Reviewers can confirm the dark-theme `--danger` palette and the cargo-limit copy without touching the chips. |
| `Deal Book tab — empty (Refs #2993 E7)` | Synthetic Game with `WorldMarketState.empty` (no `lastTurnActivity` and no carry-forwards). Mounted with `TradeScreen.initialTabIndex: 1` so the Deal Book tab is foregrounded on first frame. Proves the per-side empty-state copies (`dealBookBidsEmpty` / `dealBookOffersEmpty`) render together with the always-mounted `Total spent: 0` / `Total received: 0` rows. |
| `Deal Book tab — mixed fills + carry-forwards (Refs #2993 E7)` | Synthetic Game with one FRR-tagged human buy and one FTP-tagged human buy of timber (`3 × 30.0` each), one human sale of iron (`4 × 80.0`), one FTP-tagged human sale of fabric (`7 × 120.0`), one human carry-forward bid (grain `qty 8 priority 2`), one human carry-forward offer (cast-iron `qty 4 priority 1`), and a foreign-only carry-forward (timber `qty 99` for `gp_aragon`) that must not surface in the human Deal Book. Proves both Filled and Unfilled subsections render together, the FRR / FTP audit tags paint in `--muted`, and the totals row reads `Total spent: 180` (`3×30 + 3×30`) and `Total received: 1160` (`4×80 + 7×120`). |
| `Deal Book tab — mobile (stacked) (Refs #2993 E7)` | Same mixed data inside `mobileViewport` (360 × 640 dp). Proves the panels stack vertically inside the `Column` layout below `dealBookTwoPanelMinWidth` so the 320 dp minimum viewport stays overflow-safe per `SPEC/ui/mobile-adaptation.md` § 7. |

These use cases share the same data sources as the trade screen runtime (`Game.worldMarketState`) so the Widgetbook contract evolves with the live render automatically.

Follow-up E5b cont. slices append `Market tab — priority dropdown` as the priority API surface lands. The tab structure remains the same; only each tab body's content advances.

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
- **Given** the same conditions and `Game.worldMarketState.prices` contains an entry `{'timber': 30}` (and no entry for `'iron'`, whose published default market price per `ResourceRules.defaultRules` is the integer `80`), **when** the Market tab body renders, **then** the `tradeScreenMarketRow:timber` row contains the text `30` (the integer market value) and the `tradeScreenMarketRow:iron` row contains the text `80` (the catalog default-market-price fallback for raw resources absent from `Game.worldMarketState.prices`).
- **Given** the same conditions and `Game.worldMarketState.prices` is empty and the row is a manufactured commodity (e.g. `'lumber'`) whose id is not enumerated in `ResourceRules.defaultRules.defaultMarketPrice`, **when** the Market tab body renders, **then** the row's price cell contains the canonical em-dash glyph `—` (`priceUnknownGlyph`) because neither the market state nor the catalog has a published default price for that commodity (manufactured-commodity defaults are tracked as follow-up to `#3093`).
- **Given** the same conditions and `Game.worldMarketState.lastTurnActivity` contains `{'timber': MarketActivity(totalBidQuantity: 12, totalOfferQuantity: 8)}` (and no entry for `'fabric'`), **when** the Market tab body renders, **then** the `tradeScreenMarketRow:timber` row contains the text `Bids 12 / Offers 8` and the `tradeScreenMarketRow:fabric` row contains the text `Bids 0 / Offers 0` (zero-default for commodities absent from the activity map).
- **Given** the `TradeScreen` is mounted with a human player and observe mode is **not** active, **then** the `tradeScreenMarketCommodityList` widget is present **only** under the `tradeScreenMarketTabBody` subtree (not under the off-stage `tradeScreenDealBookTabBody` subtree, even when reached via `find.byKey(..., skipOffstage: false)`).

### Market tab — interactive bid/offer/quantity controls (`#2993` E5b)

- **Given** the `TradeScreen` is mounted with a human player, observe mode is **not** active, and no `TradeOrder` is staged for the row's commodity, **then** the per-row direction chips render the `None` chip selected and the `Bid` / `Offer` chips unselected, and the quantity readout (`marketRowQuantityTextKey`) renders the canonical em-dash glyph `marketRowQuantityIdleGlyph` (`—`).
- **Given** the same conditions, **when** the user taps the row's `Bid` chip (`marketRowBidChipKey`), **then** `currentOrdersProvider` is mutated so `Orders.tradeOrdersByPlayerId[player.id]` contains exactly one `TradeOrder` for the commodity with `type = TradeOrderType.bid`, `quantity = TradeScreen.marketRowQuantityDefault` (1), and `priority = TradeScreen.marketRowDefaultPriority` (1).
- **Given** the row already has a staged `TradeOrder(type: bid, quantity: 2)` for the commodity, **when** the user taps the row's `Offer` chip (`marketRowOfferChipKey`), **then** the staged `TradeOrder` for that commodity is replaced by `TradeOrder(type: offer, quantity: 2, priority: 1)` (the prior quantity is preserved across the direction change) and `tradeOrdersByPlayerId[player.id]` contains exactly **one** TradeOrder for the commodity (mutual exclusion: at most one staged direction per `(player, commodityId)` pair).
- **Given** the row already has a staged `TradeOrder` for the commodity, **when** the user taps the row's `None` chip (`marketRowNoneChipKey`), **then** the staged `TradeOrder` for that commodity is removed from `tradeOrdersByPlayerId[player.id]`.
- **Given** the row has a staged `TradeOrder(quantity: q)` with `q < INT32_MAX`, **when** the user taps the row's increment button (`marketRowIncrementKey`), **then** the staged TradeOrder is updated to `quantity: q + 1` and the quantity readout renders the new value.
- **Given** the row has a staged `TradeOrder(quantity: q)` with `q > marketRowQuantityMin` (1), **when** the user taps the row's decrement button (`marketRowDecrementKey`), **then** the staged TradeOrder is updated to `quantity: q − 1`.
- **Given** the row has a staged `TradeOrder(quantity: 1)` (at the lower bound `marketRowQuantityMin`), **when** the user taps the row's decrement button, **then** the staged TradeOrder is unchanged (the stepper is clamped at the lower bound; going below 1 is reached via the `None` chip rather than the decrement button).
- **Given** the row has **no** staged `TradeOrder` (None direction), **when** the user taps the row's increment or decrement button, **then** `currentOrdersProvider` is **not** mutated (stepper taps without a staged direction are silent no-ops; the user must pick `Bid` or `Offer` first).
- **Given** the row for commodity X has a staged `TradeOrder(type: bid)` and the user toggles a different commodity Y to `Offer`, **then** both rows have a staged TradeOrder simultaneously — `tradeOrdersByPlayerId[player.id].length == 2` — confirming mutual exclusion is per-commodity, not per-player.
- **Given** the `TradeScreen` is mounted with `shellPlayerContextProvider.canMutateViaUi == false` (observing another GP — distinct from the `showPlayerChrome == false` global-observe sentinel covered by variant `c`), **when** the user attempts to tap any of the row's direction chips, increment, or decrement buttons, **then** `currentOrdersProvider` is **not** mutated (the Market tab body is wrapped in `IgnorePointer` so taps do not propagate); the chips and stepper remain mounted in the widget tree so the read-only data still renders.

### Market tab — cross-commodity cargo indicator + cap + warning (`#2993` E5c)

- **Given** the `TradeScreen` is mounted with a human player, observe mode is **not** active, the player has no home fleet (`cargoHoldsForHomeFleet` falls back to `defaultCargoHoldsStub = 24`), and `currentOrdersProvider.tradeOrdersByPlayerId[player.id]` is empty (or contains only offers), **then** the Market tab body contains exactly one widget keyed `TradeScreen.marketCargoIndicatorKey` whose visible `Text` is `Cargo remaining: 24` and **no** widget keyed `TradeScreen.marketCargoWarningKey` is mounted (`find.byKey(marketCargoWarningKey)` resolves to zero widgets).
- **Given** the same conditions and the player has staged `TradeOrder`s totalling 7 across two commodities (e.g. `Bid` timber qty 4 + `Bid` iron qty 3), **then** the cargo indicator visible `Text` is `Cargo remaining: 17` (`24 − 7`) and the cargo warning row is still absent.
- **Given** the player has `tradeCargoCapacity = 10` (e.g. via a home-fleet override) and has staged `Bid`s totalling 10 across commodities (`Bid` timber qty 6 + `Bid` iron qty 4), **then** the cargo indicator reads `Cargo remaining: 0` AND the cargo warning row keyed `TradeScreen.marketCargoWarningKey` is mounted with the literal text `Cargo limit reached — increase your fleet capacity or reduce bids.`.
- **Given** the player has `tradeCargoCapacity = 10`, has staged `Bid` timber qty 6 (cargo remaining 4), and is staging on commodity X via `marketRowIncrementKey`, **when** the user repeatedly taps the `+` button on commodity X, **then** the staged quantity for commodity X increments by 1 per tap up to qty 4 (cargo remaining 0); the next `+` tap on commodity X is a silent no-op (`currentOrdersProvider` is **not** mutated), the staged TradeOrder.quantity stays at 4, the cargo indicator reads `Cargo remaining: 0`, and `tradeScreenMarketCargoWarning` is mounted.
- **Given** the player has `tradeCargoCapacity = 10`, has staged `Bid` timber qty 6 and `Bid` iron qty 4 (cargo remaining 0), **when** the user taps the `Bid` chip on commodity grain (`marketRowBidChipKey('grain')`), **then** the toggle is a silent no-op (`currentOrdersProvider` is **not** mutated, no `TradeOrder` for grain is staged), cargo indicator stays at `Cargo remaining: 0`, and the warning row stays mounted. The cross-commodity bid total stays at 10 and never exceeds `tradeCargoCapacity`.
- **Given** the player has `tradeCargoCapacity = 10` and a staged `Offer` for fabric qty 8 (offers don't consume cargo so cargo remaining is 10), **when** the user taps the `Bid` chip on commodity fabric (toggling fabric's direction from `Offer` to `Bid`), **then** the staged `TradeOrder` for fabric is replaced by `TradeOrder(type: bid, quantity: 8)` (the prior quantity is preserved because it fits inside cargo capacity) and the cargo indicator updates to `Cargo remaining: 2`.
- **Given** the player has `tradeCargoCapacity = 10`, has staged `Bid` timber qty 9 (cargo remaining 1), and has a staged `Offer` for fabric qty 5, **when** the user taps the `Bid` chip on commodity fabric, **then** the staged `TradeOrder` for fabric is replaced by `TradeOrder(type: bid, quantity: 1)` (the prior 5 is clamped to the remaining cargo of 1, not the prior offer's 5) and the cargo indicator updates to `Cargo remaining: 0` and the warning row is mounted.
- **Given** the player has `tradeCargoCapacity = 10`, has staged `Bid` timber qty 10 (cargo remaining 0), **when** the user taps the `−` button on timber (`marketRowDecrementKey('timber')`), **then** the staged `TradeOrder.quantity` for timber decrements to 9, the cargo indicator updates to `Cargo remaining: 1`, and the warning row keyed `TradeScreen.marketCargoWarningKey` is removed from the widget tree.
- **Given** the player has `tradeCargoCapacity = 10`, has staged `Bid` timber qty 10, **when** the user taps the `None` chip on timber (`marketRowNoneChipKey('timber')`), **then** the staged `TradeOrder` for timber is removed, the cargo indicator updates to `Cargo remaining: 10`, and the warning row is removed (because `totalStagedBidQuantity == 0`).
- **Given** the `TradeScreen` is mounted with `shellPlayerContextProvider.canMutateViaUi == false`, **then** the cargo indicator and (when applicable) warning row remain mounted with the same text values as in the editable case (they read directly from `Game` + `currentOrdersProvider` regardless of the observe-mode `IgnorePointer`).

### Market tab — sellable readout + offer-side clamp (`#3093` slice)

- **Given** the `TradeScreen` is mounted with a human player whose `Player.stockpile.quantities['timber'] == 10` and `currentOrdersProvider` has no staged offers for timber, **then** the Market row for timber renders a widget keyed `TradeScreen.marketRowSellableReadoutKey('timber')` whose visible text is `(10)`, and the `marketRowOfferChipKey('timber')` `CtChoiceChip` is rendered in the enabled (non-disabled) visual state.
- **Given** the same conditions and a staged `TradeOrder(commodityId: 'timber', type: offer, quantity: 2)`, **then** the sellable readout for timber renders `(8)`. **When** the user taps `marketRowIncrementKey('timber')`, the staged quantity increments by 1 and the readout updates to `(7)`. **When** the user keeps tapping `+` until the staged quantity reaches 10 (offerCap), the next `+` tap is a silent no-op (`currentOrdersProvider` is **not** mutated) and the readout stays at `(0)`.
- **Given** the `TradeScreen` is mounted with `Player.stockpile.quantities['timber'] == 0`, **then** the Market row for timber renders the sellable readout `(0)`, the `marketRowOfferChipKey('timber')` chip is rendered in the disabled visual state (muted background + label per `CtChoiceChip(onSelected: null)`), and tapping the chip does **not** mutate `currentOrdersProvider`. Tapping `marketRowBidChipKey('timber')` is unaffected and stages a bid normally (offer-side clamp does not affect bids).
- **Given** the player has `Player.stockpile.quantities['timber'] == 5` and a staged `Bid` for timber qty 3, **when** the user taps `marketRowOfferChipKey('timber')`, **then** the staged `TradeOrder` is replaced by `TradeOrder(type: offer, quantity: min(3, 5) == 3)` (the prior quantity is preserved because it fits inside the offer cap) and the sellable readout updates to `(2)`.
- **Given** the player has `Player.stockpile.quantities['timber'] == 5` and a staged `Bid` for timber qty 8 (e.g. left over from a prior cargo configuration), **when** the user taps `marketRowOfferChipKey('timber')`, **then** the staged `TradeOrder` is replaced by `TradeOrder(type: offer, quantity: 5)` (the prior 8 is clamped to the offer cap of 5) and the sellable readout updates to `(0)`.
- **Given** the player has staged offers on two distinct commodities and **then** decrements one of them via `marketRowDecrementKey`, **then** that row's sellable readout increments by 1 and the other row's readout is unchanged.
- **Given** the player has a staged `Bid` for timber qty 7 (bids do not consume offer headroom), **then** the timber row's sellable readout still renders the raw `offerCap == stockpile` (e.g. `(5)`) and the Offer chip's enabled/disabled state is determined solely by `offerCap`, **not** by staged bids on the same commodity.

### Market tab — treasury bid cap (`#3093` slice)

- **Given** the `TradeScreen` is mounted with a human player whose `Player.treasury == 100`, `Game.worldMarketState.prices == {timber: 30}`, and `currentOrdersProvider` has no staged trade orders, **when** the user taps the `Bid` chip on timber (`marketRowBidChipKey('timber')`), **then** a `TradeOrder(commodityId: 'timber', type: bid, quantity: 1)` is staged (`marketRowQuantityDefault == 1` fits inside the treasury budget of `100 / 30 == 3`), the staged-bid-total-spend `1 × 30 == 30` is at most `100`, and the cargo cap continues to apply unchanged.
- **Given** the player has `Player.treasury == 100`, market price `timber: 30`, and a staged `Bid` for timber qty 3 (total bid spend `3 × 30 == 90`), **when** the user taps `marketRowIncrementKey('timber')`, **then** the staged quantity grows to 4 only if `(3 + 1) × 30 == 120 ≤ 100` — since it is **not**, the increment tap is a silent no-op (`currentOrdersProvider` is **not** mutated), the staged `TradeOrder.quantity` stays at 3, and the cargo indicator is unaffected.
- **Given** the player has `Player.treasury == 100`, market price `timber: 30`, a staged `Bid` for timber qty 3 (total bid spend 90), and the user toggles a fresh row commodity `iron` (market price 80) to `Bid`, **then** the toggle is a silent no-op because the treasury headroom `100 − 90 == 10` is less than the row price `80` (`treasuryHeadroom < rowPrice`); the row stays `None`, the staged timber bid is unchanged, and no `TradeOrder` for iron is added.
- **Given** the player has `Player.treasury == 100`, market price `iron: 80`, no staged trade orders, **when** the user toggles `marketRowBidChipKey('iron')`, **then** the staged `TradeOrder(commodityId: 'iron', type: bid)` is staged with `quantity == min(marketRowQuantityDefault, treasuryHeadroom ~/ rowPrice) == min(1, 100 ~/ 80) == 1`; cargo cap and treasury cap both apply but neither further clamps the default-1 staged quantity.
- **Given** the player has `Player.treasury == 50`, market price `timber: 30`, a staged `Offer` for timber qty 4 (offers do not consume treasury), **when** the user taps `marketRowBidChipKey('timber')` (toggling timber from `Offer` to `Bid`), **then** the staged `TradeOrder` for timber is replaced by `TradeOrder(type: bid, quantity: min(4, treasuryQuantityCap) == min(4, 50 ~/ 30) == 1)` and the staged-bid-total-spend `1 × 30 == 30` is at most `50`.
- **Given** the player has `Player.treasury == 100`, `Game.worldMarketState.prices` is empty for the row's commodity, and the catalog default price for that commodity is **also** absent (manufactured commodity whose first price is discovered in-game), **when** the user taps `marketRowBidChipKey(commodityId)`, **then** the **treasury** clamp is skipped (`rowPrice == null` cannot be evaluated against the budget) and the cargo cap is the only constraint; the staged `TradeOrder(type: bid, quantity: min(marketRowQuantityDefault, cargoMaxAllowedBidQuantity))` is added when cargo allows, and the row's price text continues to render the canonical em-dash glyph. The validator-side enforcement (follow-up) catches over-spend cases for unpriced commodities independently.

### Deal Book tab — live two-panel ledger (`#2993` E6)

- **Given** the `TradeScreen` is mounted with a human player, observe mode is **not** active, the player has zero `FilledDeal` entries on `lastTurnActivity[*].deals` (filtered by `buyerFactionId == playerId` and `sellerFactionId == playerId`), and the player has zero carry-forward bids and zero carry-forward offers, **when** the user taps the `Deal Book` tab label, **then** the Deal Book tab body keyed `tradeScreenDealBookTabBody` foregrounds, both `tradeScreenDealBookBidsEmpty` and `tradeScreenDealBookOffersEmpty` widgets are mounted, the `tradeScreenDealBookBidsTotals` widget renders the literal `Total spent: 0`, and the `tradeScreenDealBookOffersTotals` widget renders the literal `Total received: 0`.

- **Given** the `TradeScreen` is mounted with a human player `gp_h`, observe mode is **not** active, and `lastTurnActivity['timber'].deals` contains exactly one `FilledDeal(sellerFactionId: 'gp_a', buyerFactionId: 'gp_h', commodityId: 'timber', quantity: 5, pricePerUnit: 30.0)`, **when** the user taps the `Deal Book` tab label, **then** the widget tree contains exactly one widget keyed `dealBookFilledRowKey(dealBookSideBids, 0)`, no widget keyed `dealBookFilledRowKey(dealBookSideBids, 1)`, the row text is `timber — qty 5 × 30.0 = 150`, no `tradeScreenDealBookBidsEmpty` widget is mounted, and the `tradeScreenDealBookBidsTotals` widget renders the literal `Total spent: 150`.

- **Given** the same conditions and a second, **unrelated** deal `FilledDeal(sellerFactionId: 'gp_a', buyerFactionId: 'gp_b', commodityId: 'iron', quantity: 4, pricePerUnit: 50.0)` is present on `lastTurnActivity['iron'].deals`, **when** the user taps the `Deal Book` tab label, **then** no row keyed `dealBookFilledRowKey(dealBookSideBids, ?)` is mounted for the iron deal (the buyer filter excludes it), and the bids panel total spent remains `150`.

- **Given** the `TradeScreen` is mounted with a human player `gp_h`, observe mode is **not** active, and `lastTurnActivity` contains two filled sales by `gp_h` — `timber qty 7 × 30.0` and `iron qty 3 × 60.0` — both with `sellerFactionId == 'gp_h'`, **when** the user taps the `Deal Book` tab label, **then** the widget tree contains exactly two widgets keyed `dealBookFilledRowKey(dealBookSideOffers, 0)` and `dealBookFilledRowKey(dealBookSideOffers, 1)`, and the `tradeScreenDealBookOffersTotals` widget renders the literal `Total received: 390` (`7×30 + 3×60`).

- **Given** the `TradeScreen` is mounted with a human player `gp_h`, observe mode is **not** active, `lastTurnActivity` is empty, and `carryForwardBidsByFactionId['gp_h']` contains a single `TradeOrder(commodityId: 'timber', type: bid, quantity: 8, priority: 2)`, **when** the user taps the `Deal Book` tab label, **then** the widget tree contains exactly one widget keyed `dealBookUnfilledRowKey(dealBookSideBids, 0)`, the row text is `timber — qty 8 (priority 2)`, no `dealBookFilledRowKey(dealBookSideBids, ?)` widget is mounted, no `tradeScreenDealBookBidsEmpty` widget is mounted, and the `tradeScreenDealBookBidsTotals` widget continues to render the literal `Total spent: 0` (carry-forwards have not cleared and never contribute to treasury totals).

- **Given** the `TradeScreen` is mounted with a human player `gp_h`, observe mode is **not** active, `lastTurnActivity` is empty, and `carryForwardOffersByFactionId` contains entries for `gp_h` (`fabric qty 6 priority 1`, `fabric qty 4 priority 3`) **and** for the foreign GP `gp_a` (`timber qty 99 priority 1`), **when** the user taps the `Deal Book` tab label, **then** the widget tree contains exactly two widgets keyed `dealBookUnfilledRowKey(dealBookSideOffers, 0)` and `dealBookUnfilledRowKey(dealBookSideOffers, 1)`, and no widget with text `timber — qty 99 (priority 1)` is mounted anywhere (player isolation: foreign carry-forwards never leak into the human player's Deal Book).

- **Given** the `TradeScreen` is mounted with a human player `gp_h`, observe mode is **not** active, and `lastTurnActivity['timber'].deals` contains one FRR-tagged buy (`isFirstRightOfRefusalMatch: true`) and one FTP-tagged buy (`isFtpMatch: true`) both with `buyerFactionId == 'gp_h'`, **when** the user taps the `Deal Book` tab label, **then** the widget tree contains exactly two widgets keyed `dealBookFilledRowKey(dealBookSideBids, 0)` and `dealBookFilledRowKey(dealBookSideBids, 1)`, the literal text `FRR` appears exactly once on the page, the literal text `FTP` appears exactly once on the page, and `tradeScreenDealBookBidsTotals` renders the literal `Total spent: 180` (`3×30 + 3×30`).

- **Given** the viewport width is at least `TradeScreen.dealBookTwoPanelMinWidth` (600 dp), **when** the Deal Book tab is foregrounded, **then** `tester.getTopLeft(find.byKey(dealBookOffersPanelKey)).dx` is strictly greater than `tester.getTopLeft(find.byKey(dealBookBidsPanelKey)).dx` and their `dy` values are equal (the panels render side-by-side with a shared top anchor inside the `Row`).

- **Given** the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, **when** the Deal Book tab is foregrounded, **then** `tester.takeException()` returns `null`, `tester.getTopLeft(find.byKey(dealBookOffersPanelKey)).dy` is strictly greater than `tester.getTopLeft(find.byKey(dealBookBidsPanelKey)).dy` (the panels stack vertically), and the Deal Book renders inside the 320 dp column without horizontal overflow.

### Deal Book tab — initial tab override + Widgetbook stories (`#2993` E7)

- **Given** the `TradeScreen` is mounted with `initialTabIndex: 1` (the Deal Book tab) and observe mode is **not** active, **then** on the first frame after pump (without simulating a label tap) the Deal Book tab body keyed `tradeScreenDealBookTabBody` is the on-stage child of the `CtTabStrip` `IndexedStack` (`Visibility(visible: true)` — `find.byKey(dealBookTabBodyKey)` resolves to one widget without `skipOffstage: false`) and the Market tab body keyed `tradeScreenMarketTabBody` is off-stage (visible only via `find.byKey(..., skipOffstage: false)`).
- **Given** the `TradeScreen` is mounted **without** an explicit `initialTabIndex` argument, **then** the existing E4 default contract holds — `initialTabIndex` resolves to `0`, the Market tab body is foregrounded on first frame, and the Deal Book tab body is off-stage. This preserves backwards-compatibility for the production route.
- **Given** the `TradeScreen` is mounted with `initialTabIndex: 1` and a `worldMarketState` whose `lastTurnActivity` is empty and whose carry-forward maps are empty, **then** the foregrounded Deal Book body contains the `tradeScreenDealBookBidsEmpty` and `tradeScreenDealBookOffersEmpty` widgets and the totals rows render `Total spent: 0` / `Total received: 0`.
- **Given** the `TradeScreen` is mounted with `initialTabIndex: 1` and the *mixed fills + carry-forwards* `worldMarketState` (one FRR-tagged human buy + one FTP-tagged human buy of timber `3 × 30.0` each, one human sale of iron `4 × 80.0`, one FTP-tagged human sale of fabric `7 × 120.0`, one human carry-forward bid grain `qty 8 priority 2`, one human carry-forward offer cast-iron `qty 4 priority 1`, plus a foreign carry-forward `gp_aragon` timber `qty 99 priority 1`), **then** the Deal Book body contains exactly two `dealBookFilledRow(dealBookSideBids, *)` widgets, exactly two `dealBookFilledRow(dealBookSideOffers, *)` widgets, exactly one `dealBookUnfilledRow(dealBookSideBids, 0)` widget, exactly one `dealBookUnfilledRow(dealBookSideOffers, 0)` widget, the literal text `FRR` appears exactly once on the foregrounded Deal Book body, the literal text `FTP` appears exactly twice (one FTP-tagged bid + one FTP-tagged sale), no widget rendering the foreign timber carry-forward (`timber — qty 99 (priority 1)`) is mounted, the bids totals row reads `Total spent: 180` (`3×30 + 3×30`), and the offers totals row reads `Total received: 1160` (`4×80 + 7×120`).
- **Given** the Widgetbook `tradeScreenDirectories` are registered into the catalog, **then** the `Trade Screen` folder lists every documented use case in this order — `Scaffold (Market tab)`, `Scaffold (mobile)`, `Market tab — staged bid + offer (Refs #2993 E5b)`, `Market tab — cargo saturated (Refs #2993 E5c)`, `Deal Book tab — empty (Refs #2993 E7)`, `Deal Book tab — mixed fills + carry-forwards (Refs #2993 E7)`, `Deal Book tab — mobile (stacked) (Refs #2993 E7)`. The order matches `SPEC/ui/trade-screen.md` § Widgetbook so reviewers and the catalog stay in lockstep.

### `CtTabStrip.initialTabIndex` (`#2993` E7 — shared primitive)

- **Given** a `CtTabStrip` is constructed with `initialTabIndex: i` where `0 ≤ i < tabLabels.length`, **when** the strip is first mounted, **then** the inner `IndexedStack.index` resolves to `i` on the first frame and the corresponding tab label paints in `EditorialMonoclePalette.accentBright` (selected state) without any user input.
- **Given** a `CtTabStrip` is constructed with `initialTabIndex` outside the bounds of `tabLabels`, **then** the constructor `assert` fails with the message `initialTabIndex out of bounds for the supplied tabLabels`. This is a programmer-error contract — production callers must clamp before passing.
- **Given** a `CtTabStrip` is constructed without an explicit `initialTabIndex`, **then** the parameter resolves to `0` and the existing default-selection contract is preserved (no other `CtTabStrip` consumer has to opt in to keep its existing behavior).

### Full screen (follow-up `#2993` E5b cont.)

Migrate the remaining parent-issue ACs from `#2988` § Acceptance criteria — UI into Given–When–Then rows under this section as each follow-up slice ships (priority dropdown bound to `kMaxTradePriority`).
