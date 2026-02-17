# Turn Resolution Phases

**SPEC/program** — Phase sequence and per-phase behaviour. Overview: [turn-resolution.md](turn-resolution.md). Factions: [factions.md](../game/factions.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** (gather / validate; orders are already submitted with WorldState). **Orders are submitted by Great Powers only;** Minor Nations and Tribes do not submit orders.
2. **Extraction** — Tile yields to stockpile.
3. **Riches to treasury** — Riches in stockpile convert to treasury at base price and are removed from stockpile.
4. **Production** — Recipes and labour; outputs to stockpile.
5. **Consumption** — Military regiments consume food upkeep from stockpile **first**, then workers and navy consume food and luxuries from the remaining stockpile.
6. **Movement** — Apply move orders; update unit locations.
7. **Combat** — Resolve battles in provinces with opposing units; apply casualties and province flips (in scope from Phase 3).
8. **Build / work** — Apply build-unit orders (deduct cost, add unit); apply work orders (stub or one improvement type).
9. **End-of-turn** — Advance turn number; optionally reset unit status (e.g. movement points).

Exact ordering of build vs movement is implementation-defined as long as extraction → riches to treasury → production → consumption run before movement and build.

---

## Per-Phase Behaviour

- **Extraction:** (1) **Connectivity:** Recompute per-player connectivity (connectivity resolver; see [extraction-pipeline.md](extraction-pipeline.md)). (2) **Extract:** For each player, compute per-tile effective extraction (min(improvement, tech cap), then min(..., transport level)); sum by commodity; separate same-region vs overseas. (3) **Land:** Add same-region totals to each player's stockpile. (4) **Sea:** Allocate overseas totals to stockpile by priority, capped by cargo holds (stub); add allocated amounts to stockpile. Reference: [capital-and-connectivity.md](../game/capital-and-connectivity.md), [extraction-pipeline.md](extraction-pipeline.md).
- **Riches to treasury:** For each player, for each riches commodity (gold, silver, gems, diamonds, spices) in the stockpile, add quantity × basePrice to the player's treasury; then remove that quantity from the stockpile (riches convert to cash and are consumed). Base prices: spices = 50; others derived from relative scarcity (spawn weights) so scarcer riches have higher base price. Reference: Imperialism II 02-economy, GDD 04.
- **Production:** For each recipe (or per-player production choices), consume inputs and labour from stockpile and WorkerPool; add outputs to stockpile. Insufficient input: skip or partial per spec.
- **Consumption:** Military regiments consume food upkeep **before** workers and navy. Per player:
  - Compute total regiment food demand from the regiment economy config (sum over regiments of `foodUpkeepPerRegiment`).
  - Consume food from stockpile up to this demand (military-first feeding).
  - Derive a **feeding coverage** ratio (`fedRegiments / totalRegiments`) and pass it forward as a morale/strength modifier into the Combat phase (e.g. coverage ≥ 1.0 → 1.0; 0.5–<1.0 → 0.75; <0.5 → 0.5).
  - With remaining food and luxuries, workers consume per [workers-and-population.md](../game/workers-and-population.md); starvation removes workers as specified. Upkeep shortfall for military affects morale/strength, not unit count, in Phase 2.
- **Movement:** Apply validated MoveOrders; set unit location to destination province.
- **Combat:** (1) **Minor military parity step:** compute `maxGreatPowerMilitaryLevel` and set each Minor Nation / Tribe’s `effectiveMilitaryLevel` accordingly (see [factions.md](../game/factions.md)). (2) Run **conflict detection** (after movement: for each province, group units by faction; if two or more factions have units in the same province, build a BattleContext with one defender and one or more attacking sides). (3) For each BattleContext, run the **combat resolver chain**; collect casualties and final province owners. (4) **Apply:** remove casualty units from WorldState; set `province.ownerId` for conquered provinces (defender eliminated). Reference: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md).
- **Build / work:** Apply BuildUnitOrder (cost, worker for military, add unit); apply WorkOrder (status or one improvement).
- **End-of-turn:** Increment WorldState turn number; clear or carry over orders as designed.

When combat is in scope, the **minor military parity** step is always executed at the **start of the Combat phase** (before conflict detection). The combat resolver uses the resulting `effectiveMilitaryLevel` for Minor Nation and Tribe defenders.

**Diplomacy (when in scope):** Resolve overtures and Join Empire with Minor Nations and Tribes as targets. Combat is in scope from Phase 3; diplomacy from Phase 4.
