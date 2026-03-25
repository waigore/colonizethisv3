# Extraction and Improvements

## Overview

Per-tile resource extraction using improvements, constrained by tech level and transport infrastructure. Civilian work orders build improvements, roads, ports, and railroads. Province and tile identity (e.g. owned provinces, tile keys, town and port lookup) follow [world-model-identity.md](world-model-identity.md): extraction and connectivity use **tile keys** (format `regionId|localId|x|y`) and **province ids** (prefixed `regionId|localId`); province lookup must be region-scoped.

---

## Rules

### Province and tile identity

Extraction and connectivity use **tile keys** (format `regionId|localId|x|y`) and **province ids** (prefixed `regionId|localId`). Province lookup must be region-scoped; see [world-model-identity.md](world-model-identity.md).

### Extraction Formula

Each land tile in an owned province may have one extraction improvement (mine, farm, ranch, plantation, fur post, town, etc.) with an improvement level (0–4) and at most one resource (terrain-constrained per [resource-terrain-region-rules.md](resource-terrain-region-rules.md)).

**Production** = min(improvement level, owner's tech-allowed max level).
**Effective yield** = min(production, transport level, **town development level**, **transport level along path to town and to capital**). See [capital-and-connectivity.md](capital-and-connectivity.md) for town and connectivity.

Tech caps first, then transport caps. Example: level 4 farm, tech cap 3, transport 2 → 2 units/turn. The improvement stays at level 4; tech/transport upgrades or conquest can unlock more later.

### Improvement Naming

Improvement **names** are purely descriptive; they do **not** change extraction rules or yields, which continue to follow the formula above. The UI derives the displayed name from the tile's **resource id**, independent of improvement level:

| Resource id (or group) | Default improvement name |
|------------------------|--------------------------|
| `grain`                | Farm                     |
| `meat`, `horses`       | Ranch                    |
| `wool`                 | Pasture                  |
| `timber`               | Lumber camp              |
| `sugarCane`, `tobacco`, `cotton`, `spices` | Plantation  |
| `furs`                 | Fur post                 |
| `iron`, `copper`, `tin`, `coal`, `silver`, `gold`, `gems`, `diamonds` | Mine |

If a tile has **no resource id** (e.g. development-only tile in a future ruleset), the improvement name is `Improvement` by default. UI layers **may** append the numeric level for clarity (e.g. `Farm (L2)`), but the canonical base name is given by the table above.

Acceptance criteria (naming only):

- Given a land tile with resource id `gold` and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Mine` for that tile, regardless of the value of \(N\)

- Given a land tile with resource id `grain` and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Farm` for that tile, regardless of the value of \(N\)

- Given a land tile with resource id `furs` and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Fur post` for that tile, regardless of the value of \(N\)

- Given a land tile with no resource id and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Improvement` for that tile

### Town and extraction

Each province has one **town** tile assigned at game init (see [capital-and-connectivity.md](capital-and-connectivity.md) § Town per province). A tile's resources are extractable only if the tile is **connected to the province's town** (path of road/rail/port to the town) and the town is connected to the capital. **Town development level** (raised by Builder `upgrade_town` work) and the **transport level** along the path limit extraction. If multiple paths exist from a tile to the capital, the **maximum** transport level path determines the cap.

### Mineral Prospecting Gate

Iron, copper, tin, coal, silver, gold, gems, diamonds require prospecting before extraction. Tile must be (a) connected and (b) prospected by that player. Non-minerals do not require prospecting. See [fog-and-exploration.md](fog-and-exploration.md).

### Transport Level (Per Tile)

**Road level** (the value stored per tile for roads/railroads/ports) is the **transport level** used in the formula "effective yield = min(production, transport level)". Each land tile has transport level in {0, 1, 2, 4}:

- **0** — not connected.
- **1** — primitive road.
- **2** — improved road (requires Road Construction tech + Engineer work order).
- **4** — port or railroad (requires Early Steam Engine and related techs + Engineer/Rail Builder work order).

Tech only **allows** building — it does not upgrade existing tiles. Ports and railroads both provide level 4. Railroads are a tech-gated road type; for connectivity they function like roads (tiles with road/railroad form paths). No separate "railroad" connectivity rule. Adjacent port tile grants level 4 to that tile. See [tech-tree-transport.md](tech-tree-transport.md), [capital-and-connectivity.md](capital-and-connectivity.md).

### Flow to Stockpile

Connected tiles' effective yields are summed by commodity. **Same-region:** added to owning player's stockpile. **Overseas:** sea transport step (cargo limit + priority). No per-province storage. See [stockpiles-and-production.md](stockpiles-and-production.md).

### Improvement Build Eligibility (Builder)

A Builder may build an improvement on a tile only if: (a) the tile has a **resource** (per terrain/ruleset; no improvement on empty tiles), (b) the tile's improvement level is below the **max improvement level** (4), and (c) the **next** improvement level (current + 1) does not exceed the player's **tech-allowed extraction cap** (see [tech-and-extraction-cap.md](tech-and-extraction-cap.md)). The order engine rejects build_improvement work orders when the tile has no resource or when the player lacks sufficient tech to build the next level.

### Improvement Build Costs (Builder)

| Level | Material Cost | Output |
|---|---|---|
| 1 | 1 lumber + 1 cast iron | 1 resource/turn |
| 2 | 4 lumber + 4 cast iron | 2 resources/turn |
| 3 | 8 lumber + 8 cast iron | 3 resources/turn |
| 4 | 16 lumber + 16 cast iron | 4 resources/turn |

### Road Costs (Engineer)

1 lumber + 1 cast iron per tile (transport level 1). **Improved road (level 2):** requires **Road Construction** tech; validation and completion must check tech before setting road level to 2.

### Railroad Costs (Rail Builder)

2 lumber + 2 steel per tile (authoritative values in `work_order_costs.dart` / ruleset config).

### Port Placement

One port per seaboard (seaboard = one sea zone adjacent to the province). Province with two seaboards: overseas connectivity requires a port on the seaboard with a sea path to the capital's sea.

### Fort Costs

See [siege-mechanics.md](siege-mechanics.md).

1 extra turn per build level, capped at 3 turns.

### Commodities in the Game

Extractable commodities are exactly the same as in Imp2. See [commodity-catalog.md](commodity-catalog.md).

---

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| Max improvement level | 4 | |
| Transport levels | 0, 1, 2, 4 | |
| Improvement cost scaling | 1, 4, 8, 16 per level | lumber + cast iron |
| Road cost | 1 lumber + 1 cast iron | Per tile |

---

## Interactions

- Province and tile identity: [world-model-identity.md](world-model-identity.md)
- Connectivity: [capital-and-connectivity.md](capital-and-connectivity.md)
- Stockpile flow: [stockpiles-and-production.md](stockpiles-and-production.md)
- Transport tech: [tech-tree-transport.md](tech-tree-transport.md)
- Fog/prospecting: [fog-and-exploration.md](fog-and-exploration.md)
- Development resolution: see program/development-resolution.md
- Tile generation: [tile-map-and-generation.md](tile-map-and-generation.md)

---

## Acceptance Criteria

- Given a land tile with improvement level N (0-4) in an owned province
  When the system computes extraction for that tile
  Then the production equals min(N, owner's tech-allowed max level for that terrain/resource)

- Given a land tile with improvement level N and transport level T in an owned province that is connected to a town with development level D
  When the system computes effective yield for that tile
  Then the effective yield equals min(N, T, D, transport level along path to town and capital)

- Given a player attempts to build a level 2 road (transport level 2) on a tile
  When the system validates the build_road work order
  Then the system checks that the player has the Road Construction tech; if not, the order is rejected

- Given a tile with a resource that requires prospecting (iron, copper, tin, coal, silver, gold, gems, or diamonds)
  When the system evaluates whether that resource can be extracted
  Then the system requires both (a) the tile is connected to a town and (b) the player has prospected that tile

- Given a player submits a build_improvement work order for a tile that has no resource (resource id missing or empty)
  When the order engine validates the work order
  Then the system rejects the order with reason that the tile has no resource

- Given a player submits a build_improvement work order for a tile whose next improvement level (current + 1) would exceed the player's tech-allowed extraction cap
  When the order engine validates the work order
  Then the system rejects the order with reason that the player lacks sufficient tech to build the next level

- Given a Builder civilian unit completes a build_improvement work order on a tile
  When the system applies the work effect
  Then the tile's improvement level increases by 1, up to the tech-allowed max for that terrain/resource

- Given a Builder civilian unit completes an upgrade_town work order on a province's town tile
  When the system applies the work effect
  Then the province's town development level increases by 1

- Given an Engineer civilian unit completes a build_road work order on a tile with transport level 0 or 1
  When the system applies the work effect
  Then the tile's transport level is set to 1 (or 2 if the player has Road Construction tech)

- Given a Rail Builder civilian unit completes a build_rail work order on a land tile with transport level 1 or 2, per-tile terrain is available from the tile map, and the player has the transport technology required for that terrain per [tech-tree-transport.md](tech-tree-transport.md)
  When the system applies the work effect
  Then the tile's transport level is set to 4 (railroad) and 2 lumber and 2 steel are consumed for that work order per ruleset cost

- Given a player submits a build_rail work order when the tile has transport level 0, or terrain data is missing for that tile, or the player lacks the rail tech required for that tile's terrain
  When the system validates the work order at submit time
  Then the system rejects the order with a clear reason

- Given a player has multiple paths from a tile to the capital
  When the system computes transport level cap for that tile's extraction
  Then the system uses the maximum transport level among all valid paths

- Given a province has a town on a port tile adjacent to a sea zone
  When the system evaluates connectivity for overseas extraction
  Then that province is considered connected via sea transport using that port

- Given a tile's improvement level, transport level, or town development level changes
  When the next production phase runs
  Then extraction recalculates using the updated values
