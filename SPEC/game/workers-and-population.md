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

---

## Relations

- **Player** → **WorkerPool** (or Population): per-player worker counts by tier.
- Workers consume from Player stockpile. Workers supply labour to production.

---

## Implementation

Data structures in [economy-models.md](../program/economy-models.md). Worker model distinct from Unit; workers live in economy (TDD 04), not unit model (TDD 05). Config is program-level (no JSON rulesets).

**Current scope:** Food and luxury consumption and strike rules are implemented in `economy_consumption.dart` and `worker_economy.dart` (peasant 1 food unit, trained 2 food units; grain then meat; worker food priority Masters→Peasants; `WorkerIdleCounts` / `ConsumptionResult.idleLabour`; `resolveProduction` takes post-consumption `idleLabour`). Worker tier training (paper + cash → next tier) remains deferred until Recruiting/Training quantities are defined or a simplification is chosen.

---

## Luxury consumption (in scope)

- **Commodity per tier:** Apprentice → 1 refinedSugar; Journeyman → 1 cigars; Master → 1 furHats. Commodity ids per [commodity-catalog.md](commodity-catalog.md).
- **Deduction:** After worker food allocation, the System deducts luxury only for workers who become **idle** (food-fed and assigned a unit). Count per tier = min(food-fed count for that tier, stockpile quantity). Food-unfed trained workers incur **no** luxury deduction.
- **Order:** Masters, then Journeymen, then Apprentices (each tier uses its own commodity).
- **Labour effect:** Effective labour for Production is derived from `WorkerIdleCounts` after Consumption (see Implementation). UI/AI preview uses `effectiveLabourForWorkers` / `previewWorkerIdleLabour` with the same rules, including military food first when regiment counts are provided.

---

## Acceptance Criteria

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
