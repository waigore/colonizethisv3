# Economy Planner (AI)

**SPEC/ai** — AI decisions for worker allocation (production) and cargo capacity. Source: GDD economy, [ai-architecture.md](ai-architecture.md). Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [production-recipes.md](../game/production-recipes.md), [workers-and-population.md](../game/workers-and-population.md). Cargo: [auto-transport.md](../program/auto-transport.md), [ships-and-naval.md](../game/ships-and-naval.md).

---

## Purpose

The economy planner chooses **production assignments** (which recipes receive how much labour) and a **cargo preference** (whether to favour more cargo capacity this turn). It runs once per AI-controlled Great Power per turn, before or as part of domain planning. Output feeds turn resolution (production phase) and optionally the naval planner (join home fleet vs missions).

---

## Inputs

- **PlayerView** — player's stockpile, WorkerPool, visibility; no hidden state.
- **Game** — for effective labour (stockpile at Production phase start: luxury caps labour per [workers-and-population.md](../game/workers-and-population.md)), recipe catalog, and (for cargo) home fleet and overseas extraction.
- **Personality / agenda** — economy domain weight, hidden agenda (e.g. warmonger → bias military inputs; industrial_trader → bias trade goods).
- **Seed** — per-turn economy sub-seed for deterministic tie-breaking and optional randomness.

All inputs are observable; no cheats.

---

## Outputs

1. **Production assignments** — `List<AssignedRecipe>` (recipe id, assigned labour). Total assigned labour must not exceed the player's **effective labour** (luxury-capped). Assignments are passed to the Production phase as that player's default assignments (see [turn-resolution-phases.md](../program/turn-resolution-phases.md)); resolver must support per-player assignments when multiple players are AI.
2. **Cargo preference** (optional) — one of: `none`, `prefer_cargo`, `strong_cargo`. Used by the naval planner to bias **join home fleet** vs patrol/blockade when a fleet is in the capital port; and by the **build planner** when choosing among build orders (ships vs regiments): it scores candidates and may prefer cargo-capable ships when `prefer_cargo` or `strong_cargo`.

---

## Worker allocation (production)

### Principles

- **Feasible only:** Only assign labour to recipes that can run at least one full run (inputs and labour sufficient per [production-recipes.md](../game/production-recipes.md)).
- **Effective labour cap:** Use effective labour computed from WorkerPool and stockpile at start of Production phase (peasants×1 + min(apprentices, refinedSugar)×4 + …). Do not assign more than this total across all recipes.
- **No fractional runs:** Assignments are integer labour per recipe; the Production phase computes runs per recipe and consumes inputs/labour.

### Scoring (utility)

Score each **feasible** recipe (can run ≥1 run with current stockpile and remaining labour). Use a small set of signals so the AI behaves sensibly without full optimization:

1. **Shortage** — Output commodity is in deficit or low (e.g. below a small target or below estimated consumption). Prefer producing what is needed.
2. **Chain value** — Output is an input to other recipes or to military/luxury (e.g. lumber, castIron for builds; refinedSugar/cigars/furHats for labour). Boosts score when that downstream use is relevant.
3. **Personality / agenda** — Economy domain weight and hidden agenda modifiers (e.g. warmonger: boost military inputs; industrial_trader: boost trade-good outputs; tech_thief: no direct production bias).
4. **Stability** — Slight preference for recipes that sustain current chains (e.g. luxury production when the player has trained workers) to avoid oscillation.

Scores are combined (e.g. weighted sum). Exact weights and thresholds are implementation-defined but must be deterministic given seed and config.

### Allocation algorithm

- **Option A (greedy):** Sort feasible recipes by score descending. For each recipe in order, assign as much labour as possible (capped by remaining effective labour and by inputs so that runs are integer); subtract used labour and update virtual stockpile for next recipe. Repeat until no labour or no feasible recipe.
- **Option B (proportional):** Allocate labour to recipes in proportion to score, then round down to integer labour per recipe and cap by feasible runs; sweep remaining labour with greedy.
- **Determinism:** Tie-breaking and order use the economy sub-seed. Same (game state, seed, config) → same assignments.

### Edge cases

- **No effective labour** → empty assignments.
- **No feasible recipe** (missing inputs for all) → empty assignments.
- **Luxury shortage** — Effective labour already reflects this; planner does not double-penalize.

---

## Cargo capacity preference

Cargo capacity is the sum of **cargoHold** over ships in the **home fleet** at the capital port ([ships-and-naval.md](../game/ships-and-naval.md), [auto-transport.md](../program/auto-transport.md)). It limits overseas extraction delivered to the stockpile and trade/export.

### When to prefer cargo

- **Overseas extraction** — Player has meaningful overseas extraction (e.g. New World) that exceeds or is close to current cargo capacity → prefer bringing ships home to increase capacity next turn.
- **Colonial expansion (Full AI)** — When `ColonialSummary` lists invadable or adjacent New World owners, effective economy weight receives `kColonialCargoPreferenceEconomyBoost` (and `kColonialCargoPreferenceNoNwColoniesBoost` when the GP owns zero NW provinces). See [ai-architecture.md](ai-architecture.md) § Colonial expansion.
- **EXPAND treasury recovery (Full AI)** — When `isBelowQuotaPeaceTreasuryRecovery` is true (below-quota peace insufficient regiments and effective treasury below cheapest regiment build), effective economy weight receives `kBelowQuotaPeaceTreasuryRecoveryCargoBoost` so cargo preference can rise during EXPAND to pull overseas riches for the next build pass. See [ai-architecture.md](ai-architecture.md) § Observer goal phases.
- **Economy goal / personality** — High economy domain weight or trade-oriented agenda → more likely to set `prefer_cargo` or `strong_cargo`.
- **No urgent naval need** — When not at war or not blockading, favouring cargo is safer.

### Output

- **none** — Naval planner ignores cargo; decide missions purely by military/exploration.
- **prefer_cargo** — If a sea-going fleet is in the capital port sea zone and there is no strong military reason to keep it at sea, consider **join home fleet** mission (increase cargo for next turn).
- **strong_cargo** — Same as prefer_cargo but stronger weight; build planner may prefer building merchant ships when evaluating build orders.

Naval planner and build planner consume this preference; the economy planner only outputs it. How exactly they weight join_home_fleet vs patrol/blockade is defined in the naval planner spec.

---

## Regiment build-input production priority (Refs #2847 H8)

Companion to [treasury-planner.md](treasury-planner.md) § Lock-recovery seller regiment build-input bootstrap. The treasury planner can emit a world-market **bid** for the cheapest regiment's missing `buildInputs`, but on seed 42 there is often **no matching offer supply** for `fabric`, so the bid does not fill. When the EXPAND economy directive `forceCheapestRegimentBuild` is active, the GP holds `player.treasury >= cheapestRegimentBuildTreasuryCost()`, owns **zero** regiments, and the projected stockpile is short at least one `peasant_levies` build-input commodity, the economy planner adds `kRegimentBuildInputProductionScoreBoost` (`50.0`) to every **feasible** recipe whose `outputCommodityId` supplies a missing input. The boost is planner-internal (not a new `ai_victory_config.dart` constant). Labour is still capped by effective labour and integer runs; no affordability rule is bypassed.

### Acceptance criteria (H8 production)

- Given an AI GP with positive effective labour, a feasible `fabric_from_wool` (or `fabric_from_cotton`) recipe, `regimentCountForPlayer == 0`, `player.treasury >= cheapestRegimentBuildTreasuryCost()`, zero `fabric` in the stockpile, and a dispatched `PhasePlanOutcome` whose `expandEconomyPlan.forceCheapestRegimentBuild == true`, when `runEconomyPlanner` runs, then at least one production assignment references a recipe whose `outputCommodityId` is `fabric`.
- Given the same inputs except `expandEconomyPlan.forceCheapestRegimentBuild == false`, when `runEconomyPlanner` runs with the same seed, then no assignment is required solely because of the H8 boost (the fabric recipe may still win from ordinary shortage scoring).
- Given `forceCheapestRegimentBuild == true` but `player.treasury < cheapestRegimentBuildTreasuryCost()`, when `runEconomyPlanner` runs, then the H8 production boost does not apply (negative control — treasury must be recovered first).

---

## Regiment build-input feedstock extraction priority (Refs #2847 H8-extraction)

Companion to § Regiment build-input production priority (Refs #2847 H8) and [treasury-planner.md](treasury-planner.md) § Lock-recovery seller regiment build-input bootstrap. The production boost only converts feedstock the GP **already holds**, and the world-market bid only fills when a seller offers the feedstock. On seed 42 the failing below-quota zero-NW Great Powers (`gp3` / `gp5` / `gp6`) hold **no** `wool` / `cotton` because their idle Builders are not routed to improve the feedstock resource tiles they own, so neither the domestic production path nor the market-supply path has any feedstock to work with (the residual disclosed in `treasury-planner.md` § Residual feedstock-acquisition dependency).

This slice routes the Full-AI civilian work selection (`selectFullAiCivilianWorkOrders`, `packages/colonizethis_logic/lib/src/ai/full_ai_civilian_work_selection.dart`) toward feedstock extraction. When the **same bootstrap gate** as the treasury build-input bootstrap holds for the player — a below-quota zero-NW lock-recovery seller (`oldWorldProvinceCountOwnedBy` in `[2, kObserverConquestMinOwProvincesPerGp)`, zero New World provinces), `player.treasury >= cheapestRegimentBuildTreasuryCost()` (recovered), and `regimentCountForPlayer == 0` — the build-improvement work score adds a planner-internal `kRegimentBuildInputFeedstockExtractionScoreBoost` (`600`) to every **unimproved** (`improvementLevel < 1`) resource tile whose resource id is a production-recipe feedstock of a missing `peasant_levies` build input (`wool` / `cotton` for `fabric`; tile resource ids equal commodity ids per `resource_extractor.dart` § `_resourceToCommodityId`).

The boost re-prioritises the Builder onto the feedstock tile ahead of other extractable improvements; it adds no new work order and does not bypass any suggestion or affordability gate (the tile must already be a `build_improvement` suggestion). The constant is planner-internal (not a new `ai_victory_config.dart` constant), mirroring the H8 production boost and the #2847 scope constraint. The gate is **self-clearing**: once the build input lands in the stockpile or the GP owns a regiment, the feedstock set is empty and selection reverts to its ordinary deterministic ordering. The feedstock-resource set is a pure function of `(game, playerId)` and the static `RegimentEconomyCatalog` / `ProductionRecipesCatalog`; identical inputs yield identical selections.

### Residual feedstock-tile dependency (disclosure)

The boost re-prioritises **existing** build-improvement suggestions; it does not acquire a feedstock resource tile for a seller that owns none. A failing GP whose Old World territory contains no `wool` / `cotton` resource tile still cannot source `fabric` domestically, and the turn-100 conquest gate stays open on that axis. Closing it (feedstock-tile acquisition or routing extraction onto purchasable land) is tracked as further #2847 work; this slice is the extraction-routing invariant that converts owned feedstock tiles into stockpiled feedstock once the bootstrap gate is active.

### Acceptance criteria (H8-extraction)

- Given a below-quota zero-NW lock-recovery seller (`oldWorldProvinceCountOwnedBy` in `[2, kObserverConquestMinOwProvincesPerGp)`, zero New World provinces) with `player.treasury >= cheapestRegimentBuildTreasuryCost()`, `regimentCountForPlayer == 0`, and zero `fabric` in the stockpile, when the feedstock-extraction gate is evaluated, then it returns the recipe feedstock ids `{wool, cotton}` (the inputs of every recipe whose output is the missing `peasant_levies` build input).
- Given an otherwise identical seller whose `player.treasury < cheapestRegimentBuildTreasuryCost()`, when the gate is evaluated, then it returns the empty set (negative control — treasury must be recovered first).
- Given an otherwise identical seller with `regimentCountForPlayer > 0` or that already holds the `fabric` build input, when the gate is evaluated, then it returns the empty set (the bootstrap targets the zero-regiment, missing-input rebuild gap only).
- Given an AI GP at or above the conquest quota (`oldWorldProvinceCountOwnedBy >= kObserverConquestMinOwProvincesPerGp`) or that owns at least one New World province, when the gate is evaluated, then it returns the empty set (the carve-out is scoped to below-quota zero-NW sellers).
- Given the gate is active and a Builder has both an unimproved `wool` resource tile and an unimproved non-feedstock (`grain`) resource tile as `build_improvement` suggestions, when `selectFullAiCivilianWorkOrders` runs, then it selects the `wool` tile; given the same fixture but the gate inactive (e.g. at quota), it selects by the ordinary build-improvement score ordering.
- Given identical inputs, when the feedstock-extraction gate and `selectFullAiCivilianWorkOrders` run twice, then both runs return identical results (determinism).

### Orchestrator civilian-work force-on (Refs #2847 H8-extraction wiring)

The feedstock-extraction score boost in `selectFullAiCivilianWorkOrders` has no effect when `_runEconomyDomainPlanners` (`packages/colonizethis_ai/lib/src/planning/domain_planner_orchestrator.dart`) skips the Full-AI civilian work pass because `domainWeights.economy < workThreshold` and `primaryGoal != StrategicGoal.expand`. Below-quota lock-recovery sellers in EXPAND often carry `StrategicGoal.conquer`, so the orchestrator forces `runFullAiCivilianWork` whenever `regimentBuildInputFeedstockExtractionResourceIds(game, nationId)` is non-empty — mirroring the DEVELOP / colonial-pressure / NW-owned force-on clauses already present in `_runEconomyDomainPlanners`. The orchestrator reuses the existing logic-side gate predicate unchanged (it only reads whether the feedstock set is non-empty); it adds no duplicate regiment-count logic and no new config constant.

#### Acceptance criteria (H8-extraction orchestrator wiring)

- Given a below-quota zero-NW lock-recovery seller with `primaryGoal == StrategicGoal.conquer`, `player.treasury >= cheapestRegimentBuildTreasuryCost()`, `regimentCountForPlayer == 0`, and a Builder offered both an unimproved `wool` feedstock tile and an unimproved `grain` tile as `build_improvement` suggestions, when the domain planners run via `runDomainPlannersWithOutcome`, then the work planner runs (`workPlannerRan == true`) and the single emitted `WorkOrder` targets the `wool` feedstock tile.
- Given an otherwise identical seller whose `player.treasury < cheapestRegimentBuildTreasuryCost()` so the feedstock-extraction gate is inactive, when the domain planners run via `runDomainPlannersWithOutcome`, then no feedstock score boost fires and the single emitted `WorkOrder` targets the `grain` tile under the ordinary build-improvement ordering (negative control).

---

## Integration

- **Caller:** Strategic AI (e.g. `generateStrategicOrders`) calls the economy planner for each AI GP first, then passes the resulting **economy plan** (including `cargoPreference`) into the domain planners so the build step can weight ship vs land builds. Production assignments are collected per player and passed to the turn resolver as **per-player default production assignments** (resolver must accept `Map<String, List<AssignedRecipe>>` or equivalent for multi-player).
- **Human players:** Production assignments for human players come from UI or saved choices; the economy planner is not used.
- **Determinism:** Same PlayerView, game state, config, and economy seed → same production assignments and cargo preference.

---

## Acceptance criteria

- Given an AI-controlled player with positive effective labour and at least one recipe feasible (inputs and labour sufficient for ≥1 run), when the economy planner runs with a fixed seed, then it returns a non-empty list of production assignments whose total assigned labour does not exceed effective labour, and each assignment references a known recipe id and non-negative labour.
- Given an AI-controlled player with zero effective labour or no feasible recipe, when the economy planner runs, then it returns an empty list of production assignments.
- Given the same game state, player, config, and economy sub-seed, when the economy planner runs twice, then it returns the same production assignments and the same cargo preference.
- Given the economy planner outputs `prefer_cargo` or `strong_cargo`, when the naval planner runs, then it may use that preference to favour a join home fleet mission for a fleet in the capital port sea zone when military need is low; exact weighting is defined in the naval planner.

---

## Recruitment planner

The recruitment planner unifies worker recruit / train, regiment build, and ship build decisions for one AI-controlled Great Power per turn. It enforces peasant reservation across all peasant-consuming candidates and the luxury soft cap for trained tiers per [workers-and-population.md](../game/workers-and-population.md). Refs #2692 S8.

### Interface (stable contract)

```dart
RecruitmentPlan runRecruitmentPlanner({
  required Game game,
  required PlayerView view,
  required Orders currentOrders,
  required AIConfig config,
  required AISeedBundle seeds,
  required ObserverGoalPhase goalPhase,
  required OrderSuggestionAPI suggestionApi,
  EconomyPlan? economyPlanHint,
});

class RecruitmentPlan {
  final List<RecruitWorkerOrder> recruitOrders;
  final List<BuildUnitOrder> buildUnitOrders;
  final List<RejectedRecruitmentSuggestion> rejected;
}

class RejectedRecruitmentSuggestion {
  /// One of: `Insufficient workers`, `Soft luxury cap exceeded`.
  final String reason;
  /// `WorkerTier.name` for recruit candidates; `BuildUnitOrder.unitType` for builds.
  final String targetTier;
}
```

The signature is **stable across #2509 orchestrator changes**: phase planners (`expand_phase_planner`, `colonial_phase_planner`, `develop_phase_planner`) are the only callers and pass their resolved `ObserverGoalPhase` directly. Algorithm internals may evolve; the public surface above must not.

### Inputs

- `suggestionApi` — emitted orders MUST come from `suggestionApi.suggestRecruitWorkerOrders(...)` and `suggestionApi.suggestBuildOrders(...)`. The planner does not re-validate; it filters the pre-validated candidates by planner-side rules.
- `currentOrders` — same `Orders` passed to the suggestion API. Pending recruit / military / naval build orders are counted toward the peasant reservation ledger.
- `goalPhase` — observer-derived phase (`expand`, `colonialLite`, `colonial`, `develop`) selects the emit-order weighting (military builds first in EXPAND / COLONIAL-lite / COLONIAL; recruit / train first in DEVELOP).
- `economyPlanHint` (optional) — last-turn or projected `EconomyPlan` for the same player. When provided, the planner adds the projected luxury-commodity output (refinedSugar / cigars / furHats) from `productionAssignments` to the sustainable-trained-count denominator.

### Rules

- **Peasant reservation.** Let
  - `pendingConsumes = (recruit orders in currentOrders that consume a peasant) + (military and naval builds in currentOrders)`
  - `availablePeasants = view.player.workerPool.peasants − pendingConsumes − sum(this plan's accepted peasant-consuming emissions)`.

  Civilian builds do not consume peasants. Any candidate that would push `availablePeasants` below `0` is dropped into `rejected` with reason `Insufficient workers` and is **not** emitted in `recruitOrders` / `buildUnitOrders`.

- **Soft luxury cap (Requirement #10).** For each trained tier T ∈ {apprentice, journeyman, master}:
  - `sustainableTrainedCount[T] = stockpile[T-luxury] + projectedOutputThisTurn[T-luxury]` where luxury commodity ids are apprentice → `refinedSugar`, journeyman → `cigars`, master → `furHats`. `projectedOutputThisTurn` is read from `economyPlanHint.productionAssignments` (per-recipe `assignedLabour` → integer runs of the recipe that produces the luxury) when `economyPlanHint` is non-null; otherwise it is `0`.
  - `deficit = effectiveLabour < targetRecipesLabour × 0.8` where `effectiveLabour = effectiveLabourForWorkers(...)` (current `WorkerPool` + `Stockpile`) and `targetRecipesLabour = sum(assignedLabour) over economyPlanHint.productionAssignments` (or `0` when the hint is null).
  - `projectedTrainedCount[T] = view.player.workerPool.tierCount(T) + emittedSoFar[T]`.
  - When `deficit == false`, reject any candidate that would push `projectedTrainedCount[T] > sustainableTrainedCount[T]`.
  - When `deficit == true`, reject only when `projectedTrainedCount[T] > 1.2 × sustainableTrainedCount[T]` (integer multiplication after rounding `floor`). Above the `1.2 ×` cap, the planner MUST NOT emit further recruit or train orders for that tier this turn (Requirement #10).

  Rejected candidates appear in `rejected` with reason `Soft luxury cap exceeded`. Peasant recruit candidates are not gated by the soft cap.

- **Emit order.** For `goalPhase == develop`, recruit / train candidates are processed before build candidates so trained-tier recruiting wins the peasant budget. For `goalPhase ∈ {expand, colonialLite, colonial}`, build candidates are processed before recruit candidates so military / naval rebuilds win the peasant budget. Within each step, candidates are iterated in the order returned by the suggestion API (deterministic per `SPEC/program/order-suggestions.md` § Rules).

- **Determinism.** Same `(game, view, currentOrders, config, seeds, goalPhase, suggestionApi candidate outputs, economyPlanHint)` MUST produce the same `RecruitmentPlan` (same `recruitOrders`, `buildUnitOrders`, and `rejected` lists in the same order).

- **Suggestion API integration.** Emitted orders MUST be drawn from the suggestion API outputs. The planner MUST NOT manufacture a `RecruitWorkerOrder` or `BuildUnitOrder` that did not come from `suggestionApi.suggestRecruitWorkerOrders(...)` / `suggestionApi.suggestBuildOrders(...)` for the same `(view, game, topology, currentOrders)`.

### Acceptance criteria

- **AC-RP-1 (Peasant reservation).** Given an AI-controlled Great Power player whose `workerPool.peasants == P` and `currentOrders` already consume `C` peasants (recruit train rows + military / naval builds) such that `P − C == 0`, when the recruitment planner runs with a suggestion API that returns one peasant-consuming recruit candidate and one regiment build candidate, then the resulting `RecruitmentPlan.recruitOrders` and `RecruitmentPlan.buildUnitOrders` contain no peasant-consuming entries and both candidates appear in `RecruitmentPlan.rejected` with reason `Insufficient workers`.

- **AC-RP-2 (Soft cap below sustainable).** Given an AI-controlled Great Power player with `effectiveLabour ≥ targetRecipesLabour × 0.8` (no deficit), `workerPool.apprentices == 0`, and `sustainableTrainedCount[apprentice] == 0`, when the recruitment planner runs with a suggestion API that returns an `apprentice` recruit candidate, then `recruitOrders` contains no apprentice entry and the candidate appears in `rejected` with reason `Soft luxury cap exceeded`.

- **AC-RP-3 (Soft cap deficit override).** Given an AI-controlled Great Power player with `effectiveLabour < targetRecipesLabour × 0.8` (deficit), `workerPool.journeymen == 1`, `sustainableTrainedCount[journeyman] == 1` (so `1.2 × 1 == 1` floor), and a `journeyman` recruit candidate from the suggestion API, then `recruitOrders` contains no journeyman entry (the deficit allows projected `2 > 1` cap of `1`, then rounds to `1`) and the candidate appears in `rejected` with reason `Soft luxury cap exceeded`.

- **AC-RP-4 (Deterministic).** Given identical `(game, view, currentOrders, config, seeds, goalPhase, suggestionApi candidate outputs, economyPlanHint)`, when the recruitment planner runs twice, then both returned `RecruitmentPlan` instances have identical `recruitOrders`, `buildUnitOrders`, and `rejected` lists in the same order.

- **AC-RP-5 (Emit order by phase).** Given an AI-controlled Great Power player with `workerPool.peasants == 1`, no `currentOrders` peasant consumes, a suggestion API that returns one peasant-consuming recruit candidate (`apprentice`) and one military build candidate within budget, when `goalPhase == ObserverGoalPhase.develop`, then `recruitOrders` contains the apprentice entry and `buildUnitOrders` is empty; when `goalPhase == ObserverGoalPhase.expand`, then `buildUnitOrders` contains the military entry and `recruitOrders` is empty.

## Interactions

- [ai-architecture.md](ai-architecture.md) — turn pipeline, domain planning
- [ai-personalities.md](ai-personalities.md) — economy domain weight
- [hidden-agendas.md](hidden-agendas.md) — agenda modifiers for production/cargo
- [ai-systems-impl.md](../program/ai-systems-impl.md) — module boundaries, who calls the planner
- [ai-planner.md](../program/ai-planner.md) — seeding, control rules
- [turn-resolution-phases.md](../program/turn-resolution-phases.md) — Production phase, per-player assignments
- [order-suggestions.md](../program/order-suggestions.md) — `suggestRecruitWorkerOrders` and `suggestBuildOrders` (recruitment planner inputs)
- [workers-and-population.md](../game/workers-and-population.md) — recruit / train cost table, peasant reservation, tech gates
