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

**Production recipes** live in **colonizethis_data** as program-level constants (list or map of recipe definitions). colonizethis_logic reads them at resolve time. Program-level config only; no JSON rulesets in MVP.
