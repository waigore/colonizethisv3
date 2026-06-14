# Production Recipes

**SPEC/game** — Recipe structure and location. Cross-refs: [stockpiles-and-production.md](stockpiles-and-production.md), [economy-models.md](../program/economy-models.md), [order-projections.md](../program/order-projections.md). Commodities: [commodity-catalog.md](commodity-catalog.md). Labour: [workers-and-population.md](workers-and-population.md).

---

## Recipe Structure

Each **production recipe** has:

- **Output:** One commodity, quantity per run (e.g. 1).
- **Inputs:** Map of commodity id → quantity consumed per output unit.
- **Labour:** Labour points required per output unit (e.g. 2 timber → 1 lumber = 2 labour). Production consumes labour from the player's WorkerPool.
- **Turns per unit:** Optional; default 1 turn per output unit. **current product:** All recipes behave as 1 turn per output unit; multi-turn recipes (e.g. >1 turn per unit) are out of scope for current product and deferred.

Industry consumes inputs and labour from stockpile and WorkerPool; produces output into stockpile. When available inputs or labour do not allow all theoretically possible runs for a recipe, the System executes the recipe as many whole times as possible (maximum complete runs) and scales inputs and outputs accordingly; production-phase ordering and stockpile updates follow [stockpiles-and-production.md](stockpiles-and-production.md) and [economy-models.md](../program/economy-models.md).

---

## Recipe Catalog

The following recipes are defined for current product:

| Recipe | Output | Inputs | Labour |
|--------|--------|--------|--------|
| Lumber | lumber (1) | timber ×2 | 2 |
| Fabric (wool) | fabric (1) | wool ×2 | 2 |
| Fabric (cotton) | fabric (1) | cotton ×2 | 2 |
| Cast Iron | castIron (1) | timber ×2, iron ×2 | 5 |
| Refined Sugar | refinedSugar (1) | sugarCane ×2 | 2 |
| Cigars | cigars (1) | tobacco ×3 | 3 |
| Fur Hats | furHats (1) | furs ×2 | 2 |
| Steel | steel (1) | castIron ×2, coal ×1 | 5 |
| Paper | paper (1) | timber ×3 | 3 |
| Bronze | bronze (1) | copper ×1, tin ×1 | 3 |

---

## Technology-gated recipes

Most recipes are always available. A recipe MAY declare a **required technology id**; such a recipe is **available per player** only when that player has the technology in its `techUnlocked` set. Gating is per player and deterministic.

- **Fabric (cotton)** (`fabric_from_cotton`) requires `cotton_weaving` ([tech-tree-new-world.md](tech-tree-new-world.md)). Until the player researches `cotton_weaving`, that player cannot produce fabric from cotton.
- **Fabric (wool)** (`fabric_from_wool`) is **always available** (no technology gate).
- A recipe with no required technology id is always available to every player.

The gate is enforced wherever recipe availability is evaluated for a player: production assignment/feasibility, order projections and suggestions, and the AI economy planner's recipe candidate selection. A player that has not unlocked the required technology never has a tech-gated recipe assigned, suggested, or scored. The recipe definition stays in the program-level catalog; availability is computed from the player's `techUnlocked` set, not by removing the recipe from the catalog.

---

## Examples

- Timber ×2, Iron ×2 → Cast Iron (labour per unit from constants).
- Wool or Cotton ×2 → Fabric.
- Sugar Cane ×2 → Refined Sugar.

Worker tiers supply labour: Peasant 1, Apprentice 4, Journeyman 6, Master 8 per turn. One labour per resource input consumed.

---

## Where Stored

**Production recipes** are program-level constants defined in config (list or map of recipe definitions). Program-level config only; no JSON rulesets in current product.

---

## Scope (current product vs deferred)

- **current product:** One turn per output unit only; recipe config may omit turns-per-unit (default 1). Multi-turn recipes are not implemented and are **deferred**.

---

## Acceptance Criteria

Testable conditions for "done": recipe structure (output commodity + quantity, inputs map, labour per output, optional turns per unit default 1); recipes stored as program-level constants (no JSON rulesets in current product); Production phase consumes inputs and labour and adds output to stockpile; insufficient inputs or labour for even a single run → recipe does not run; if inputs or labour limit the number of runs, the System executes an integer number of complete runs (no fractional runs) bounded by available inputs and labour; recipe-run results recorded (e.g. productionByRecipe) for inspection and order projections. Implementation: [stockpiles-and-production.md](stockpiles-and-production.md), [economy-models.md](../program/economy-models.md), [order-projections.md](../program/order-projections.md).

- Given the program-level config defines a list or map of production recipes where each recipe has a non-empty output commodity id, a non-negative integer output quantity, a map of input commodity ids to non-negative integer quantities, a non-negative integer labour requirement, and optionally a positive integer turns per unit (default 1 when omitted)  
  When the System loads the economy configuration at game start  
  Then the System builds an in-memory recipe catalog that contains exactly those recipes, rejects any configuration that refers to an unknown commodity id in inputs or outputs with an error code such as `unknown_commodity_id_in_recipe`, and makes the loaded recipes available to the Production phase.

- Given a player has a central stockpile and WorkerPool state as described in [stockpiles-and-production.md](stockpiles-and-production.md) and [workers-and-population.md](workers-and-population.md), and there exists a recipe whose input commodity quantities and labour requirement are fully satisfied by the current stockpile and WorkerPool  
  When the System executes the Production phase for that player  
  Then the System may run that recipe one or more times, consuming the required inputs and labour per run, adding the specified output quantity per run to the stockpile, and never allowing any input commodity or labour count to drop below zero.

- Given a player has insufficient input commodities or insufficient available labour to satisfy the full input and labour requirements of a recipe for even a single run  
  When the System evaluates which recipes to execute during the Production phase  
  Then the System does not execute that recipe (i.e. it produces zero units of the recipe’s output for that phase) and does not partially consume inputs in a way that leaves the recipe half-complete.

- Given a player has a central stockpile and WorkerPool state as described in [stockpiles-and-production.md](stockpiles-and-production.md) and [workers-and-population.md](workers-and-population.md), and there exists a recipe where the current stockpile and WorkerPool allow at least one complete run but not an unbounded number of runs (because one or more required input commodities or available labour would reach zero)  
  When the System executes the Production phase for that player  
  Then the System computes the maximum integer number of complete runs that do not cause any required input commodity or labour count to drop below zero, runs the recipe exactly that many times, consumes the corresponding inputs and labour, and adds the corresponding total output quantity to the stockpile.

- Given the System has executed the Production phase for a player and at least one recipe ran  
  When the phase completes  
  Then the System records which recipes ran and the quantity produced per recipe (e.g. productionByRecipe: recipe id → quantity produced) so that order projections and inspection can use it; see [order-projections.md](../program/order-projections.md) (§ productionByRecipe) and [economy-models.md](../program/economy-models.md).

- Given a recipe declares no required technology id  
  When the System evaluates whether that recipe is available to any player  
  Then the System reports the recipe as available regardless of the player's `techUnlocked` set.

- Given the `fabric_from_cotton` recipe declares required technology id `cotton_weaving`, and a player whose `techUnlocked` set does not contain `cotton_weaving` mapped to `true`  
  When the System evaluates recipe availability for that player (production assignment, feasibility, order suggestion, or AI economy planning)  
  Then the System reports `fabric_from_cotton` as not available to that player while `fabric_from_wool` remains available.

- Given the `fabric_from_cotton` recipe declares required technology id `cotton_weaving`, and a player whose `techUnlocked` set maps `cotton_weaving` to `true`  
  When the System evaluates recipe availability for that player  
  Then the System reports `fabric_from_cotton` as available to that player.

- Given an AI-controlled player whose `techUnlocked` set does not contain `cotton_weaving` mapped to `true`  
  When the AI economy planner scores and allocates production recipes for that player  
  Then the AI economy planner does not score, assign labour to, or suggest `fabric_from_cotton`.
