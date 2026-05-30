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

---

## Determinism

`computeNextPrice` and `computeMarketActivity` are pure functions of their inputs and reproduce identical outputs across runs given identical input. They are safely callable from inside the deterministic turn-resolution pipeline.

## Logging

Resolution-time logging (when the phase handler is implemented in #2990) MUST use `logic:` prefix per `SPEC/program/logging/logging.md`. The pure pricing helpers in this slice are silent — they never log — so they remain trivially callable from hot paths inside the 15-second turn-resolution budget ([colonizethis-turn-resolution-budget rule](../../.cursor/rules/colonizethis-turn-resolution-budget.mdc)).
