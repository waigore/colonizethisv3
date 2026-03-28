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

- Workers consume food and luxuries from player stockpile during end-of-turn Consumption phase.
- **Starvation (per Imp2):** Food is deducted from transported amounts first, then from warehouse/stockpile. If a worker's required food cannot be met from either source, the worker **starves and is immediately removed** at end of that turn's Consumption phase. There is no grace period.
- Without luxury: trained worker produces no labour that turn (but is not removed).
- Production uses labour: one labour per resource input consumed by a recipe (e.g. 2 timber → 1 lumber = 2 labour).
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

**Current scope:** Food consumption and starvation are implemented in economy_consumption.dart (peasant 1 food, trained 2 food; starvation order: peasants first, then apprentices, journeymen, masters). Navy food: 2 units per ship per turn after land military, before workers. **Luxury consumption** is in scope: trained workers consume one unit of their tier luxury per turn (refinedSugar / cigars / furHats); shortage reduces that worker's labour contribution to zero for that turn (worker is not removed). Worker tier training (paper + cash → next tier) remains deferred until Recruiting/Training quantities are defined or a simplification is chosen.

---

## Luxury consumption (in scope)

- **Commodity per tier:** Apprentice → 1 refinedSugar; Journeyman → 1 cigars; Master → 1 furHats. Commodity ids per [commodity-catalog.md](commodity-catalog.md).
- **Deduction:** During the Consumption phase, the System deducts from the player stockpile up to one unit of the tier luxury per trained worker of that tier (e.g. 3 apprentices → deduct min(3, stockpile.refinedSugar)).
- **Order:** Luxury deduction happens after food deduction and starvation; order by tier is implementation-defined (e.g. apprentices, then journeymen, then masters).
- **Labour effect:** When computing available labour for the Production phase, a trained worker contributes labour only if that worker's tier luxury was available and deducted for them (or equivalently: effective labour = peasants×1 + min(apprentices, refinedSugar)×4 + min(journeymen, cigars)×6 + min(masters, furHats)×8). Workers without luxury remain in the WorkerPool and contribute zero labour that turn.

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
  Then the System deducts the required food quantities for each worker tier from the stockpile in the specified order, removes workers that starve when their required food cannot be met starting with Peasants and proceeding up through Apprentices, Journeymen, and Masters, and does not reduce any worker count below zero.

- Given a player has at least one trained worker (Apprentice, Journeyman, or Master) and a non-zero stockpile quantity of that tier's luxury commodity (refinedSugar, cigars, or furHats respectively)  
  When the System executes the Consumption phase for that player  
  Then the System deducts from the stockpile one unit of that luxury per trained worker of that tier, up to the available stockpile quantity (e.g. 2 apprentices and 1 refinedSugar → deduct 1 refinedSugar; 2 apprentices and 3 refinedSugar → deduct 2 refinedSugar), and does not deduct more than the number of workers in that tier or more than the stockpile quantity.

- Given a trained worker (Apprentice, Journeyman, or Master) remains alive after the Consumption phase but the required luxury commodity for that tier was not fully available in the stockpile (so fewer units were deducted than workers in that tier)  
  When the System computes available labour for the Production phase  
  Then the System counts that worker's labour contribution as zero for that turn while still leaving the worker in the WorkerPool for future turns (effective labour formula: peasants×1 + min(apprentices, refinedSugar_available_at_production)×4 + min(journeymen, cigars_available)×6 + min(masters, furHats_available)×8, where "available" is the stockpile quantity at the start of Production phase before luxury is deducted).

- Given a player has sufficient fabric (and, when defined, paper and cash) in the stockpile to recruit or train a worker according to the recruiting and training rules for a particular era  
  When the System resolves a recruit or train action for that worker  
  Then the System consumes the specified commodity quantities from the stockpile, updates the WorkerPool counts by adding the new or upgraded worker to the correct tier and removing the source worker in the case of training, and ensures that no stockpile quantity or worker count becomes negative as a result of the action.
