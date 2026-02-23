## Development Resolution

**SPEC/program** — Multi-turn resolution of civilian work orders that change terrain (improvements, roads, ports, forts, rails). Game rules: [civilian-units.md](../game/civilian-units.md), [extraction-and-improvements.md](../game/extraction-and-improvements.md), [siege-mechanics.md](../game/siege-mechanics.md), Imperialism II 02-economy and 03-units-civilian.

**Province identity:** Province ids (e.g. in build_port mapping, province ownership) and tile keys (targetTileKey, unit location) use the prefixed format and lookup rules in [world-model-identity.md](../game/world-model-identity.md).

---

### State Model

- Each **civilian unit** that is working has:
  - `status`: `idle | working` only (on completion, status is set to idle).
  - `currentWork` (optional): `(target: WorkTarget, tileKey, totalTurns, remainingTurns)`.
- `WorkTarget` values and allowed unit types/tiles are defined in [orders.md](orders.md) (`explore`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail`, `steal_tech`, `counter_spy`, `purchase_land`).
- Costs (lumber, castIron, bronze, steel, etc.) and max levels come from program-level config in `colonizethis_data`, mirroring Imperialism II tables.

---

### Assigning Work

- WorkOrder applies to **civilian units only** and carries **targetTileKey**. Military and naval units do not have tileKey or work orders of this kind.
- When a `WorkOrder` is accepted for a civilian:
  - Validate **unit type**, **target tile** (targetTileKey: exists, tile ownership, terrain eligibility), and **tech prerequisites** (e.g. Road Construction for transport level 2, Early Steam Engine for rail, Mine Engineering / Modern Forts for higher forts, gathering techs for higher improvements).
  - Look up:
    - `totalTurns` for this action from ruleset config (higher levels → more turns; fort and rail slower than level-1 road/improvement).
    - Material **costs** per action.
  - If validation passes and the player has sufficient materials (or no material cost for that target):
    - **Deduct materials when work is assigned** (during Build/Work phase application of WorkOrder; atomic per action; no refund if later cancelled). Look up costs from ruleset/config.
    - Set unit `status = working`, `currentWork = (target, targetTileKey, totalTurns, remainingTurns = totalTurns)`, and **unit.tileKey = targetTileKey** (civilian unit is considered on the target tile for the turn).
  - `totalTurns` comes from ruleset config (default 1); config can vary by action and level (e.g. higher improvement/fort levels take more turns).

---

### Build/Work Phase Loop

During the **Build / Work** phase (see [turn-resolution-phases.md](turn-resolution-phases.md)):

1. For each civilian with `status = working` and a `currentWork` record:
   - If unit is dead or tile is no longer owned by the player, **cancel** work: clear `currentWork`, set `status = idle`; costs are not refunded.
   - Otherwise, decrement `remainingTurns` by 1.
2. When `remainingTurns` reaches 0, apply the action's effect:
   - `build_improvement`: increase improvement level for `tileKey` by 1, clamped by terrain and tech caps.
   - `upgrade_town`: increase the province's **town development level** by 1 (not generic improvement level on the tile); used in extraction formula per [capital-and-connectivity.md](../game/capital-and-connectivity.md).
   - `build_road`: set or upgrade transport level for `tileKey` (0→1→2; level 2 requires Road Construction tech) and, if applicable, adjacent capital/port tiles per [capital-and-connectivity.md](../game/capital-and-connectivity.md).
   - `build_port`: create/update a `(provinceId, seaZoneId) → tileKey` mapping in `portsByProvinceSeaboard` and ensure the port tile has transport level 4.
   - `build_fort`: increase the province's `fortLevel` by 1 (up to max).
   - `build_rail`: upgrade an existing road tile at `tileKey` to railroad (transport level 4).
   - `steal_tech`: roll 8% per turn (or on final turn); on success, grant random tech from (target GP techs − player techs) and clear work; on expiry, clear work.
   - `counter_spy`: ongoing; each turn, in that province, probability to kill one enemy Spy = min(30%, 5% × number of friendly Spies with counter_spy there); resolve kills then continue (no completion).
   - `purchase_land`: applied when order is accepted (single-turn): deduct treasury (15 × resource base price), record purchased tile for the GP; extraction/connectivity treat that tile as GP-owned for extraction.
3. After applying effects (or when work is cancelled), set unit `status = idle` and clear `currentWork`.

Exploration and prospecting (`explore`, `prospect`) follow [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); they share the same `status` and `currentWork` shape but operate on visibility and prospected state instead of terrain.

---

### Shared Use in Main Game and sim_game

- The **same TurnResolver and development resolution logic** must be used in:
  - The main game (normal turns).
  - `ctdev`'s `sim_game` feature.
- `sim_game` inputs may include civilian `WorkOrder`s; its output should expose:
  - Updated improvement levels, road/rail levels, ports, and fort levels.
  - Updated visibility and prospected tiles for exploration/prospecting.
- This guarantees that simulations exercise identical development rules and multi-turn timing as regular play.

---

### Acceptance criteria

- **Work assign:** Validation covers unit type, target tile (exists, ownership, terrain eligibility), tech prerequisites, and material availability; on accept, materials are deducted at assign (no refund if work is later cancelled); unit gets `currentWork` set and `status = working`.
- **Build/Work phase loop:** Each turn, for each working civilian: if unit is dead or the tile is no longer owned by the player (e.g. conquest; see #376), cancel work (clear `currentWork`, set `status = idle`); otherwise decrement `remainingTurns`; when it reaches 0, apply the action effect then set `status = idle` and clear `currentWork`.
- **build_port:** Completion requires topology to be defined (topology-null behaviour is documented in a dedicated issue); port key uses full province id per [world-model-identity.md](../game/world-model-identity.md).
- **Shared use:** The same TurnResolver and development resolution logic are used in the main game and in sim_game.

