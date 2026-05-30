# World Market — First Right of Refusal

## Overview

When a Great Power purchases a tile from a minor/tribe via the Merchant
`purchase_land` work order ([orders.md](../program/orders.md), tracked in
`WorldState.purchasedTilesByTileKey: Map<tileKey, buyerGpId>`), that tile's
commodity offers continue to be auto-listed by the **owning minor/tribe**
in the world market. The purchasing GP retains a **first right of refusal**:
when it does **not** bid on a deal whose offered units include
purchased-tile production, and another GP buys those units, the original
purchaser receives an **overseas profit cut** from the buyer's clear price.

Authority: issue [#2992](https://github.com/waigore/colonizethisv3/issues/2992)
(parent design [#2988](https://github.com/waigore/colonizethisv3/issues/2988)).
Foundation data types and deal matcher are owned by issue
[#2989](https://github.com/waigore/colonizethisv3/issues/2989); the program-side
turn-resolution document is `SPEC/program/world-market-resolution.md`
(planned by #2989) — that doc must reference this one when it lands.

---

## Rules

### Eligibility

- **Owning GP:** The buyer recorded in `purchasedTilesByTileKey[tileKey]`.
- **Source faction:** The minor/tribe that owns the underlying province
  (`Province.ownerId`); the deal seller is the source faction, not the
  owning GP.
- **Trigger:** During world-market deal matching ([turn-resolution-phases.md](../program/turn-resolution-phases.md)
  phase 13), when a deal fills units sourced from a purchased tile and the
  **buyer** is **not** the owning GP. If the owning GP itself wins the
  deal, no overseas profit applies (it bought normally).

### Profit formula (D3)

Let `relationScore ∈ [0, 100]` be the owning GP's hidden relation score
with the source faction (`SPEC/game/diplomacy.md` § Relation Model).

```
profitRate     = clamp((relationScore / 100) * 0.40, 0.0, 0.40)
profitTreasury = filledQuantity * pricePerUnit * profitRate
```

- `pricePerUnit` is the matched **clear price** for this deal in treasury
  units (deterministic per #2989's price-discovery output).
- `filledQuantity` is the units transferred for this match.
- Out-of-range inputs (negative quantity, negative price, score < 0 or
  > 100) are clamped to zero defensively; production callers should not
  rely on negative inputs.

### Treasury transfer (D4)

For each filled deal that is FRR-eligible:

1. The **buyer GP** pays the full `filledQuantity * pricePerUnit` per the
   standard market clear (no double charge).
2. The **owning GP** is credited `profitTreasury` from that payment.
3. The **remainder** (`filledQuantity * pricePerUnit - profitTreasury`)
   is the minor/tribe treasury sink (no faction credited), matching the
   GDD's auto-sell sink rule for minor/tribe sellers.

### Relation 0 / equal to owner

- `relationScore == 0` ⇒ `profitRate == 0` ⇒ no FRR credit; the deal
  resolves as a plain minor/tribe auto-sell.
- Buyer == owning GP ⇒ FRR is not invoked (no overseas profit on
  domestic purchases, even if the owning GP itself uses the purchased
  tile).

### Determinism

- The formula is a pure function of `(relationScore, filledQuantity,
  pricePerUnit)`; no RNG, no logger calls in the helper hot path
  (`SPEC/program/turn-resolution-phases.md` § Determinism).
- Iteration order in callers must remain deterministic per #2989's deal
  matcher contract (FTP-then-relation tiebreakers); FRR is applied
  per-deal at attribution time, after the matcher selects the deal.

---

## Implementation

- **Pure helper (D3):**
  `packages/colonizethis_logic/lib/src/economy/world_market/first_right_profit.dart`,
  exported as `computeFirstRightProfit({relationScore, filledQuantity,
  pricePerUnit}) → FirstRightProfit(profitRate, profitTreasury)`.
- **Constants:**
  `kFirstRightMaxProfitRate = 0.40` and
  `kFirstRightRelationScoreMax = 100`.
- **Data sources already on dev:**
  `WorldState.purchasedTilesByTileKey` (set by `purchase_land` work
  completion in `packages/colonizethis_logic/lib/src/orders/purchase_land_work_completion.dart`).
- **D2 / D4 callers** land with the world-market deal-match phase
  (#2989 / #2991) and must invoke this helper per deal at the point
  where the seller faction and underlying tile are known.

---

## Acceptance criteria

- **AC-1 — Lower bound:** Given `relationScore == 0` and any `filledQuantity > 0`,
  `pricePerUnit > 0`, when the helper is called, then it returns
  `FirstRightProfit.zero` (`profitRate == 0.0`, `profitTreasury == 0.0`).
- **AC-2 — Upper bound:** Given `relationScore == 100`, `filledQuantity == 4`,
  `pricePerUnit == 2.5`, when the helper is called, then `profitRate == 0.40`
  and `profitTreasury == 4.0` (i.e. `4 * 2.5 * 0.40`).
- **AC-3 — Mid sample:** Given `relationScore == 75`, `filledQuantity == 10`,
  `pricePerUnit == 5.0`, when the helper is called, then `profitRate == 0.30`
  and `profitTreasury == 15.0`.
- **AC-4 — Defensive clamping:** Given any negative `filledQuantity` or
  negative `pricePerUnit`, when the helper is called, then it returns
  `FirstRightProfit.zero` regardless of relation score.
- **AC-5 — Range invariant:** For every integer relation score in
  `[0, 100]`, the resulting `profitRate` is in `[0.0, 0.40]` and
  monotonically non-decreasing in relation score.
- **AC-6 — No-bid path only:** D2/D4 callers must invoke the helper
  only when the buyer is **not** the owning GP for the purchased tile;
  unit tests for D2/D4 (in #2989's deal-matcher / #2991's transfers)
  must cover this gate.
