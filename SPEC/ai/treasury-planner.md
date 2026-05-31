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
- **Cargo:** `max(0, cargoHoldsForHomeFleet(game, playerId))` — overseas extraction tonnage reservation deferred until extraction publishes planned tonnage on the pipeline (same deferral as world-market phase handler Refs #2990 B3).
- **Bid type cap:** `worldMarketBidTypeCap(game, playerId)` (embassy / trade-fairs diplomacy gates).

### Acceptance criteria (F1–F5 / F7)

- Given an AI GP with timber stockpile well above reserve and `treasury` below `cheapestRegimentBuildTreasuryCost()`, when `runTreasuryPlanner` runs, then it emits at least one `TradeOrderType.offer` for timber at priority `2`.
- Given an AI GP with embassy overture, fabric production input need, and market fabric price below recipe input cost, when `runTreasuryPlanner` runs, then it emits a `TradeOrderType.bid` for fabric at priority `1`.
- Given an AI GP with no embassy (`bidTypeCap == 0`), when `runTreasuryPlanner` runs, then it emits offers only (no bids).
- Given identical inputs, when `runTreasuryPlanner` runs twice, then both runs return identical `List<TradeOrder>`.
- Given an `EconomyPlan` whose `tradeOrders` is non-empty for an AI GP, when `runDomainPlannersWithOutcome` runs, then `outcome.orders.tradeOrdersByPlayerId[nationId]` equals `economyPlan.tradeOrders` and `outcome.domainGateData.tradePlannerRan` is `true` (F7 wiring).
- Given an `EconomyPlan` whose `tradeOrders` is empty, when `runDomainPlannersWithOutcome` runs, then `outcome.orders.tradeOrdersByPlayerId` does not contain `nationId` and `outcome.domainGateData.tradePlannerRan` is `false`.
- Given identical orchestrator inputs (game / topology / nationId / view / snapshot / config / primary goal / seeds / suggestion API / economy plan / tile maps / phase plan), when `runDomainPlannersWithOutcome` runs twice, then both runs produce identical `outcome.orders.tradeOrdersByPlayerId[nationId]` lists (determinism).

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

## Out of scope for this SPEC slice

The following remain under remaining `#2994` subtasks:

- Full treasury inflow/outflow forecasting (riches phase, subsidies, build/research spend) beyond the surplus/need maps and F8 offer-inflow discount above (F1 extension).
- Observer-game seed-42 trade-behaviour verification and budget profiling (F9 / F10).
- Overseas extraction tonnage subtraction from trade cargo once extraction publishes per-player planned tonnage.

---

## Interactions

- [economy-planner.md](economy-planner.md) — production assignments and cargo preference (TreasuryPlanner sub-planner integration point in F5).
- [ai-architecture.md](ai-architecture.md) — turn pipeline, domain planning, `selectPrimaryGoal`.
- [ai-personalities.md](ai-personalities.md) — base `trade` goal weights per leader.
- [phase-planner-architecture.md](phase-planner-architecture.md) — observer-goal phase resolution that feeds `evaluateStrategicGoalScores`.
- [order-suggestions.md](../program/order-suggestions.md) — trade-order suggestion API (consumed by future F-slices).
- [world-market-resolution.md](../program/world-market-resolution.md) — market matching, pricing, and `MarketActivity` outputs (consumed by future F8).
