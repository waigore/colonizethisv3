# Orders

**SPEC/program** — Order types, validation, and resolution. Reference: [movement.md](movement.md), [SPEC/game/unit-types.md](../game/unit-types.md).

---

## Order Types (Current Scope)

- **MoveOrder** — Unit id, destination province id. Valid if destination is adjacent (see [movement.md](movement.md)); applied in movement phase.
- **BuildUnitOrder** — Unit type (civilian or military), optional spawn province. Valid if player has sufficient stockpile (cost) and, for military, a worker to consume; within unit caps; military regiment buildable only if unlocking tech is researched (see [tech-tree-military.md](../game/tech-tree-military.md)). Applied in build phase: deduct cost, consume worker if military, add unit to world state.
- **WorkOrder** — Unit id, work target. Valid if unit is civilian and in scope. Supported targets:
  - `explore` — Explorer; province-level; reveals all tiles in province over up to 3 turns (scaled by province size). See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
  - `prospect` — Explorer; tile-level; prospects tile under unit; tile must be mineral-eligible (swamp, hills, mountain). See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
  - `build_improvement` — Builder; tile-level; raises improvement level by 1 (subject to terrain and tech caps) after a **multi-turn build**; consumes lumber + cast iron per level.
  - `upgrade_town` — Builder; province town tile; upgrades town to produce materials based on connected resources; multi-turn; costs per ruleset.
  - `build_road` — Engineer; tile-level; sets or upgrades road level (0→1→2) subject to terrain and tech (e.g. Road Construction); multi-turn; consumes lumber + metal.
  - `build_port` — Engineer; coastal town/river tile; creates a port for a (province, seaboard) pair; sets transport level 4 on port tile; multi-turn; consumes lumber + metal.
  - `build_fort` — Engineer; province town tile; increases fort level by 1 (up to max), gated by fort techs (Mine Engineering, Modern Forts) and costs.
  - `build_rail` — Rail Builder; tile-level; upgrades an existing road tile to railroad (transport level 4) when rail tech permits; multi-turn; consumes steel + lumber.

- WorkOrder resolution (multi-turn progress, completion effects, cancellation) is specified in [development-resolution.md](development-resolution.md). The same WorkOrder model is used by the main game and by `ctdev`'s `sim_game`.
- **ResearchOrder** (Phase 5+) — Per player, per turn: **slot assignments** (slot index → tech id, or empty) and **funding level per slot** (None / Low / Medium / High / Maximum). Valid if: each tech id is in the catalog; all prerequisites of that tech are in the player’s techUnlocked set; slot count ≤ max (3 base, 4 with University); total research cost for the turn ≤ player treasury; tech not already researched. Applied in Research phase: see [research-resolution.md](research-resolution.md), [turn-resolution-phases.md](turn-resolution-phases.md). Merge: human and AI research orders merged like other orders (precedence per order-engine). A tech B that depends on A cannot be in any slot until A is completed.

---

## Validation

- **Topology:** MoveOrder destination from colonizethis_data adjacency.
- **Costs (civilian):** BuildUnitOrder for **civilian** units consumes the specified construction commodities from player stockpile (e.g. paper, cash, lumber, metal) per [civilian-units.md](../game/civilian-units.md). Costs and caps come from program-level config (colonizethis_data).
- **Costs (military):** BuildUnitOrder for **military** regiments consults the regiment economy catalog in `colonizethis_data` and:
  - Requires `treasury ≥ regimentEconomy.buildTreasuryCost`.
  - Requires sufficient stockpile for all `(commodityId, quantity)` entries in `regimentEconomy.buildInputs`.
  - Requires at least one available worker in the player's `WorkerPool` (Phase 2: one Peasant is consumed).
  - On success, **deducts treasury and commodities and consumes one worker**, then spawns the regiment in the chosen province.
- **Caps:** Civilian and military unit counts must not exceed per-player caps after build.

Rejected orders are not applied; state unchanged.

---

## Resolution

Orders are applied in defined phases: build orders (add units, deduct costs) before or after movement as per [turn-resolution-phases.md](turn-resolution-phases.md). Move orders applied in movement phase. Work orders applied in same or separate step; work-in-progress can persist across turns.
