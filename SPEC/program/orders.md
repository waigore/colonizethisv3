# Orders

**SPEC/program** — Order types, validation, and resolution. Reference: [movement.md](movement.md), [civilian-units.md](../game/civilian-units.md), [military-units.md](../game/military-units.md).

---

## Order Types (Current Scope)

- **MoveOrder** — Unit id, destination province id. Valid if destination is adjacent (see [movement.md](movement.md)); applied in movement phase.
- **BuildUnitOrder** — Unit type (civilian or military), optional spawn province. Valid if player has sufficient stockpile (cost) and, for military, a worker to consume; within unit caps; military regiment buildable only if unlocking tech is researched (see [tech-tree-military.md](../game/tech-tree-military.md)). Applied in build phase: deduct cost, consume worker if military, add unit to world state.
- **WorkOrder** — Applies to **civilian units only**. Unit id + **target** (action string) + **targetTileKey** (tile key string, format `regionId|provinceId|x|y`). For province-level actions (e.g. `explore`), targetTileKey may be a synthetic key for that province (e.g. `regionId|provinceId|0|0`). Validation: target tile must be in a province the unit may work in; unit must be civilian (has tileKey). Military and naval units do not receive work orders. Supported targets:
  - `explore` — Explorer; province-level; reveals all tiles in province over up to 3 turns (scaled by province size). See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
  - `prospect` — Explorer; tile-level; prospects the target tile; tile must be mineral-eligible (swamp, hills, mountain). See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
  - `build_improvement` — Builder; tile-level; raises improvement level by 1 (subject to terrain and tech caps) after a **multi-turn build**; consumes lumber + cast iron per level.
  - `upgrade_town` — Builder; province town tile; upgrades town to produce materials based on connected resources; multi-turn; costs per ruleset.
  - `build_road` — Engineer; tile-level; sets or upgrades transport level (0→1→2) subject to terrain and tech (e.g. Road Construction); multi-turn; consumes lumber + metal.
  - `build_port` — Engineer; coastal town/river tile; creates a port for a (province, seaboard) pair; sets transport level 4 on port tile; multi-turn; consumes lumber + metal.
  - `build_fort` — Engineer; province town tile; increases fort level by 1 (up to max), gated by fort techs (Mine Engineering, Modern Forts) and costs.
  - `build_rail` — Rail Builder; tile-level; upgrades an existing road tile to railroad (transport level 4) when rail tech permits; multi-turn; consumes steel + lumber.

- **WorkOrder resolution:** When a WorkOrder is applied, the **civilian** unit’s **tileKey is set to the order’s targetTileKey**; `currentWork` uses that same tile. Multi-turn progress, completion effects, cancellation: [development-resolution.md](development-resolution.md). The same WorkOrder model is used by the main game and by `ctdev`'s `sim_game`.
- **ResearchOrder** (Phase 5+) — Per player, per turn: **slot assignments** (slot index → tech id, or empty) and **funding level per slot** (None / Low / Medium / High / Maximum). Valid if: each tech id is in the catalog; all prerequisites of that tech are in the player’s techUnlocked set; slot count ≤ max (3 base, 4 with University); total research cost for the turn ≤ player treasury; tech not already researched. Applied in Research phase: see [research-resolution.md](research-resolution.md), [turn-resolution-phases.md](turn-resolution-phases.md). Merge: human and AI research orders merged like other orders (precedence per order-engine). A tech B that depends on A cannot be in any slot until A is completed.

---

## Validation and Resolution

Validation rules (topology, costs, caps, visibility) and resolution phase ordering: see [order-engine.md](order-engine.md). Rejected orders are not applied; state unchanged.
