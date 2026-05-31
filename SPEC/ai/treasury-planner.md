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

## Out of scope for this SPEC slice

The following are tracked under the remaining `#2994` subtasks and are not specified here:

- `TreasuryPlanner` module: treasury inflow/outflow forecasting (F1), sell-surplus heuristic (F2), buy-deficit heuristic (F3), priority ordering (F4), integration into `runEconomyPlanner()` (F5).
- Partial-fill-aware forecasting using previous-turn `MarketActivity` (F8).
- Observer-game seed-42 trade-behaviour verification and budget profiling (F9 / F10).
- Wiring `StrategicGoal.trade` selection through the domain orchestrator into actual emitted trade orders (F7); this slice changes only the goal score, not the downstream dispatch.

---

## Interactions

- [economy-planner.md](economy-planner.md) — production assignments and cargo preference (TreasuryPlanner sub-planner integration point in F5).
- [ai-architecture.md](ai-architecture.md) — turn pipeline, domain planning, `selectPrimaryGoal`.
- [ai-personalities.md](ai-personalities.md) — base `trade` goal weights per leader.
- [phase-planner-architecture.md](phase-planner-architecture.md) — observer-goal phase resolution that feeds `evaluateStrategicGoalScores`.
- [order-suggestions.md](../program/order-suggestions.md) — trade-order suggestion API (consumed by future F-slices).
- [world-market-resolution.md](../program/world-market-resolution.md) — market matching, pricing, and `MarketActivity` outputs (consumed by future F8).
