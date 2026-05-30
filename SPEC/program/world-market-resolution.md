# World Market Resolution

**SPEC/program** — Algorithm and data flow for the World Market turn phase. Authority: [SPEC/game/world-market.md](../game/world-market.md). Phase ordering: [turn-resolution-phases.md](turn-resolution-phases.md). Order types: [orders.md](orders.md). Cargo source: [auto-transport.md](auto-transport.md). Implementation tracker: [#2989](https://github.com/waigore/cololizethisv3/issues/2989).

---

## Data types (in `colonizethis_models`)

All types live in `packages/colonizethis_models/lib/src/world_market.dart` and follow the existing pattern: immutable, JSON-serializable, value-equal.

### `TradeOrderType`

Enum: `bid`, `offer`. Serialized as the lowercase enum name.

### `TradeOrderStatus`

Enum: `pending`, `filled`, `partiallyFilled`, `unfilled`, `droppedInsufficientStockpile`, `droppedInsufficientCargo`, `rejected`. Used by Deal Book and carry-forward bookkeeping. Serialized as lowercase enum name.

### `TradeOrder`

```dart
class TradeOrder {
  final CommodityId commodityId;
  final TradeOrderType type;
  final int quantity;
  final int priority;            // 1 = highest; positive int
  final bool isFtp;              // derived during matching
}
```

Invariants enforced in the constructor (throw `ArgumentError`):

- `quantity >= 0`
- `priority >= 1`
- `commodityId.isNotEmpty`

### `MarketActivity`

```dart
class MarketActivity {
  final int totalBidQuantity;
  final int totalOfferQuantity;
  final int filledQuantity;
  final double priceChangePercent;  // signed, e.g. -0.20 .. +0.20
}
```

`MarketActivity.empty` is the zero record.

### `WorldMarketState`

```dart
class WorldMarketState {
  final Map<CommodityId, double> prices;
  final Map<CommodityId, MarketActivity> lastTurnActivity;
}
```

`WorldMarketState.empty` constructs an instance with empty maps. `withDefaultPrices(Map<CommodityId, int> basePrices)` returns a populated initial state.

### `FilledDeal`

```dart
class FilledDeal {
  final String sellerFactionId;
  final String buyerFactionId;
  final CommodityId commodityId;
  final int quantity;
  final double pricePerUnit;
  final bool isFtpMatch;
}
```

### `DealMatchResult`

```dart
class DealMatchResult {
  final List<FilledDeal> filledDeals;
  final Map<String, List<TradeOrder>> unfilledOffersByFactionId;
  final Map<String, List<TradeOrder>> unfilledBidsByFactionId;
  final Map<CommodityId, MarketActivity> activityByCommodityId;
}
```

`DealMatchResult.empty` is the zero record.

---

## Price discovery

Implementation lives in `packages/colonizethis_logic/lib/src/economy/world_market/price_discovery.dart`.

```dart
typedef PriceDiscoveryInputs = ({
  double oldPrice,
  int basePrice,
  int newBidQuantity,
  int newOfferQuantity,
});

double computeNextPrice(PriceDiscoveryInputs i);
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

Determinism: pure function of inputs. Inputs must be non-negative integers; the function asserts in debug builds.

`computeMarketActivity(PriceDiscoveryInputs i, {required int filledQuantity})` returns a `MarketActivity` with `priceChangePercent = (newPrice / oldPrice) - 1.0` (zero when `oldPrice == 0`, defensive guard for hand-constructed test states).

---

## Deal matching engine

Implementation lives in `packages/colonizethis_logic/lib/src/economy/world_market/deal_matcher.dart`. Like price discovery, the matcher is pure (deterministic for fixed inputs, no logger calls) and safe to call from hot turn-resolution paths inside the 15-second budget.

### Signature

```dart
typedef DealMatchInputs = ({
  Map<String, List<TradeOrder>> offersByFactionId,
  Map<String, List<TradeOrder>> bidsByFactionId,
  Map<String, int> tradeCapacityByFactionId,
  Map<CommodityId, double> pricesByCommodityId,
  Set<String> ftpPairKeys,
});

class DealMatcher {
  /// Canonical key for an unordered bilateral faction pair (FTP membership
  /// is symmetric). Returns `min(a,b) + '|' + max(a,b)`.
  static String pairKey(String a, String b);

  /// Runs a single matching pass and returns the deals, carry-forwards,
  /// and per-commodity activity totals.
  static DealMatchResult matchDeals(DealMatchInputs inputs);
}
```

### Algorithm

For each commodity that appears in any offer or bid (commodities iterated in alphabetical id order for determinism):

1. Collect all offers as `(sellerFactionId, TradeOrder)` entries; collect all bids as `(buyerFactionId, TradeOrder)` entries.
2. Group entries by integer `priority`. Process priority tiers in **ascending integer order** (tier `1` first — lower integer is higher precedence).
3. Inside each tier, run two passes:
   - **Pass 1 — FTP-only.** Iterate offers in `(sellerFactionId, faction-local index)` order. For each offer, iterate bids in `(buyerFactionId, faction-local index)` order and attempt a fill **only if** `ftpPairKeys` contains `pairKey(sellerFactionId, buyerFactionId)`. Buyer cargo (`remainingCargoByBuyerFactionId`) is consulted before each match attempt; if the buyer has zero cargo left, skip the bid.
   - **Pass 2 — Any.** Iterate the remaining offers and bids (those with `remaining > 0`) in the same order and attempt matches regardless of FTP.
4. A match attempt produces `matchQty = min(offer.remaining, bid.remaining, buyer.remainingCargo)`. When `matchQty > 0` the matcher emits a `FilledDeal(sellerFactionId, buyerFactionId, commodityId, quantity: matchQty, pricePerUnit: pricesByCommodityId[commodityId] ?? 0.0, isFtpMatch: <ftp-paired>)`, decrements the offer's and bid's remaining quantities, and decrements `remainingCargoByBuyerFactionId[buyerFactionId]` by `matchQty`.
5. After all tiers process for a commodity, any offer with `remaining > 0` is preserved in `unfilledOffersByFactionId` (keyed by `sellerFactionId`, original order ordering preserved). Bids likewise feed `unfilledBidsByFactionId`. Orders whose remaining is `0` are not preserved.
6. The carry-forward `TradeOrder` instances are constructed via `copyWith(quantity: remaining)` so unrelated fields (priority, isFtp, type) survive the next-turn re-entry intact.

`activityByCommodityId` records, per commodity that had any submitted volume, a `MarketActivity` with:

- `totalBidQuantity` — sum of all input bid `quantity` values for the commodity (across all factions).
- `totalOfferQuantity` — sum of all input offer `quantity` values for the commodity.
- `filledQuantity` — sum of `quantity` across all emitted `FilledDeal`s for the commodity.
- `priceChangePercent` — `0.0`. Price discovery is composed separately by the phase handler (see Issue B / #2990) using `PriceDiscovery.computeNextPrice`, because only the phase handler knows which inputs are newly-submitted vs carry-forward (carry-forwards are excluded from the supply/demand signal per `SPEC/game/world-market.md` § Price discovery).

### Edge cases

- Missing price for a commodity (`pricesByCommodityId` lookup returns `null`) is recorded on emitted `FilledDeal`s as `pricePerUnit = 0.0`. The phase handler is responsible for seeding `pricesByCommodityId` from `WorldMarketState.prices`; a missing entry signals a setup defect, not a runtime failure.
- A faction with bids but no entry in `tradeCapacityByFactionId` is treated as having `tradeCapacity = 0` — none of its bids fill, all carry forward.
- An offer or bid with `quantity == 0` is treated as already exhausted — no `FilledDeal` is emitted, no carry-forward record is generated for it.
- `ftpPairKeys` is consulted as a set; ordering of pairs inside the set does not affect output. The canonical `pairKey` ensures the input set need not be duplicated for both `(a,b)` and `(b,a)`.
- First right of refusal is **not** handled by this engine (see Issue D / #2992). When implemented, it will pre-flag matched pairs ahead of the standard tier loop.

---

## Phase placement (informational; covered fully by Issue B / #2990)

Phase 13 (`worldMarket`) sits between Build / work and End-of-turn — End-of-turn renumbers from 13 → 14. The handler will gather `Orders.tradeOrders`, run matching, apply transfers, then call `computeNextPrice` per commodity and store the resulting `WorldMarketState` on `Game`.

---

## Acceptance criteria

- Given `TradeOrder(commodityId: 'timber', type: bid, quantity: 5, priority: 2, isFtp: false)`, when `toJson()` and `TradeOrder.fromJson` round-trip, then the resulting instance equals the original (including `==` and `hashCode`) and the JSON contains `{commodityId: 'timber', type: 'bid', quantity: 5, priority: 2, isFtp: false}`.

- Given a `TradeOrder` constructor invocation with `quantity = -1`, when the constructor runs, then it throws `ArgumentError` with message containing `quantity` (negative quantities are invalid).

- Given a `TradeOrder` constructor invocation with `priority = 0`, when the constructor runs, then it throws `ArgumentError` with message containing `priority` (priority must be ≥ 1).

- Given `WorldMarketState.withDefaultPrices({'timber': 30, 'iron': 80})`, when the state is constructed, then `prices == {'timber': 30.0, 'iron': 80.0}` and `lastTurnActivity.isEmpty`.

- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 20, newOfferQuantity: 10)`, when `computeNextPrice` runs, then it returns `100 * (1 + 1/6) ≈ 116.6666…` (within 1e-9 of `100 * (1 + 1/6)`).

- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 0)`, when `computeNextPrice` runs, then it returns `100.0` exactly.

- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 1000, newOfferQuantity: 0)`, when `computeNextPrice` runs, then `cappedDelta = +0.20` and the result is `120.0` (cap applied).

- Given `PriceDiscoveryInputs(oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000)`, when `computeNextPrice` runs, then `cappedDelta = -0.20` and the result is `max(80.0, 30.0) = 80.0`.

- Given `PriceDiscoveryInputs(oldPrice: 32.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000)`, when `computeNextPrice` runs, then `candidate = 32 * 0.80 = 25.6`, `floor = 30.0`, and the result is `30.0` (floor clamps).

- Given `PriceDiscoveryInputs(oldPrice: 30.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000)`, when `computeNextPrice` runs, then `candidate = 24.0`, floor `30.0`, and the result is `30.0` (price stays at the floor; never drifts below).

- Given a `computeNextPrice` invocation with `oldPrice = 0.0` (defensive guard) and any volumes, when the function runs, then it returns `max(0.0, basePrice * 0.30) = basePrice * 0.30` (price recovers to the floor instead of staying at zero).

- Given `computeMarketActivity(inputs, filledQuantity: 5)` where the new price equals the old price, when the function runs, then the result `MarketActivity` has `priceChangePercent == 0.0`, `totalBidQuantity == newBidQuantity`, `totalOfferQuantity == newOfferQuantity`, and `filledQuantity == 5`.

### Deal matching engine

- Given a single commodity with one offer `(seller: 'a', quantity: 10, priority: 1)` and one bid `(buyer: 'b', quantity: 5, priority: 1)`, prices `{commodity: 30.0}`, `tradeCapacity['b'] = 10`, and `ftpPairKeys = {}`, when `DealMatcher.matchDeals` runs, then the result has one `FilledDeal(seller: 'a', buyer: 'b', quantity: 5, pricePerUnit: 30.0, isFtpMatch: false)`, the offer carries forward at quantity `5` under `unfilledOffersByFactionId['a']`, no bid carry-forward is recorded, and `activityByCommodityId[commodity] = MarketActivity(totalBidQuantity: 5, totalOfferQuantity: 10, filledQuantity: 5, priceChangePercent: 0.0)`.

- Given priority tier `1` contains a non-FTP `(seller, buyer)` pair with offer `10` and bid `10`, and tier `2` contains an FTP pair with offer `10` and bid `10`, when matching runs, then the tier-1 pair fills first (priority integer takes absolute precedence over FTP) — tier `2`'s FTP pair fills next only if cargo remains, and the resulting `FilledDeal.isFtpMatch` flags reflect each pair's FTP membership.

- Given priority tier `1` contains an FTP pair `(a, b)` with offer `5` and bid `5`, and a non-FTP pair `(a, c)` with offer `5` and bid `5`, when matching runs, then the FTP pair fills first within tier `1` (FTP is the same-tier tiebreaker) and produces a `FilledDeal(isFtpMatch: true)`; the non-FTP pair fills next from the offer's remaining quantity if any (which is `0` in this scenario, so no second deal is emitted).

- Given a buyer with `tradeCapacity = 15` who submits a priority-1 bid `A x 8` and a priority-2 bid `B x 10`, and offers cover both, when matching runs, then `A` fills `8`, `remainingCargo = 7`, `B` partial-fills `7`, `B`'s carry-forward quantity is `3`, and `activityByCommodityId['B'].filledQuantity = 7`.

- Given a faction has bids but no entry in `tradeCapacityByFactionId`, when matching runs, then no deals are emitted for that faction and every bid for that faction is preserved at its original quantity in `unfilledBidsByFactionId`.

- Given an offer with `quantity = 0` and a bid with positive quantity at the same priority tier, when matching runs, then no `FilledDeal` is emitted from that offer, the zero-quantity offer is not carried forward, and the bid remains unfilled (carries forward at its full quantity if no other offer matches).

- Given `DealMatcher.pairKey('zeta', 'alpha')` and `DealMatcher.pairKey('alpha', 'zeta')`, when both are evaluated, then they return the same canonical key string (`'alpha|zeta'`), so FTP membership set entries are order-independent.

---

## Determinism

`computeNextPrice` and `computeMarketActivity` are pure functions of their inputs and reproduce identical outputs across runs given identical input. They are safely callable from inside the deterministic turn-resolution pipeline.

## Logging

Resolution-time logging (when the phase handler is implemented in #2990) MUST use `logic:` prefix per `SPEC/program/logging/logging.md`. The pure pricing helpers in this slice are silent — they never log — so they remain trivially callable from hot paths inside the 15-second turn-resolution budget ([colonizethis-turn-resolution-budget rule](../../.cursor/rules/colonizethis-turn-resolution-budget.mdc)).
