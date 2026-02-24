# Production Recipes

**SPEC/game** — Recipe structure and location. Derived from GDD 04, TDD 04. Commodities: [commodity-catalog.md](commodity-catalog.md). Labour: [workers-and-population.md](workers-and-population.md).

---

## Recipe Structure

Each **production recipe** has:

- **Output:** One commodity, quantity per run (e.g. 1).
- **Inputs:** Map of commodity id → quantity consumed per output unit.
- **Labour:** Labour points required per output unit (e.g. 2 timber → 1 lumber = 2 labour). Production consumes labour from the player's WorkerPool.
- **Turns per unit:** Optional; default 1 turn per output unit.

Industry consumes inputs and labour from stockpile and WorkerPool; produces output into stockpile. Insufficient inputs or labour: recipe does not run (or partial run per design).

---

## Examples (GDD 04)

- Timber ×2, Iron ×2, Coal ×1 → Cast Iron (labour per unit from constants).
- Wool or Cotton ×2 → Fabric.
- Sugar Cane ×2 → Refined Sugar.

Worker tiers supply labour: Peasant 1, Apprentice 4, Journeyman 6, Master 8 per turn. One labour per resource input consumed.

---

## Where Stored

**Production recipes** are program-level constants defined in config (list or map of recipe definitions). Program-level config only; no JSON rulesets.

---

## Acceptance Criteria

- Given the program-level config defines a list or map of production recipes where each recipe has a non-empty output commodity id, a non-negative integer output quantity, a map of input commodity ids to non-negative integer quantities, and a non-negative integer labour requirement  
  When the System loads the economy configuration at game start  
  Then the System builds an in-memory recipe catalog that contains exactly those recipes, rejects any configuration that refers to an unknown commodity id in inputs or outputs with an error code such as `unknown_commodity_id_in_recipe`, and makes the loaded recipes available to the Production phase.

- Given a player has a central stockpile and WorkerPool state as described in [stockpiles-and-production.md](stockpiles-and-production.md) and [workers-and-population.md](workers-and-population.md), and there exists a recipe whose input commodity quantities and labour requirement are fully satisfied by the current stockpile and WorkerPool  
  When the System executes the Production phase for that player  
  Then the System may run that recipe one or more times, consuming the required inputs and labour per run, adding the specified output quantity per run to the stockpile, and never allowing any input commodity or labour count to drop below zero.

- Given a player has insufficient input commodities or insufficient available labour to satisfy the full input and labour requirements of a recipe for even a single run  
  When the System evaluates which recipes to execute during the Production phase  
  Then the System does not execute that recipe (i.e. it produces zero units of the recipe’s output for that phase) and does not partially consume inputs in a way that leaves the recipe half-complete.
