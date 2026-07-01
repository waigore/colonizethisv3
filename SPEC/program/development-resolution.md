## Development Resolution

**SPEC/program** — Multi-turn resolution of civilian work orders that change terrain (improvements, roads, ports, forts, rails). Game rules: [civilian-units.md](../game/civilian-units.md), [extraction-and-improvements.md](../game/extraction-and-improvements.md), [siege-mechanics.md](../game/siege-mechanics.md), Imperialism II 02-economy and 03-units-civilian.

**Province identity:** Province ids (e.g. in build_port mapping, province ownership) and tile keys (targetTileKey, unit location) use the prefixed format and lookup rules in [world-model-identity.md](../game/world-model-identity.md).

---

### State Model

- Each **civilian unit** that is working has:
  - `status`: `idle | working` only (on completion, status is set to idle).
  - `currentWork` (optional): `(target: WorkTarget, tileKey, totalTurns, remainingTurns)`.
  - assignment placement tracking: optional `originTileKey` and `assignedTileKey`.
- `WorkTarget` values and allowed unit types/tiles are defined in [orders.md](orders.md) (`explore`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail`, `counter_spy`, `purchase_land`). **`steal_tech` removed** (Refs #3834). **Builder upgrade_town tech gate (current product):** The requirement for `national_bureaucracy` in `techUnlocked` for Builder `upgrade_town` work is **deferred** in current product; currently all Builders may submit and complete `upgrade_town`. When enforced, validation will require `techUnlocked['national_bureaucracy']` per [tech-tree-diplomacy-civilian.md](../game/tech-tree-diplomacy-civilian.md).
- Costs (lumber, castIron, bronze, steel, etc.) and max levels come from program-level config in `colonizethis_data`, mirroring Imperialism II tables.
- **Per-player tile exclusivity:** For each **player** and **tile** (`tileKey`), at most one Builder/Engineer/Merchant work stream may target that tile at any time. The development resolver assumes the order engine has already enforced that no two Builder/Engineer/Merchant units owned by the same player have `currentWork.tileKey` equal to the same value.

---

### Assigning Work

- WorkOrder applies to **civilian units only** and carries **targetTileKey**. Military and naval units do not have tileKey or work orders of this kind.
- When a `WorkOrder` is accepted for a civilian:
  - Validate **unit type**, **target tile** (targetTileKey: exists, tile ownership, terrain eligibility), and **tech prerequisites** (e.g. Road Construction for transport level 2, Early Steam Engine for rail, Mine Engineering / Modern Forts for higher forts, gathering techs for higher improvements).
  - For **build_improvement** specifically: reject if the tile has no resource (per [extraction-and-improvements.md](../game/extraction-and-improvements.md)); for **prospect-required minerals** (iron, copper, tin, coal, silver, gold, gems, diamonds — same set as [extraction-and-improvements.md](../game/extraction-and-improvements.md) Mineral Prospecting Gate), reject if that tile is not in the player's `playerProspectedTiles` entry (same message pattern as `purchase_land`: mineral must be prospected first); reject if the tile's improvement level is already at max (4) or if the next level would exceed the player's tech-allowed extraction cap (see [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md)).
  - Look up:
    - `totalTurns` for this action using `totalTurnsForWork` in `packages/colonizethis_data` `work_order_costs.dart`, applied from `applyBuildAndWorkOrders` for standard material-backed targets (`build_improvement`, `build_road`, `build_port`, `build_fort`, `build_rail`, `upgrade_town`), plus **`prospect`** and **`purchase_land`** (each **1** turn in current ruleset). **`explore`** uses the province-scaled turn count computed in that application path (see [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md)). **`counter_spy`** is ongoing (see loop below).
    - For UI pending-row display, logic exposes assign-time duration preview from shared order helpers. This preview must be deterministic and uses a minimum display value of `1` turn for all pending civilian work targets.
    - Material **costs** per action from `work_order_materialCost` / related helpers in the same module. **`purchase_land`:** validate `treasury >= cost` at assign; **debit treasury only on completion** (same module cost lookup for the amount).
  - If validation passes and the player has sufficient materials (or no material cost for that target):
    - **Deduct materials when work is assigned** (during Build/Work phase application of WorkOrder; atomic per action; no refund if later cancelled).
    - Enforce **per-player tile exclusivity** for development and purchase work: if another Builder, Engineer, or Merchant unit owned by the same player already has `currentWork` targeting that `targetTileKey`, the new work order must have been rejected earlier and is not applied here.
    - Set unit `status = working`, `currentWork = (target, targetTileKey, totalTurns, remainingTurns = totalTurns)`, and **unit.tileKey = targetTileKey** (civilian unit is considered on the target tile for the turn).
    - Persist assignment placement: set `originTileKey` to the unit tile before assignment and set `assignedTileKey = targetTileKey`.
  - Durations are code-defined in `totalTurnsForWork` (and the `explore` formula where applicable); `build_fort` scales with current fort level (e.g. longer builds for higher fort levels).

---

### Build/Work Phase Loop

During the **Build / Work** phase (see [turn-resolution-phases.md](turn-resolution-phases.md)):

1. For each civilian with `status = working` and a `currentWork` record:
   - If unit is dead, **cancel** work: clear `currentWork`, set `status = idle`; costs are not refunded.
   - Else if the work target is **not** `explore` or `purchase_land`, and the worked tile is **no longer owned by the player** where that target requires player ownership, **cancel** work: clear `currentWork`, set `status = idle`; costs are not refunded. (For `explore` and `purchase_land`, foreign or not-yet-purchased target tiles do **not** trigger this cancel by themselves.)
   - Otherwise, decrement `remainingTurns` by 1.
2. When `remainingTurns` reaches 0, apply the action's effect:
   - `build_improvement`: set stored improvement level to `min(currentLevel + 1, 4)` (global max improvement level per [extraction-and-improvements.md](../game/extraction-and-improvements.md)). Tech-allowed extraction cap and tile eligibility are enforced **only when the work order is accepted**; completion does **not** recompute those caps. Effective extraction still uses `min(improvement level, tech cap, …)` each turn per that GDD.
   - `upgrade_town`: increase the province's **town development level** by 1 (not generic improvement level on the tile); used in extraction formula per [capital-and-connectivity.md](../game/capital-and-connectivity.md).
   - `build_road`: set or upgrade transport level for `tileKey` (0→1→2; level 2 requires Road Construction tech) and, if applicable, adjacent capital/port tiles per [capital-and-connectivity.md](../game/capital-and-connectivity.md). "If applicable" means: when the target tile is adjacent (4-neighbour) to a tile that is either the player's capital or a port, the transport level is also applied to that adjacent tile (upgrade only, never downgrade).
   - `build_port`: create/update a `(provinceId, seaZoneId) → tileKey` mapping in `portsByProvinceSeaboard` and ensure the port tile has transport level 4.
   - `build_fort`: increase the province's `fortLevel` by 1 (up to max).
   - `build_rail`: upgrade a tile at `tileKey` with transport level 1 or 2 to railroad (transport level 4) when terrain is known and rail tech matches terrain per [tech-tree-transport.md](../game/tech-tree-transport.md).
   - `counter_spy`: ongoing assignment only; kill/defection resolved in pre-Research spy-resolution (empire-wide; see [turn-resolution-phases.md](turn-resolution-phases.md)).
   - `purchase_land`: when `remainingTurns` reaches 0, deduct treasury (15 × resource base price), record purchased tile for the GP; extraction/connectivity treat that tile as GP-owned thereafter.
   - `prospect`: when `remainingTurns` reaches 0, add the target tile to the player's prospected set (mineral-eligible rules per GDD).
3. After applying effects (or when work is cancelled), set unit `status = idle` and clear `currentWork`.
   - On completion: clear `originTileKey` and `assignedTileKey`; keep `tileKey` at the resolved target tile.
   - On cancellation: restore `tileKey` from `originTileKey`, then clear `originTileKey` and `assignedTileKey`.

Exploration and prospecting (`explore`, `prospect`) follow [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); they share the same `status` and `currentWork` shape but operate on visibility and prospected state instead of terrain.

---

### Player-initiated cancel of in-progress work

- The player may request to **cancel** a civilian unit's **in-progress** work (unit has `status == working` and `currentWork != null`). On confirm, the system produces a game state in which that unit has `currentWork` cleared, `status = idle`, and `tileKey` restored from `originTileKey`; the system then clears `originTileKey` and `assignedTileKey`. **Materials are not refunded.**
- **Implementation:** Either (a) a **cancel-work order** (e.g. unit id) applied at the **start** of the Build/Work phase (before processing work and new WorkOrders), or (b) a **direct game-state update** (e.g. game service method that returns an updated `Game` with that unit's work cleared). TDD and [order-engine.md](order-engine.md) / [orders.md](orders.md) specify which. Pending work orders for the same unit are cancelled by removing them from the current turn's orders (order engine `removeWorkOrder`); no separate spec for that.

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

- **Work assign (validation and materials):** Given a civilian `WorkOrder` that passes order-engine validation for unit type, target tile (exists, ownership, terrain eligibility), tech prerequisites, and material availability  
  When the system applies that order in the Build/Work application path  
  Then the system deducts materials at assign time (no refund if work is later cancelled), sets the unit `status` to `working`, and sets `currentWork` with `remainingTurns == totalTurns`.

- **Work assign (`totalTurns` source):** Given a standard material-backed work target handled by `applyStandardWorkOrder` (e.g. `build_improvement`, `build_road`, `build_fort`)  
  When the system assigns that work  
  Then `currentWork.totalTurns` equals `totalTurnsForWork` from `colonizethis_data` `work_order_costs.dart` for that target and its level arguments (e.g. fort level for `build_fort`).

- **build_improvement validation:** Given a `build_improvement` work order  
  When the order engine validates it  
  Then the engine rejects the order if the target tile has no resource, if the tile's improvement level is already 4, if the player's tech-allowed extraction cap is strictly less than (current improvement level + 1), or if the tile's resource is a prospect-required mineral and the tile key is not in that player's `playerProspectedTiles` set (rejection reason includes that the mineral tile must be prospected first).

- **build_improvement validation (mineral prospected):** Given an owned or player-controlled tile whose `resourceByTileKey` entry is a prospect-required mineral and that tile key is present in `playerProspectedTiles` for the submitting player, and given improvement level and tech cap allow the next level  
  When the order engine validates a `build_improvement` work order on that tile  
  Then the engine does not reject for missing prospection (subject to existing resource, level, tech, materials, and territory rules).

- **build_improvement validation (non-mineral):** Given a tile whose resource is not a prospect-required mineral and that tile is not in `playerProspectedTiles`  
  When the order engine validates `build_improvement`  
  Then the engine does not reject for missing prospection when all other validation rules pass.

- **build_improvement completion (stored level):** Given a unit completes `build_improvement` on a tile whose stored improvement level is `N` with `0 <= N <= 3`  
  When `remainingTurns` reaches 0 and the effect is applied  
  Then the stored improvement level becomes `N + 1` (and never exceeds 4).

- **build_improvement completion (no assign-time re-check):** Given a unit has in-progress `build_improvement` on a tile at stored level 3  
  When `remainingTurns` reaches 0 and the effect is applied  
  Then the system sets stored improvement level to 4 without re-evaluating the player's tech-allowed extraction cap at completion (cap was enforced when the order was accepted; extraction yield still follows `min(level, tech cap, …)` per GDD).

- **Build/Work phase loop:** Given a civilian with `status = working` and `currentWork != null`  
  When the Build/Work phase runs  
  Then if the unit is dead, the system clears `currentWork` and sets `status = idle` with no material refund; else if the target is not `explore` or `purchase_land` and the worked tile is no longer player-owned when required, it clears work the same way; otherwise it decrements `remainingTurns` by 1, and when `remainingTurns` reaches 0 it applies the action effect, then sets `status = idle` and clears `currentWork`.

- **Pending duration preview contract:** Given a pending civilian `WorkOrder` shown in UI before turn resolution  
  When the UI queries the shared logic duration-preview helper  
  Then the helper returns assign-time deterministic `totalTurns` for that target using the same assignment semantics as build/work, and never returns less than `1`.

- **Player-initiated cancel:** Given a unit with in-progress work  
  When the player confirms cancel  
  Then the system clears that unit's `currentWork`, sets `status = idle`, restores `tileKey` from `originTileKey`, clears `originTileKey` and `assignedTileKey`, and does not refund materials; pending work orders for that unit are removed from the current turn's orders. Implementation may use a cancel-work order at the start of Build/Work phase or a direct game-state update per TDD.

- **build_port:** Given `build_port` work completes  
  When topology is `null`  
  Then the system does not register a port in `portsByProvinceSeaboard` and does not set transport level on the tile from that completion. Port keys use full province id per [world-model-identity.md](../game/world-model-identity.md).

- **Shared use:** Given the same `WorkOrder` inputs  
  When the main game or `sim_game` resolves the Build/Work phase  
  Then both use the same turn resolution / development application logic for durations, costs, and completion effects.

