# Turn Resolution Phases

**SPEC/program** — Phase sequence and per-phase behaviour. Overview: [turn-resolution.md](turn-resolution.md). Factions: [factions.md](../game/factions.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** (gather / validate; orders are already submitted with WorldState). **Orders are submitted by Great Powers only;** Minor Nations and Tribes do not submit orders. Per-player lists from the order engine are merged (human + AI) and cross-player effects resolved before application.
2. **Diplomacy** (when in scope, Phase 4+) — Runs **before** Movement so declarations and peace take effect for the same turn. Steps: overture payments, advance overtures, Join Empire/Colony resolution, alliance proposals/responses, Declare War, Peace, relation modifiers, score updates. See [diplomacy-resolution.md](diplomacy-resolution.md).
3. **Extraction** — Tile yields to stockpile.
4. **Riches to treasury** — Riches in stockpile convert to treasury at base price and are removed from stockpile.
5. **Production** — Recipes and labour; outputs to stockpile.
6. **Consumption** — Military regiments consume food upkeep from stockpile **first**, then workers and navy consume food and luxuries from the remaining stockpile.
7. **Research** (Phase 5+) — For each GP: read research orders (slot → techId, funding per slot); validate treasury and prerequisites; deduct research spending from treasury; add progress per slot; complete techs (progress ≥ cost → techUnlocked, clear slot, update derived state). See [research-resolution.md](research-resolution.md).
8. **Movement** — Apply land MoveOrders; apply naval MoveOrders and mission assignments (ship reveal on fleet enter sea zone per [naval-movement-resolution.md](naval-movement-resolution.md)); update unit/fleet locations.
9. **Naval Interception & Naval Combat** (Phase 6+) — Resolve patrol/blockade/beachhead interceptions and sea battles per [naval-movement-resolution.md](naval-movement-resolution.md) and [naval-combat-resolution.md](naval-combat-resolution.md); update fleet compositions and locations.
10. **Combat** — Resolve land battles in provinces with opposing units; apply casualties and province flips (in scope from Phase 3).
11. **Build / work** — Apply build-unit orders (deduct cost, add unit); apply work orders (explore progress, prospect, civilian development such as improvements, roads, ports, forts, rails). See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) and [development-resolution.md](development-resolution.md).
12. **End-of-turn** — Fog decay (other-faction provinces with no Explorer/Spy → fogged); advance turn number; optionally reset unit status.

Exact ordering of build vs movement is implementation-defined as long as extraction → riches to treasury → production → consumption run before movement and build. Research runs after consumption so that treasury is current; research cost is committed from the player’s treasury for that turn (validated before/during resolution).

---

## Per-Phase Behaviour

- **Extraction:** (1) **Connectivity:** Recompute per-player connectivity (connectivity resolver; see [extraction-pipeline.md](extraction-pipeline.md)). (2) **Extract:** For each player, compute per-tile effective extraction (min(improvement, tech cap), then min(..., transport level)); for minerals (iron, copper, tin, coal, silver, gold, gems, diamonds), only from prospected tiles per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); sum by commodity; separate same-region vs overseas. (3) **Land:** Add same-region totals to each player's stockpile. (4) **Sea:** Allocate overseas totals to stockpile by priority, capped by cargo holds (stub); add allocated amounts to stockpile. Reference: [capital-and-connectivity.md](../game/capital-and-connectivity.md), [extraction-pipeline.md](extraction-pipeline.md).
- **Riches to treasury:** For each player, for each riches commodity (gold, silver, gems, diamonds, spices) in the stockpile, add quantity × basePrice to the player's treasury; then remove that quantity from the stockpile (riches convert to cash and are consumed). Base prices: spices = 50; others derived from relative scarcity (spawn weights) so scarcer riches have higher base price. Reference: Imperialism II 02-economy, GDD 04.
- **Production:** For each recipe (or per-player production choices), consume inputs and labour from stockpile and WorkerPool; add outputs to stockpile. Insufficient input: skip or partial per spec.
- **Consumption:** Military regiments consume food upkeep **before** workers and navy. Per player:
  - Compute total regiment food demand from the regiment economy config (sum over regiments of `foodUpkeepPerRegiment`).
  - Consume food from stockpile up to this demand (military-first feeding).
  - Derive a **feeding coverage** ratio (`fedRegiments / totalRegiments`) and pass it forward as a morale/strength modifier into the Combat phase (e.g. coverage ≥ 1.0 → 1.0; 0.5–<1.0 → 0.75; <0.5 → 0.5).
  - With remaining food and luxuries, workers consume per [workers-and-population.md](../game/workers-and-population.md); starvation removes workers as specified. Upkeep shortfall for military affects morale/strength, not unit count, in Phase 2.
- **Research:** (1) For each GP, read research orders (slot → techId, funding per slot). (2) Validate treasury can cover total research commitment; reject or reduce per [research-resolution.md](research-resolution.md). (3) Deduct research spending from treasury. (4) Add progress per slot (funding → points per GDD). (5) For each tech where progress ≥ cost: mark tech researched, update techUnlocked and derived state (extraction cap, military level), clear that slot’s progress. (6) A tech is only assignable if all prerequisites are in techUnlocked.
- **Diplomacy:** See [diplomacy-resolution.md](diplomacy-resolution.md) for step-by-step resolution (overture payments, Join Empire/Colony, alliances, war/peace, relation updates). Phase runs before Movement so war/peace state is current for movement and combat.
- **Movement:** Apply validated land MoveOrders; apply naval MoveOrders and mission assignments (update fleet location, ship reveal on fleet enter sea zone per [naval-movement-resolution.md](naval-movement-resolution.md)); set unit/fleet location and active missions.
- **Naval Interception & Naval Combat (Phase 6+):** (1) Using fleet locations and missions, resolve patrol and blockade interceptions, trade/transport raids, and conflicts between hostile fleets in the same sea zone per [naval-movement-resolution.md](naval-movement-resolution.md). (2) For each contested sea zone, build a BattleContextSea and resolve sea battles per [naval-combat-resolution.md](naval-combat-resolution.md); update fleet compositions and locations. (3) Ensure beachhead fleets are resolved here before any associated land invasions are processed.
- **Combat:** (1) **Minor military parity step:** compute `maxGreatPowerMilitaryLevel` and set each Minor Nation / Tribe’s `effectiveMilitaryLevel` accordingly (see [factions.md](../game/factions.md)). (2) Run **conflict detection** on provinces (after Movement and Naval Combat): for each province, group units by faction; if two or more factions have units in the same province, build a BattleContext with one defender and one or more attacking sides. (3) For each BattleContext, run the **combat resolver chain**; collect casualties and final province owners. (4) **Apply:** remove casualty units from WorldState; set `province.ownerId` for conquered provinces (defender eliminated). Reference: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md).
- **Build / work:** Apply BuildUnitOrder (cost, worker for military, add unit); apply WorkOrder:
  - Exploration/prospecting progress per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
  - Civilian development (Builder improvements and town upgrades; Engineer roads, ports, forts; Rail Builder railroads) per [development-resolution.md](development-resolution.md), with multi-turn work progress and completion effects.
- The same TurnResolver, including this Build/Work behaviour, is used both in the main game and in `ctdev`'s `sim_game` feature so that simulations and normal turns share identical development and exploration rules.
- **End-of-turn:** Fog decay: for each other-faction province where player had Explorer/Spy working, if no Explorer/Spy remains, set tiles to fogged; increment WorldState turn number; clear or carry over orders as designed.

When combat is in scope, the **minor military parity** step is always executed at the **start of the Combat phase** (before conflict detection). The combat resolver uses the resulting `effectiveMilitaryLevel` for Minor Nation and Tribe defenders.

**Diplomacy (when in scope, Phase 4+):** Full resolution per [diplomacy-resolution.md](diplomacy-resolution.md): overtures, Join Empire/Colony, alliances, war/peace, relation updates. Combat is in scope from Phase 3; diplomacy from Phase 4.
