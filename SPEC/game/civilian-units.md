# Civilian Units

**SPEC/game** — All six civilian unit types and their roles. Derived from GDD 05, TDD 05. Reference: Imperialism II 03-units-civilian (GDD).

---

## Overview

**The game supports all six civilian types** per Imperialism II 03-units-civilian: Explorer, Engineer, Builder, Spy, Merchant, Rail Builder. Civilian units are map units — they deploy, move, and work on terrain. They are distinct from workers (population for industry; see [workers-and-population.md](workers-and-population.md)).

---

## Civilian Types and Roles

| Unit | Role | Training cost | Unlock | Special |
|------|------|---------------|--------|---------|
| **Explorer** | Explore fog of war; prospect for minerals | 1000 cash, 2 paper | Starting | Minerals must be prospected before extraction; free exploration and prospecting |
| **Engineer** | Build roads, ports, fortifications | 1000 cash, 2 paper | Starting | Roads gather resources; ports and forts in cities/rivers |
| **Builder** | Improve terrain production (mines, farms, ranches, plantations, fur posts, towns) | 1000 cash, 2 paper | Starting | Increases output 1→2→3→4; tech caps max level |
| **Spy** | Presence reveal; steal technology; counter-spy | 2000 cash, 4 paper | Starting | Presence reveal in non-owner province; steal_tech/counter_spy work orders; invisible to other players |
| **Merchant** | Purchase land in Minor Nations/Tribes and New World | 2000 cash, 4 paper | Merchant Companies tech; embassy for purchase_land | purchase_land WorkOrder: tile with resource; embassy required; not at war; cost 15× resource base price. See [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md). |
| **Rail Builder** | Upgrade roads to railroads | 2000 cash, 4 paper | Early Steam Engine tech | Rail transports up to 4 resources per tile |

Work costs (materials per build_improvement, build_road, build_fort, etc.) are defined in [extraction-and-improvements.md](extraction-and-improvements.md) and [siege-mechanics.md](siege-mechanics.md).

---

## Work Order Summary

Canonical list of WorkOrder targets per civilian type. Order engine and suggestions API derive allowed targets and validation from this table and from [orders.md](../program/orders.md).

| Target | Unit | Cost / gates | Duration | Notes |
|--------|------|--------------|----------|-------|
| explore | Explorer | Free | Multi-turn (province size) | Province-level; reveals tiles |
| prospect | Explorer | Free | 1 turn (`currentWork`) | Tile-level; mineral-eligible; prospected set updated when work **completes** |
| build_improvement | Builder | Lumber + cast iron per level | Config (default 1) | Tile-level; level 1–4; prospect-required minerals → tile must be prospected (same gate as extraction / `purchase_land`) |
| upgrade_town | Builder | Per ruleset | Config | Town tile; town development level |
| build_road | Engineer | 1 lumber + 1 cast iron (level 1); Road Construction for level 2 | Config | 0→1→2; tech for 2 |
| build_port | Engineer | Lumber + metal | Config | Coastal/river; transport 4 |
| build_fort | Engineer | Per siege-mechanics | Config (1+ turn per level) | Town tile; fort level 1–3 |
| build_rail | Rail Builder | 2 lumber + 2 steel | Config | Road 1–2→4; rail tech vs terrain |
| steal_tech | Spy | — | Up to 5 turns | Target = **GP capital province**; 8%/turn success; random tech player lacks |
| counter_spy | Spy | — | Ongoing | Target = **owned province**; +5% per friendly spy/turn (cap 30%) to kill enemy spies |
| purchase_land | Merchant | 15 × resource base price (treasury); validate ≥ cost at assign; **debit at completion**; embassy in Minor/Tribe | 1 turn (`currentWork`) | Tile in Minor/Tribe with resource; not at war; mineral → must be prospected; `purchasedTilesByTileKey` updated at completion |

Spy does not have explore/prospect; Spy's garrison reveal is handled by visibility (see [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md)), not a work order.

**UI:** The Civilian Units panel shows pending-turn cost previews (commodity icons + quantities or treasury for `purchase_land`) per [civilian-units-panel.md](../ui/civilian-units-panel.md); it does not restate affordability.

---

## Work Types and Multi-Turn Builds

- **Explorer work:** Uses `WorkOrder` targets `explore` and `prospect`. Explore is **province-level** and completes over multiple turns per [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md). Prospect is **tile-level** with **one** turn of `currentWork`; the prospected-set update runs at **completion** in Build/Work, not at accept-only.
- **WorkOrder** specifies both an **action** (e.g. `build_improvement`, `build_road`) and a **target tile** (`targetTileKey`). Civilians can move to and act on a tile different from their current tile (Imperialism-style).
- **Builder work:** Uses `WorkOrder` targets `build_improvement` and `upgrade_town`. Each completed order increases the tile's improvement level by 1 (or upgrades a town) after a **multi-turn build** whose duration increases with target level and terrain; costs and turn counts derive from Imperialism II (e.g. Level 1 cheaper/faster than Level 4). See [extraction-and-improvements.md](extraction-and-improvements.md) and [development-resolution.md](../program/development-resolution.md).
- **Engineer work:** Uses `WorkOrder` targets `build_road`, `build_port`, and `build_fort`. Each completed order constructs or upgrades transport/fortification on the **target tile** after one or more turns, consuming lumber and metal per [02-economy](../../Obsidian/obsidian-shared/Projects/ColonizeThisV3/Imperialism II/02-economy.md) mirrored in ruleset config.
- **Rail Builder work:** Uses `WorkOrder` target `build_rail`. Each completed order upgrades an existing road tile (transport level 1 or 2) to railroad (transport level 4) over multiple turns, costing 2 lumber + 2 steel; validation requires per-tile terrain from the region tile map and the transport tech appropriate to that terrain per [tech-tree-transport.md](tech-tree-transport.md). Authoritative material cost: `packages/colonizethis_data` `work_order_costs.dart` (`workOrderCostBuildRail`).
- **Spy:** (1) **Presence reveal:** While a Spy is in a non-owner province, that province is fully visible to the Spy's owner; when the Spy leaves, the province returns to fogged after 5 turns (turn timer). (2) **steal_tech:** WorkOrder target = other GP's **capital province**; up to 5 turns; 8% per turn to steal a random tech the player does not have; completion or expiry clears work. (3) **counter_spy:** WorkOrder target = any **owned** province; each friendly Spy in that province adds 5% per turn (capped 30%) chance to kill an enemy Spy there. (4) **Invisibility:** Spy province locations are invisible to all players except the Spy's owner.
- **Merchant:** **purchase_land** WorkOrder: target = tile in Minor/Tribe province that has a resource; if resource requires prospecting, player must have prospected that tile; player must not be at war with that Minor/Tribe; cost = 15 × resource base price (treasury) debited when work **completes**; requires **embassy** with that Minor/Tribe; assign-time validates `treasury >= cost` without debiting. **A tile may be purchased by at most one GP;** once recorded in `purchasedTilesByTileKey` at completion, no other GP may purchase that tile (validation rejects). Building a Merchant unit requires Merchant Companies tech; purchasing land requires embassy (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md)).

---

### Per-player tile exclusivity (Builder, Engineer, Merchant)

- **Rule:** For a given **player** and **tile** (`targetTileKey`), at most **one** of that player's **Builder**, **Engineer**, or **Merchant** units may have **active or newly assigned** work targeting that tile in a turn. This applies to:
  - Multi-turn development work (`build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`) on owned tiles.
  - Tile-level **purchase_land** work by Merchants on Minor/Tribe tiles.
  - Both existing `Unit.currentWork` (multi-turn work already in progress) and newly submitted `WorkOrder`s for the same tile in the current turn.
- **Scope:** This exclusivity is **per player** only — other factions may still have their own development or purchase work on the same tile when game rules allow them to be present there. Explorers, Spies, and Rail Builders are **not** subject to this exclusivity rule.

Multi-turn progress for all civilian work is tracked in the model and resolved during the Build/Work phase; `Unit.status` is **idle** or **working** only (on completion, status is set to idle). See [orders.md](../program/orders.md) and [development-resolution.md](../program/development-resolution.md).

---

## Acceptance Criteria

- Given the player has sufficient treasury cash and stockpile paper for a civilian unit type in the Civilian Types and Roles table  
  When the player issues a build order for that civilian unit and the order is accepted  
  Then the system creates a civilian `Unit` with `type` equal to the requested civilian type, deducts the listed cash from the player's treasury, deducts the listed paper from the player's stockpile, and does not change any worker counts or food consumption.

- Given the player submits a `WorkOrder` with `unitId` referencing a civilian unit and `action` equal to one of the Work Order Summary targets that is allowed for that unit type  
  When the system applies Build/Work orders for the turn and the player has all required materials in treasury/stockpile (for `purchase_land`, sufficient treasury is validated at assign; treasury is debited only when that work completes)  
  Then the system marks that civilian unit's `status` as `working`, reserves or deducts material costs that are due at assign time per target rules, and starts multi-turn progress (`currentWork`) without applying terrain, visibility, purchase, or prospection **primary** effects until progress completes (except where a target explicitly completes in the same tick after decrement per [development-resolution.md](../program/development-resolution.md)).

- Given a civilian unit has an active multi-turn `WorkOrder` and its work duration expires at the end of the current Build/Work phase  
  When the system resolves development for that phase  
  Then the system applies exactly one level of the specified effect to the `targetTileKey` (e.g., improvement level increase, road/rail/fort/port construction), sets the unit's `status` to `idle`, and clears the unit's active work so it does not continue on the next turn.

- Given an Explorer civilian unit with `status = idle` is located in a province that still has fogged tiles  
  When the player assigns an `explore` `WorkOrder` to that Explorer  
  Then the system starts a multi-turn exploration process for that province and, on completion, reveals all tiles in that province to the Explorer's owner according to [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md).

- Given a Spy civilian unit controlled by the player is present in a province that is not owned by that player  
  When the system evaluates visibility for that player's map each turn  
  Then the system treats that province as fully visible for that player, and when the Spy leaves that province, the system starts a 5-turn countdown after which all tiles in that province revert to fogged unless revealed by another source.

- Given a Spy civilian unit controlled by the player has an active `counter_spy` `WorkOrder` targeting an owned province and an enemy Spy is present in the same province  
  When the system resolves counter-spy checks at end of turn  
  Then the system computes a per-turn kill chance equal to 5% per friendly Spy in that province, capped at 30%, and removes the enemy Spy from the game if the random roll succeeds while leaving all friendly Spies in place.

- Given a Merchant civilian unit controlled by the player has an active `purchase_land` `WorkOrder` targeting a tile in a Minor Nation or Tribe province that has a resource, the player is not at war with that Minor/Tribe, the player has an embassy with that Minor/Tribe, and any mineral resource on that tile has already been prospected by that player  
  When the system completes that `purchase_land` work (`remainingTurns` reaches 0 in Build/Work)  
  Then the system deducts treasury cash equal to 15 times the resource base price, transfers ownership of that tile (and its resource) to the player, records the tile in `purchasedTilesByTileKey`, and leaves diplomatic status with that Minor/Tribe unchanged.

- Given a Rail Builder civilian unit controlled by the player has an active `build_rail` `WorkOrder` targeting a tile that currently has transport level 1 or 2, per-tile terrain is present on the region tile map, and the player's unlocked transport techs allow railroad on that terrain per [tech-tree-transport.md](tech-tree-transport.md)  
  When the system completes that work after the configured duration  
  Then the system upgrades the tile's transport level to railroad (transport level 4), deducts 2 lumber and 2 steel once for that work, and does not allow another `build_rail` order on that tile while it already has transport level 4.

- Given the player submits a `build_rail` `WorkOrder` for a tile whose transport level is not 1 or 2, or whose terrain cannot be read from the tile map, or whose terrain is not yet covered by the player's unlocked rail techs  
  When the system validates work orders at order submit time  
  Then the system rejects the order with a clear reason and does not assign `build_rail` work to that unit.

- Given a civilian `Unit` of any type exists on the map  
  When the system evaluates that unit's `location` and any `WorkOrder.targetTileKey` for rules that depend on province or region identity  
  Then the system derives province and region solely from the prefixed tile key format `regionId|provinceId|x|y` and never treats a bare `provinceId` without its `regionId` as a valid reference.

- Given the system resolves the Build/Work phase for all civilians in a turn  
  When it completes processing of all active `WorkOrder`s for that turn  
  Then every civilian unit has `status` equal to either `idle` or `working` (no other values), with `working` only for units that still have an active, incomplete multi-turn `WorkOrder`.

- Given a player controls at least one Builder, Engineer, or Merchant unit and any of those units already has active multi-turn `currentWork` whose `tileKey` is `T`  
  When the player submits a new `WorkOrder` for any of their Builder, Engineer, or Merchant units with `targetTileKey = T` in the same turn  
  Then the system rejects the new work order during validation with a reason that clearly indicates the tile already has development or purchase work for that player, and the new order is not added to that player's `workOrdersByPlayerId`.

- Given a player submits multiple `WorkOrder`s in the same turn for their Builder, Engineer, or Merchant units where two or more of those work orders have `targetTileKey` equal to the same tile `T`  
  When the system validates that player's work orders in submission order  
  Then the first valid work order for tile `T` may be accepted, and every subsequent Builder/Engineer/Merchant work order for tile `T` from that player in that turn is rejected with a reason indicating per-player tile exclusivity.

---

## Relations

- **Unit** (type = civilian) → has owner (player id) and **location** = **tileKey** only (required, format `regionId|provinceId|x|y`); province and region are derived from tileKey. Work is ordered via WorkOrder (unitId, action, targetTileKey). Military and naval units do not have tileKey. See [fog-and-exploration.md](fog-and-exploration.md).
- **Assignment tracking (current schema):** Civilian units may persist `originTileKey` (tile before current assignment) and `assignedTileKey` (current assignment destination). While work is in progress, `tileKey` represents rendered intent placement (typically equal to `assignedTileKey`). On completion, both tracking fields are cleared; on cancel, `tileKey` is restored from `originTileKey` and both tracking fields are cleared.
- **Province identity:** Civilian **location** (tileKey) and WorkOrder **targetTileKey** use the prefixed tile key format `regionId|provinceId|x|y`. Province and region for a civilian are derived from tileKey; any province lookup (e.g. for work cancel, build_port, steal_tech target) must use the full province id (`regionId|localId`). See [world-model-identity.md](world-model-identity.md).
- Civilian units have a **training cost**: cash is deducted from the player's **treasury** and paper from the player's **stockpile** when the unit is built. Work orders consume materials (lumber, metal, etc.) as defined in extraction-and-improvements and siege-mechanics. Materials are deducted when the work is **assigned** (during Build/Work phase application of WorkOrder); validation checks treasury/stockpile at order submit time.
- Civilian units do not eat food; they do not consume workers when built (unlike military/naval).

---

## Implementation

See [world-model.md](world-model.md) for Unit entity. Implementation scope: civilian types per this doc; military per [military-units.md](military-units.md).
