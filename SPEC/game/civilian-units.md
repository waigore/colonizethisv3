# Civilian Units

**SPEC/game** — All six civilian unit types and their roles. Derived from GDD 05, TDD 05. Reference: Imperialism II 03-units-civilian (GDD).

---

## Overview

**The game supports all six civilian types** per Imperialism II 03-units-civilian: Explorer, Engineer, Builder, Spy, Merchant, Rail Builder. Civilian units are map units — they deploy, move, and work on terrain. They are distinct from workers (population for industry; see [workers-and-population.md](workers-and-population.md)).

---

## Civilian Types and Roles

| Unit | Role | Cost | Unlock | Special |
|------|------|------|--------|---------|
| **Explorer** | Explore fog of war; prospect for minerals | Free | Starting | Minerals must be prospected before extraction; free exploration and prospecting |
| **Engineer** | Build roads, ports, fortifications | Lumber + metal (cast iron/bronze/steel) | Starting | Roads gather resources; ports and forts in cities/rivers |
| **Builder** | Improve terrain production (mines, farms, ranches, plantations, fur posts, towns) | Lumber + cast iron | Starting | Increases output 1→2→3→4; tech caps max level |
| **Spy** | Scout garrison strength; steal technology; defensive counter-spy | Free | Starting | Must be assigned to province; invisible to enemies |
| **Merchant** | Purchase land in Minor Nations/Tribes and New World | Cash | Merchant Companies tech, embassy | Creates economic control; protects New World province from invasion |
| **Rail Builder** | Upgrade roads to railroads | Steel + lumber | Early Steam Engine tech | Rail transports up to 4 resources per tile |

---

## Work Types and Multi-Turn Builds

- **Explorer work:** Uses `WorkOrder` targets `explore` and `prospect`. Explore is **province-level** and completes over multiple turns per [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md); prospect is **tile-level** (one tile per completed order).
- **WorkOrder** specifies both an **action** (e.g. `build_improvement`, `build_road`) and a **target tile** (`targetTileKey`). Civilians can move to and act on a tile different from their current tile (Imperialism-style).
- **Builder work:** Uses `WorkOrder` targets `build_improvement` and `upgrade_town`. Each completed order increases the tile's improvement level by 1 (or upgrades a town) after a **multi-turn build** whose duration increases with target level and terrain; costs and turn counts derive from Imperialism II (e.g. Level 1 cheaper/faster than Level 4). See [extraction-and-improvements.md](extraction-and-improvements.md) and [development-resolution.md](../program/development-resolution.md).
- **Engineer work:** Uses `WorkOrder` targets `build_road`, `build_port`, and `build_fort`. Each completed order constructs or upgrades transport/fortification on the **target tile** after one or more turns, consuming lumber and metal per [02-economy](../../Obsidian/obsidian-shared/Projects/ColonizeThisV3/Imperialism II/02-economy.md) mirrored in ruleset config.
- **Rail Builder work:** Uses `WorkOrder` target `build_rail`. Each completed order upgrades an existing road tile to railroad (transport level 4) over multiple turns, costing steel + lumber; only available after the relevant transport techs. See [tech-tree-transport.md](tech-tree-transport.md).

Multi-turn progress for all civilian work is tracked in the model and resolved during the Build/Work phase; `Unit.status` reflects whether a civilian is idle, working, or done for the turn. See [orders.md](../program/orders.md) and [development-resolution.md](../program/development-resolution.md).

---

## Relations

- **Unit** (type = civilian) → has owner (player id) and **location** = **tileKey** only (required, format `regionId|provinceId|x|y`); province and region are derived from tileKey. Work is ordered via WorkOrder (unitId, action, targetTileKey). Military and naval units do not have tileKey. See [fog-and-exploration.md](fog-and-exploration.md).
- Civilian units consume construction costs (paper, cash, lumber, metal) from player stockpile when built.
- Civilian units do not eat food; they do not consume workers when built (unlike military/naval).

---

## Implementation

See [world-model.md](world-model.md) for Unit entity. Implementation scope: civilian types per this doc; military per [military-units.md](military-units.md).
