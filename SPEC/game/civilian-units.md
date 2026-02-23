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
| prospect | Explorer | Free | 1 turn | Tile-level; mineral-eligible |
| build_improvement | Builder | Lumber + cast iron per level | Config (default 1) | Tile-level; level 1–4 |
| upgrade_town | Builder | Per ruleset | Config | Town tile; town development level |
| build_road | Engineer | 1 lumber + 1 cast iron (level 1); Road Construction for level 2 | Config | 0→1→2; tech for 2 |
| build_port | Engineer | Lumber + metal | Config | Coastal/river; transport 4 |
| build_fort | Engineer | Per siege-mechanics | Config (1+ turn per level) | Town tile; fort level 1–3 |
| build_rail | Rail Builder | Steel + lumber | Config | Road→4; rail tech |
| steal_tech | Spy | — | Up to 5 turns | Target = **GP capital province**; 8%/turn success; random tech player lacks |
| counter_spy | Spy | — | Ongoing | Target = **owned province**; +5% per friendly spy/turn (cap 30%) to kill enemy spies |
| purchase_land | Merchant | 15 × resource base price (treasury); embassy in Minor/Tribe | 1 turn | Tile in Minor/Tribe with resource; not at war; mineral → must be prospected |

Spy does not have explore/prospect; Spy's garrison reveal is handled by visibility (see [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md)), not a work order.

---

## Work Types and Multi-Turn Builds

- **Explorer work:** Uses `WorkOrder` targets `explore` and `prospect`. Explore is **province-level** and completes over multiple turns per [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md); prospect is **tile-level** (one tile per completed order).
- **WorkOrder** specifies both an **action** (e.g. `build_improvement`, `build_road`) and a **target tile** (`targetTileKey`). Civilians can move to and act on a tile different from their current tile (Imperialism-style).
- **Builder work:** Uses `WorkOrder` targets `build_improvement` and `upgrade_town`. Each completed order increases the tile's improvement level by 1 (or upgrades a town) after a **multi-turn build** whose duration increases with target level and terrain; costs and turn counts derive from Imperialism II (e.g. Level 1 cheaper/faster than Level 4). See [extraction-and-improvements.md](extraction-and-improvements.md) and [development-resolution.md](../program/development-resolution.md).
- **Engineer work:** Uses `WorkOrder` targets `build_road`, `build_port`, and `build_fort`. Each completed order constructs or upgrades transport/fortification on the **target tile** after one or more turns, consuming lumber and metal per [02-economy](../../Obsidian/obsidian-shared/Projects/ColonizeThisV3/Imperialism II/02-economy.md) mirrored in ruleset config.
- **Rail Builder work:** Uses `WorkOrder` target `build_rail`. Each completed order upgrades an existing road tile to railroad (transport level 4) over multiple turns, costing steel + lumber; only available after the relevant transport techs. See [tech-tree-transport.md](tech-tree-transport.md).
- **Spy:** (1) **Presence reveal:** While a Spy is in a non-owner province, that province is fully visible to the Spy's owner; when the Spy leaves, the province returns to fogged after 5 turns (turn timer). (2) **steal_tech:** WorkOrder target = other GP's **capital province**; up to 5 turns; 8% per turn to steal a random tech the player does not have; completion or expiry clears work. (3) **counter_spy:** WorkOrder target = any **owned** province; each friendly Spy in that province adds 5% per turn (capped 30%) chance to kill an enemy Spy there. (4) **Invisibility:** Spy province locations are invisible to all players except the Spy's owner.
- **Merchant:** **purchase_land** WorkOrder: target = tile in Minor/Tribe province that has a resource; if resource requires prospecting, player must have prospected that tile; player must not be at war with that Minor/Tribe; cost = 15 × resource base price (treasury); requires **embassy** with that Minor/Tribe. Building a Merchant unit requires Merchant Companies tech; purchasing land requires embassy (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md)).

Multi-turn progress for all civilian work is tracked in the model and resolved during the Build/Work phase; `Unit.status` is **idle** or **working** only (on completion, status is set to idle). See [orders.md](../program/orders.md) and [development-resolution.md](../program/development-resolution.md).

---

## Relations

- **Unit** (type = civilian) → has owner (player id) and **location** = **tileKey** only (required, format `regionId|provinceId|x|y`); province and region are derived from tileKey. Work is ordered via WorkOrder (unitId, action, targetTileKey). Military and naval units do not have tileKey. See [fog-and-exploration.md](fog-and-exploration.md).
- **Province identity:** Civilian **location** (tileKey) and WorkOrder **targetTileKey** use the prefixed tile key format `regionId|provinceId|x|y`. Province and region for a civilian are derived from tileKey; any province lookup (e.g. for work cancel, build_port, steal_tech target) must use the full province id (`regionId|localId`). See [world-model-identity.md](world-model-identity.md).
- Civilian units have a **training cost**: cash is deducted from the player's **treasury** and paper from the player's **stockpile** when the unit is built. Work orders consume materials (lumber, metal, etc.) as defined in extraction-and-improvements and siege-mechanics. Materials are deducted when the work is **assigned** (during Build/Work phase application of WorkOrder); validation checks treasury/stockpile at order submit time.
- Civilian units do not eat food; they do not consume workers when built (unlike military/naval).

---

## Implementation

See [world-model.md](world-model.md) for Unit entity. Implementation scope: civilian types per this doc; military per [military-units.md](military-units.md).
