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

## Interactions

- [ai-architecture.md](ai-architecture.md) — turn pipeline, domain planning
- [ai-personalities.md](ai-personalities.md) — economy domain weight
- [hidden-agendas.md](hidden-agendas.md) — agenda modifiers for production/cargo
- [ai-systems-impl.md](../program/ai-systems-impl.md) — module boundaries, who calls the planner
- [ai-planner.md](../program/ai-planner.md) — seeding, control rules
- [turn-resolution-phases.md](../program/turn-resolution-phases.md) — Production phase, per-player assignments
