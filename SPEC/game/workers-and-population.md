# Workers and Population

**SPEC/game** — Industrial labour model, distinct from civilian units. Derived from GDD 04, TDD 04. Reference: Imperialism II 02-economy (GDD).

---

## Workers as Separate Population Model

**Workers are a separate population model** — they are not map units. Civilian units (Explorer, Builder, Engineer, etc.) deploy, move, and work on terrain; workers are industrial labour in the capital, assigned to production, and never appear on the map.

Per Imperialism II 02-economy: workers "in your city" supply labour for industry. They consume food and luxuries directly from the player's stockpile.

---

## Worker Tiers

| Tier | Labour/turn | Food | Luxury (trained only) |
|------|-------------|------|------------------------|
| **Peasant** | 1 | 1 grain or meat | None |
| **Apprentice** | 4 | 1 grain + 1 meat | Refined sugar |
| **Journeyman** | 6 | 1 grain + 1 meat | Cigars |
| **Master** | 8 | 1 grain + 1 meat | Fur hats |

---

## Recruiting and Training

- **Recruiting:** fabric → new Peasant. Adds to worker pool. **CLARIFICATION NEEDED:** How much fabric per Peasant? Need Imperialism II reference.
- **Training:** worker + paper + cash → next tier. Worker is out of pool that turn. Requires tech per tier. **CLARIFICATION NEEDED:** What quantities of paper and cash? Need Imperialism II reference.
- **Military/naval construction:** regiments and ships consume a worker when built.

---

## Consumption and Production

- **Phase order:** Consumption runs **before** Production in turn resolution (after Extraction and Riches-to-treasury). Production uses the stockpile **after** food and luxury deductions, and labour from **idle** workers only (see below).
- Workers consume food and luxuries from the player stockpile during the Consumption phase (implementation: central stockpile; transported-then-warehouse ordering is not modelled separately).
- **Food strike:** If a worker’s required food cannot be met, that worker **stays in the WorkerPool** but is **on strike** for labour that turn (no partial labour for a shortfall). There is no grace period and **no removal** from the pool for missing food.
- **Worker food priority (high to low):** Masters → Journeymen → Apprentices → Peasants. Within a tier, workers are fed in full units only: as many as possible receive a full ration; the rest are on strike for food.
- **Luxury strike:** A trained worker who did **not** receive food consumes **no** luxury that turn. Among food-fed trained workers, luxury is assigned and deducted **all-or-nothing** per worker (up to one unit per worker per tier, capped by stockpile). Workers who are food-fed but do not receive a luxury unit are **on strike** for labour (same as food strike for productivity).
- **Idle (labour):** A worker who is food-fed and, if trained, received their tier luxury assignment for that turn. Only idle workers count toward **available labour** for Production.
- Production uses labour: one labour per resource input consumed by a recipe (e.g. 2 timber → 1 lumber = 2 labour).
- **Military/naval build costs** that consume a peasant from the pool use **headcount**, not idle labour (food strikers remain draftable).
- Total food demand = workers + navy + army.
- **Navy food:** Each ship in the player's fleets consumes **2 food units** per turn (same grain/meat abstraction as military upkeep; see [ships-and-naval.md](ships-and-naval.md) § Ship food upkeep). Deduction order for the Consumption phase: **land military regiments first**, then **navy (all owned ships in all fleets)**, then **workers** (with worker starvation and luxury deduction unchanged). Any `ship_type_id` present in fleet state that is **not** in `ShipEconomyCatalog` is invalid data: the System **must fail** turn resolution (session error) rather than ignore or silently skip.
- **Naval combat:** Navy feeding shortfall uses the **same morale multipliers** as land military feeding shortfall for that player (see [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Consumption): effective naval strength in sea battles is scaled by that multiplier derived from `fullyFedShips / totalShips` for the turn.

---

## Relations

- **Player** → **WorkerPool** (or Population): per-player worker counts by tier.
- Workers consume from Player stockpile. Workers supply labour to production.

---

## Implementation

Data structures in [economy-models.md](../program/economy-models.md). Worker model distinct from Unit; workers live in economy (TDD 04), not unit model (TDD 05). Config is program-level (no JSON rulesets).

**Current scope:** Food and luxury consumption, land military and navy upkeep order, and worker **strike** rules (no removal for missing food) are implemented in `economy_consumption.dart` and `worker_economy.dart` (peasant 1 food unit, trained 2 food units; grain then meat; order land military → navy → workers; worker food priority Masters→Peasants; `WorkerIdleCounts` / `ConsumptionResult.idleLabour`; `resolveProduction` takes post-consumption `idleLabour`). Navy: 2 food units per ship per turn from catalog after land military, before workers. **Luxury consumption:** trained workers deduct tier luxury only when food-fed and assigned a unit; shortage of luxury zeros labour for that tier for that turn. Worker tier training (paper + cash → next tier) remains deferred until Recruiting/Training quantities are defined or a simplification is chosen.

---

## Luxury consumption (in scope)

- **Commodity per tier:** Apprentice → 1 refinedSugar; Journeyman → 1 cigars; Master → 1 furHats. Commodity ids per [commodity-catalog.md](commodity-catalog.md).
- **Deduction:** After worker food allocation, the System deducts luxury only for workers who become **idle** (food-fed and assigned a unit). Count per tier = min(food-fed count for that tier, stockpile quantity). Food-unfed trained workers incur **no** luxury deduction.
- **Order:** Masters, then Journeymen, then Apprentices (each tier uses its own commodity).
- **Labour effect:** Effective labour for Production is derived from `WorkerIdleCounts` after Consumption (see Implementation). UI/AI preview uses `effectiveLabourForWorkers` / `previewWorkerIdleLabour` with the same rules, including land military and navy food first when regiment and ship counts are provided.

---

## Acceptance Criteria

- Given a player owns one or more fleets whose `shipTypeIds` entries are all present in `ShipEconomyCatalog` and the player has a non-negative integer quantity of grain and meat in the central stockpile  
  When the System executes the Consumption phase for that player after land military upkeep  
  Then the System deducts **2 food units per ship** (from grain and meat per the same rules as military upkeep) for every ship in those fleets before deducting worker food, and does not reduce any stockpile commodity quantity below zero except by those deductions.

- Given a player's fleet lists a `ship_type_id` that is not a key in `ShipEconomyCatalog`  
  When the System executes the Consumption phase for that player  
  Then the System fails turn resolution with an error (invalid fleet data).

- Given a player has a WorkerPool with non-negative integer counts for each worker tier and a central stockpile as described in [stockpiles-and-production.md](stockpiles-and-production.md)  
  When the System executes the Consumption phase for that player  
  Then the System deducts food from the stockpile for military upkeep first (when applicable), then allocates worker food in priority order **Masters, Journeymen, Apprentices, Peasants**, assigns full rations only (no fractional workers fed), leaves all worker headcounts unchanged, and records **idle** vs **on strike** for labour per the food and luxury rules above.

- Given a player has at least one food-fed trained worker in a tier and a non-negative stockpile quantity of that tier's luxury commodity (refinedSugar, cigars, or furHats respectively)  
  When the System executes the Consumption phase for that player  
  Then the System deducts up to one unit of that luxury per food-fed worker of that tier, not exceeding the food-fed count or the stockpile quantity (e.g. 2 food-fed apprentices and 1 refinedSugar → deduct 1 refinedSugar), and deducts **no** luxury for workers who were not food-fed.

- Given a worker remains in the WorkerPool after Consumption but is **on strike** (insufficient food for a full ration for that worker, or for trained tiers insufficient luxury assignment after food)  
  When the System executes the Production phase for that player  
  Then the System counts that worker's labour contribution as **zero** for that turn while the WorkerPool headcount is unchanged, and Production uses the post-Consumption stockpile and **WorkerIdleCounts** (or equivalent) for the labour budget.

- Given a player has sufficient fabric (and, when defined, paper and cash) in the stockpile to recruit or train a worker according to the recruiting and training rules for a particular era  
  When the System resolves a recruit or train action for that worker  
  Then the System consumes the specified commodity quantities from the stockpile, updates the WorkerPool counts by adding the new or upgraded worker to the correct tier and removing the source worker in the case of training, and ensures that no stockpile quantity or worker count becomes negative as a result of the action.
