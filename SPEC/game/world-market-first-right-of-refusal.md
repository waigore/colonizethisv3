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
- **Purchased-tile index (D1):**
  `packages/colonizethis_logic/lib/src/economy/world_market/purchased_tile_index.dart`,
  exported as `PurchasedTileIndex.fromGame(game) →
  PurchasedTileAttribution? attributionForTileKey(tileKey)`. Eagerly
  builds a tile-keyed snapshot from `WorldState.purchasedTilesByTileKey`
  joined against `WorldState.tileKeysByRegionAndProvince` (to resolve
  the province containing the tile) and `Province.ownerId` (to resolve
  the source minor/tribe). Only entries whose **source faction is still
  a minor/tribe** at index-build time are retained — entries where the
  containing province was subsequently conquered by a GP are filtered
  out so D2/D4 callers cannot accidentally credit FRR profit on
  GP-on-GP transactions. Pure, no logger calls, no RNG.
- **Data sources already on dev:**
  `WorldState.purchasedTilesByTileKey` (set by `purchase_land` work
  completion in `packages/colonizethis_logic/lib/src/orders/purchase_land_work_completion.dart`)
  and `WorldState.tileKeysByRegionAndProvince` (game-setup seeded
  region/province tile bucket map).
- **D2 (priority override in deal matching) is implemented** in
  `packages/colonizethis_logic/lib/src/economy/world_market/deal_matcher.dart`.
  `DealMatcher.matchDeals` accepts an optional `purchasedTileIndex` on
  its `DealMatchInputs` record; when supplied, the matcher runs an FRR
  absolute-priority pre-pass per commodity that pairs purchased-tile
  offers (offers whose `TradeOrder.originTileKey` resolves via the
  index) with the owning Great Power's bids before the integer-priority
  tier loop. Emitted deals are flagged via
  `FilledDeal.isFirstRightOfRefusalMatch = true` so D4 (treasury
  transfer) and the Deal Book UI can identify FRR-applied flows.
  Passing `null` (or an empty index) preserves legacy behavior for
  pre-#2992 callers and tests.
- **D4 caller (overseas-profit treasury transfer)** lands with the
  world-market phase handler (#2990 B3) and consumes the
  `isFirstRightOfRefusalMatch` flag together with the same
  `purchasedTileIndex` row to compute and credit the owning GP's
  overseas-profit cut via [computeFirstRightProfit] from D3. The
  expected call site builds `PurchasedTileIndex.fromGame(game)` once
  per phase (or once per resolver pass) and looks up
  `attributionForTileKey` per minor/tribe offer entry whose backing
  tile resolves to a purchased attribution.

---

## Acceptance criteria

### Profit helper (D3)

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

### Purchased-tile index (D1)

- **AC-D1-1 — Empty world:** Given a `Game` whose `WorldState.purchasedTilesByTileKey`
  is empty, when `PurchasedTileIndex.fromGame(game)` is built, then
  `index.length == 0`, `index.isEmpty == true`, and
  `attributionForTileKey(any)` returns `null`.
- **AC-D1-2 — Minor-owned purchased tile:** Given a `Game` whose
  `WorldState.purchasedTilesByTileKey = {tileKey: gpA}` and whose
  containing province is owned by minor `M1` (declared in
  `Game.minorNations`), when the index is built, then
  `attributionForTileKey(tileKey)` returns a `PurchasedTileAttribution`
  with `owningGpId == 'gpA'`, `sourceFactionId == 'M1'`, and
  `provinceId` equal to the full prefixed id of the containing
  province.
- **AC-D1-3 — Tribe-owned purchased tile:** Given the same scenario as
  AC-D1-2 but with the province owned by tribe `T1` (declared in
  `Game.tribes`), when the index is built, then the attribution is
  returned with `sourceFactionId == 'T1'`.
- **AC-D1-4 — Post-conquest filter:** Given a purchased tile whose
  containing province is currently owned by a Great Power (`Player.id`
  in `Game.players`) instead of a minor/tribe, when the index is
  built, then the attribution for that tile key is **excluded**
  (`attributionForTileKey(tileKey) == null`) so FRR cannot fire on
  GP-on-GP sales.
- **AC-D1-5 — Unowned province filter:** Given a purchased tile whose
  containing province has `ownerId == null`, when the index is built,
  then the attribution for that tile key is **excluded**.
- **AC-D1-6 — Unmapped tile filter:** Given a `purchasedTilesByTileKey`
  entry whose tile key is not present in
  `WorldState.tileKeysByRegionAndProvince` for any province, when the
  index is built, then the attribution for that tile key is
  **excluded**.
- **AC-D1-7 — Determinism:** Given the same `Game` value, when
  `PurchasedTileIndex.fromGame(game)` is built twice, then both
  indices return the same attribution set (`index.length` equal;
  per-tile lookups return equal `PurchasedTileAttribution` records).

### Priority override (D2)

Tested in
`packages/colonizethis_logic/test/world_market_deal_matcher_first_right_test.dart`.

- **AC-D2-1 — Owning GP bid wins despite lower-precedence priority.**
  Given Great Power `gpA` owns a purchased tile from minor `M1`
  producing `timber`, `M1` auto-offers `timber × 10` with
  `originTileKey` set to that tile, `gpA` submits a bid for
  `timber × 10` at integer priority `5`, and rival GP `gpB` submits a
  bid for `timber × 10` at the higher-precedence integer priority `1`,
  when `DealMatcher.matchDeals` runs with the purchased-tile index
  populated, then the only emitted `FilledDeal` has
  `buyerFactionId == 'gpA'`,
  `isFirstRightOfRefusalMatch == true`,
  `isFtpMatch == false`, and `gpB`'s bid carries forward intact.
- **AC-D2-2 — FRR overrides FTP within the same priority tier.** Given
  `gpA` owns the purchased tile, `M1` is FTP-paired with `gpFtp`, and
  both `gpA` and `gpFtp` submit equal-priority bids for the same
  commodity, when matching runs, then the FRR fill goes to `gpA` first
  (`isFirstRightOfRefusalMatch == true`, `isFtpMatch == false`) and the
  FTP partner's bid carries forward when the offer is exhausted.
- **AC-D2-3 — Owning GP absent: standard tier matching.** Given the
  owning GP submits **no** bid for the commodity, when the matcher
  runs, then the purchased-tile offer is matched normally against
  other GPs' bids (the highest-precedence integer-priority bid wins),
  and the resulting `FilledDeal.isFirstRightOfRefusalMatch == false`.
- **AC-D2-4 — Partial FRR fill exposes residual to standard tiers.**
  Given the owning GP bids only `4` units of a `10`-unit purchased-tile
  offer, when matching runs, then exactly one `FilledDeal` of `4`
  units flagged FRR is emitted to the owning GP and the remaining
  `6` units fill against the highest-precedence rival bid via the
  normal tier loop (with `isFirstRightOfRefusalMatch == false`).
- **AC-D2-5 — Per-buyer cumulative cargo still applies inside FRR.**
  Given the owning GP has `tradeCapacity = 3` and bids `10`, when
  matching runs, then the FRR pre-pass emits a single `FilledDeal` of
  `3` units (the cargo cap), the remaining purchased-tile quantity
  becomes available to rival bids in the standard tier loop, and the
  owning GP's residual `7` units carry forward.
- **AC-D2-6 — Offers without `originTileKey` are not affected.** Given
  a plain offer (no `originTileKey`) and a populated purchased-tile
  index, when matching runs, then the matcher does **not** invoke
  the FRR pre-pass for that offer — the standard priority/FTP rules
  decide the buyer.
- **AC-D2-7 — `null` purchasedTileIndex disables FRR.** Given the same
  inputs as AC-D2-1 but with `purchasedTileIndex == null`, when
  matching runs, then the FRR pre-pass is skipped and the deal flows
  through the standard tier loop, preserving the legacy contract for
  pre-#2992 callers.
