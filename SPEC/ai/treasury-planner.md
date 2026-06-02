# Treasury Planner (AI)

**SPEC/ai** — AI treasury-acquisition strategy via the World Market. Source: [#2988 World Market design overview](../game/), [#2994 issue F (TreasuryPlanner)]. Related: [economy-planner.md](economy-planner.md), [ai-architecture.md](ai-architecture.md), [phase-planner-architecture.md](phase-planner-architecture.md). Goal model: [ai-personalities.md](ai-personalities.md).

---

## Purpose

The treasury planner is the AI's interface to the World Market. It decides what commodities to bid for, what surplus to sell, and how aggressively to use the market based on the GP's treasury health. It is a sub-planner of the economy planner and runs once per AI-controlled Great Power per turn.

The planner has two distinct surfaces:

1. **Goal-score treasury-acquisition bias** (this issue, slice **F6** of [#2994](https://github.com/waigore/colonizethisv3/issues/2994)). A purely additive modification to `evaluateStrategicGoalScores` in `goal_manager.dart` that boosts the `StrategicGoal.trade` score inversely with the GP's treasury, so that a broke AI prioritises the market.
2. **Trade-order generation** (later slices F1–F5, F7–F10). The full `TreasuryPlanner` module that forecasts treasury inflows/outflows, picks sell-surplus and buy-deficit commodities, respects trade-cargo capacity, and emits `TradeOrder` rows (depends on [#2989](https://github.com/waigore/colonizethisv3/issues/2989) data types).

Slice F6 is independent of #2989 data types and lands first so the AI goal selection treats `StrategicGoal.trade` as a real competitor before the trade-order generation surface arrives.

---

## Treasury-acquisition goal bias (Refs #2994 F6)

### Inputs

- `snapshot.economy.treasury` — current treasury balance of the AI-controlled GP (`int`, may be `0` or negative under emergency conditions; the snapshot field is built directly from `player.treasury`).
- `cheapestRegimentBuildTreasuryCost()` — the existing helper in `expand_phase_planner.dart` that returns the minimum `buildTreasuryCost` across `RegimentEconomyCatalog.byId.values`. This is the same threshold used by EXPAND-phase below-quota arms for the "below cheapest regiment cost" concept; the treasury planner shares the helper rather than introducing a new threshold (Refs #2994 Requirement 9).

No new perception field is added; `EconomySummary.treasury` already exists.

### Bias formula

After every other goal-score adjustment in `evaluateStrategicGoalScores` (war threats, agenda modifiers, province-count effects, stalled-OW caps, colonial pressure floors, far-from-victory caps), the function applies the treasury-acquisition bias to `trade`:

```
let threshold = cheapestRegimentBuildTreasuryCost()
let treasury  = snapshot.economy.treasury

if treasury <= 0:
    trade = max(trade, kEmergencyTradeGoalDominantFloor)
else if treasury < threshold:
    let ratio = treasury / threshold              // 0 < ratio < 1
    let boost = round((1 - ratio) * kTreasuryAcquisitionTradeBoostMax)
    trade = trade + boost
else:
    // treasury >= threshold: no bias applied
    trade = trade
```

Bias placement after all other passes is deliberate so the broke-AI floor can override the stalled-OW `trade = math.min(trade, 35)` clamp and the colonial-pressure `kColonialTradeGoalPenaltyWhenPressure` penalty. Without that override an AI that has run out of treasury while stalled on OW expansion (the most common emergency case in observer runs) would still try to recruit regiments it cannot afford.

### Constants (configurable per ruleset)

Both constants live in `packages/colonizethis_data/lib/src/ai_victory_config.dart` alongside the existing trade / colonial / stalled goal-score constants, so rulesets that tune AI behaviour can adjust them in one place.

- `kEmergencyTradeGoalDominantFloor = 200` — `trade` floor when `treasury <= 0`. Sized to outrank every other goal after their floors and bonuses have been applied: the largest competing floor is `kMinimumColonialConquerScoreWhenPressure = 95`; the stalled-OW path bumps `conquer = math.max(conquer, 120)`; victory-pace and endgame bonuses on `conquer` add at most `40 + 25 = 65` on top of a base weight (max base trade weight is `90`), keeping the worst-case competitor near `~185`. A floor of `200` keeps trade strictly above that envelope so AC3 holds across every leader / phase combination.
- `kTreasuryAcquisitionTradeBoostMax = 80` — peak linear boost as `treasury → 0+`. Sized to produce a meaningful — but not yet emergency-floor — signal: at `treasury == 1` (just above zero) the boost is `~80`, which lifts a moderate-trade leader (`trade = 50`) up near `130`, comparable to the stalled-OW conquer floor of `120` so trade can compete but does not yet dominate. At `treasury == threshold − 1` the boost is `~0`, preserving the moderate-treasury behaviour required by AC4.

### Determinism

The bias is a pure function of `snapshot.economy.treasury` and the static `RegimentEconomyCatalog` (read by `cheapestRegimentBuildTreasuryCost`). For the same snapshot + catalog it always yields the same `(boost, trade)` pair, so `evaluateStrategicGoalScores` remains deterministic and existing AC-RP-4 (Recruitment planner determinism) and `selectPrimaryGoal` determinism contracts are preserved.

### Interaction with existing trade-goal modifiers

The bias **adds** on top of (and may override) prior modifiers; it does not remove them. Concretely:

| Existing modifier on `trade`                         | F6 interaction                                                                                     |
|------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `trade -= kStalledTradeGoalPenalty` (40)             | Applied first; F6 boost can recover or exceed it when treasury is low.                              |
| `trade = math.min(trade, 35)` (stalled + invadable)  | F6 floor of 200 at `treasury <= 0` overrides this clamp; F6 linear boost can lift trade above 35 but does not re-clamp. |
| `trade -= kColonialTradeGoalPenaltyWhenPressure` (25) | Applied first; F6 boost / floor compensate when treasury is low.                                    |
| Far-from-victory `tradePenalty` (cap 30)             | Applied first; F6 floor at `treasury <= 0` overrides it.                                            |

The bias never affects `defend`, `expand`, `conquer`, `tech`, or `diplomacy`; those goals retain their existing weights so a broke AI is steered toward trade specifically rather than blanket-suppressing competing strategies.

---

## Acceptance criteria (#2994 F6)

- Given an AI-controlled Great Power with `snapshot.economy.treasury == 0` and any personality / observer phase combination, when `evaluateStrategicGoalScores` runs, then `result[StrategicGoal.trade]` is greater than or equal to `kEmergencyTradeGoalDominantFloor` (`200`) and strictly greater than `result[StrategicGoal.defend]`, `result[StrategicGoal.expand]`, and `result[StrategicGoal.conquer]`.
- Given an AI-controlled Great Power with `snapshot.economy.treasury` set to a value strictly between `0` and `cheapestRegimentBuildTreasuryCost()`, when `evaluateStrategicGoalScores` runs, then `result[StrategicGoal.trade]` equals the pre-bias `trade` plus `round((1 - treasury / threshold) * kTreasuryAcquisitionTradeBoostMax)`, and the boost is strictly positive (so trade scales inversely with treasury but does not yet hit the emergency floor).
- Given an AI-controlled Great Power with `snapshot.economy.treasury` set to a value greater than or equal to `cheapestRegimentBuildTreasuryCost()`, when `evaluateStrategicGoalScores` runs, then `result[StrategicGoal.trade]` equals the pre-bias `trade` (no F6 boost applied) and is not forced to the emergency floor.
- Given an AI-controlled Great Power whose Old World expansion is stalled with invadable provinces remaining (legacy path triggers `trade = math.min(trade, 35)`) and whose `snapshot.economy.treasury == 0`, when `evaluateStrategicGoalScores` runs, then `result[StrategicGoal.trade]` is greater than or equal to `kEmergencyTradeGoalDominantFloor` (the F6 floor overrides the stalled clamp) and strictly greater than `result[StrategicGoal.conquer]`.
- Given two `evaluateStrategicGoalScores` invocations with identical `snapshot`, `config`, `observerGoalPhase`, `suppressColonialPressure`, and `colonialPressureWeight`, when both runs complete, then they produce identical `Map<StrategicGoal, int>` outputs (the bias preserves determinism).

---

## Trade-order generation (Refs #2994 F1–F5, F7)

### Module

- `packages/colonizethis_ai/lib/src/planning/treasury_planner.dart` — `runTreasuryPlanner(...)`.
- Called from `runEconomyPlanner` after production assignments are chosen; results are stored on `EconomyPlan.tradeOrders` and merged into `Orders.tradeOrdersByPlayerId` by `runDomainPlannersWithOutcome` (F7 wiring) so every orchestrator caller — including the strategic-AI entry `generateStrategicOrdersWithTrace` and the simpler `runDomainPlanners` test entrypoint — surfaces the same trade output without duplicating the merge.

### Orchestrator wiring (Refs #2994 F7)

- After all other domain planners run, the orchestrator appends `economyPlan.tradeOrders` (when non-empty) to `ctx.orders.tradeOrdersByPlayerId[nationId]` via `Orders.appendTradeOrders`. The append is skipped when the list is empty, so `tradeOrdersByPlayerId` stays absent for that player and downstream `MapEquality` checks in tests remain stable.
- The orchestrator records a `tradePlannerRan` boolean on `DomainGateData` (`true` iff at least one trade order was emitted by the treasury planner). This field is emitted under `thresholds.domainGates.tradePlannerRan` in the AI trace alongside the existing per-domain `*PlannerRan` flags, so an analyst can distinguish "treasury planner produced zero orders" from "treasury planner did not run for this player turn" without consulting per-player JSON.
- `ai_order_reporting.orderCountsByDomain` and `finalAggregatedOrders` include trade entries (`domain: 'trade'`, with `commodityId`, `type`, `quantity`, `priority`) so the trace's `domainOutputs.trade` count and `finalAggregatedOrders` array reflect the merged trade orders. This keeps counts symmetric with every other domain (move/build/work/diplomatic/research/navalMove/navalMission) the orchestrator already reports.
- Strategic-AI (`generateStrategicOrdersWithTrace`) consumes the orchestrator's `outcome.orders` directly without re-merging trade orders; the in-function `tradeOrdersByPlayerId` `copyWith` block previously responsible for the merge is retired by F7.

### Surplus / need maps (F1–F3)

Given current `Stockpile`, `productionAssignments`, and `game.worldMarketState.prices`:

1. **Project** post-production stockpile by simulating assigned recipes.
2. **Track** commodities that appear in the stockpile, projected stockpile, recipe inputs/outputs from assignments, or the food category.
3. **Consumption forecast** — `kShortageThreshold` for food; for commodities with production input needs, `min(need, kShortageThreshold)`; otherwise half-threshold for other tracked commodities.
4. **Safety buffer** — `2×` consumption for food, `1×` for others.
5. **Sell surplus** — `available[id] = max(0, projected − (consumption + inputs + safety))`.
6. **Buy deficit** — `need[id] = max(0, (consumption + inputs) − projected)` only when market price is strictly below the cheapest recipe production cost for that commodity (F3 price gate).

### Priority and cargo (F4–F5)

- Delegates offer/bid quantity selection to `TradeOrderSuggester` with the computed maps.
- **Bid priority tiers:** essential inputs (manufactured/advanced) = 1, luxury = 2, raw = 3, food = 4. Re-sorts admitted bids after the suggester pass.
- **Offer priority:** `2` (urgent) when `treasury < cheapestRegimentBuildTreasuryCost()`, else `5` (moderate).
- **Cargo:** When `runEconomyPlanner` supplies `tileMapByRegion` and `topology`, `tradeCargoCapacityForGreatPower` forecasts `max(0, cargoHoldsForHomeFleet − overseasShippedTonnage)` using the same extraction + `allocateOverseasToStockpile` path as phase 12/13 (`packages/colonizethis_logic/lib/src/economy/trade_cargo_capacity.dart`, Refs #2924). Without tile maps, falls back to full home-fleet holds (legacy test path).
- **Bid type cap:** `worldMarketBidTypeCap(game, playerId)` (embassy / trade-fairs diplomacy gates).

### Acceptance criteria (F1–F5 / F7)

- Given an AI GP with timber stockpile well above reserve and `treasury` below `cheapestRegimentBuildTreasuryCost()`, when `runTreasuryPlanner` runs, then it emits at least one `TradeOrderType.offer` for timber at priority `2`.
- Given an AI GP with embassy overture, fabric production input need, and market fabric price below recipe input cost, when `runTreasuryPlanner` runs, then it emits a `TradeOrderType.bid` for fabric at priority `1`.
- Given an AI GP with no embassy and `treasury == 0` and no production-input consumption deficit, when `runTreasuryPlanner` runs, then it emits offers only (no bids) — speculative bidding is gated by treasury affluence so broke GPs never spend on speculation.
- Given identical inputs, when `runTreasuryPlanner` runs twice, then both runs return identical `List<TradeOrder>`.
- Given an `EconomyPlan` whose `tradeOrders` is non-empty for an AI GP, when `runDomainPlannersWithOutcome` runs, then `outcome.orders.tradeOrdersByPlayerId[nationId]` equals `economyPlan.tradeOrders` and `outcome.domainGateData.tradePlannerRan` is `true` (F7 wiring).
- Given an `EconomyPlan` whose `tradeOrders` is empty, when `runDomainPlannersWithOutcome` runs, then `outcome.orders.tradeOrdersByPlayerId` does not contain `nationId` and `outcome.domainGateData.tradePlannerRan` is `false`.
- Given identical orchestrator inputs (game / topology / nationId / view / snapshot / config / primary goal / seeds / suggestion API / economy plan / tile maps / phase plan), when `runDomainPlannersWithOutcome` runs twice, then both runs produce identical `outcome.orders.tradeOrdersByPlayerId[nationId]` lists (determinism).

---

## Affluent-GP speculative bidding (Refs #2924 F10)

F10 supplements the F1–F5 deficit-based bid path so the world market clears even when no Great Power currently has a strict input shortfall. Without it the seed-42 "EXPAND geographic peer-war lock" stays gridlocked at zero deals (per the diagnostic in `packages/colonizethis_ai/test/seed42_observer_world_market_lock_recovery_diagnostic_test.dart`): every GP offers, none bids, and the failing GPs never earn treasury through legitimate trade. F10 lets treasury-rich GPs *choose* to spend treasury on inventory ahead of any modelled deficit, providing the buy-side demand that converts other GPs' offers into deals.

### Affluence gate

A GP is **affluent** when `treasury >= kTreasuryAffluenceThreshold = kTreasuryAffluenceThresholdMultiplier × cheapestRegimentBuildTreasuryCost()` (default multiplier `1`, so `>= 2000` treasury — the same band that authorizes a cheapest regiment build). Below the gate the planner uses the F1–F5 path unchanged — broke GPs that cannot afford even one regiment never emit speculative bids.

### Speculative-bid commodity selection

The speculative pass adds **at most one** synthetic entry to the `need` map per invocation so the bid is concentrated on the commodity most likely to clear into a real deal (treasury redistributes only when matching offers exist; spraying bids across commodities with no offers leaves the market gridlocked). Eligibility filter:

- Skip any commodity in `richesCommodityIds` (riches are excluded from world-market trade).
- Skip any commodity already present in the F1–F5 `need` map (the deficit path already speaks for it).
- Skip any commodity already present in the F1–F5 `available` map (mutual-exclusion preserved).
- Require `speculativeGap = kSpeculativeBidStockpileTarget − projectedStockpile[commodityId] − carryForwardBids[commodityId] > 0`. The default target is `kShortageThreshold` (`8`), aligned with `_consumptionForecast` so a successful speculative buy raises stockpile to one full consumption cycle.

Among eligible commodity ids, select **exactly one** in this deterministic order:

1. Commodities with prior-turn `MarketActivity.totalOfferQuantity > 0` — proven liquidity. Sort descending by offer volume, alphabetical tiebreak.
2. Otherwise food-category commodities (alphabetical) — minor/tribe auto-offers reliably surface food on the next world-market phase.
3. Otherwise the alphabetical first eligible commodity (deterministic fallback for an empty market — preserves determinism for tests that do not seed `lastTurnActivity`).

Add `need[selectedId] = speculativeGap(selectedId)` and return.

### Price-gate bypass for speculative bids

Speculative bids **do not** apply the F3 "market price strictly below cheapest production cost" gate. The affluent GP is electing to spend treasury on stockpile regardless of unit cost (the alternative is being unable to spend treasury at all). Affordability is still enforced at the validator boundary (`tradeCargoCapacity`, `bidTypeCap`) and at deal-clearing time (treasury debited per filled unit).

### Cap inheritance

Speculative bids share the same `bidTypeCap` and `tradeCargoCapacity` as F1–F5 bids; the deficit pass admits bids first, the speculative pass fills any remaining cap slots in alphabetical commodity order. Because `worldMarketBidTypeCap` returns `kWorldMarketBaselineBidTypeCap` (= `1`) by default ([world-market-resolution.md](../program/world-market-resolution.md) § Bid type cap helper), no-embassy GPs still get at least one speculative bid per turn.

### Determinism and budget

The selection set, scoring, and cap distribution are pure functions of `Stockpile`, `productionAssignments`, `treasury`, `game.worldMarketState`, and the static catalogs. Identical inputs produce identical outputs across runs. No hot-path logging; per-turn cost is bounded by `O(catalog × players)`, well inside the 15-second turn-resolution budget.

### Acceptance criteria (F10)

- Given an AI GP with `treasury >= kTreasuryAffluenceThreshold` (= `1 × cheapestRegimentBuildTreasuryCost()` = `2000`), no recipe-input deficit, an empty stockpile for a non-riches commodity `C`, and `worldMarketBidTypeCap(game, playerId) == kWorldMarketBaselineBidTypeCap` (`1`, no embassy), when `runTreasuryPlanner` runs, then it emits exactly one `TradeOrderType.bid` for `C` with `quantity == kSpeculativeBidStockpileTarget` (`8`) and `priority` set per `_bidPriorityForCommodity(C)`.
- Given an AI GP whose `treasury < kTreasuryAffluenceThreshold` and no deficit-driven bid, when `runTreasuryPlanner` runs, then it emits no bid (speculative pass is gated off).
- Given an AI GP whose `treasury >= kTreasuryAffluenceThreshold` and whose projected stockpile of every non-riches commodity is at or above `kSpeculativeBidStockpileTarget`, when `runTreasuryPlanner` runs, then it emits no speculative bid (no commodity has positive `speculativeTarget`).
- Given identical orchestrator inputs, when `runTreasuryPlanner` runs twice on the affluent path, then both runs return identical `List<TradeOrder>` outputs (determinism preserved by alphabetical commodity ordering and the cap distribution rule).

---

## Lock-recovery liquidity alignment (Refs #2924 F11)

F11 closes the seed-42 gridlock where every GP emits urgent **offers** (typically `grain`) below the regiment treasury threshold but **bids** target other commodities and land on different integer priority tiers than urgent offers, so [DealMatcher](../program/world-market-resolution.md) clears zero deals and `lifetimeSellerCredit` stays at `0` (see `packages/colonizethis_ai/test/seed42_observer_world_market_lock_recovery_diagnostic_test.dart`).

### Priority-tier alignment

When `treasuryForecast < cheapestRegimentBuildTreasuryCost()`, emitted bids use the same `priority` as urgent offers (`kTreasuryOfferPriorityUrgent` = `2`) instead of `_bidPriorityForCommodity`. Per `SPEC/game/world-market.md` § Trade orders, matching runs only **within** the same integer priority tier; misaligned tiers were the primary mechanical break after F10 restored bid-side cap.

### Rotating designated buyer (Refs #2924 F11 / F12)

When at least one Great Power is broke (`player.treasury < cheapestRegimentBuildTreasuryCost()`):

1. `lockRecoveryDesignatedBuyerId(game)` rotates among Great Powers whose **current** `player.treasury >= treasuryAffluenceThreshold()` (same band as F10 speculative bidding). When no GP meets that band, it falls back to `sortedGreatPowerIds[turnNumber % count]`. Returns the empty string when **no** GP is broke (steady-state F1–F5 / F10 path only).
2. The designated buyer (when non-empty) adds a synthetic `need` entry for the lock-recovery food commodity (highest prior-turn `MarketActivity.totalOfferQuantity` among food ids; default alphabetical first food when activity is empty) with quantity `min(kSpeculativeBidStockpileTarget − carryForwardBids[liquidity], max(0, buyerTreasury / pricesByCommodityId[liquidity]))` — **treasury-capped** (Refs #2924 F12) so the buyer never commits more treasury than it currently holds. Other commodities are stripped from `need` for that GP so the single `bidTypeCap` slot cannot be spent on fabric/bronze deficits; F10 speculative bidding is suppressed for the designated buyer that turn.
3. The designated buyer **removes** that commodity from `available` so it does not offer and bid the same commodity (validator mutual-exclusion rule 3).
4. All broke GPs keep urgent offers on their surplus food; the designated buyer's bid at priority `2` matches those offers in the same tier. When the designated buyer is affluent its own `offerPriority` is moderate, but `forceBidPriority` overrides the emitted bid to `kTreasuryOfferPriorityUrgent` so tier alignment holds (Refs #2924 F12).
5. Broke non-designated GPs **do not** emit deficit or speculative bids (their single `bidTypeCap` slot would target non-grain commodities that do not match the urgent grain offers). F1–F5 deficit bids resume once `treasuryForecast >= cheapestRegimentBuildTreasuryCost()`.

The lock-recovery branch activates for the designated buyer even when its own `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` (`isDesignatedLockRecoveryBuyer`), because the affluent buyer is providing buy-side liquidity for other broke GPs' urgent offers.

No affordability bypass: buyers debit treasury at deal time. Because the bid quantity is capped at `buyerTreasury / pricesByCommodityId[liquidity]`, the buyer never spends more than it holds (worst case residual `(buyerTreasury mod pricePerUnit)`). Speculative bidding (F10) remains gated by `treasuryAffluenceThreshold`.

### Acceptance criteria (F11 / F12)

- Given at least one broke GP and `playerId == lockRecoveryDesignatedBuyerId(game)` with `player.treasury >= pricesByCommodityId[liquidity]`, when `runTreasuryPlanner` runs, then it emits at least one `TradeOrderType.bid` for the lock-recovery food commodity at `priority == kTreasuryOfferPriorityUrgent` and emits no `TradeOrderType.offer` for that commodity — including when the designated buyer's own `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` (affluent designated buyer path; Refs #2924 F12).
- Given the designated buyer with `player.treasury == T` and lock-recovery food priced at `P`, when `runTreasuryPlanner` runs, then the synthetic grain bid's `quantity` equals `min(kSpeculativeBidStockpileTarget − carryForwardBids[liquidity], max(0, T / P))` (integer-truncating division; Refs #2924 F12).
- Given at least one broke GP but `playerId != lockRecoveryDesignatedBuyerId(game)` and `treasuryForecast < cheapestRegimentBuildTreasuryCost()`, when `runTreasuryPlanner` runs, then it emits offers only (no bids).
- Given **no** GP with `player.treasury < cheapestRegimentBuildTreasuryCost()`, when `lockRecoveryDesignatedBuyerId(game)` runs, then it returns the empty string and no synthetic grain bid is emitted.
- Given `treasuryForecast < cheapestRegimentBuildTreasuryCost()` for any GP that emits a bid in this lock-recovery configuration, when `runTreasuryPlanner` emits any such bid, then each bid's `priority` equals `kTreasuryOfferPriorityUrgent` (tier alignment).
- Given identical inputs, when `runTreasuryPlanner` runs twice, then `lockRecoveryDesignatedBuyerId` and the emitted trade orders are identical (determinism).
- Given tile maps and topology where overseas extraction would consume all home-fleet cargo holds, when `runTreasuryPlanner` runs with those maps, then `TradeOrderSuggester` receives `tradeCargoCapacity == 0` (no bids that cannot clear at world-market phase).
- Given the same fixture but `tileMapByRegion` omitted, when `runTreasuryPlanner` runs, then `tradeCargoCapacity` equals `cargoHoldsForHomeFleet` (backward-compatible unit-test path).

---

## Partial-fill-aware forecasting (Refs #2994 F8)

F8 layers two pure refinements onto `runTreasuryPlanner`: skip orders already represented by Issue A's carry-forward queue, and discount forecasted treasury inflow by the previous turn's offer-side fill rate. All inputs come from `game.worldMarketState`; no new lookups, logging, or `WorldState` traversals.

### Carry-forward de-duplication

For each commodity `id`, sum the player's current carry-forward residuals:

```
carryForwardOffers[id] = Σ order.quantity in worldMarketState.carryForwardOffersByFactionId[playerId]
carryForwardBids[id]   = Σ order.quantity in worldMarketState.carryForwardBidsByFactionId[playerId]
```

Subtract them from the surplus / deficit gap before populating the suggester maps:

- `surplus(id) = projected[id] − (consumption + inputs + safety) − carryForwardOffers[id]`
- `deficit(id) = (consumption + inputs) − projected[id] − carryForwardBids[id]`

Non-positive results drop the commodity from `available` / `need`, so the suggester never emits a new order whose intent is already represented in Issue A's queue.

### Prior-turn fill-rate-aware offer urgency

For each commodity `id`:

```
fillRateOffer(id) =
    if lastTurnActivity[id] is null OR totalOfferQuantity <= 0: 1.0
    else clamp(filledQuantity / totalOfferQuantity, 0.0, 1.0)
```

`1.0` is the deterministic default for the first market turn and for commodities the previous aggregator never touched — matches the existing F2 "no prior data → assume fully fillable" convention.

Forecasted inflow (rounded to integer treasury units) drives the urgency switch:

```
expectedOfferInflow = round(Σ available[id] * marketPrice[id] * fillRateOffer(id))
treasuryForecast    = treasury + expectedOfferInflow
offerPriority       = treasuryForecast < cheapestRegimentBuildTreasuryCost()
                          ? kTreasuryOfferPriorityUrgent
                          : kTreasuryOfferPriorityModerate
```

`treasuryForecast` — not raw `treasury` — gates urgency. Markets with reliable demand (`fillRate ≈ 1.0`) preserve F1–F5 behaviour; markets that cleared zero of the player's prior offers leave the planner urgent even when the nominal stockpile value looks generous.

### Determinism and budget

`carryForwardOffers`, `carryForwardBids`, `fillRateOffer`, `expectedOfferInflow`, and `treasuryForecast` are pure functions of `game.worldMarketState`, `availableStockpileByCommodityId`, and the price map. No hot-path logging; same 15-second turn-resolution budget envelope as F1–F5.

### Acceptance criteria (F8)

- Given an AI Great Power whose `carryForwardOffersByFactionId[playerId]` contains a `TradeOrder(timber, offer, quantity=Q1)` and whose computed timber surplus is `Q1 + R` with `R > 0`, when `runTreasuryPlanner` runs, then it emits exactly one new timber offer with `quantity == R`.
- Given an AI Great Power whose `carryForwardOffersByFactionId[playerId]` contains a `TradeOrder(timber, offer, quantity=Q1)` and whose computed timber surplus equals `Q1`, when `runTreasuryPlanner` runs, then it emits no new timber offer.
- Given an AI Great Power whose `carryForwardBidsByFactionId[playerId]` contains a `TradeOrder(fabric, bid, quantity=Q1)` and whose computed fabric deficit equals `Q1`, when `runTreasuryPlanner` runs, then it emits no new fabric bid.
- Given an AI Great Power with `treasury` below `cheapestRegimentBuildTreasuryCost()`, an abundant timber surplus, and a previous-turn `MarketActivity` for timber with `totalOfferQuantity > 0` and `filledQuantity == 0`, when `runTreasuryPlanner` runs, then `treasuryForecast == treasury` (zero discounted inflow) and the timber offer carries `kTreasuryOfferPriorityUrgent`.
- Given an AI Great Power with `treasury` just below `cheapestRegimentBuildTreasuryCost()`, an abundant timber surplus at the default `timber` market price, and a previous-turn `MarketActivity` for timber with `filledQuantity / totalOfferQuantity == 1.0` (full fill), when `runTreasuryPlanner` runs, then `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` (full-fill credit) and the timber offer carries `kTreasuryOfferPriorityModerate`.
- Given two `runTreasuryPlanner` invocations whose inputs (including `carryForward*ByFactionId` and `lastTurnActivity`) are identical, when both runs complete, then they return identical `List<TradeOrder>` outputs.

## Observer-game seed-42 trade-order emission (Refs #2994 F9)

F9 closes the orchestrator-level verification gap for F1–F8 by pinning the
deterministic outcome of `generateOrdersForGameFullAI` on the canonical
`GameSetupConfig(seed: 42)` initialisation. Unit tests under
`packages/colonizethis_ai/test/planning/treasury_planner_test.dart` already
cover the per-planner emission rules; F9 instead verifies that the production
**Full AI** entrypoint — running through `runEconomyPlanner` →
`runDomainPlannersWithOutcome` (F7 wiring) → `supplementMutualStalledGreatPowerPeaceOrders`
— actually surfaces those orders on a real seed-42 starting state without any
test fixtures or hand-built game objects.

### Verification surface

- Test file: `packages/colonizethis_ai/test/seed42_observer_treasury_planner_trade_emission_test.dart`.
- Entrypoint exercised: `generateOrdersForGameFullAI(game, topology, tileMapByRegion: …)` against the seed-42 game `init.game.copyWith(aiControlByGpId: {for (final p in init.game.players) p.id: true})`.
- Output read: `result.orders.tradeOrdersByPlayerId` — the same map persisted to `Orders` after F7 orchestrator append.

### Why turn 1

Seed-42 GPs stay in EXPAND for the full observer horizon (see
`seed42_observer_colonial_regression_test.dart` § skip rationale). A turn-1
inspection therefore deterministically captures the **EXPAND-phase** trade
emission baseline without needing the broader 150-turn observer loop, keeps the
test inside the same single-turn budget envelope as `full_ai_first_turn_wall_clock_budget_test.dart`,
and avoids the carry-forward state that later turns would introduce. Once the
seed-42 colonial-acquisition gap (Refs #2848 / #2509 S7) closes, a follow-up
slice can extend the same trace to a phase-varying assertion across EXPAND →
COLONIAL turns.

### Acceptance criteria (F9 — turn-1 emission pin)

- Given the seed-42 `runInitGame` output (`GameSetupConfig(seed: 42)`, default options) with every Great Power flipped to AI-controlled via `aiControlByGpId`, when `generateOrdersForGameFullAI` runs once for turn 1, then `result.orders.tradeOrdersByPlayerId.values.expand((list) => list)` is non-empty — at least one Great Power emits at least one `TradeOrder`.
- Given the same seed-42 turn-1 invocation, when the test inspects each Great Power `gp1..gp6` in `result.orders.tradeOrdersByPlayerId`, then every emitted `TradeOrder` satisfies the F1–F5 invariants: `quantity > 0`, `priority` ∈ `{1, 2, 3, 4, 5}` (matches `kTreasuryBidPriority*` / `kTreasuryOfferPriority*`), `commodityId` is not in `richesCommodityIds`, and `type` is one of `TradeOrderType.bid` or `TradeOrderType.offer`.
- Given the same seed-42 turn-1 invocation runs twice in succession, when both runs complete, then `result.orders.tradeOrdersByPlayerId` is equal across runs (determinism — mirrors the existing `generateOrdersForGameFullAI determinism` pin in `full_ai_planner_determinism_test.dart`).
- Given a failing assertion in any of the criteria above, when the test reports the failure, then the assertion `reason` contains a per-GP trace row `gp<n>  tradeOrders=<count>  bids=<count>  offers=<count>  treasury=<int>  phase=<ObserverGoalPhase>` so a future regression in `runTreasuryPlanner` or the orchestrator F7 append surfaces structured per-GP context (matches the trace-table pattern used by `seed42_expand_phase_turn1_pin_test.dart`).

## Seed-42 trade-enabled wall-clock budget (Refs #2994 F10)

F10 extends the existing `kTurnProcessingWallClockBudgetMs` (15 000 ms) envelope to the **seed-42** starting state and adds an explicit **trade-orders-enabled** assertion so a regression that (a) silently disables the TreasuryPlanner integration, or (b) re-introduces market resolution work that pushes the seed-42 turn over budget, fails the same single test rather than two separate suites. F1–F5 cover the planner unit behaviour, F9 pins per-GP trade emission, and F10 pins the timed envelope.

### Verification surface

- Test file: `packages/colonizethis_ai/test/perf/seed42_first_turn_trade_enabled_wall_clock_budget_test.dart`.
- Entrypoint exercised: `generateOrdersForGameFullAI(game, topology, tileMapByRegion: …)` against the seed-42 game `init.game.copyWith(aiControlByGpId: {for (final p in init.game.players) p.id: true})`, followed by `validateOrdersAndResolveTurnFromTrustedOrders` to drive the full pipeline including the World Market phase.
- Outputs read: combined `Stopwatch().elapsedMilliseconds` for the AI + resolve span, and `result.orders.tradeOrdersByPlayerId` from the Full AI invocation.

### Test structure

The seed-42 budget test mirrors `full_ai_first_turn_wall_clock_budget_test.dart` (Refs #2507) — one timed `generateOrdersForGameFullAI` + `validateOrdersAndResolveTurnFromTrustedOrders` invocation per assertion — and adds an explicit `tradeOrdersByPlayerId` non-empty check so the timed envelope cannot pass on a path that silently skipped trade emission. Seed-42 GPs stay in EXPAND for the full observer horizon (see `seed42_observer_colonial_regression_test.dart` § skip rationale), so turn 1 deterministically captures the trade-enabled budget without paying the 150-turn observer-loop cost.

### Acceptance criteria (F10 — seed-42 trade-enabled budget pin)

- Given the seed-42 `runInitGame` output (`GameSetupConfig(seed: 42)`, default options) with every Great Power flipped to AI-controlled via `aiControlByGpId`, when `generateOrdersForGameFullAI` runs once for turn 1, then `result.orders.tradeOrdersByPlayerId.values.expand((list) => list).length` is strictly greater than `0` (the timed envelope must exercise the trade-orders code path).
- Given the same seed-42 turn-1 init, when `generateOrdersForGameFullAI` and `validateOrdersAndResolveTurnFromTrustedOrders` run end-to-end inside a single `Stopwatch`, then the combined `Stopwatch().elapsedMilliseconds` is less than or equal to `kTurnProcessingWallClockBudgetMs` (15 000 ms).
- Given a failing budget assertion, when the test reports the failure, then the assertion `reason` contains the structured row `total_ms=<int> full_ai_ms=<int> resolve_ms=<int> trade_orders=<int> budget_ms=15000` so a regression surfaces which phase exceeded the envelope and whether the trade-orders path was exercised in that envelope.

## Seed-42 100-turn per-turn World-Market lock-recovery diagnostic (Refs #2924)

#2924 (EXPAND geographic peer-war lock at `treasury == 0`) requires verifying
which link of the lock-recovery chain (`StrategicGoal.trade` floor F6 →
`runTreasuryPlanner` surplus / offers F1–F5/F8 → `world_market_phase` matching
→ treasury credited per `FilledDeal`) is failing on seed 42 for the four
failing Great Powers gp3–gp6. The Step-0 baseline posted on #2924 (2026-06-01)
captured the headline gate metrics (`gpOwGain`, `gpTreasuryUnderCheapestRegimentTurns`,
turn-99 treasury) reused from the existing `seed42_observer_conquest_s7d_diagnostic_test.dart`
S7-D rollup; it confirmed Path F **alone, without tuning**, leaves all four
failing GPs below `cheapestRegimentBuildTreasuryCost()` for 97 of 100 turns.

The Step-0 rollup does **not** decompose where the chain breaks (no
surplus / no cargo / no bid liquidity / no offer fill / threshold mis-tuned).
This SPEC slice authorises the **per-turn, per-Great-Power** diagnostic that
captures every link of the chain in the same seed-42 100-turn loop so the
failing lever can be isolated before any Path F tuning code lands.

### Verification surface

- Test file: `packages/colonizethis_ai/test/seed42_observer_world_market_diagnostic_test.dart`.
- Entrypoint exercised: `generateOrdersForGameFullAI` + `validateOrdersAndResolveTurnFromTrustedOrders`
  in the same 100-turn loop as `seed42_observer_conquest_s7d_diagnostic_test.dart`
  (Refs #2847 S7-D) so the two diagnostics agree on the simulation harness
  and either can be cross-referenced when a tuning slice shifts both surfaces.
- Outputs read (per Great Power per turn, before and after turn resolution):
  - Treasury (`game.playerById(gpId).treasury`) at start and end of turn,
    and treasury delta attributable to filled deals as seller / buyer that
    turn.
  - Trade-cargo capacity (`cargoHoldsForHomeFleet`) and bid-type cap
    (`worldMarketBidTypeCap`) — the two suggester preconditions for
    emitting offers and bids.
  - Trade orders emitted that turn from `fullAi.orders.tradeOrdersByPlayerId[gpId]`
    (bid count, offer count, total quantity).
  - Carry-forward residuals at start of turn from
    `game.worldMarketState.carryForwardOffersByFactionId[gpId]` /
    `carryForwardBidsByFactionId[gpId]`.
  - Filled deals from the resolved turn's
    `game.worldMarketState.lastTurnActivity` — counts and treasury credited
    (`quantity * pricePerUnit`) attributed to `gpId` as seller, and
    attributed to `gpId` as buyer.
- Aggregate per-GP rollup: cumulative trade orders emitted (bids, offers),
  cumulative deals as seller / buyer, cumulative treasury credited from
  market sales, turns with zero `tradeCargoCapacity`, turns with zero
  `bidTypeCap`, turns under `cheapestRegimentBuildTreasuryCost()` (mirrors
  S7-D's `gpTreasuryUnderCheapestRegimentTurns` count), and the first turn
  index (if any) on which treasury crosses `cheapestRegimentBuildTreasuryCost()`.
- Per-commodity rollup for the four failing GPs (gp3, gp4, gp5, gp6): top-5
  commodity ids by offer quantity emitted and top-5 commodity ids by
  filled-deal quantity matched as seller.

### Skip semantics and runtime

The test is skipped by default with the same rationale as
`seed42_observer_conquest_s7d_diagnostic_test.dart` (long-running, ~4 min on
the project reference host, no value pinned — re-run manually when the
diagnostic surface shifts after a Path F tuning slice lands). The lightweight
assertion mirrors the S7-D pattern: each GP's per-turn record count equals
the turn count so a regression that silently drops turns from the loop
still fails the test.

### Acceptance criteria (Refs #2924 per-turn diagnostic)

- Given the seed-42 `runInitGame` output with every Great Power flipped to
  AI-controlled via `aiControlByGpId`, when the diagnostic test runs the
  same 100-turn `generateOrdersForGameFullAI` + `validateOrdersAndResolveTurnFromTrustedOrders`
  loop as `seed42_observer_conquest_s7d_diagnostic_test.dart`, then for
  every Great Power `gp1..gp6` the test records exactly `100` per-turn
  entries (one per turn) covering treasury, cargo, bid-type cap, emitted
  trade-order counts, carry-forward residuals, and filled-deal seller /
  buyer totals.
- Given the same 100-turn loop completes, when the test emits the
  structured diagnostic JSON, then the JSON contains a `gpRollup` object
  with one entry per `gp1..gp6` exposing `cumulativeOffersEmitted`,
  `cumulativeBidsEmitted`, `cumulativeDealsAsSeller`,
  `cumulativeTreasuryCreditedAsSeller`, `cumulativeDealsAsBuyer`,
  `cumulativeTreasurySpentAsBuyer`, `turnsZeroTradeCargo`,
  `turnsZeroBidTypeCap`, `turnsTreasuryUnderCheapestRegiment`, and
  `firstTurnTreasuryCrossesCheapest` (`int` turn index ≥ 1, or `null`
  when treasury never crosses the threshold across the 100-turn window).
- Given the same diagnostic JSON, when the test prints it to stdout via
  `aiLogger`, then the output is wrapped in greppable
  `WM2924_DIAGNOSTIC_JSON_BEGIN` / `WM2924_DIAGNOSTIC_JSON_END` markers
  so the rollup can be transcribed into a comment on #2924 without
  manual reformatting (mirrors the S7-D `S7D_DIAGNOSTIC_JSON_BEGIN/END`
  contract).

## Out of scope for this SPEC slice

The following remain under remaining `#2994` subtasks:

- Full treasury inflow/outflow forecasting (riches phase, subsidies, build/research spend) beyond the surplus/need maps and F8 offer-inflow discount above (F1 extension).
- Observer-game seed-42 multi-turn treasury-growth + phase-varying (EXPAND vs COLONIAL) verification (F9 follow-up — gated on the seed-42 colonial-acquisition gap, Refs #2848 / #2509 S7, the same gate that keeps `seed42_observer_colonial_regression_test.dart` skipped). The Refs #2924 per-turn diagnostic above complements but does not replace this F9 follow-up: the diagnostic does not pin treasury-growth thresholds, only records the chain links so a tuning slice can target the failing lever.
- Overseas extraction tonnage subtraction from trade cargo once extraction publishes per-player planned tonnage.

---

## Interactions

- [economy-planner.md](economy-planner.md) — production assignments and cargo preference (TreasuryPlanner sub-planner integration point in F5).
- [ai-architecture.md](ai-architecture.md) — turn pipeline, domain planning, `selectPrimaryGoal`.
- [ai-personalities.md](ai-personalities.md) — base `trade` goal weights per leader.
- [phase-planner-architecture.md](phase-planner-architecture.md) — observer-goal phase resolution that feeds `evaluateStrategicGoalScores`.
- [order-suggestions.md](../program/order-suggestions.md) — trade-order suggestion API (consumed by future F-slices).
- [world-market-resolution.md](../program/world-market-resolution.md) — market matching, pricing, and `MarketActivity` outputs (consumed by future F8).
