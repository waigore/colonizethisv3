# World Market Resolution

**SPEC/program** — Phase 13 resolution algorithm: gathers `TradeOrder` submissions and auto-generated minor/tribe offers, runs per-commodity priority-queue deal matching with FTP and first-right-of-refusal tiebreaking, applies commodity / treasury / cargo transfers, updates `WorldMarketState` prices, and rolls unfilled quantities forward as carry-forwards. Game rules: [world-market.md](../game/world-market.md). Phase placement: [turn-resolution-phases.md](turn-resolution-phases.md) § Phase 13. Diplomacy interaction: [diplomacy-resolution.md](diplomacy-resolution.md). Cargo allocation: [auto-transport.md](auto-transport.md). Trade order shape: [orders.md](orders.md).

> **Status:** Foundational TDD for [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988). Concrete data types, price discovery, deal matching, trade-order validation, FTP diplomatic agreement, and the trade-order suggestion API are implemented by [issue #2989](https://github.com/waigore/colonizethisv3/issues/2989) (slice A1–A8). Phase wiring is implemented by #2990, minor/tribe auto-sell by #2991, first right of refusal by #2992, UI by #2993, AI by #2994. When each remaining slice lands, extend the relevant section with concrete class names and file paths.

---

## Data model

`WorldMarketState` lives on `Game.worldState` and survives serialization. It carries the current per-commodity market price and the **previous-turn** activity rollup used by the UI Deal Book and by the AI treasury planner. Per-turn match results are produced as a `DealMatchResult` value carried in `TurnPipelineState` (see [turn-resolution.md](turn-resolution.md)) and consumed by the End-of-turn phase for victory/event surfacing.

High-level shape:

```
WorldMarketState {
  Map<CommodityId, double> prices;                                // current market price per commodity
  Map<CommodityId, MarketActivity> activity;                      // previous-turn activity (or empty on game start)
  Map<FactionId, List<TradeOrder>> carryForwardOffersByFactionId; // submitter-keyed; original priority preserved
  Map<FactionId, List<TradeOrder>> carryForwardBidsByFactionId;   // submitter-keyed; original priority preserved
}

MarketActivity {
  int totalBidQuantityNew;       // current-turn newly-submitted bid quantity
  int totalOfferQuantityNew;     // current-turn newly-submitted offer quantity
  int filledQuantity;            // total units matched this turn
  double priceChangePercent;     // applied capped Δ% per § Price discovery
  List<FilledDeal> deals;        // for Deal Book ledger
  List<MarketActivityNote> notes;// drop reasons, validation rejections, etc.
}

FilledDeal {
  FactionId sellerId;
  FactionId buyerId;
  CommodityId commodityId;
  int quantity;
  double pricePerUnit;            // = pre-turn price (deals clear at old price)
  bool isFtpMatch;
  bool isFirstRightOfRefusalMatch;
}
```

`TradeOrder` (added to [orders.md](orders.md) by issue #2989) carries `submitterId`, `commodityId`, `type ∈ {bid, offer}`, `quantity`, `priority` (1 = highest tier), and an `originTileKey` for offers attributed to a specific minor/tribe tile (used by first right of refusal).

### Concrete Dart types (issue #2989 slice A1/A3)

Implemented in `packages/colonizethis_models/lib/src/world_market.dart`. Immutable, JSON-serializable, value-equal, following existing model conventions.

```dart
enum TradeOrderType { bid, offer }            // lowercase JSON

enum TradeOrderStatus {
  pending,
  filled,
  partiallyFilled,
  unfilled,
  droppedInsufficientStockpile,
  droppedInsufficientCargo,
  rejected,
}

class TradeOrder {
  final CommodityId commodityId;
  final TradeOrderType type;
  final int quantity;
  final int priority;            // 1 = highest; positive int
  final bool isFtp;              // derived during matching
}
```

Invariants enforced in the `TradeOrder` constructor (throw `ArgumentError`): `quantity >= 0`, `priority >= 1`, `commodityId.isNotEmpty`.

```dart
class MarketActivity {
  final int totalBidQuantity;
  final int totalOfferQuantity;
  final int filledQuantity;
  final double priceChangePercent;
  final List<FilledDeal> deals;        // per-commodity Deal Book ledger
  final List<MarketActivityNote> notes;
}

class WorldMarketState {
  final Map<CommodityId, double> prices;
  final Map<CommodityId, MarketActivity> lastTurnActivity;
  final Map<String, List<TradeOrder>> carryForwardOffersByFactionId;
  final Map<String, List<TradeOrder>> carryForwardBidsByFactionId;
}

class FilledDeal {
  final String sellerFactionId;
  final String buyerFactionId;
  final CommodityId commodityId;
  final int quantity;
  final double pricePerUnit;
  final bool isFtpMatch;
}

class DealMatchResult {
  final List<FilledDeal> filledDeals;
  final Map<String, List<TradeOrder>> unfilledOffersByFactionId;
  final Map<String, List<TradeOrder>> unfilledBidsByFactionId;
  final Map<CommodityId, MarketActivity> activityByCommodityId;
}
```

`MarketActivity.empty`, `WorldMarketState.empty`, and `DealMatchResult.empty` are zero records. `WorldMarketState.withDefaultPrices(Map<CommodityId, int> basePrices)` returns a populated initial state.

`Orders.tradeOrders` (per [orders.md](orders.md)) carries the per-player `List<TradeOrder>` submitted this turn. `Game.worldMarket` holds the `WorldMarketState`. `Game.ftpPartnershipKeys` holds canonical bilateral FTP pair keys (see § Favored Trading Partner).

## Resolution algorithm

Phase 13 runs after phase 12 Build/work and before phase 14 End-of-turn ([turn-resolution-phases.md](turn-resolution-phases.md) § Phase Sequence). All steps execute deterministically: ties between equal-priority entries are broken by ascending `submitterId`, then by ascending order id, so identical merged-order input produces identical match outcomes across runs ([turn-resolution-phases.md](turn-resolution-phases.md) § Determinism).

### Step A — Gather

1. Validate and accept this turn's newly-submitted Great-Power `TradeOrder` list against [world-market.md](../game/world-market.md) § Validation (concrete validator: § Trade order validation below). Rejected orders are discarded; the rejection is logged and surfaced in `MarketActivity.notes`.
2. Generate auto-offers for every connected developed resource on every Minor Nation and Tribe tile per [world-market.md](../game/world-market.md) § Minor and tribe auto-sell. Auto-offers use `priority = 1`, `submitterId = minorOrTribeId`, and `originTileKey` set to the source tile.
3. **Lock-recovery minor auto-bids (Refs #2924 F15).** When at least one Great Power has `player.treasury < cheapestRegimentBuildTreasuryCost()`, each Minor Nation and Tribe submits one synthetic `TradeOrder(type: bid)` for the liquidity food commodity (highest prior-turn offer volume among food commodities, same rule as `SPEC/ai/treasury-planner.md` § Lock-recovery liquidity commodity). Implementation: `lock_recovery_minor_bids.dart` / `computeLockRecoveryMinorAutoBids`. Priority `2` (urgent tier, aligned with broke GP grain offers). Inject per-minor/tribe `tradeCapacity` and `treasuryBudget` into the matcher only (not `Player.treasury`); buyer debits are a sink because minors/tribes are not GPs. These bids are excluded from price-discovery aggregation (not GP-submitted) and do not carry forward.
3.1. **Lock-recovery treasury floor (Refs #2924 F15).** Before Step C matching, any Great Power with `treasury < cheapestRegimentBuildTreasuryCost()` and `treasury < 0` is clamped to `0` for phase-13 accounting only so seller credits from urgent offers are not consumed servicing negative balances left by phases 1–12. This is not an affordability bypass for regiment builds.
3.2. **Lock-recovery seller credit amplification (Refs #2924 F15).** When applying filled deals, liquidity-food sales by broke GP sellers (`treasury < cheapestRegimentBuildTreasuryCost()` at phase start) credit **2×** match notional plus `kLockRecoverySellerBonusPerLiquidityDeal` (75) per deal, still keyed off the matched quantity and price (no affordability bypass).
4. Drop carry-forward offers whose submitter stockpile is insufficient and carry-forward bids whose submitter trade cargo capacity is insufficient ([world-market.md](../game/world-market.md) § Order persistence). Record each drop as a `MarketActivityNote`.
5. Combine accepted current-turn orders, surviving carry-forwards, minor/tribe auto-offers, and lock-recovery minor bids into per-commodity working queues, preserving submitter, priority, origin, and new-vs-carry provenance.

### Step B — Build queues

For each commodity, partition into an offer queue and a bid queue. Sort each queue **ascending by integer priority** (so priority 1 fills before priority 2, etc.; lower integer = higher precedence). Within each integer priority tier, sort:

1. **First right of refusal first.** Any bid whose `submitterId` owns at least one purchased tile sourcing this commodity is moved to an **absolute-priority tier above tier 1** for matching purposes (see Step C). Symmetrically, offers with `originTileKey` on that GP's purchased tile are paired into the absolute-priority tier with that GP's bid only.
2. **Lock-recovery sellers (Refs #2924).** Within a tier, offers from Great Powers whose `treasury < cheapestRegimentBuildTreasuryCost()` (from `colonizethis_data` `regiment_economy.dart`) sort before other offers; among those sellers, ascending phase-start `treasury` (poorest first) so limited buyer cargo reaches the most broke GPs instead of early faction ids alone.
3. **FTP tiebreaker.** Among remaining entries at the same integer priority tier, pairs whose `submitterId`s share an active FTP record (from phase 6 Diplomacy) are sorted before non-FTP pairs. FTP never crosses priority tiers.
4. **Submitter id (deterministic).** Equal-priority, equal-FTP entries sort by ascending `submitterId` then by ascending order id.

### Step C — Match

Maintain a per-buyer running cargo accumulator `remainingCargo[buyerId] = tradeCapacity[buyerId]` (see [world-market.md](../game/world-market.md) § Cargo) and a per-buyer running treasury accumulator `remainingTreasury[buyerId] = max(0, treasuryBudget[buyerId])` (see [world-market.md](../game/world-market.md) § Treasury budget for bids; the budget is the buyer's `Player.treasury` at phase 13 start, clamped at `0` for negative balances). For each commodity, iterate priority tiers from the absolute-priority first-right tier downward through integer tiers (1, 2, …). Within each tier, iterate offers in sorted order; for each offer, iterate compatible bids:

```
maxAffordable = pricePerUnit > 0
    ? floor(remainingTreasury[bid.submitterId] / pricePerUnit)
    : bid.remaining     // missing-price defect path: legacy free-fill preserved
matchQty = min(offer.remaining,
               bid.remaining,
               remainingCargo[bid.submitterId],
               maxAffordable)
if matchQty > 0:
  emit FilledDeal(seller=offer.submitterId, buyer=bid.submitterId,
                  commodity=c, quantity=matchQty,
                  pricePerUnit=WorldMarketState.prices[c],   // OLD price
                  isFtpMatch=ftpPair(offer, bid),
                  isFirstRightOfRefusalMatch=firstRightPair(offer, bid))
  offer.remaining -= matchQty
  bid.remaining   -= matchQty
  remainingCargo[bid.submitterId] -= matchQty
  if pricePerUnit > 0:
    remainingTreasury[bid.submitterId] -= round(matchQty * pricePerUnit)
```

Cargo tracking is **per buyer**, shared across all that buyer's commodities. Once `remainingCargo` reaches zero for a buyer, none of that buyer's remaining bids are filled. Treasury tracking is also **per buyer**, shared across all that buyer's commodities and tiers: once `remainingTreasury` falls below `pricePerUnit` for the current match, that bid produces no further fills in the same phase pass; subsequent bids for the same buyer at any tier or commodity are skipped if they would require treasury the buyer no longer has. Partial fills are emitted as a `FilledDeal` for the matched quantity and a residual remainder on the bid; the residual continues to the next bid/offer pairing in the same tier, then to subsequent tiers if it remains. **In-turn treasury credits are not folded back into the running tally** mid-match: FRR overseas-profit credits and GP-seller credits remain Step-D additive (preserves determinism and avoids a fixed-point pass).

A treasury-truncated bid (residual `> 0` because `maxAffordable` clamped the match) records exactly one `MarketActivityNote` with `kind = bidPartialFillTreasuryInsufficient` on the commodity's `MarketActivity` so the Deal Book and observer tooling can attribute the truncation. The treasury-truncated residual is preserved in `unfilledBidsByFactionId` with original `priority` / `commodityId` / `isFtp` / `originTileKey` and rolls into `WorldMarketState.carryForwardBidsByFactionId` per § Step E.

### Step D — Apply transfers

For every `FilledDeal`:

- Debit `buyerId` treasury by `quantity × pricePerUnit`.
- For Great-Power sellers, credit `sellerId` treasury by `quantity × pricePerUnit` and add `quantity` units of `commodityId` to `buyerId`'s central stockpile; subtract `quantity` from `sellerId`'s central stockpile.
- For Minor/Tribe sellers, add `quantity` units to `buyerId`'s central stockpile and subtract from the source tile's effective auto-offer pool. Sale proceeds follow the treasury-sink rule below.

### Treasury sink (minor/tribe offers)

Minor Nations and Tribes never hold treasury (see [factions.md](../game/factions.md)). For each `FilledDeal` whose seller is a Minor or Tribe:

- If the buyer's purchase falls under **first right of refusal — overseas profit** ([world-market.md](../game/world-market.md) § First right of refusal): credit the owning GP by `quantity × pricePerUnit × profitRate` and remove the remainder from the economy. No other faction is credited.
- Otherwise: remove the full `quantity × pricePerUnit` from the economy. No faction is credited.

The treasury sink is recorded as a `MarketActivityNote` (`treasury_sink_minor_tribe`) so the Deal Book and observer tools can audit the flow.

### Step E — Price discovery and carry-forwards

Aggregate `totalBid_new` and `totalOffer_new` per commodity from this turn's newly-submitted orders, with a bid-side asymmetry:

- `totalBid_new[c]` aggregates the **filled portion** of this turn's newly-submitted bids for commodity `c`. Concretely: per faction `f` and commodity `c`, `filledNewBids[f, c] = min(submittedNewBids[f, c], filledQuantityByBuyer[f, c])` (newly-submitted bids appear at the head of each faction's merged bid list per § Step A, so Step C consumes them before any carry-forward residuals; the `min` allocates filled units to newly-submitted bids first). Sum `filledNewBids` across factions to obtain `totalBid_new[c]`.
- `totalOffer_new[c]` aggregates the **submitted** quantity of this turn's newly-submitted offers for commodity `c` (offers are stockpile-bounded by `TradeOrderValidator` rule 7, which already eliminates the anti-gaming surface that bids carry).

Carry-forward quantities (offers and bids) and minor/tribe auto-offers remain excluded from price discovery — they continue to participate in matching but never contribute to `totalBid_new` or `totalOffer_new`.

The bid-side filled-quantity cap prevents a low-treasury or low-cargo Great Power from staging unfillable mega-bids to inflate `Δ%` upward. Compute `Δ%` per [world-market.md](../game/world-market.md) § Price discovery, cap at ±20 %, apply multiplicatively, and clamp to the 30 %-of-base floor. Persist the new price into `WorldMarketState.prices` for next-turn matching; this-turn deals already cleared at the **old** price in Step C.

Remaining unfilled offers and bids that originated from a Great-Power submitter (including residuals from partial fills) are tagged with their original priority and submitter and pushed onto `WorldMarketState.carryForwardOffersByFactionId` / `carryForwardBidsByFactionId` (per-faction-keyed maps mirroring `DealMatchResult.unfilledOffersByFactionId` / `unfilledBidsByFactionId`) for the next turn. Minor/Tribe auto-offers do not carry forward: each turn re-emits them based on that turn's extraction.

### Step F — Activity rollup

Replace `WorldMarketState.activity` with a fresh `Map<CommodityId, MarketActivity>` that includes the current-turn `totalBidQuantityNew`, `totalOfferQuantityNew`, `filledQuantity` (sum of `FilledDeal.quantity` across this turn), `priceChangePercent`, the full `deals` list, and any `notes` (drops, validation rejections, treasury-sink entries). The phase emits the activity payload to the End-of-turn pipeline for victory checks and Deal-Book UI consumption.

---

## Price discovery

Implementation: `packages/colonizethis_logic/lib/src/economy/world_market/price_discovery.dart`. Pure (no I/O, no logger calls), safe under the 15-second turn-resolution budget ([colonizethis-turn-resolution-budget](../../.cursor/rules/colonizethis-turn-resolution-budget.mdc)).

```dart
typedef PriceDiscoveryInputs = ({
  double oldPrice,
  int basePrice,
  int newBidQuantity,
  int newOfferQuantity,
});

double computeNextPrice(PriceDiscoveryInputs i);
MarketActivity computeMarketActivity(PriceDiscoveryInputs i, {required int filledQuantity});
```

Algorithm (matches [world-market.md § Price discovery](../game/world-market.md)):

```
volume = newBidQuantity + newOfferQuantity
if volume == 0: return oldPrice
rawDelta = 0.5 * (newBidQuantity - newOfferQuantity) / volume
cappedDelta = clamp(rawDelta, -0.20, 0.20)
candidate = oldPrice * (1 + cappedDelta)
floor = basePrice * 0.30
return max(candidate, floor)
```

Constants are exposed as named values for tests:

- `PriceDiscovery.maxDeltaPerTurn = 0.20`
- `PriceDiscovery.priceFloorRatio = 0.30`
- `PriceDiscovery.deltaCoefficient = 0.5`

`computeMarketActivity` returns a `MarketActivity` with `priceChangePercent = (newPrice / oldPrice) - 1.0` (zero when `oldPrice == 0`, a defensive guard for hand-constructed test states).

---

## Deal matching engine

Implementation: `packages/colonizethis_logic/lib/src/economy/world_market/deal_matcher.dart`. Pure, deterministic, silent (no logger calls). Concretely realizes Steps B–C of the resolution algorithm above.

```dart
typedef DealMatchInputs = ({
  Map<String, List<TradeOrder>> offersByFactionId,
  Map<String, List<TradeOrder>> bidsByFactionId,
  Map<String, int> tradeCapacityByFactionId,
  Map<String, int> treasuryBudgetByBuyerFactionId, // missing buyer → 0
  Map<CommodityId, double> pricesByCommodityId,
  Set<String> ftpPairKeys,
  PurchasedTileIndex? purchasedTileIndex, // null disables FRR (legacy)
});

class DealMatcher {
  static String pairKey(String a, String b);    // canonical "min|max"
  static DealMatchResult matchDeals(DealMatchInputs inputs);
}
```

`treasuryBudgetByBuyerFactionId` carries each buyer's `Player.treasury` at phase 13 start, clamped at `0` for negative balances. A buyer that has bids but is missing from this map is treated as having `treasury = 0` (mirroring the existing `tradeCapacityByFactionId` edge case) — no fills are emitted for that buyer and every bid carries forward at original quantity. The matcher decrements a per-buyer `remainingTreasuryByBuyerFactionId` mirror after each emitted `FilledDeal` by `round(matchQty × pricePerUnit)`; this running tally is the fourth term in the `matchQty` clamp (see § Step C). The FRR pre-pass uses the same clamp — FRR fills are not exempt.

For each commodity that appears in any offer or bid (commodities iterated in alphabetical id order for determinism):

1. Collect all offers as `(sellerFactionId, TradeOrder)` entries; collect all bids as `(buyerFactionId, TradeOrder)` entries.
2. **First Right of Refusal pre-pass (issue #2992 D2).** When `purchasedTileIndex` is non-`null` and non-empty, iterate offers in `(sellerFactionId, faction-local index)` order. For each offer whose `TradeOrder.originTileKey` resolves through `purchasedTileIndex.attributionForTileKey`, look up the `owningGpId`. Iterate that owning GP's bids for the same commodity in `factionLocalIndex` order and attempt fills **before** any priority-tier loop. Each emitted `FilledDeal` carries `isFirstRightOfRefusalMatch: true` and ignores FTP membership for this match. Buyer cargo (`remainingCargoByBuyerFactionId`) is decremented per match. The pre-pass is a no-op when `purchasedTileIndex` is `null` (preserves the legacy contract for callers that have not yet wired FRR).
3. Group remaining entries by integer `priority`. Process priority tiers in **ascending integer order** (tier `1` first — lower integer is higher precedence).
4. Inside each tier, run two passes:
   - **Pass 1 — FTP-only.** Iterate offers in `(sellerFactionId, faction-local index)` order. For each offer, iterate bids in `(buyerFactionId, faction-local index)` order and attempt a fill **only if** `ftpPairKeys` contains `pairKey(sellerFactionId, buyerFactionId)`. Buyer cargo (`remainingCargoByBuyerFactionId`) is consulted before each match attempt; if the buyer has zero cargo left, skip the bid.
   - **Pass 2 — Any.** Iterate the remaining offers and bids (those with `remaining > 0`) in the same order and attempt matches regardless of FTP.
4. A match attempt produces `matchQty = min(offer.remaining, bid.remaining, buyer.remainingCargo)`. When `matchQty > 0` the matcher emits a `FilledDeal(sellerFactionId, buyerFactionId, commodityId, quantity: matchQty, pricePerUnit: pricesByCommodityId[commodityId] ?? 0.0, isFtpMatch: <ftp-paired>)`, decrements the offer's and bid's remaining quantities, and decrements `remainingCargoByBuyerFactionId[buyerFactionId]` by `matchQty`.
5. After all tiers process for a commodity, any offer with `remaining > 0` is preserved in `unfilledOffersByFactionId` (keyed by `sellerFactionId`, original order ordering preserved). Bids likewise feed `unfilledBidsByFactionId`. Orders whose remaining is `0` are not preserved.
6. The carry-forward `TradeOrder` instances are constructed via `copyWith(quantity: remaining)` so unrelated fields (priority, isFtp, type) survive next-turn re-entry intact.

`activityByCommodityId` records, per commodity with submitted volume, a `MarketActivity` with `totalBidQuantity` (sum of input bids), `totalOfferQuantity` (sum of input offers), `filledQuantity` (sum across emitted `FilledDeal`s), and `priceChangePercent = 0.0`. Price discovery is composed separately by the phase handler (Issue B / #2990) using `PriceDiscovery.computeNextPrice`, because only the phase handler knows which inputs are newly-submitted vs carry-forward.

### Phase-handler activity rollup — `deals` ledger (Refs #2993 E6)

`worldMarketTurnPhaseHandler` is the sole writer of `MarketActivity.deals`. After Step C/D it groups the resolved turn's `DealMatchResult.filledDeals` by `commodityId` and writes the per-commodity list (preserving emission order) onto the `MarketActivity` it builds for `WorldMarketState.lastTurnActivity`. The list is stored unmodifiable. Commodities that received submissions but produced zero fills carry an empty `deals` list; commodities with no submissions are absent from `lastTurnActivity` altogether. Carry-forward residuals are **not** in `deals` — they live on `carryForwardOffersByFactionId` / `carryForwardBidsByFactionId` and re-enter next turn's match. The Deal Book UI (`SPEC/ui/trade-screen.md` § Deal Book tab) filters `deals` per the active player's faction id (buyer or seller side) and never mutates the list in place.

Edge cases:

- Missing price for a commodity (`pricesByCommodityId` lookup returns `null`) is recorded on emitted `FilledDeal`s as `pricePerUnit = 0.0`. The phase handler is responsible for seeding `pricesByCommodityId` from `WorldMarketState.prices`; a missing entry signals a setup defect, not a runtime failure.
- A faction with bids but no entry in `tradeCapacityByFactionId` is treated as having `tradeCapacity = 0` — none of its bids fill, all carry forward.
- An offer or bid with `quantity == 0` is treated as already exhausted — no `FilledDeal` is emitted, no carry-forward record is generated for it.
- `ftpPairKeys` is consulted as a set; ordering of pairs inside the set does not affect output. The canonical `pairKey` ensures the input set need not be duplicated for both `(a,b)` and `(b,a)`.
- First right of refusal **is** handled by this engine when `purchasedTileIndex` is supplied (see Issue D / #2992 D2). Offers without an `originTileKey`, offers whose `originTileKey` is not in the index, and runs with a `null` index all skip the FRR pre-pass and behave exactly as the legacy tier loop. The D4 treasury transfer (overseas-profit credit to the owning GP) is a separate phase-handler responsibility — it consumes `FilledDeal.isFirstRightOfRefusalMatch` to identify FRR-applied flows and looks up the owning GP via the same `purchasedTileIndex` row to compute the relation-based profit per `SPEC/game/world-market-first-right-of-refusal.md` § Treasury transfer (D4).

---

## Trade order validation

Implementation: `packages/colonizethis_logic/lib/src/economy/world_market/trade_order_validator.dart`. Pure, deterministic, silent. Safe to call from order-submission, suggestion, and resolver-prep paths.

The validator inspects the **full set** of `TradeOrder` entries a single player intends to submit this turn and returns a parallel result list. It does **not** look at carry-forward queues — carry-forwards are re-evaluated at the start of the next turn against current stockpile and cargo per [world-market.md § Trade orders](../game/world-market.md) rule 5.

```dart
class TradeOrderValidationContext {
  const TradeOrderValidationContext({
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    required this.availableStockpileByCommodityId,
    required this.treasuryBudgetForBids,
    this.worldMarketState = const WorldMarketState(),
    this.resourceRules = ResourceRules.defaultRules,
  });

  final String playerId;
  final int bidTypeCap;                                      // 0 / 3 / 6
  final int tradeCargoCapacity;                              // units
  final Map<CommodityId, int> availableStockpileByCommodityId;
  final int treasuryBudgetForBids;
  final WorldMarketState worldMarketState;
  final ResourceRules resourceRules;
}

class TradeOrderValidator {
  static List<OrderValidationResult> validate({
    required TradeOrderValidationContext context,
    required List<TradeOrder> proposedOrders,
  });
}
```

Rules are applied **once per submitted order** in the order received, with two pre-pass classifiers computed first (mutual-exclusion sets and distinct bid commodity sequence) so determinism does not depend on submission interleaving.

| # | Rule | Stable rejection reason code |
|---|------|------------------------------|
| 1 | `TradeOrder.quantity > 0` | `tradeOrderInvalidQuantity` |
| 2 | `TradeOrder.commodityId` is not in `richesCommodityIds` (riches do not trade — see `SPEC/game/commodity-catalog.md`). | `tradeOrderRichesNotTradeable` |
| 3 | A commodity may have only **one** intent per turn: every `TradeOrder` whose `commodityId` appears as **both** a bid and an offer across `proposedOrders` is rejected (both sides — neither survives). | `tradeOrderMutualExclusion` |
| 4 | Distinct bid commodity count must be ≤ `bidTypeCap`. Bids are admitted in submission order until the cap is reached; bids that introduce a **new** commodity past the cap are rejected (later bids on already-admitted commodities still pass this gate). | `tradeOrderBidTypeCapExceeded` |
| 5 | Cross-commodity bid spend: cumulative `Σ (quantity × effectiveMarketPrice)` across admitted bids in submission order must not exceed `treasuryBudgetForBids` (from `treasuryAvailableForBidsByPlayer`, optionally reduced by projected non-bid deficits when the caller supplies staged orders + topology). Bids with no effective price contribute `0` spend. | `tradeOrderBidExceedsTreasuryBudget` |
| 6 | Per-commodity bid quantity ≤ `tradeCargoCapacity`. | `tradeOrderBidExceedsCargoCapacity` |
| 7 | Per-commodity offer quantity ≤ `availableStockpileByCommodityId[commodityId] ?? 0`. | `tradeOrderOfferExceedsStockpile` |

Rules 1–2 are intrinsic to the order. Rules 3–4 are computed from the submitted set. Rule 5 tracks running treasury spend across admitted bids in submission order. Rules 6–7 are per-order quantity checks. The validator records the **first** failing rule for each rejected order (deterministic order: 1 → 2 → 3 → 4 → 5 → 6 → 7). Accepted orders return `OrderValidationResult.accepted()`. Stable rejection codes are exposed as `String` constants on `TradeOrderRejectionReasons` so UI, AI suggestion, and tests can branch on them without parsing free-text.

### Bid type cap helper

`worldMarketBidTypeCap(Game game, String playerId)` lives in `packages/colonizethis_logic/lib/src/diplomacy/diplomacy_subsidies_relations_resolver.dart` next to `tradeSlotsForGp` ([diplomacy-resolution.md](diplomacy-resolution.md)):

- `0` only when [playerId] is not a known player (`Game.playerById` returns `null`).
- `kWorldMarketBaselineBidTypeCap` (= **1**) when the player exists and has no embassy (`OvertureStage.embassy` or stronger) with **any** target faction. This baseline keeps the global market liquid for every Great Power — including EXPAND-phase GPs that are structurally blocked from emitting NW-only `establishOverture` orders (`SPEC/ai/phase-planner-architecture.md` § EXPAND planner suppressions) — so treasury can still redistribute through legitimate trade per [world-market.md](../game/world-market.md) § Bid type cap.
- `3` when the player has at least one embassy and has not unlocked `kTechIdTradeFairs`.
- `6` when the player has at least one embassy **and** has unlocked `kTechIdTradeFairs`.

This is the **world-market**-scoped analogue of `tradeSlotsForGp` (which is per-target). The market is global, so the cap aggregates across all of the player's embassies. The baseline `1`-cap step preserves the embassy gradient (`1 → 3 → 6`): diplomatic investment still multiplies trade reach.

---

## Trade order suggestion API

Implementation: `packages/colonizethis_logic/lib/src/economy/world_market/trade_order_suggester.dart`, wired through `OrderSuggestionAPI.suggestTradeOrders` (default impl in `DefaultOrderSuggestionAPI`). Pure, deterministic, silent.

The suggester returns a `TradeSuggestionResult` carrying parallel offer and bid `TradeOrder` lists that, by construction, pass `TradeOrderValidator.validate` against the same context numbers. Callers (UI prompts, AI `TreasuryPlanner` per Issue F / #2994) may apply additional ranking but never need to re-clamp for validity.

```dart
class TradeSuggestionContext {
  const TradeSuggestionContext({
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    required this.availableStockpileByCommodityId,
    required this.commodityNeedByCommodityId,
    this.treasuryBudgetForBids = 1 << 30,
    this.worldMarketState = const WorldMarketState(),
    this.resourceRules = ResourceRules.defaultRules,
    this.offerPriority = 5,
    this.bidPriority = 5,
  });

  final String playerId;
  final int bidTypeCap;
  final int tradeCargoCapacity;
  final Map<CommodityId, int> availableStockpileByCommodityId;
  final Map<CommodityId, int> commodityNeedByCommodityId;
  final int treasuryBudgetForBids;
  final WorldMarketState worldMarketState;
  final ResourceRules resourceRules;
  final int offerPriority;
  final int bidPriority;
}

class TradeSuggestionResult {
  final List<TradeOrder> offers;
  final List<TradeOrder> bids;
}

class TradeOrderSuggester {
  static TradeSuggestionResult suggest(TradeSuggestionContext context);
}
```

Both selectors iterate commodities in **alphabetical id order** for determinism and skip every entry with `commodityId` in `richesCommodityIds` (rule 2) or `quantity <= 0` (rule 1) before emitting a `TradeOrder`. Mutual-exclusion (rule 3) is enforced at suggestion time: a commodity that has both a positive available stockpile and a positive forecast need is treated as **net** — `net = availableStockpile - need`; positive net produces an offer and zero bid, non-positive net produces a bid (when `need > availableStockpile`) and zero offer. The resulting parallel lists never share a commodity id.

1. **Offer pass** — for every commodity with `net > 0`, emit `TradeOrder(commodityId, type: offer, quantity: net, priority: offerPriority, isFtp: false)`. There is no per-commodity offer cap (rule 6 only requires `quantity <= availableStockpile`, which `net` satisfies by construction).
2. **Bid pass** — maintain `remainingCargoBudget = tradeCargoCapacity`, `remainingTreasuryBudget = treasuryBudgetForBids`, and `admittedBids = 0`. For every commodity with `bidQuantity > 0` (need exceeds available stockpile):
   - Resolve `unitPrice = effectiveMarketPriceForCommodityId(commodityId, worldMarketState, resourceRules)` (same helper as validator rule 5).
   - Compute `cappedQty = min(bidQuantity, remainingCargoBudget)`. When `unitPrice > 0`, further cap with `floor(remainingTreasuryBudget / unitPrice)`; when `unitPrice` is `null` or `0`, treasury does not constrain quantity (validator treats spend as `0`).
   - When `cappedQty == 0` (capacity or treasury exhausted) skip — no zero-quantity bid is emitted.
   - When `admittedBids == bidTypeCap` (cap exhausted) stop iterating bids — later candidates are silently dropped to keep the suggestion validator-clean.
   - Otherwise emit `TradeOrder(commodityId, type: bid, quantity: cappedQty, priority: bidPriority, isFtp: false)`, decrement `remainingCargoBudget` by `cappedQty`, decrement `remainingTreasuryBudget` by `cappedQty × unitPrice` when `unitPrice > 0`, and increment `admittedBids` by 1.

### Default `OrderSuggestionAPI` wiring

`DefaultOrderSuggestionAPI.suggestTradeOrders` derives the context from `Game` / `PlayerView` as follows. Any layer that lacks a richer projection contributes a conservative zero so the suggester never proposes orders that would violate the validator.

| Field | Source |
|-------|--------|
| `bidTypeCap` | `worldMarketBidTypeCap(game, playerId)` |
| `tradeCargoCapacity` | `cargoHoldsForHomeFleet(game, playerId)` (extraction-tonnage subtraction is folded in by the phase handler in Issue B / #2990) |
| `availableStockpileByCommodityId` | `Player.stockpile.quantities` minus `richesCommodityIds`; industry-allocation subtraction stays at the validator boundary today and tightens up when the production projection wires in. |
| `commodityNeedByCommodityId` | empty map until the production-input projection lands; documents the validator-clean default (the suggester emits offers only and `OrderSuggestionAPI` callers must opt in to bids by passing an explicit forecast). |
| `treasuryBudgetForBids` | `treasuryAvailableForBidsByPlayer(game, playerId)` (raw treasury; projection wiring matches validator when callers supply staged orders). |
| `worldMarketState` | `game.worldMarketState` (prices for bid-spend caps). |

---

## Favored Trading Partner (FTP) diplomacy

Storage: `Game.ftpPartnershipKeys` holds canonical bilateral keys (`pairKey(factionA, factionB)` from `diplomacy_relation_lookup.dart`, same format as `DealMatcher.pairKey`).

Order: `DiplomaticOrderType.establishFtp` (GP–GP only). Proposer must have embassy-tier overture toward target and relation score ≥ **65** (`relationScoreMinFtp`). Target must accept (human via `FtpDecision` resume path; AI when score ≥ 65 and target holds embassy toward proposer). Both sides need embassy-tier overture before FTP forms.

Break: FTP removed on war between the pair or when either side loses embassy-tier overture toward the other (`breakFtpOnWar`, `breakFtpOnEmbassyLoss` in Diplomacy phase step 6).

Matching input: `ftpPairKeysFromGame(game)` supplies `DealMatcher.matchDeals` `ftpPairKeys`.

---

## Logging

Phase 13 follows [logging/turn-resolution.md](logging/turn-resolution.md): the turn resolver emits `logic: phase worldMarket start` and `logic: phase worldMarket end`. The resolver logs **key outcomes** with the `logic:` prefix at info level (one entry per commodity that produced a non-zero `filledQuantity` and per first-right-of-refusal payout) and at debug level for per-deal trace. Tight loops over per-bid validation use summary-only logging per the agent run cleanup and turn-resolution-budget rules.

The pure helpers (`computeNextPrice`, `computeMarketActivity`, `DealMatcher.matchDeals`, `TradeOrderValidator.validate`, `TradeOrderSuggester.suggest`) are silent — they never log — so they remain trivially callable from hot paths inside the 15-second turn-resolution budget ([colonizethis-turn-resolution-budget](../../.cursor/rules/colonizethis-turn-resolution-budget.mdc)).

---

## Acceptance criteria

### Phase resolution

- **Empty turn no-op.** Given no Great Power submits any `TradeOrder` and there are no carry-forwards or minor/tribe auto-offers, when phase 13 runs, then the system does not mutate `Game.worldState` apart from copying `WorldMarketState.activity` to an empty per-commodity map; no `FilledDeal`, no price change, and no carry-forward are produced.
- **Priority-tier ordering.** Given offer/bid pairs for the same commodity at integer priorities `1` and `2` and no first-right-of-refusal entries, when phase 13 runs, then the matching engine fully fills the priority-1 pair (subject to quantity and cargo) before considering any priority-2 pair, regardless of FTP status on either pair.
- **FTP within a tier.** Given two offer/bid candidate pairs at the **same** integer priority tier where one pair shares an active FTP record and the other does not, when phase 13 runs, then the FTP pair fills before the non-FTP pair and the non-FTP pair receives only the residual quantity left after the FTP pair clears.
- **First right of refusal beats FTP.** Given Great Power A owns a tile purchased from Minor M producing commodity `C`, GP A submits a bid for `C`, GP B holds an FTP with M, and GP B submits a bid for `C` at priority 1, when phase 13 runs, then GP A's bid fills first against M's purchased-tile offer (absolute-priority tier) and GP B's FTP pair fills only from any remaining tier-1 offer quantity.
- **Cargo enforced per-buyer cumulative.** Given a buyer with `tradeCapacity = 15` and matched bids of A = 8 followed by B = 10 in priority order, when phase 13 processes B, then `remainingCargo[buyer] = 7` after A clears, so B receives a `FilledDeal` of exactly 7 units and a residual carry-forward of 3 units is added to `carryForwardBidsByFactionId[buyer]` with B's original priority preserved.
- **Deals clear at old price.** Given the previous turn's `WorldMarketState.prices[c] = P_old` and a `FilledDeal` for commodity `c` of `Q` units this turn, when the system emits the deal in Step C, then `FilledDeal.pricePerUnit = P_old` and any `Δ%`-adjusted next-turn price applies only after Step E completes.
- **Minor/tribe treasury sink.** Given a `FilledDeal` whose seller is a Minor or Tribe and which is not under first-right-of-refusal overseas profit, when phase 13 applies transfers, then the buyer is debited `Q × P_old`, the buyer's central stockpile gains `Q` units of the commodity, and no faction (including the seller) is credited by any amount.
- **First-right-of-refusal overseas profit.** Given Great Power A owns a tile purchased from Minor M (hidden relation score `R = 75`), GP A submits no bid, and GP B buys 10 units of M's commodity at `P_old = 20`, when phase 13 runs, then `WorldMarketState.activity[c].deals` contains the GP B fill, the system credits GP A treasury by exactly `10 × 20 × (75 / 100) × 0.40 = 60`, and the remaining `10 × 20 − 60 = 140` is removed via the treasury sink.
- **Deterministic matching.** Given two phase-13 runs with identical merged-order input, identical `WorldMarketState`, and identical seeds, when both runs execute Step C, then both emit byte-identical sequences of `FilledDeal` entries (same order, same quantities, same buyers/sellers) and produce byte-identical `MarketActivity` payloads.
- **Carry-forward provenance preserved.** Given a current-turn bid by faction `f` of quantity 10 for commodity `c` at priority 2 that receives a partial fill of 4, when phase 13 produces carry-forwards in Step E, then `WorldMarketState.carryForwardBidsByFactionId[f]` contains one `TradeOrder` with `commodityId = c`, `quantity = 6`, `priority = 2` (the submitter is encoded by the map key, preserving attribution without requiring a per-order `submitterId` field).
- **Phase placement preserved.** Given a turn whose phase sequence runs to completion, when the resolver emits phase markers, then `worldMarket` begins after the `buildWork end` marker and ends before the `endOfTurn start` marker, matching [turn-resolution-phases.md](turn-resolution-phases.md) § Acceptance criteria.
- **Deals ledger emitted per commodity (Refs #2993 E6).** Given current-turn submissions that produce one or more `FilledDeal` entries for commodity `c`, when phase 13 builds `MarketActivity` for `c`, then `MarketActivity.deals` contains each `FilledDeal` exactly once in emission order, no `FilledDeal` for any other commodity, and the list is unmodifiable.
- **Empty deals ledger for unfilled commodity.** Given a commodity `c` receives at least one submitted offer or bid but matching emits no `FilledDeal` for `c` (e.g. offer-only or insufficient cargo), when phase 13 builds `MarketActivity` for `c`, then `MarketActivity.deals.isEmpty` is true (not null, not absent) so the Deal Book UI can iterate it unconditionally.
- **Deals JSON round-trip.** Given a `WorldMarketState` whose `lastTurnActivity[c].deals` has one or more `FilledDeal` entries, when the state is serialized to JSON and parsed back, then the restored `MarketActivity.deals` equals the original (`==` and `hashCode`) including each `FilledDeal`'s `isFirstRightOfRefusalMatch` and `isFtpMatch` flags.

### Treasury clamp inside matcher (Refs #3115)

- **Treasury truncates a single oversized bid.** Given a Great Power `gp1` with `treasury = 100` at phase 13 start, a single tier-1 bid for `10` units of `c` at `pricePerUnit = 30`, a matching tier-1 offer of `10` units, and sufficient buyer cargo, when phase 13 runs, then the matcher emits exactly one `FilledDeal(buyer = gp1, commodity = c, quantity = 3, pricePerUnit = 30)`, post-phase `gp1.treasury == 10`, and `WorldMarketState.carryForwardBidsByFactionId['gp1']` contains the residual bid with `quantity = 7` and original `priority` / `commodityId` / `isFtp` preserved.
- **Treasury exhausts across multiple bids in submission order.** Given `gp1` with `treasury = 100` submits two tier-1 bids in submission order — `A x 5 @ 20` (notional 100) then `B x 5 @ 20` (notional 100) — with matching offers and sufficient cargo, when phase 13 runs, then bid `A` fully fills (`quantity = 5`), bid `B` emits no `FilledDeal`, bid `B`'s full `quantity = 5` carries forward in `carryForwardBidsByFactionId['gp1']`, and post-phase `gp1.treasury == 0`.
- **Negative-treasury buyer is fully suppressed.** Given `gp1` enters phase 13 with `treasury = -50` (already in debt from earlier phases) and any set of bids and matching offers, when phase 13 runs, then no `FilledDeal` is emitted for `gp1`, every one of `gp1`'s submitted and carry-forward bids is preserved in `carryForwardBidsByFactionId['gp1']` at original quantity, and post-phase `gp1.treasury == -50`.
- **FRR respects treasury clamp.** Given `gp1` is the owning GP of a first-right-of-refusal offer for `10` units of `c` at `pricePerUnit = 20`, `gp1.treasury = 60`, and `gp1` submits a bid for `c`, when the FRR pre-pass runs, then it emits `FilledDeal(quantity = 3, isFirstRightOfRefusalMatch = true)` and the residual `7` carries forward in `carryForwardBidsByFactionId['gp1']`.
- **Treasury-insufficient activity note.** Given a treasury-truncated bid (residual `r > 0` because the treasury clamp reduced `matchQty`), when phase 13 records activity notes, then the commodity's `MarketActivity.notes` contains exactly one entry with `kind = bidPartialFillTreasuryInsufficient`, `factionId` equal to the buyer's faction id, and `quantity` equal to the original submitted bid quantity.
- **Deterministic with treasury clamp.** Given two phase-13 runs with identical merged-order input, identical `WorldMarketState`, identical `treasuryBudgetByBuyerFactionId`, and identical seeds, when both runs execute Step C, then both emit byte-identical sequences of `FilledDeal` entries (same order, same quantities, same buyers/sellers).
- **Price-discovery bid-side cap at filled quantity.** Given a treasury-truncated bid for commodity `c` (submitted quantity `S = 10`, filled quantity `F = 3`) and an unrelated offer for `c` of submitted quantity `10`, when phase 13 aggregates Step E, then `totalBid_new[c] == 3` (filled) and `totalOffer_new[c] == 10` (submitted), and the price update uses those values per the existing capped formula.
- **Zero-price commodity preserves legacy free-fill.** Given a bid whose matched offer has `pricePerUnit == 0` (missing-price defect path), when matching runs, then the treasury clamp does not reduce `matchQty` below what the other three clamps would produce, no treasury debit is recorded against `remainingTreasury`, and behavior is preserved relative to the legacy free-fill branch.
- **Missing budget entry treats buyer as zero-treasury.** Given a call to `DealMatcher.matchDeals` whose `treasuryBudgetByBuyerFactionId` omits buyer `gp1` while `gp1` has bids, when matching runs, then `gp1`'s budget is treated as `0` (mirroring the existing `tradeCapacityByFactionId` edge case), no `FilledDeal` is emitted for `gp1`, and every `gp1` bid carries forward at original quantity.

### Data types (issue #2989)

- Given `TradeOrder(commodityId: 'timber', type: bid, quantity: 5, priority: 2, isFtp: false)`, when `toJson()` and `TradeOrder.fromJson` round-trip, then the resulting instance equals the original (including `==` and `hashCode`) and the JSON contains `{commodityId: 'timber', type: 'bid', quantity: 5, priority: 2, isFtp: false}`.
- Given a `TradeOrder` constructor invocation with `quantity = -1`, when the constructor runs, then it throws `ArgumentError` with message containing `quantity`.
- Given a `TradeOrder` constructor invocation with `priority = 0`, when the constructor runs, then it throws `ArgumentError` with message containing `priority`.
- Given `WorldMarketState.withDefaultPrices({'timber': 30, 'iron': 80})`, when the state is constructed, then `prices == {'timber': 30.0, 'iron': 80.0}` and `lastTurnActivity.isEmpty`.

### Price discovery (issue #2989)

- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 20, newOfferQuantity: 10)`, when `computeNextPrice` runs, then it returns `100 * (1 + 1/6) ≈ 116.6666…` (within 1e-9).
- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 0)`, when `computeNextPrice` runs, then it returns `100.0` exactly.
- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 1000, newOfferQuantity: 0)`, when `computeNextPrice` runs, then `cappedDelta = +0.20` and the result is `120.0` (cap applied).
- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000)`, when `computeNextPrice` runs, then `cappedDelta = -0.20` and the result is `max(80.0, 30.0) = 80.0`.
- Given `PriceDiscoveryInputs(oldPrice: 32.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000)`, when `computeNextPrice` runs, then `candidate = 32 * 0.80 = 25.6`, `floor = 30.0`, and the result is `30.0` (floor clamps).
- Given `PriceDiscoveryInputs(oldPrice: 30.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000)`, when `computeNextPrice` runs, then `candidate = 24.0`, floor `30.0`, and the result is `30.0`.
- Given a `computeNextPrice` invocation with `oldPrice = 0.0` and any volumes, when the function runs, then it returns `max(0.0, basePrice * 0.30) = basePrice * 0.30`.
- Given `computeMarketActivity(inputs, filledQuantity: 5)` where the new price equals the old price, when the function runs, then the result `MarketActivity` has `priceChangePercent == 0.0`, `totalBidQuantity == newBidQuantity`, `totalOfferQuantity == newOfferQuantity`, and `filledQuantity == 5`.

### Deal matching engine (issue #2989)

- Given a single commodity with one offer `(seller: 'a', quantity: 10, priority: 1)` and one bid `(buyer: 'b', quantity: 5, priority: 1)`, prices `{commodity: 30.0}`, `tradeCapacity['b'] = 10`, and `ftpPairKeys = {}`, when `DealMatcher.matchDeals` runs, then the result has one `FilledDeal(seller: 'a', buyer: 'b', quantity: 5, pricePerUnit: 30.0, isFtpMatch: false)`, the offer carries forward at quantity `5` under `unfilledOffersByFactionId['a']`, no bid carry-forward is recorded, and `activityByCommodityId[commodity] = MarketActivity(totalBidQuantity: 5, totalOfferQuantity: 10, filledQuantity: 5, priceChangePercent: 0.0)`.
- Given priority tier `1` contains a non-FTP `(seller, buyer)` pair with offer `10` and bid `10`, and tier `2` contains an FTP pair with offer `10` and bid `10`, when matching runs, then the tier-1 pair fills first (priority integer takes absolute precedence over FTP) — tier `2`'s FTP pair fills next only if cargo remains, and the resulting `FilledDeal.isFtpMatch` flags reflect each pair's FTP membership.
- Given priority tier `1` contains an FTP pair `(a, b)` with offer `5` and bid `5`, and a non-FTP pair `(a, c)` with offer `5` and bid `5`, when matching runs, then the FTP pair fills first within tier `1` (FTP is the same-tier tiebreaker) and produces a `FilledDeal(isFtpMatch: true)`; the non-FTP pair fills next from the offer's remaining quantity if any (which is `0` in this scenario, so no second deal is emitted).
- Given a buyer with `tradeCapacity = 15` who submits a priority-1 bid `A x 8` and a priority-2 bid `B x 10`, and offers cover both, when matching runs, then `A` fills `8`, `remainingCargo = 7`, `B` partial-fills `7`, `B`'s carry-forward quantity is `3`, and `activityByCommodityId['B'].filledQuantity = 7`.
- Given a faction has bids but no entry in `tradeCapacityByFactionId`, when matching runs, then no deals are emitted for that faction and every bid for that faction is preserved at its original quantity in `unfilledBidsByFactionId`.
- Given an offer with `quantity = 0` and a bid with positive quantity at the same priority tier, when matching runs, then no `FilledDeal` is emitted from that offer, the zero-quantity offer is not carried forward, and the bid remains unfilled (carries forward at its full quantity if no other offer matches).
- Given `DealMatcher.pairKey('zeta', 'alpha')` and `DealMatcher.pairKey('alpha', 'zeta')`, when both are evaluated, then they return the same canonical key string (`'alpha|zeta'`), so FTP membership set entries are order-independent.

### Validation (issue #2989)

- Given `TradeOrderValidationContext(bidTypeCap: 3, tradeCargoCapacity: 100, availableStockpileByCommodityId: {'timber': 50})` and a single `TradeOrder(commodityId: 'timber', type: offer, quantity: 10, priority: 1)`, when `TradeOrderValidator.validate` runs, then the result is `[OrderValidationResult.accepted()]`.
- Given a player whose submission contains both `TradeOrder(timber, bid, 5, 1)` and `TradeOrder(timber, offer, 5, 1)`, when validation runs, then **both** orders are rejected with reason `TradeOrderRejectionReasons.mutualExclusion`.
- Given `TradeOrder(spices, offer, 5, 1)` and `availableStockpileByCommodityId: {'spices': 999}` (riches), when validation runs, then the order is rejected with reason `TradeOrderRejectionReasons.richesNotTradeable` regardless of stockpile size.
- Given `TradeOrder(timber, bid, 0, 1)`, when validation runs, then the order is rejected with reason `TradeOrderRejectionReasons.invalidQuantity`.
- Given `bidTypeCap = 0` and any bid in the submission, when validation runs, then every bid is rejected with reason `TradeOrderRejectionReasons.bidTypeCapExceeded` and every offer is judged independently against rules 5–6.
- Given `bidTypeCap = 3` and bids on `[timber, iron, coal, wool]` (four distinct commodities, submission order), when validation runs, then the first three bids are accepted (subject to rules 5–6) and the fourth (`wool`) is rejected with reason `TradeOrderRejectionReasons.bidTypeCapExceeded`. A subsequent bid for an already-admitted commodity (e.g. another `timber` bid) does **not** count as a new type and passes rule 4.
- Given `bidTypeCap = 6` and bids on `[timber, iron, coal, wool, hides, cattle, grain]`, when validation runs, then the seventh distinct-commodity bid (`grain`) is rejected with reason `TradeOrderRejectionReasons.bidTypeCapExceeded`.
- Given `treasuryBudgetForBids = 50`, `worldMarketState.prices: {'timber': 30}`, and a single `TradeOrder(timber, bid, 3, 1)` (notional `3 × 30 = 90`), when `TradeOrderValidator.validate` runs, then the order is rejected with reason `TradeOrderRejectionReasons.bidExceedsTreasuryBudget` (Refs #3123).
- Given `treasuryBudgetForBids = 100`, `worldMarketState.prices: {'timber': 30, 'iron': 10}`, and bids `[TradeOrder(timber, bid, 2, 1), TradeOrder(iron, bid, 4, 1)]` in submission order (notionals `60` then `40`, cumulative `100`), when validation runs, then the first result is `accepted`, the second result is `accepted`, and total admitted bid notional equals `100` (cumulative cap is inclusive — equality is admitted) (Refs #3123).
- Given `treasuryBudgetForBids = 100`, `worldMarketState.prices: {'timber': 30, 'iron': 10}`, and bids `[TradeOrder(timber, bid, 4, 1), TradeOrder(iron, bid, 1, 1)]` in submission order (notionals `120` then `10`), when validation runs, then the first result is rejected with reason `TradeOrderRejectionReasons.bidExceedsTreasuryBudget` and the second result is `accepted` (greedy continuation — a rejected bid does not consume the running spend budget so a later smaller bid that fits the remaining budget is admitted) (Refs #3123).
- Given `treasuryBudgetForBids = 0`, `worldMarketState.prices: {'timber': 30}`, and any `TradeOrder(timber, bid, q, 1)` with `q > 0`, when validation runs, then the order is rejected with reason `TradeOrderRejectionReasons.bidExceedsTreasuryBudget` (zero treasury budget rejects every priced bid) (Refs #3123).
- Given `treasuryBudgetForBids = 2 × catalogTimberDefault`, `worldMarketState.prices = {}` (no live price for `timber`), and a single `TradeOrder(timber, bid, 2, 1)`, when validation runs, then the order is `accepted` because rule 5 prices the bid at `ResourceRules.defaultMarketPriceForCommodityId('timber')` (the catalog raw-resource default) and the cumulative notional fits the budget — rule 5 must not reject solely for "missing live price" when an initial/default price exists (Refs #3123).
- Given `treasuryBudgetForBids = catalogLumberDefault`, `worldMarketState.prices = {}` (no live price for `lumber`), and a single `TradeOrder(lumber, bid, 1, 1)`, when validation runs, then the order is `accepted` because rule 5 prices the bid at `ResourceRules.defaultMarketPriceForCommodityId('lumber')` (the catalog manufactured default per `SPEC/game/commodity-catalog.md` § Manufactured base prices) and the cumulative notional equals the budget — manufactured commodities resolve through the same fallback as raw resources (Refs #3123).
- Given two consecutive invocations of `TradeOrderValidator.validate` with byte-identical `proposedOrders` and `TradeOrderValidationContext`, when both invocations run, then both result lists have identical length, identical `isAccepted` values per index, and identical `reason` values per index — the validator is pure and deterministic for fixed inputs, exercising both the accepted and rejected branches of rule 5 in the same submission (Refs #3123).
- Given `effectiveMarketPriceForCommodityId(commodityId, WorldMarketState.empty, ResourceRules.defaultRules)` is invoked for **every** id in `CommodityCatalog.all` excluding `richesCommodityIds`, when each call returns, then every result is non-`null` and `≥ 0` — every tradeable commodity has a catalog default so rule 5 never silently admits unbounded spend on a tradeable commodity for "unknown price" reasons in normal play (Refs #3123 catalog-coverage guard).
- Given a live `Game` where `Player.treasury == 175` for `playerId` and no staged orders or topology supplied, when `tradeOrderValidationContextFromGame(game, playerId)` builds the context, then `TradeOrderValidationContext.treasuryBudgetForBids == 175` (raw treasury, per § Budget source) (Refs #3123).
- Given a live `Game` where `Player.treasury == -25` for `playerId` (already negative from earlier phases) and no staged orders or topology supplied, when `tradeOrderValidationContextFromGame(game, playerId)` builds the context, then `TradeOrderValidationContext.treasuryBudgetForBids == 0` (`treasuryAvailableForBidsByPlayer` clamps negative treasury at zero per `SPEC/game/world-market.md` § Treasury budget for bids) (Refs #3123).
- Given `tradeCargoCapacity = 10` and a single `TradeOrder(timber, bid, 12, 1)`, when validation runs, then the order is rejected with reason `TradeOrderRejectionReasons.bidExceedsCargoCapacity`.
- Given `availableStockpileByCommodityId: {'timber': 5}` and `TradeOrder(timber, offer, 10, 1)`, when validation runs, then the order is rejected with reason `TradeOrderRejectionReasons.offerExceedsStockpile`. The validator does **not** silently cap the quantity — callers (suggestion API, UI) must clamp before submission per `SPEC/game/world-market.md` rule 4.
- Given `worldMarketBidTypeCap(game, playerId)` for a player with **no** overtures or only `OvertureStage.tradeConsulate` overtures, when the helper runs, then the cap is `kWorldMarketBaselineBidTypeCap` (`1`) — baseline participation in the global market for any known Great Power.
- Given `worldMarketBidTypeCap(game, playerId)` for a `playerId` that does not exist in `game.players`, when the helper runs, then the cap is `0` (ghost-player guard; baseline cap applies only to known players).
- Given `worldMarketBidTypeCap(game, playerId)` for a player with at least one `OvertureStage.embassy` (or `nap` / `joinEmpire`) overture and `kTechIdTradeFairs` **not** unlocked, when the helper runs, then the cap is `3`.
- Given `worldMarketBidTypeCap(game, playerId)` for a player with at least one embassy-tier overture and `techUnlocked[kTechIdTradeFairs] == true`, when the helper runs, then the cap is `6`.

### Suggestion API (issue #2989)

- Given `TradeSuggestionContext(playerId: 'gp1', bidTypeCap: 3, tradeCargoCapacity: 100, availableStockpileByCommodityId: {'timber': 12}, commodityNeedByCommodityId: {})`, when `TradeOrderSuggester.suggest` runs, then `result.offers == [TradeOrder('timber', offer, 12, 5)]` and `result.bids` is empty. The same offers pass `TradeOrderValidator.validate` with reason `accepted`.
- Given `availableStockpileByCommodityId: {'timber': 0}, commodityNeedByCommodityId: {'timber': 8}` and `tradeCargoCapacity: 100`, when the suggester runs, then `result.bids == [TradeOrder('timber', bid, 8, 5)]` and `result.offers` is empty.
- Given `availableStockpileByCommodityId: {'timber': 5}, commodityNeedByCommodityId: {'timber': 9}`, when the suggester runs, then `net = -4`, `result.bids == [TradeOrder('timber', bid, 4, 5)]`, and `result.offers` is empty (mutual-exclusion preserved at suggestion time).
- Given `availableStockpileByCommodityId: {'spices': 999, 'gold': 999}, commodityNeedByCommodityId: {'gems': 5}`, when the suggester runs, then `result.offers` and `result.bids` are both empty (riches excluded from both passes).
- Given `bidTypeCap: 0` and any `commodityNeedByCommodityId`, when the suggester runs, then `result.bids` is empty (rule 4 absolute cap respected).
- Given `bidTypeCap: 3` and `commodityNeedByCommodityId: {'coal': 10, 'iron': 10, 'timber': 10, 'wool': 10}` (alphabetical iteration), when the suggester runs, then exactly the first three commodities (`coal`, `iron`, `timber`) appear as bids and `wool` is silently dropped.
- Given `tradeCargoCapacity: 6` and `commodityNeedByCommodityId: {'coal': 4, 'iron': 5}`, when the suggester runs, then `coal` is emitted at quantity `4`, `iron` is partial-capped at `2` (`6 - 4`), and the suggested bids honor cumulative buyer cargo.
- Given `treasuryBudgetForBids: 90`, `worldMarketState.prices: {'iron': 30, 'timber': 30}`, `commodityNeedByCommodityId: {'iron': 5, 'timber': 5}`, and `tradeCargoCapacity: 100`, when the suggester runs, then `iron` bid quantity is `3` and `timber` is omitted (alphabetical bid pass exhausts treasury on the first commodity).
- Given `treasuryBudgetForBids: 90`, `worldMarketState.prices: {'timber': 30}`, `commodityNeedByCommodityId: {'timber': 5}`, and `tradeCargoCapacity: 100`, when the suggester runs, then `timber` bid quantity is `3` (`min(5, 100, floor(90/30))`).
- Given any `TradeSuggestionContext`, when the suggester runs and the resulting orders are passed to `TradeOrderValidator.validate` with the same context's `bidTypeCap`, `tradeCargoCapacity`, `treasuryBudgetForBids`, `worldMarketState`, `resourceRules`, and `availableStockpileByCommodityId`, then every entry in the parallel result is `accepted` (suggester output is validator-clean by construction).

### FTP diplomacy (issue #2989)

- Given GPs `gp1` and `gp2` with mutual embassy overtures and relation score 70, when `gp1` submits `establishFtp` toward `gp2` and `gp2` is AI-controlled, then after the Diplomacy phase `hasFtpPartnership(game, 'gp1', 'gp2')` is true and a `DiplomaticEvent` with `ftpFormed` is appended.
- Given the same setup but relation score 60, when `gp1` submits `establishFtp` toward `gp2` and `gp2` is AI-controlled, then FTP is not established.
- Given active FTP between `gp1` and `gp2`, when `gp1` declares war on `gp2` in the same Diplomacy phase, then FTP is cleared and a `ftpBroken` event is recorded.
