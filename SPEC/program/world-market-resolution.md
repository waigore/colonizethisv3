# World Market Resolution

**SPEC/program** — Phase 13 resolution algorithm: gathers `TradeOrder` submissions and auto-generated minor/tribe offers, runs per-commodity priority-queue deal matching with FTP and first-right-of-refusal tiebreaking, applies commodity / treasury / cargo transfers, updates `WorldMarketState` prices, and rolls unfilled quantities forward as carry-forwards. Game rules: [world-market.md](../game/world-market.md). Phase placement: [turn-resolution-phases.md](turn-resolution-phases.md) § Phase 13. Diplomacy interaction: [diplomacy-resolution.md](diplomacy-resolution.md). Cargo allocation: [auto-transport.md](auto-transport.md). Trade order shape: [orders.md](orders.md).

> **Status:** Draft foundation for [issue #2988](https://github.com/waigore/colonizethisv3/issues/2988); concrete types and APIs are implemented across issues #2989 (core engine), #2990 (phase wiring), #2991 (minor/tribe auto-sell), #2992 (first right of refusal), #2993 (UI), and #2994 (AI). When the slices land, extend this document with concrete class names and file paths.

---

## Data model

`WorldMarketState` lives on `Game.worldState` and survives serialization. It carries the current per-commodity market price and the **previous-turn** activity rollup used by the UI Deal Book and by the AI treasury planner. Per-turn match results are produced as a `DealMatchResult` value carried in `TurnPipelineState` (see [turn-resolution.md](turn-resolution.md)) and consumed by the End-of-turn phase for victory/event surfacing.

```
WorldMarketState {
  Map<CommodityId, double> prices;            // current market price per commodity
  Map<CommodityId, MarketActivity> activity;  // previous-turn activity (or empty on game start)
  List<TradeOrder> carryForwardOffers;        // submitter-tagged, with original priority
  List<TradeOrder> carryForwardBids;          // submitter-tagged, with original priority
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

`TradeOrder` (to be added to [orders.md](orders.md) by issue #2989) carries `submitterId`, `commodityId`, `type ∈ {bid, offer}`, `quantity`, `priority` (1 = highest tier), and an `originTileKey` for offers attributed to a specific minor/tribe tile (used by first right of refusal).

## Resolution algorithm

Phase 13 runs after phase 12 Build/work and before phase 14 End-of-turn ([turn-resolution-phases.md](turn-resolution-phases.md) § Phase Sequence). All steps execute deterministically: ties between equal-priority entries are broken by ascending `submitterId`, then by ascending order id, so identical merged-order input produces identical match outcomes across runs ([turn-resolution-phases.md](turn-resolution-phases.md) § Determinism).

### Step A — Gather

1. Validate and accept this turn's newly-submitted Great-Power `TradeOrder` list against [world-market.md](../game/world-market.md) § Validation. Rejected orders are discarded; the rejection is logged and surfaced in `MarketActivity.notes`.
2. Generate auto-offers for every connected developed resource on every Minor Nation and Tribe tile per [world-market.md](../game/world-market.md) § Minor and tribe auto-sell. Auto-offers use `priority = 1`, `submitterId = minorOrTribeId`, and `originTileKey` set to the source tile.
3. Drop carry-forward offers whose submitter stockpile is insufficient and carry-forward bids whose submitter trade cargo capacity is insufficient ([world-market.md](../game/world-market.md) § Order persistence). Record each drop as a `MarketActivityNote`.
4. Combine accepted current-turn orders and surviving carry-forwards into per-commodity working queues, preserving submitter, priority, origin, and new-vs-carry provenance.

### Step B — Build queues

For each commodity, partition into an offer queue and a bid queue. Sort each queue **descending by priority** (so priority 1 fills before priority 2, etc.). Within each integer priority tier, sort:

1. **First right of refusal first.** Any bid whose `submitterId` owns at least one purchased tile sourcing this commodity is moved to an **absolute-priority tier above tier 1** for matching purposes (see Step C). Symmetrically, offers with `originTileKey` on that GP's purchased tile are paired into the absolute-priority tier with that GP's bid only.
2. **FTP tiebreaker.** Among remaining entries at the same integer priority tier, pairs whose `submitterId`s share an active FTP record (from phase 6 Diplomacy) are sorted before non-FTP pairs. FTP never crosses priority tiers.
3. **Submitter id (deterministic).** Equal-priority, equal-FTP entries sort by ascending `submitterId` then by ascending order id.

### Step C — Match

Maintain a per-buyer running cargo accumulator `remainingCargo[buyerId] = tradeCapacity[buyerId]` (see [world-market.md](../game/world-market.md) § Cargo). For each commodity, iterate priority tiers from the absolute-priority first-right tier downward through integer tiers (1, 2, …). Within each tier, iterate offers in sorted order; for each offer, iterate compatible bids:

```
matchQty = min(offer.remaining,
               bid.remaining,
               remainingCargo[bid.submitterId])
if matchQty > 0:
  emit FilledDeal(seller=offer.submitterId, buyer=bid.submitterId,
                  commodity=c, quantity=matchQty,
                  pricePerUnit=WorldMarketState.prices[c],   // OLD price
                  isFtpMatch=ftpPair(offer, bid),
                  isFirstRightOfRefusalMatch=firstRightPair(offer, bid))
  offer.remaining -= matchQty
  bid.remaining   -= matchQty
  remainingCargo[bid.submitterId] -= matchQty
```

Cargo tracking is **per buyer**, shared across all that buyer's commodities. Once `remainingCargo` reaches zero for a buyer, none of that buyer's remaining bids are filled. Partial fills are emitted as a `FilledDeal` for the matched quantity and a residual remainder on the bid; the residual continues to the next bid/offer pairing in the same tier, then to subsequent tiers if it remains.

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

Aggregate `totalBid_new` and `totalOffer_new` per commodity using **only** the newly-submitted current-turn quantities (carry-forward quantities and minor/tribe auto-offers count as carry-forwards-equivalent and are excluded from price discovery, since auto-offers track a steady-state extraction rather than turn-of-submission demand intent). Compute `Δ%` per [world-market.md](../game/world-market.md) § Price discovery, cap at ±20 %, apply multiplicatively, and clamp to the 30 %-of-base floor. Persist the new price into `WorldMarketState.prices` for next-turn matching; this-turn deals already cleared at the **old** price in Step C.

Remaining unfilled offers and bids that originated from a Great-Power submitter (including residuals from partial fills) are tagged with their original priority and submitter and pushed onto `WorldMarketState.carryForwardOffers` / `carryForwardBids` for the next turn. Minor/Tribe auto-offers do not carry forward: each turn re-emits them based on that turn's extraction.

### Step F — Activity rollup

Replace `WorldMarketState.activity` with a fresh `Map<CommodityId, MarketActivity>` that includes the current-turn `totalBidQuantityNew`, `totalOfferQuantityNew`, `filledQuantity` (sum of `FilledDeal.quantity` across this turn), `priceChangePercent`, the full `deals` list, and any `notes` (drops, validation rejections, treasury-sink entries). The phase emits the activity payload to the End-of-turn pipeline for victory checks and Deal-Book UI consumption.

## Logging

Phase 13 follows [logging/turn-resolution.md](logging/turn-resolution.md): the turn resolver emits `logic: phase worldMarket start` and `logic: phase worldMarket end`. The resolver logs **key outcomes** with the `logic:` prefix at info level (one entry per commodity that produced a non-zero `filledQuantity` and per first-right-of-refusal payout) and at debug level for per-deal trace. Tight loops over per-bid validation use summary-only logging per the agent run cleanup and turn-resolution-budget rules.

---

## Acceptance criteria

- **Empty turn no-op.** Given no Great Power submits any `TradeOrder` and there are no carry-forwards or minor/tribe auto-offers, when phase 13 runs, then the system does not mutate `Game.worldState` apart from copying `WorldMarketState.activity` to an empty per-commodity map; no `FilledDeal`, no price change, and no carry-forward are produced.
- **Priority-tier ordering.** Given offer/bid pairs for the same commodity at integer priorities `1` and `2` and no first-right-of-refusal entries, when phase 13 runs, then the matching engine fully fills the priority-1 pair (subject to quantity and cargo) before considering any priority-2 pair, regardless of FTP status on either pair.
- **FTP within a tier.** Given two offer/bid candidate pairs at the **same** integer priority tier where one pair shares an active FTP record and the other does not, when phase 13 runs, then the FTP pair fills before the non-FTP pair and the non-FTP pair receives only the residual quantity left after the FTP pair clears.
- **First right of refusal beats FTP.** Given Great Power A owns a tile purchased from Minor M producing commodity `C`, GP A submits a bid for `C`, GP B holds an FTP with M, and GP B submits a bid for `C` at priority 1, when phase 13 runs, then GP A's bid fills first against M's purchased-tile offer (absolute-priority tier) and GP B's FTP pair fills only from any remaining tier-1 offer quantity.
- **Cargo enforced per-buyer cumulative.** Given a buyer with `tradeCapacity = 15` and matched bids of A = 8 followed by B = 10 in priority order, when phase 13 processes B, then `remainingCargo[buyer] = 7` after A clears, so B receives a `FilledDeal` of exactly 7 units and a residual carry-forward of 3 units is added to `carryForwardBids` with B's original priority and submitter.
- **Deals clear at old price.** Given the previous turn's `WorldMarketState.prices[c] = P_old` and a `FilledDeal` for commodity `c` of `Q` units this turn, when the system emits the deal in Step C, then `FilledDeal.pricePerUnit = P_old` and any `Δ%`-adjusted next-turn price applies only after Step E completes.
- **Minor/tribe treasury sink.** Given a `FilledDeal` whose seller is a Minor or Tribe and which is not under first-right-of-refusal overseas profit, when phase 13 applies transfers, then the buyer is debited `Q × P_old`, the buyer's central stockpile gains `Q` units of the commodity, and no faction (including the seller) is credited by any amount.
- **First-right-of-refusal overseas profit.** Given Great Power A owns a tile purchased from Minor M (hidden relation score `R = 75`), GP A submits no bid, and GP B buys 10 units of M's commodity at `P_old = 20`, when phase 13 runs, then `WorldMarketState.activity[c].deals` contains the GP B fill, the system credits GP A treasury by exactly `10 × 20 × (75 / 100) × 0.40 = 60`, and the remaining `10 × 20 − 60 = 140` is removed via the treasury sink.
- **Deterministic matching.** Given two phase-13 runs with identical merged-order input, identical `WorldMarketState`, and identical seeds, when both runs execute Step C, then both emit byte-identical sequences of `FilledDeal` entries (same order, same quantities, same buyers/sellers) and produce byte-identical `MarketActivity` payloads.
- **Carry-forward provenance preserved.** Given a current-turn bid of quantity 10 for commodity `c` at priority 2 that receives a partial fill of 4, when phase 13 produces carry-forwards in Step E, then `WorldMarketState.carryForwardBids` includes one entry with `submitterId`, `commodityId = c`, `quantity = 6`, `priority = 2`, and `isCarryForward = true`, and the entry's `submittedTurn` matches the current turn.
- **Phase placement preserved.** Given a turn whose phase sequence runs to completion, when the resolver emits phase markers, then `worldMarket` begins after the `buildWork end` marker and ends before the `endOfTurn start` marker, matching [turn-resolution-phases.md](turn-resolution-phases.md) § Acceptance criteria.
