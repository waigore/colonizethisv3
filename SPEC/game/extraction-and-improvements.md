# Extraction and Improvements

## Overview

Per-tile resource extraction using improvements, constrained by tech level and transport infrastructure. Civilian work orders build improvements, roads, ports, and railroads.

---

## Rules

### Extraction Formula

Each land tile in an owned province may have one extraction improvement (mine, farm, ranch, plantation, fur post, town, etc.) with an improvement level (0–4) and at most one resource (terrain-constrained per [resource-terrain-region-rules.md](resource-terrain-region-rules.md)).

**Production** = min(improvement level, owner's tech-allowed max level).
**Effective yield** = min(production, transport level).

Tech caps first, then transport caps. Example: level 4 farm, tech cap 3, transport 2 → 2 units/turn. The improvement stays at level 4; tech/transport upgrades or conquest can unlock more later.

### Mineral Prospecting Gate

Iron, copper, tin, coal, silver, gold, gems, diamonds require prospecting before extraction. Tile must be (a) connected and (b) prospected by that player. Non-minerals do not require prospecting. See [fog-and-exploration.md](fog-and-exploration.md).

### Transport Level (Per Tile)

Each land tile has transport level in {0, 1, 2, 4}:

- **0** — not connected.
- **1** — primitive road.
- **2** — improved road (requires Road Construction tech + Engineer work order).
- **4** — port or railroad (requires Early Steam Engine and related techs + Engineer/Rail Builder work order).

Tech only **allows** building — it does not upgrade existing tiles. Ports and railroads both provide level 4. Adjacent port tile grants level 4 to that tile. See [tech-tree-transport.md](tech-tree-transport.md).

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

1 lumber + 1 cast iron per tile (transport level 1). Improved road: requires Road Construction tech.

### Port Placement

One port per seaboard (seaboard = one sea zone adjacent to the province). Province with two seaboards: overseas connectivity requires a port on the seaboard with a sea path to the capital's sea.

### Fort Costs

See [siege-mechanics.md](siege-mechanics.md).

> **REQUIRES CLARIFICATION:** (a) Exact turn duration per build level (Imp2 implies ~1 turn per level but doesn't state explicitly). (b) Railroad material costs (Imp2 says "steel and lumber per tile" but no exact amounts). (c) Whether ColonizeThis adapts the exact Imp2 material types or uses its own commodity catalog.

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

- Connectivity: [capital-and-connectivity.md](capital-and-connectivity.md)
- Stockpile flow: [stockpiles-and-production.md](stockpiles-and-production.md)
- Transport tech: [tech-tree-transport.md](tech-tree-transport.md)
- Fog/prospecting: [fog-and-exploration.md](fog-and-exploration.md)
- Development resolution: see program/development-resolution.md
- Tile generation: [tile-map-and-generation.md](tile-map-and-generation.md)
