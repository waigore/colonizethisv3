# Extraction and Improvements

## Overview

Per-tile resource extraction using improvements, constrained by tech level and transport infrastructure. Civilian work orders build improvements, roads, ports, and railroads. Province and tile identity (e.g. owned provinces, tile keys, town and port lookup) follow [world-model-identity.md](world-model-identity.md).

---

## Rules

### Extraction Formula

Each land tile in an owned province may have one extraction improvement (mine, farm, ranch, plantation, fur post, town, etc.) with an improvement level (0–4) and at most one resource (terrain-constrained per [resource-terrain-region-rules.md](resource-terrain-region-rules.md)).

**Production** = min(improvement level, owner's tech-allowed max level).
**Effective yield** = min(production, transport level, **town development level**, **transport level along path to town and to capital**). See [capital-and-connectivity.md](capital-and-connectivity.md) for town and connectivity.

Tech caps first, then transport caps. Example: level 4 farm, tech cap 3, transport 2 → 2 units/turn. The improvement stays at level 4; tech/transport upgrades or conquest can unlock more later.

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

2 lumber + 2 cast iron per tile

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
| Improvement cost scaling | ×2 per level | lumber + cast iron |
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
