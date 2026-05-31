# World Market

**SPEC/game** — Player-facing commodity market: bid/offer orders, deal matching, price discovery, Favored Trading Partner (FTP), and first right of refusal on purchased minor/tribe tiles. Authority: parent design [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988). Resolution details: [world-market-resolution.md](../program/world-market-resolution.md). Phase placement: [turn-resolution-phases.md](../program/turn-resolution-phases.md) § Phase 13. UI: [trade-screen.md](../ui/trade-screen.md). AI: [treasury-planner.md](../ai/treasury-planner.md) (planned).

> **Status:** Draft foundation. Issues #2989–#2994 implement the engine, AI, and UI sliced from this design. When implementation lands, replace any "(planned)" link target with the published file.

---

## Tradeable commodities

The market clears all commodities defined in [commodity-catalog.md](commodity-catalog.md) **except** the riches set (`gold`, `silver`, `gems`, `diamonds`, `spices`). Riches continue to auto-convert to treasury in phase 3 ([turn-resolution-phases.md](../program/turn-resolution-phases.md) § Riches to treasury). Twenty-two of the twenty-eight commodities are tradeable today: 2 food, 11 raw materials, 9 manufactured. The catalog's reserved `luxury` category is empty per [commodity-catalog.md](commodity-catalog.md) § Categories and contributes no tradeable ids.

Every Great Power, Minor Nation, and Tribe participates in the same single global market. There are no regional or per-continent markets, no player-set ask/bid prices, and no trade routes drawn on the map; the market is a strategic abstraction layered above the canonical sea-transport simulation ([ships-and-naval.md](ships-and-naval.md) § Cargo capacity).

## Trade orders

Great Powers submit `TradeOrder` entries alongside other orders in phase 1 ([turn-resolution-phases.md](../program/turn-resolution-phases.md) § Orders; the `TradeOrder` shape is added to [orders.md](../program/orders.md) by issue #2989). Each order names a `commodityId`, a `type` (`bid` or `offer`), a positive integer `quantity`, and an integer `priority` (1 = highest tier; lower-priority tiers are matched only after higher tiers exhaust). Minor Nations and Tribes never submit orders themselves: their extracted commodities are emitted as system-authored offers in phase 13 (see § Minor and tribe auto-sell).

### Validation rules

- **Mutual exclusion per commodity.** A Great Power may either offer or bid for a given commodity in a turn, never both. Selling commodity A while buying commodity B in the same turn is allowed; submitting both directions for the same commodity rejects all of that GP's orders for that commodity.
- **Bid type cap (`tradeSlotsForGp`).** The number of distinct commodities a GP may bid on in one turn is **0** without an embassy toward any target, **3** with embassy (baseline), and **6** with embassy and `trade_fairs` ([diplomacy-resolution.md](../program/diplomacy-resolution.md) § Integration; [tech-tree-labour-economy.md](tech-tree-labour-economy.md) § trade_fairs). Offers are not subject to the type cap.
- **Per-commodity quantity cap.** Each bid quantity is capped at the GP's trade cargo capacity (see § Cargo). Each offer quantity is capped at the GP's post-production projected stockpile minus industry-allocation reservations ([stockpiles-and-production.md](stockpiles-and-production.md) § Production flow).
- **Riches excluded.** Trade orders for any commodity in the riches set are rejected at validation.

## Price discovery

Each commodity starts at the default market price defined in the resource–terrain–region table in [resource-terrain-region-rules.md](resource-terrain-region-rules.md). After phase 13 deal matching, each commodity's price updates by:

\[
\Delta\% = 0.5 \times \frac{\text{totalBid}_{\text{new}} - \text{totalOffer}_{\text{new}}}{\text{totalBid}_{\text{new}} + \text{totalOffer}_{\text{new}}}, \quad \text{capped at} \pm 20\%
\]

`totalBid_new` / `totalOffer_new` aggregate **only** newly-submitted quantities for the current turn. Carry-forward unfilled quantities from prior turns are excluded from price discovery (they continue to participate in matching). When `totalBid_new + totalOffer_new` is zero, the price is unchanged. The new price is clamped to a floor of **30 % of the commodity's default market price**.

Deals clear at the **old** price (pre-update). The new price applies to the next turn.

## Cargo

Trade shipping consumes a GP's cargo holds. The buyer ships purchased commodities; the seller does not consume cargo. Per-turn trade cargo capacity equals `max(0, totalHomeFleetCargoHolds − overseasExtractionActualTonnage)`: overseas extraction reserves and ships first, and only the **actual** tonnage shipped by extraction is subtracted (any reserved-but-unused extraction capacity becomes available for trade) per [auto-transport.md](../program/auto-transport.md) § Sea Transport (Overseas Only). Trade shipping is not subject to naval interception.

## Favored Trading Partner (FTP)

FTP is a bilateral diplomatic agreement separate from alliances, Non-Aggression Pacts, and overtures ([diplomacy.md](diplomacy.md) § Diplomatic Order Types). An FTP requires:

- An existing embassy with the target (minimum `tradeConsulate` overture stage),
- Bilateral acceptance (AI-controlled targets accept when their hidden relation score is `≥ 65`; human targets respond via the standard overture prompt),
- It is automatically broken when either side declares war on the other or when the embassy is lost.

FTP affects matching only as a tiebreaker within the same integer priority tier (see [world-market-resolution.md](../program/world-market-resolution.md) § Matching). FTP never elevates a pair across priority tiers and never overrides first right of refusal.

## First right of refusal

When a Great Power has purchased a tile from a Minor or Tribe via the Merchant `purchase_land` work order ([diplomacy.md](diplomacy.md) § GP–Minor — Purchase land (Merchant)), commodities extracted from that tile are auto-offered by the owning minor/tribe (see § Minor and tribe auto-sell). The owning GP receives two privileges:

- **Bid priority.** If the owning GP submits a bid for the same commodity in that turn, that bid is matched against the purchased-tile offer at **absolute highest priority** (above FTP and above all integer priority tiers).
- **Overseas profit.** If the owning GP submits no bid and another GP buys the commodity, the owning GP receives a treasury credit equal to `filledQuantity × pricePerUnit × profitRate`, where `profitRate = (relationScore / 100) × 0.40`. The `relationScore` is the hidden 0–100 GP-to-minor/tribe relation per [diplomacy.md](diplomacy.md) § Relation Model; it is clamped 0–100 at source, so `profitRate ∈ [0, 0.40]`.

## Minor and tribe auto-sell

Minor Nations and Tribes have starting developed resources connected to their capitals ([factions.md](factions.md) § Minor Nation, § Tribe). Their extracted commodities are auto-emitted as priority-1 offers by the world market phase. Minors and Tribes never bid and have no treasury wallet: payments from buyers are debited normally and removed from the economy as a treasury sink, except for the owning-GP profit share described above ([world-market-resolution.md](../program/world-market-resolution.md) § Treasury sink).

## Order persistence

Unfilled bids and offers are carried forward to the next turn so long as the submitting GP can still cover them: offers are dropped when the submitter's start-of-turn stockpile no longer covers the carry-forward quantity; bids are dropped when the submitter's start-of-turn trade cargo capacity is insufficient. Dropped carry-forwards are recorded in next-turn market activity for the Deal Book UI ([trade-screen.md](../ui/trade-screen.md) § Deal Book tab). Newly-submitted orders for the same commodity merge their quantity with the carry-forward at match time but are still tracked separately for price-discovery aggregation. Minor and Tribe auto-offers are never carried forward (each turn re-emits them based on that turn's extraction per [world-market-resolution.md](../program/world-market-resolution.md) § Step E).

---

## Acceptance criteria

- **Riches excluded.** Given a Great Power submits a `TradeOrder` for any commodity in the riches set (`gold`, `silver`, `gems`, `diamonds`, `spices`), when the order validator runs, then the system rejects the order with reason `trade_order_riches_excluded` and the riches continue to auto-convert in phase 3 Riches-to-treasury.
- **Mutual exclusion per commodity.** Given a Great Power submits both a bid and an offer for the same commodity in the same turn, when validation runs, then the system rejects every trade order for that commodity submitted by that GP and emits an `Orders` error with reason `trade_order_mutual_exclusion`.
- **Bid type cap honours `tradeSlotsForGp`.** Given a Great Power's embassy/tech state yields `tradeSlotsForGp(player) = N` (0, 3, or 6 per [diplomacy-resolution.md](../program/diplomacy-resolution.md)), when validation runs against bids for `N+1` distinct commodities, then the system rejects the `N+1`-th distinct-commodity bid with reason `trade_order_bid_type_cap_exceeded` and accepts the first `N`.
- **Price floor.** Given a commodity whose default market price is `B`, when phase 13 would compute a new price below `0.30 × B`, then the system clamps the published next-turn price to exactly `0.30 × B`.
- **Price discovery uses current-turn aggregation only.** Given a commodity with a carry-forward unfilled bid quantity of 50 from prior turns and no newly-submitted bids or offers this turn, when phase 13 runs, then the system treats `totalBid_new = 0` and `totalOffer_new = 0`, the price is unchanged, and the carry-forward bid remains in the matching queue for the next turn.
- **Cargo released by under-used extraction.** Given a turn in which overseas extraction reserves 20 cargo holds but ships only 12 actual tonnage, when phase 13 computes trade cargo capacity for that GP, then the system computes `tradeCapacity = max(0, totalHomeFleetCargoHolds − 12)` (the unused 8 holds are released to trade) per [auto-transport.md](../program/auto-transport.md) § Sea Transport (Overseas Only).
- **First right of refusal — bid priority.** Given Great Power A owns a tile purchased from Minor M producing timber, when GP A submits a timber bid and other GPs also submit timber bids at any priority tier, then the matching engine fills GP A's bid against M's timber offer before any FTP pair and before any other integer priority tier for that commodity.
- **First right of refusal — overseas profit.** Given Great Power A owns a tile purchased from Minor M (relation score `R ∈ [0, 100]`), GP A submits no bid, and GP B buys `Q` units of M's commodity at price `P` per unit, then the system credits GP A treasury by exactly `Q × P × (R / 100) × 0.40` and the remainder of the sale proceeds is removed as a treasury sink (see [world-market-resolution.md](../program/world-market-resolution.md) § Treasury sink).
- **Carry-forward drop on stockpile shortfall.** Given a carry-forward offer of quantity `Q` for commodity `C` from a previous turn, when at the start of the next turn the submitter's stockpile for `C` is less than `Q`, then the system drops the carry-forward (no partial preservation) and records a `carry_forward_dropped_stockpile_insufficient` market-activity entry for the Deal Book.
- **Carry-forward drop on cargo shortfall.** Given a carry-forward bid of quantity `Q` from a previous turn, when at the start of the next turn the submitter's trade cargo capacity is less than `Q`, then the system drops the carry-forward (no partial preservation) and records a `carry_forward_dropped_cargo_insufficient` market-activity entry for the Deal Book.
- **FTP requires embassy + bilateral acceptance.** Given two Great Powers without an embassy toward each other, when one submits a `DiplomaticOrder.establishFTP` targeting the other, then the system rejects the order with reason `ftp_requires_embassy` and no FTP record is created.
- **FTP breaks on war.** Given two Great Powers with an active FTP, when either declares war on the other in phase 6 Diplomacy, then the system removes the FTP record before phase 13 runs and any FTP tiebreaking for that pair does not apply in the same turn.
- **Minor/tribe auto-offer.** Given a Minor or Tribe with a connected developed non-riches tile producing commodity `C`, when phase 13 runs with `TurnResolverConfig.tileMapByRegion` populated, then the system emits exactly one `TradeOrder` with `type = offer`, `priority = 1`, `quantity` equal to the per-tile non-GP extraction yield (`SPEC/game/extraction-and-improvements.md` § Non-Great-Power extraction), and `originTileKey` equal to the source tile key, before deal matching runs.
- **Minor/tribe riches excluded from auto-offer.** Given a Minor or Tribe owns a connected developed tile whose resource is in `richesCommodityIds` (`spices` and the mineral riches), when phase 13 runs, then the system emits no `TradeOrder` for that tile (riches do not trade on the world market per Requirement 11).
- **Minor/tribe auto-offers never carry forward.** Given a Minor or Tribe auto-offer is unfilled at end of phase 13, when the phase persists `WorldMarketState.carryForwardOffersByFactionId`, then the system stores no entry for the minor/tribe faction id (the auto-offer is re-emitted next turn from extraction rather than persisted), per [world-market-resolution.md](../program/world-market-resolution.md) § Step E.
