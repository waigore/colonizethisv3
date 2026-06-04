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
- Called from `runEconomyPlanner` after production assignments are chosen by default; results are stored on `EconomyPlan.tradeOrders` and merged into `Orders.tradeOrdersByPlayerId` by `runDomainPlannersWithOutcome` (F7 wiring) so every orchestrator caller — including the strategic-AI entry `generateStrategicOrdersWithTrace` and the simpler `runDomainPlanners` test entrypoint — surfaces the same trade output without duplicating the merge.
- **Refs #3122 orchestrator wiring** — the strategic-AI production entry sets `runEconomyPlanner(skipTradeOrderGeneration: true)` and `runDomainPlannersWithOutcome(recomputeTradeOrdersWithPendingCosts: true)` so the orchestrator re-invokes `runTreasuryPlanner` at the tail of the domain pipeline (after work, build, recruit, research, naval, and diplomacy passes) with `currentOrders = ctx.orders`. This makes `pendingTreasuryCostsForTurn` see the AI's own pending build / recruit / research orders so the bid budget is shaped to the same treasury the matcher (#3115) will enforce at phase 13. Callers that do not opt in (existing `runDomainPlanners` test entrypoints, the wiring test fixture) continue to consume `economyPlan.tradeOrders` unchanged.

### Orchestrator wiring (Refs #2994 F7 / Refs #3122)

- After all other domain planners run, the orchestrator merges trade orders into `ctx.orders.tradeOrdersByPlayerId[nationId]` via `Orders.appendTradeOrders`. The append is skipped when the resolved list is empty, so `tradeOrdersByPlayerId` stays absent for that player and downstream `MapEquality` checks in tests remain stable.
- Source of the merged list:
  - **Default path** (`recomputeTradeOrdersWithPendingCosts == false`, Refs #2994 F7) — the orchestrator uses `economyPlan.tradeOrders` exactly as supplied. The wiring contract preserves prior behaviour for `runDomainPlanners` test entrypoints and the F7 fixture.
  - **Pending-cost projector path** (`recomputeTradeOrdersWithPendingCosts == true`, Refs #3122) — the orchestrator calls `runTreasuryPlanner(game, playerId, stockpile, productionAssignments, treasury, currentOrders: ctx.orders, tileMapByRegion, topology)` using the inputs already present on `economyPlan` plus the live `game.playerById(nationId)` stockpile and treasury. `economyPlan.tradeOrders` is **ignored** in this mode; `runEconomyPlanner(skipTradeOrderGeneration: true)` returns the empty list so no work is duplicated.
- The orchestrator records a `tradePlannerRan` boolean on `DomainGateData` (`true` iff at least one trade order was emitted in the resolved list). This field is emitted under `thresholds.domainGates.tradePlannerRan` in the AI trace alongside the existing per-domain `*PlannerRan` flags, so an analyst can distinguish "treasury planner produced zero orders" from "treasury planner did not run for this player turn" without consulting per-player JSON.
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

1. `lockRecoveryDesignatedBuyerId(game)` rotates among Great Powers whose **current** `player.treasury >= treasuryAffluenceThreshold()` (same band as F10 speculative bidding), **excluding** below-quota GPs with zero NW provinces (Path F lock-recovery sellers that must accumulate seller credits, not spend as buyers — Refs #2924 Path F). When no GP meets that filtered band, the function returns the empty string and `isLockRecoveryLiquidityBuyer` is **false** for every GP — buy-side liquidity is supplied by phase-13 minor/tribe auto-bids (`SPEC/program/world-market-resolution.md` § Lock-recovery minor auto-bids). Returns the empty string when **no** GP is broke (steady-state F1–F5 / F10 path only).
2. The designated buyer (when non-empty) adds a synthetic `need` entry for the lock-recovery food commodity (highest prior-turn `MarketActivity.totalOfferQuantity` among food ids; default alphabetical first food when activity is empty) with quantity `floor(treasuryBudgetForBids / pricesByCommodityId[liquidity])` where `treasuryBudgetForBids` is the same budget passed to `TradeOrderSuggester` (Refs #3122 — current treasury minus pending phase-pre-13 costs minus carry-forward bid notional, floored at `0`). The F10 `kSpeculativeBidStockpileTarget` ceiling does **not** apply to this synthetic bid (Refs #2924 F14). The buyer never commits more treasury than it currently holds. Other commodities are stripped from `need` for that GP so the single `bidTypeCap` slot cannot be spent on fabric/bronze deficits; F10 speculative bidding is suppressed for the designated buyer that turn.
3. The designated buyer **removes** that commodity from `available` so it does not offer and bid the same commodity (validator mutual-exclusion rule 3).
4. All broke GPs keep urgent offers on their surplus food; the designated buyer's bid at priority `2` matches those offers in the same tier. When the designated buyer is affluent its own `offerPriority` is moderate, but `forceBidPriority` overrides the emitted bid to `kTreasuryOfferPriorityUrgent` so tier alignment holds (Refs #2924 F12).
5. Broke non-designated GPs **do not** emit deficit or speculative bids (their single `bidTypeCap` slot would target non-grain commodities that do not match the urgent grain offers). Mid-below-quota zero-NW lock-recovery **sellers** (`oldWorldProvincesOwned >= 2`, below quota, zero NW) stay offers-only even when `player.treasury >= cheapestRegimentBuildTreasuryCost()` so a brief threshold crossing cannot drain Path F seller credits on grain bids or F10 speculation (Refs #2924 Path F gp6 regression) — **except** for the single regiment build-input bootstrap bid described in § Lock-recovery seller regiment build-input bootstrap (Refs #2847 H8), which fires only after the seller has fully recovered (`player.treasury >= cheapestRegimentBuildTreasuryCost()`) yet still holds zero regiments and is missing the cheapest regiment's build input. Other broke GPs use the F13 forecast guard: suppression keys off **current** `player.treasury < cheapestRegimentBuildTreasuryCost()`, not the F8 offer-inflow forecast, so an optimistic forecast cannot resume deficit bidding while the GP is still broke. F1–F5 deficit bids resume once `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` for GPs outside the seller band.
6. **Offer priority follows actual treasury under lock recovery (Refs #2924 F16).** When `player.treasury < cheapestRegimentBuildTreasuryCost()`, emitted offers use `kTreasuryOfferPriorityUrgent` even when `treasuryForecast >= cheapestRegimentBuildTreasuryCost()`. Matching runs only within the same integer priority tier; downgrading to `kTreasuryOfferPriorityModerate` while still broke strands urgent minor/tribe bids (priority `2`) and stalls seller credits one unit below the regiment threshold (seed-42 gp5 at treasury `1999`).

### Acceptance criteria (F13 / F16)

- Given `player.treasury < cheapestRegimentBuildTreasuryCost()` and `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` for a non-designated GP, when `runTreasuryPlanner` runs, then it emits offers only (no bids).
- Given the same fixture, when `runTreasuryPlanner` runs, then every emitted offer has `priority == kTreasuryOfferPriorityUrgent` (F16 tier alignment).

The lock-recovery branch activates for the designated buyer even when its own `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` (`isDesignatedLockRecoveryBuyer`), because the affluent buyer is providing buy-side liquidity for other broke GPs' urgent offers.

No affordability bypass: buyers debit treasury at deal time. Because the bid quantity is capped at `buyerTreasury / pricesByCommodityId[liquidity]`, the buyer never spends more than it holds (worst case residual `(buyerTreasury mod pricePerUnit)`). Speculative bidding (F10) remains gated by `treasuryAffluenceThreshold`.

### No GP buyer when no GP is affluent (Refs #2924 F15)

When every Great Power is below `treasuryAffluenceThreshold()` but at least one is below `cheapestRegimentBuildTreasuryCost()`, broke GPs emit urgent offers only; phase 13 injects minor/tribe synthetic bids and seller-priority matching (`world-market-resolution.md` § F15). GP liquidity buyers were removed from this band because a single turn-rotated broke buyer (~50 treasury) or parallel GP buyers spending on grain prevented seller-credit accumulation on seed 42.

### Acceptance criteria (F11 / F12 / F15)

- Given at least one broke GP and `isLockRecoveryLiquidityBuyer(...) == true` for `playerId` (affluent designated buyer only), when `runTreasuryPlanner` runs, then it emits at least one `TradeOrderType.bid` for the lock-recovery food commodity at `priority == kTreasuryOfferPriorityUrgent` and emits no `TradeOrderType.offer` for that commodity — including when the designated affluent buyer's own `treasuryForecast >= cheapestRegimentBuildTreasuryCost()` (Refs #2924 F12).
- Given every GP has `player.treasury < treasuryAffluenceThreshold()`, at least one GP is broke, and `playerId` is any Great Power, when `isLockRecoveryLiquidityBuyer` runs, then it returns **false** (F15 minor bids provide buy-side liquidity).
- Given the designated buyer with `treasuryBudgetForBids == B` and lock-recovery food priced at `P`, when `runTreasuryPlanner` runs, then the synthetic grain bid's `quantity` equals `max(0, B / P)` (integer-truncating division; Refs #2924 F12 / F14).
- Given at least one broke GP but `isLockRecoveryLiquidityBuyer(...) == false` and `player.treasury < cheapestRegimentBuildTreasuryCost()`, when `runTreasuryPlanner` runs, then it emits offers only (no bids).
- Given **no** GP with `player.treasury < cheapestRegimentBuildTreasuryCost()`, when `lockRecoveryDesignatedBuyerId(game)` runs, then it returns the empty string and no synthetic grain bid is emitted.
- Given `treasuryForecast < cheapestRegimentBuildTreasuryCost()` for any GP that emits a bid in this lock-recovery configuration, when `runTreasuryPlanner` emits any such bid, then each bid's `priority` equals `kTreasuryOfferPriorityUrgent` (tier alignment).
- Given identical inputs, when `runTreasuryPlanner` runs twice, then `lockRecoveryDesignatedBuyerId` and the emitted trade orders are identical (determinism).
- Given tile maps and topology where overseas extraction would consume all home-fleet cargo holds, when `runTreasuryPlanner` runs with those maps, then `TradeOrderSuggester` receives `tradeCargoCapacity == 0` (no bids that cannot clear at world-market phase).
- Given the same fixture but `tileMapByRegion` omitted, when `runTreasuryPlanner` runs, then `tradeCargoCapacity` equals `cargoHoldsForHomeFleet` (backward-compatible unit-test path).

---

## Lock-recovery seller food-surplus release (Refs #2924 F17)

F17 closes the seed-42 **gp6** Path F gap where a below-quota zero-NW
lock-recovery seller leaves its trade cargo idle for lack of offered food.
The per-turn seller credit a broke GP can earn is bounded by how much of the
liquidity-food commodity it ships into the net-positive minor/tribe auto-bid
pool (F15: amplified `2×` notional plus
`kLockRecoverySellerBonusPerLiquidityDeal`). On seed 42 the recovering GPs
(`gp3`, `gp5`) hoard large grain stockpiles and saturate their cargo every
turn, while `gp6` keeps only a small grain stockpile (~42) that rarely clears
the default `2×` food safety reserve (`24` units), so it emits grain offers on
only ~14 of 100 turns, never approaches its ~21-hold cargo ceiling, and its
cumulative seller credit (~913) stays far below
`cheapestRegimentBuildTreasuryCost()`.

### Food safety buffer for lock-recovery sellers

The F1–F5 surplus formula (§ Surplus / need maps) uses
`safety = 2 × consumption` for food and `1 × consumption` for other
categories. When the GP is a **below-quota zero-NW lock-recovery seller**
(`_isBelowQuotaZeroNwLockRecoverySeller`: `oldWorldProvincesOwned >= 2`,
`isBelowObserverConquestQuota(ow)`, and `newWorldProvincesOwned == 0`), the
food safety buffer is **`0`**, so the food reserve collapses to
`consumption + inputs` — one consumption cycle. The seller therefore offers
all food beyond a single-cycle reserve, maximising the cargo it ships into the
F15 minor/tribe liquidity instead of stranding surplus behind the precautionary
buffer. Non-food safety buffers are unchanged, and the change applies only to
lock-recovery sellers; every other GP keeps the `2×` food buffer. This is a
sell-side throughput change only — no affordability rule is bypassed, and
buyers/minors still debit per filled unit.

### Determinism and budget

The seller predicate and the buffer selection are pure functions of `game`,
`playerId`, the `Stockpile`, and the static catalogs; identical inputs yield
identical surplus maps. No hot-path logging is added; the per-turn cost is the
existing `O(tracked commodities)` surplus pass.

### Acceptance criteria (F17)

- Given an AI Great Power that is a below-quota zero-NW lock-recovery seller
  (`oldWorldProvincesOwned` in `[2, kObserverConquestMinOwProvincesPerGp)`,
  `newWorldProvincesOwned == 0`) with `treasury == 0` and a grain stockpile of
  `kShortageThreshold + 8` (`16`) and no production assignments, when
  `runTreasuryPlanner` runs, then it emits at least one `TradeOrderType.offer`
  for grain at `priority == kTreasuryOfferPriorityUrgent` (the `0` food safety
  buffer yields a positive surplus of `8`).
- Given an otherwise identical AI Great Power that is **not** a lock-recovery
  seller (`oldWorldProvincesOwned == 1`) with the same `16`-unit grain
  stockpile and `treasury == 0`, when `runTreasuryPlanner` runs, then it emits
  **no** grain offer (the default `2×` food safety reserve of `24` exceeds the
  stockpile, so surplus is non-positive — negative control).
- Given a below-quota zero-NW lock-recovery seller with a non-food surplus
  (e.g. `timber`) and the same fixture, when `runTreasuryPlanner` runs, then
  the timber surplus is computed with the unchanged `1×` (non-food) safety
  buffer (F17 only relaxes the food buffer).
- Given identical inputs, when `runTreasuryPlanner` runs twice on the
  lock-recovery seller path, then both runs return identical `List<TradeOrder>`
  outputs (determinism).

---

## Lock-recovery seller regiment build-input bootstrap (Refs #2847 H8)

H8 closes the seed-42 tail of the Path-F lock-recovery chain: a below-quota
zero-NW lock-recovery seller (the same `_isBelowQuotaZeroNwLockRecoverySeller`
predicate as F17) earns world-market seller credit by selling food and
*does* recover treasury to or above `cheapestRegimentBuildTreasuryCost()`,
but its bid `need` is cleared every turn (§ Rotating designated buyer point
5 — sellers are offers-only). The cheapest regiment, `peasant_levies`,
requires its `buildInputs` commodities **in the stockpile** before
`suggestBuildOrders` will return it as a candidate
(`SPEC/program/order-suggestions.md` § Build orders; the validator checks
treasury, a free worker, **and** every `buildInputs` commodity). A recovered
seller that holds zero of those input commodities therefore never produces a
regiment candidate, so the treasury the sell-down accumulated stays idle and
the GP is trapped at zero regiments indefinitely (seed-42 gp5/gp6 hold
treasury `>= cheapestRegimentBuildTreasuryCost()` with `0` fabric for tens of
consecutive turns).

### Build-input bootstrap bid

After the F13 `need.clear()` for lock-recovery sellers, the planner re-adds a
single deficit entry for each missing build input of the cheapest regiment
when **all** of the following hold for the lock-recovery seller:

- `_isBelowQuotaZeroNwLockRecoverySeller(game, playerId)` is `true` (same
  predicate as F17), and
- `player.treasury >= cheapestRegimentBuildTreasuryCost()` (the seller has
  fully recovered — the bootstrap never spends credits the seller is still
  accumulating toward the threshold), and
- `regimentCountForPlayer(game, playerId) == 0` (the GP owns no regiment
  across Home and field armies).

For each `entry` in `RegimentEconomyCatalog.peasantLevies.buildInputs`, let
`held = projectedStockpile[entry.key] + carryForwardBids[entry.key]`; when
`held < entry.value`, set `need[entry.key] = entry.value - held`. The bid is
then sized and admitted by the existing `_prioritizedBids` pass under the
**unchanged** cargo, `bidTypeCap`, and treasury-budget clamps (§
Treasury-budget-aware bid sizing). No affordability rule is bypassed: the
matcher still debits treasury per filled unit at phase 13, and the validator
still gates the eventual `BuildUnitOrder`.

The carve-out is self-clearing: once the GP owns a regiment
(`regimentCountForPlayer > 0`) or the input lands in the stockpile
(`held >= entry.value`) the entry is no longer added, so the seller returns to
the offers-only Path-F behaviour.

### Residual production-supply dependency (disclosure)

The bootstrap converts recovered treasury into **demand** for the build
input, but a deal only clears when matching **supply** exists on the world
market that turn. On seed 42 the cheapest regiment's build input (`fabric`)
often has no Great-Power or minor/tribe offer supply, so the emitted bid may
not fill. The companion **production-side** slice in
[economy-planner.md](economy-planner.md) § Regiment build-input production
priority (Refs #2847 H8) prioritizes feasible recipes that output missing
`peasant_levies` build inputs when `forceCheapestRegimentBuild` is active and
treasury has recovered. This treasury section authorises and pins the
**bid-emission** behaviour; the economy-planner section authorises domestic
production when market supply is absent.

### Determinism and budget

The seller predicate, the regiment count, and the build-input lookup are pure
functions of `game`, `playerId`, the projected `Stockpile`, the carry-forward
bid map, and the static `RegimentEconomyCatalog`; identical inputs yield
identical `need` maps. The added work is `O(buildInputs of one regiment)` with
no hot-path logging, well inside the 15-second turn-resolution budget.

### Acceptance criteria (H8)

- Given an AI Great Power that is a below-quota zero-NW lock-recovery seller
  with `player.treasury >= cheapestRegimentBuildTreasuryCost()`,
  `regimentCountForPlayer(game, playerId) == 0`, and a projected stockpile
  (plus carry-forward bids) holding fewer than `peasant_levies` requires of at
  least one `buildInputs` commodity `C`, when `runTreasuryPlanner` runs, then
  it emits at least one `TradeOrderType.bid` for `C` with
  `quantity >= peasant_levies.buildInputs[C] - held`.
- Given an otherwise identical lock-recovery seller whose
  `player.treasury < cheapestRegimentBuildTreasuryCost()`, when
  `runTreasuryPlanner` runs, then it emits **no** bid for any `peasant_levies`
  build-input commodity (negative control — the seller keeps accumulating
  credits before spending on the build input).
- Given an otherwise identical lock-recovery seller that already holds at
  least `peasant_levies.buildInputs[C]` of every build-input commodity `C`,
  when `runTreasuryPlanner` runs, then it emits **no** build-input bid
  (the carve-out clears once the input is on hand).
- Given an otherwise identical lock-recovery seller with
  `regimentCountForPlayer(game, playerId) > 0`, when `runTreasuryPlanner`
  runs, then it emits **no** build-input bid (the bootstrap targets the
  zero-regiment rebuild gap only).
- Given an AI Great Power at or above the conquest quota
  (`oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp`) — not a
  lock-recovery seller — with the same treasury and zero regiments, when
  `runTreasuryPlanner` runs, then it emits **no** build-input bootstrap bid
  (the carve-out is scoped to below-quota zero-NW sellers).
- Given identical inputs, when `runTreasuryPlanner` runs twice on the
  build-input bootstrap path, then both runs return identical
  `List<TradeOrder>` outputs (determinism).

### Build-input feedstock reservation (offer side, Refs #2847 H8-supply)

The bootstrap bid above creates **demand** for the missing build input, and
the economy-planner production boost ([economy-planner.md](economy-planner.md)
§ Regiment build-input production priority) creates **domestic supply** — but
only when the build input's recipe feedstock is on hand. `fabric` is produced
from `wool` (`fabricFromWool`) or `cotton` (`fabricFromCotton`), each requiring
two units of feedstock per run. A below-quota zero-NW lock-recovery seller that
has recovered treasury otherwise sells its surplus `wool` / `cotton` into the
world market every turn, so the feedstock never accumulates to a feasible
fabric run and the production boost has nothing to convert. The seller then
holds zero regiments indefinitely even though it can afford one (seed-42
gp3 / gp5 / gp6 hold `fabric` for only ~2 of 100 turns).

Under the **same** carve-out gate as the bootstrap bid
(`_isBelowQuotaZeroNwLockRecoverySeller(game, playerId)` is `true`,
`player.treasury >= cheapestRegimentBuildTreasuryCost()`, and
`regimentCountForPlayer(game, playerId) == 0`), the planner withholds the
build-input feedstock from its offer set: for every `peasant_levies` build
input the projected stockpile is short of, the input commodities of every
production recipe that outputs that build input are removed from the
offer-`available` map. The reservation does not add any order — it only
suppresses surplus offers for the feedstock commodities — so the retained
feedstock accumulates across turns until a fabric recipe becomes feasible and
the economy planner's boost runs it. It is self-clearing: once the build input
lands in the stockpile (so the build input is no longer missing) or the GP owns
a regiment, no feedstock is reserved and the seller resumes offering its
surplus.

The reservation never weakens a healthy GP: it is gated to the below-quota
zero-NW seller band (gp1 / gp2 are above quota), to the zero-regiment rebuild
case (a seller already holding regiments keeps selling feedstock), and to a
recovered treasury (a still-broke seller keeps selling for liquidity). The
feedstock lookup is a pure function of the projected `Stockpile` and the static
`RegimentEconomyCatalog` / `ProductionRecipesCatalog`; identical inputs yield
identical offer sets.

##### Residual feedstock-acquisition dependency (disclosure)

This reservation only has effect when the seller **already holds** the recipe
feedstock as surplus — it prevents that feedstock from being sold before it can
accumulate to a feasible run. It does **not** acquire feedstock for a seller
that holds none. On seed 42 the failing below-quota Great Powers (gp3 / gp5 /
gp6) extract no `wool` / `cotton` and the world market carries no `fabric`
seller supply, so they remain unable to source the cheapest regiment's build
input and the turn-100 conquest gate (`SPEC` seed-42 regression) stays open on
the feedstock-acquisition axis. Closing that axis (feedstock extraction routing
or a market `fabric`/feedstock seller) is tracked as separate #2847 work; this
reservation is the offer-side invariant that keeps the production path
(`economy-planner.md` § Regiment build-input production priority) viable once
feedstock is on hand.

#### Acceptance criteria (H8-supply)

- Given a below-quota zero-NW lock-recovery seller with
  `player.treasury >= cheapestRegimentBuildTreasuryCost()`,
  `regimentCountForPlayer(game, playerId) == 0`, a projected stockpile missing
  the cheapest regiment's `fabric` build input, and surplus `wool` (or
  `cotton`) it would otherwise offer, when `runTreasuryPlanner` runs, then it
  emits **no** `TradeOrderType.offer` for that feedstock commodity.
- Given an otherwise identical lock-recovery seller that already holds at least
  one `fabric`, when `runTreasuryPlanner` runs, then it emits its surplus
  `wool` / `cotton` offers as normal (the feedstock reservation self-clears once
  the build input is on hand).
- Given an otherwise identical lock-recovery seller with
  `regimentCountForPlayer(game, playerId) > 0`, when `runTreasuryPlanner` runs,
  then it emits its surplus feedstock offers as normal (the reservation targets
  the zero-regiment rebuild gap only).
- Given an AI Great Power at or above the conquest quota (not a lock-recovery
  seller) with surplus `wool` / `cotton`, when `runTreasuryPlanner` runs, then
  it emits those surplus offers as normal (the reservation is scoped to
  below-quota zero-NW sellers).
- Given identical inputs, when `runTreasuryPlanner` runs twice on the
  feedstock-reservation path, then both runs return identical
  `List<TradeOrder>` outputs (determinism).

### Lock-recovery regiment build-input market supply (Refs #2847 H8-supply market)

The offer-side feedstock reservation (above) and the economy-planner
production boost only help when the lock-recovery seller **already holds**
recipe feedstock. On seed 42 the failing below-quota zero-NW sellers
(gp3 / gp5 / gp6) extract no `wool` / `cotton`, the world market carries
no `fabric` offers, and the H8 bootstrap **fabric** bid therefore never
clears (`gpRegimentInputDealsAsBuyer == 0` in the S7-D diagnostic). This
section closes the **market supply** axis so the domestic production path
can run.

**Seller-side feedstock bid (bootstrap extension).** Under the same gate as
§ Lock-recovery seller regiment build-input bootstrap, when the projected
stockpile is short of a `peasant_levies` build input **and** short of the
feedstock required for one feasible `fabric_from_wool` / `fabric_from_cotton`
run, the planner injects a **feedstock bid first** (quantity = per-run recipe
input minus on-hand plus carry-forward). The fabric build-input bid is
suppressed while any such feedstock deficit remains so the single
`bidTypeCap` slot targets acquirable supply. Once feedstock is on hand, the
existing fabric bootstrap bid and production boost resume; the feedstock
reservation prevents selling the acquired wool / cotton before conversion.

**Affluent-GP feedstock / build-input offers.** When **any** below-quota
zero-NW lock-recovery seller in the game meets the H8 bootstrap gate
(`player.treasury >= cheapestRegimentBuildTreasuryCost()`,
`regimentCountForPlayer == 0`, missing a `peasant_levies` build input), every
**other** Great Power that is **not** a lock-recovery seller and holds
`player.treasury >= cheapestRegimentBuildTreasuryCost()` releases surplus
`wool`, `cotton`, and `fabric` aggressively into its offer set (safety buffer
`0` for those commodities — same release pattern as § Lock-recovery seller
food-surplus release) so the seller's feedstock / fabric bids can match. The
gate clears automatically once no lock-recovery seller still needs the
bootstrap path.

#### Acceptance criteria (H8-supply market)

- Given a below-quota zero-NW lock-recovery seller with recovered treasury,
  zero regiments, zero `fabric`, and zero `wool`, when `runTreasuryPlanner`
  runs for that seller, then it emits a `TradeOrderType.bid` for `wool` (or
  `cotton` when that is the feasible feedstock) and emits **no** `fabric`
  bid until the feedstock deficit is cleared.
- Given the same game state and a non-seller Great Power with surplus `wool`
  and `player.treasury >= cheapestRegimentBuildTreasuryCost()`, when
  `runTreasuryPlanner` runs for that affluent GP, then it emits a
  `TradeOrderType.offer` for `wool`.
- Given no below-quota zero-NW lock-recovery seller meets the H8 bootstrap
  gate, when `runTreasuryPlanner` runs for an affluent non-seller, then it
  does **not** apply the aggressive `wool` / `cotton` / `fabric` offer
  release (steady-state surplus rules apply).
- Given identical inputs, when `runTreasuryPlanner` runs twice on the
  H8-supply market path, then both runs return identical
  `List<TradeOrder>` outputs (determinism).

---

## Treasury-budget-aware bid sizing (Refs #3122)

After the world-market matcher began clamping bid fills to per-buyer
treasury (Refs #3115), `runTreasuryPlanner` must shape its emitted bids
so the AI never spends a `bidTypeCap` slot on a notional that exceeds
the same budget the matcher enforces at phase 13. Otherwise the AI
emits bids that the matcher truncates to zero or near-zero fills,
wasting the single bid slot for the turn and breaking lock-recovery
food liquidity (F11/F12).

### Bid treasury budget

At the start of `runTreasuryPlanner` for `playerId`:

```
budget = max(0, player.treasury)
       - pendingTreasuryCostsForTurn(game, playerId, currentOrders)
       - carryForwardBidNotional(game, playerId)
```

- **Pending treasury costs** is a new public pure helper
  `pendingTreasuryCostsForTurn(Game, String, Orders) -> int` in
  `packages/colonizethis_logic` that sums treasury debits for the
  three order types that resolve **before** phase 13 (World Market)
  and reduce `player.treasury`:
  - `ResearchOrder` — `treasuryCostForFunding(level)` per
    `SPEC/program/turn-resolution-phases.md` § Phase 7 Research and
    `packages/colonizethis_logic/lib/src/turn/research_rules.dart`.
  - `RecruitWorkerOrder` — `WorkerActionEconomyCatalog.forTier(...).treasuryCost`
    per phase 12 worker-pool sub-phase, reusing `canAffordRecruitWorker`
    affordability gating so unaffordable pending orders are excluded
    (the live resolver also skips them).
  - `BuildUnitOrder` — `buildTreasuryCost` per
    `RegimentEconomyCatalog` / `ShipEconomyCatalog`, reusing
    `ProjectedCostEngine.canAffordBuildOrder` for the same reason.
  Pending `WorkOrder` material costs are stockpile-only (no treasury)
  and are excluded. Any future phase-pre-13 treasury sink must be
  added to `pendingTreasuryCostsForTurn` in lockstep with the resolver
  change that introduces it.
- **Carry-forward notional** sums
  `quantity × effectiveMarketPriceForCommodityId(commodityId, ...)` over
  `game.worldMarketState.carryForwardBidsByFactionId[playerId]`,
  using the price-resolution helper introduced by #3115. Bids whose
  effective price is `null` (no market price and no catalog default
  — manufactured commodities until in-game discovery seeds a price)
  contribute `0` to the notional, matching the validator-side
  defensive skip in `stagedBidTotalSpendByPlayer`.
- **No in-turn credit:** the helper does **not** add `expectedOfferInflow`
  to the budget. The matcher does not credit in-turn sales mid-match
  (Refs #3115), so any speculative credit would over-estimate the
  budget at the moment bids are clamped.

### Per-bid clamp

After the existing cargo clamp in `_prioritizedBids`, for each bid
admitted in priority order:

```
maxAffordable = pricePerUnit > 0
                  ? remainingTreasuryBudget ~/ pricePerUnit
                  : remainingCargo                    // free bids fall back to cargo
cappedQty     = min(bid.quantity, remainingCargo, maxAffordable)
```

- If `cappedQty <= 0`, the bid is skipped and `admitted` is **not**
  incremented (the bid slot stays available for the next eligible
  bid).
- Otherwise the bid is emitted with `quantity = cappedQty`,
  `remainingCargo -= cappedQty`, and `remainingTreasuryBudget` is
  decremented by `(cappedQty * pricePerUnit)` (an integer because
  prices are integer treasury units; matches matcher Step D in
  #3115).
- Priority order is unchanged (`_bidPriorityForCommodity` →
  alphabetical, with `preferCommodityId` override when active).

When `pricePerUnit` is `null` (manufactured commodity without a
discovered price) the planner cannot reason about treasury cost and
falls back to the cargo-only clamp for that bid; the matcher applies
its own per-tier accounting if such a bid clears.

### Speculative and lock-recovery paths

- **Affluent speculative pass (`_addSpeculativeBidNeeds`):** still
  adds at most one synthetic `need` entry. Final quantity is clamped
  in `_prioritizedBids` (treasury and cargo). The affluence gate
  (`treasury >= treasuryAffluenceThreshold()`) is unchanged so broke
  GPs still never enter speculation; the per-bid clamp catches the
  edge case where an affluent GP's projected pending costs reduce
  budget below `pricePerUnit`.
- **Lock-recovery designated buyer (`_applyLockRecoveryLiquidityBid`):**
  the existing in-place treasury cap (`max(0, buyerTreasury / pricePerUnit)`)
  is replaced by the same budget formula above — pending costs and
  carry-forward notional are subtracted from `buyerTreasury` before
  computing `affordableQty`. When the result is `0` the designated
  buyer emits no bid for that turn (rotation handles the next turn);
  mutual-exclusion with the offer side is preserved by the existing
  `available.remove(commodityId)` call.

### Determinism and budget

`pendingTreasuryCostsForTurn`, `carryForwardBidNotional`, and the
per-bid clamp are pure functions of `(game, playerId, currentOrders)`
and the static economy/tech catalogs. They allocate at most
O(orders for one player + carryForwardBids for one player) work,
log nothing on the hot path, and preserve the alphabetical commodity
ordering already used by `_prioritizedBids`. Per-turn budget remains
well inside the 15-second turn-resolution envelope per
`.cursor/rules/colonizethis-turn-resolution-budget.mdc`.

### Acceptance criteria (Refs #3122)

- Given an AI Great Power with `player.treasury == 0` and any
  deficit / speculative / lock-recovery path active, when
  `runTreasuryPlanner` runs, then it emits no `TradeOrderType.bid`
  orders (the budget is `0` so every per-bid clamp drops to `0`).
- Given an AI Great Power with `player.treasury == 100`, one pending
  `BuildUnitOrder` with `buildTreasuryCost == 50`, and a fabric
  deficit bid whose nominal quantity would cost `80` at
  `pricePerUnit == 10`, when `runTreasuryPlanner` runs, then the
  emitted fabric bid has `quantity <= floor(50 / 10) == 5` and the
  cumulative `quantity × pricePerUnit` across all emitted bids does
  not exceed `50`.
- Given an AI Great Power with `player.treasury == 100`, one
  carry-forward `TradeOrderType.bid` for timber with
  `quantity == 6` at `effectiveMarketPriceForCommodityId(timber) == 10`
  (carry-forward notional `60`), and a new fabric deficit bid at
  `pricePerUnit == 10`, when `runTreasuryPlanner` runs, then the
  emitted fabric bid's `quantity × pricePerUnit` is at most `40`
  (`100 − 60`).
- Given an AI Great Power with two deficit commodities where the
  first bid (after cargo clamp) would consume the full remaining
  treasury budget, when `runTreasuryPlanner` runs, then the first
  bid is emitted and the second commodity is skipped without
  consuming a second `bidTypeCap` slot (the planner does not emit
  a zero-quantity placeholder for the dropped bid).
- Given an AI Great Power with `player.treasury >= treasuryAffluenceThreshold()`
  and a positive speculative gap on commodity `C` but
  `floor(remainingBudget / pricesByCommodityId[C]) < kSpeculativeBidStockpileTarget`,
  when `runTreasuryPlanner` runs, then the speculative bid's
  `quantity` equals the affordable floor and the bid is not dropped
  unless that floor is `0`.
- Given a Great Power that is the lock-recovery designated buyer with
  `player.treasury` below the liquidity-bid notional
  (`kSpeculativeBidStockpileTarget × pricesByCommodityId[liquidity]`),
  when `runTreasuryPlanner` runs, then it emits no bid for the
  lock-recovery food commodity and (per the existing
  `available.remove`) does not offer it either (mutual-exclusion
  preserved).
- Given identical inputs `(game, playerId, stockpile, productionAssignments,
  treasury, tileMapByRegion, topology, currentOrders)`, when
  `runTreasuryPlanner` runs twice, then both runs return identical
  `List<TradeOrder>` outputs (determinism — the new clamp is a pure
  function of the same inputs).
- Given any `runTreasuryPlanner` output for any fixture, when each
  emitted bid's `quantity × effectiveMarketPriceForCommodityId(commodityId)`
  is summed with `pendingTreasuryCostsForTurn` and `carryForwardBidNotional`,
  then the total is less than or equal to the player's
  `treasury` at planner entry (budget invariant — the planner never
  commits more treasury than the matcher will accept at phase 13).
- Given a player with one pending `ResearchOrder` at funding level
  `L`, one pending `BuildUnitOrder` with `buildTreasuryCost == C_b`,
  one pending `RecruitWorkerOrder` whose
  `WorkerActionEconomyCatalog.forTier(targetTier).treasuryCost == C_r`,
  and one pending stockpile-only `WorkOrder`, when
  `pendingTreasuryCostsForTurn(game, playerId, currentOrders)` is
  called, then it returns `treasuryCostForFunding(L) + C_b + C_r`
  exactly (the `WorkOrder` is excluded because it is stockpile-only).
- Given `runEconomyPlanner` is called with
  `skipTradeOrderGeneration: true`, when the planner returns, then
  `EconomyPlan.tradeOrders` is the empty list (no
  `runTreasuryPlanner` call is made and no stale planner pass is
  embedded in the plan).
- Given `runDomainPlannersWithOutcome` is called with
  `recomputeTradeOrdersWithPendingCosts: true`, an `economyPlan`
  with non-empty `tradeOrders`, and a `nationId` whose
  `game.playerById(nationId)` is non-`null`, when the orchestrator
  reaches the trade-merge step, then it ignores
  `economyPlan.tradeOrders` and instead emits whatever
  `runTreasuryPlanner` returns when called with
  `currentOrders = ctx.orders` (the orders accumulated by every
  upstream domain planner in this pipeline).
- Given the orchestrator runs with
  `recomputeTradeOrdersWithPendingCosts: true`, the AI's build pass
  has already appended a `BuildUnitOrder` whose
  `buildTreasuryCost == C_b` for `nationId`, and
  `game.playerById(nationId).treasury == T`, when the orchestrator's
  trade recompute runs and emits a bid `b`, then
  `b.quantity × effectiveMarketPriceForCommodityId(b.commodityId)`
  plus the cumulative notional of every other recomputed bid plus
  `carryForwardBidNotionalByPlayer(...)` plus the same fixture's
  `pendingTreasuryCostsForTurn` (which now includes `C_b`) is less
  than or equal to `T`. The recompute therefore never authorises an
  AI bid the matcher (#3115) would have to truncate against the
  same `T`.

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

## Conservation bound on Path F (Refs #2924)

The lock-recovery liquidity work above (F10–F14) redistributes treasury between Great Powers; it cannot create net Great-Power treasury. Per [world-market-resolution.md](../program/world-market-resolution.md) § Treasury conservation invariant, phase 13 only ever holds the Great-Power treasury pool constant (GP↔GP trade) or reduces it (purchases from minor/tribe auto-offers leak to the treasury sink). The sum of all Great-Power treasuries is therefore **non-increasing** across the World Market phase.

Consequently, a structurally broke peer set (every Great Power below `cheapestRegimentBuildTreasuryCost()`) cannot trade its way above the regiment-build threshold *in aggregate*: the planner can shift which GP holds the limited pool, but the pool itself only grows from a net treasury source outside the market (NW riches conversion via colonial acquisition — "Path E"). Treasury-planner tuning alone cannot close #2924 for seed 42 when the aggregate pool is already below `players × cheapestRegimentBuildTreasuryCost()`; the diagnostic below records the chain links so a tuning slice can confirm whether the gap is liquidity (Path F, in scope here) or aggregate insufficiency (Path E, out of scope for this planner).

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

## Seed-42 Path F lock-recovery acceptance (Refs #2924)

The primary #2924 acceptance surface is the skipped integration regression
`packages/colonizethis_ai/test/seed42_observer_world_market_lock_recovery_regression_test.dart`
(~4 min, `dart test --run-skipped`). It exercises the same faithful Full-AI
handoff as `support/faithful_full_ai_test_handoff.dart` (every GP
`isHuman: false`, every GP AI-controlled) so diplomacy intervention does not
pause the 100-turn loop.

### Acceptance criteria (primary Path F — seed 42)

- Given seed 42 and the faithful Full-AI handoff, when the 100-turn campaign
  completes, then each of gp3, gp4, gp5, and gp6 falls below
  `cheapestRegimentBuildTreasuryCost()` after turn 1, receives strictly
  positive cumulative world-market seller credits, crosses back to treasury ≥
  `cheapestRegimentBuildTreasuryCost()` at least once, and emits at least one
  regiment `BuildUnitOrder` on a turn where pre-order treasury is already ≥
  the threshold — with **no** affordability bypass at the validator boundary.
- Given the same lock-recovery configuration but `treasury <
  cheapestRegimentBuildTreasuryCost()`, when `suggestBuildOrders` runs for
  regiments, then candidates remain empty (negative control — pinned in
  `packages/colonizethis_logic/test/orders/order_suggestion_build_lock_recovery_affordability_guard_test.dart`
  and `build_order_treasury_no_bypass_test.dart`).

Secondary Path E (NW `declareWar` emission under the treasury-recovery
override) is pinned separately in
`seed42_observer_nw_lock_recovery_declare_war_regression_test.dart` and the
unit tests in `phase-planner-architecture.md` § Path E.

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
