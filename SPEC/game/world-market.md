# World Market

**SPEC/game** — Single global commodity market: bid/offer trading, supply-and-demand price discovery, cargo-constrained shipping, FTP partnerships, first right of refusal. Authorized by [#2988](https://github.com/waigore/colonizethisv3/issues/2988); core slice tracker [#2989](https://github.com/waigore/colonizethisv3/issues/2989). Phase order: [turn-resolution-phases.md](../program/turn-resolution-phases.md). Algorithm: [world-market-resolution.md](../program/world-market-resolution.md). Commodity ids and excluded riches: [commodity-catalog.md](commodity-catalog.md).

---

## Scope

The World Market lets every faction (Great Powers, minors, tribes) submit per-turn `TradeOrder` entries to buy or sell commodities. The market clears once per turn after Build / work and before End-of-turn. Cleared deals transfer commodities and treasury between participants and update each commodity's market price for the next turn.

Riches (gold, silver, gems, diamonds, spices) are **not** traded — they continue to auto-convert via the riches-to-treasury phase per [commodity-catalog.md § Riches and treasury](commodity-catalog.md). All other commodities (food, raw, manufactured) participate.

---

## Trade orders

A `TradeOrder` carries:

- `commodityId` — canonical id from [commodity-catalog.md](commodity-catalog.md), excluding riches.
- `type` — `bid` (buy) or `offer` (sell).
- `quantity` — non-negative integer units.
- `priority` — positive integer; 1 is highest. Lower integer = higher precedence.
- `isFtp` — derived flag set during matching when the offer/bid pair belongs to FTP-linked factions.

Ordering rules:

1. A faction may either bid or offer a given commodity in a turn, never both.
2. Offers may list any number of distinct commodities.
3. Bid commodity-type count is capped by `tradeSlotsForGp` ([diplomacy-resolution.md](../program/diplomacy-resolution.md)): 0 without embassy, 3 with embassy, 6 with embassy + `trade_fairs`. Per-commodity bid quantity is capped by trade cargo capacity.
4. Offers require post-production stockpile ≥ offered quantity per commodity.
5. Carry-forward unfilled orders re-enter matching the next turn but **do not** contribute to that turn's price discovery aggregation. They are dropped if stockpile (offers) or cargo (bids) constraints no longer hold.

---

## Price discovery

Each commodity's price starts at the `defaultMarketPrice` from [resource-terrain-region-rules.md](resource-terrain-region-rules.md). After matching each turn:

```
volume = totalNewBidQuantity + totalNewOfferQuantity   (carry-forwards excluded)

if volume == 0:
  newPrice = oldPrice
else:
  rawDelta = 0.5 * (totalNewBidQuantity - totalNewOfferQuantity) / volume
  cappedDelta = clamp(rawDelta, -0.20, +0.20)
  candidate = oldPrice * (1 + cappedDelta)
  newPrice = max(candidate, basePrice * 0.30)
```

Rules:

- Aggregation uses **only newly-submitted** bid/offer quantities for the current turn. Carry-forwards still match but are excluded from the supply/demand signal so they cannot bias prices over multiple turns.
- The cap `±0.20` applies symmetrically. The floor is exactly 30% of `basePrice`. Prices have no ceiling.
- Deals clear at `oldPrice` (price valid for this turn). `newPrice` applies next turn.

---

## Cargo

Trade shipping is buyer-funded. Sellers do not consume cargo holds. Per faction:

```
tradeCapacity = max(0, totalHomeFleetCargoHolds - overseasExtractionActualTonnage)
```

`overseasExtractionActualTonnage` is the **actual** tonnage shipped this turn, not the maximum reservation. Unused extraction capacity is released to trade.

During matching, cargo tracking is **per-buyer** across all commodities. As bids fill, `buyer.remainingCargo` decreases by filled quantity; when remaining cargo runs out the next bid receives a partial fill or none.

---

## Favored Trading Partner (FTP)

A new bilateral agreement (separate from NAP and alliance):

- Established via `DiplomaticOrder.establishFTP`. Both sides accept; AI threshold ≥ 65 relation score.
- Requires an active embassy with the target.
- Broken automatically when either side declares war or when the embassy is lost.

Effect on matching: within a single integer priority tier, FTP-linked offer/bid pairs sort ahead of non-FTP pairs. The integer priority **always** evaluates first — FTP never elevates a pair across tiers.

---

## First right of refusal

When a Great Power's Merchant has purchased land from a minor or tribe, commodities extracted from those tiles still belong to the minor/tribe (auto-offered). If the owning GP also bids for that commodity, the bid moves to the absolute front of the queue (above FTP and every integer tier) and matches first against the purchased-tile offer. If the owning GP does not bid, other GPs bid normally and the owning GP receives:

```
profitRate = (relationScore / 100) * 0.40   // bounded to [0, 0.40]
profit = filledQuantity * pricePerUnit * profitRate
```

`relationScore` is the 0–100 hidden score from [diplomacy.md § Relation Model](diplomacy.md). The remainder is sunk per the minor/tribe treasury sink rule (no faction is credited).

## Acceptance criteria

- Given a Great Power player whose stockpile holds 100 timber, when the player submits an offer of `timber × 10 @ priority 1`, then the order is recorded on `Orders.tradeOrders[playerId]` and a parallel `bid` for `timber` from the same player is rejected with error `trade_order_mutual_exclusion`.

- Given a commodity with newly-submitted bid 20, newly-submitted offer 10, and `oldPrice = 100`, when price discovery runs, then `volume = 30`, `cappedDelta ≈ 0.1667` (under ±0.20), and `newPrice ≈ 116.67`.

- Given a commodity with newly-submitted bid 0, newly-submitted offer 0, and a 50-unit carry-forward bid, when price discovery runs, then `volume = 0` and `newPrice = oldPrice` (carry-forwards excluded).

- Given a commodity whose candidate price falls below `basePrice × 0.30`, when price discovery runs, then `newPrice = basePrice × 0.30` exactly (floor clamp).

- Given a buyer with `tradeCapacity = 15`, a priority-1 bid `A × 8` and a priority-2 bid `B × 10` (offers abundant), when matching runs, then `A` fills 8, `remainingCargo = 7`, `B` partial-fills 7, and 3 units of `B` carry forward.

- Given two FTP factions and a non-FTP third faction submitting matching pairs at the same priority tier 1, then the FTP pair fills first within tier 1; given the FTP pair sits at tier 2 and the non-FTP pair at tier 1, then the tier-1 non-FTP pair fills first (priority integer absolutely beats FTP).

- Given an unfilled offer for `timber × 6` from turn N, when turn N+1 begins and the offering faction's `timber` stockpile has dropped below 6, then the carry-forward offer is dropped (not partially preserved) and recorded with status `dropped_insufficient_stockpile`.

---

## Where stored

Market state lives on the in-memory `Game` model as `WorldMarketState`. Order entries live on `Orders.tradeOrders` per [orders.md](../program/orders.md). Default market prices are loaded once at game start from `ResourceRules.defaultMarketPrice` ([resource-terrain-region-rules.md](resource-terrain-region-rules.md)); the floor uses the same value as `basePrice` for every commodity.
