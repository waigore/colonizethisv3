# Capital Choice Phase

**SPEC/game** — Phase before game start where each Great Power chooses their capital. Reference: [capital-and-connectivity.md](capital-and-connectivity.md). Topology: [map-topology.md](map-topology.md). Factions: [factions.md](factions.md).

---

## When and Who

The **capital-choice phase** runs **before the game starts**, as a distinct setup phase. It applies to **Great Powers only**. Each Great Power (or scenario) chooses their capital. Minor Nations and Tribes do not participate; their capitals are assigned during game setup (see [game-setup.md](game-setup.md)). In multiplayer, order of choice can be defined by scenario or lobby rules.

---

## Constraint

For **Great Powers**, the chosen province must be **sea-bound**: the topology must have at least one P<->S edge for that province. This ensures the capital can participate in sea transport (auto port or port on coast). Minor Nations and Tribes may have inland capitals; they do not use extraction or connectivity.

---

## Choice

The player selects a **province** and a **tile** within that province (e.g. by (x, y) in the region’s tile map). The tile must belong to the selected province.

---

## Effect

- Set **Player.capitalProvinceId** and **Player.capitalTile** (or equivalent key) in game state.
- **Auto-build:** If the capital tile is adjacent to sea, build a **capital port** on that tile. Otherwise, build a **port** on a tile in that province that is closest to the capital tile and adjacent to sea, and build a **road** from that port tile to the capital tile (shortest path on province tiles).
- Persist in game state so extraction and connectivity use it each turn.

Phase 2: capital choice may be implemented as scenario-only or stub if UI is deferred. The stub is **auto-choice during setup** (no UI): the game-setup pipeline runs the capital auto-choice algorithm below so every faction has a capital; a future UI can let Great Powers confirm or override.

---

## Auto-choice (game setup)

When the UI is deferred, capitals are set automatically during game setup. The algorithm runs once per faction (Great Powers, then Minor Nations, then Tribes) inside the build-state step of the game-setup pipeline.

**Inputs** (all from earlier pipeline steps):

- **Per faction:** List of owned province ids and the **region id** for those provinces (from province assignment).
- **Per region:** MapTopology and TileMapResult for that region (from map generation). Keys: e.g. `oldWorld`, `newWorld`. Referred to as **topologyByRegion** and **tileMapByRegion**.
- **Game** in the state after build-state: WorldState with Province.ownerId set; Game.players (and Game.minorNations, Game.tribes when implemented).

**Algorithm** (deterministic, per faction):

1. **Choose province:**
   - **Great Powers:** From the faction’s owned provinces, keep only those that are **sea-bound** (topology has at least one P–S edge). Pick one deterministically (e.g. first when provinces are sorted by id). If none is sea-bound, assignment is invalid (setup must assign at least one sea-bound province per GP).
   - **Minor Nations and Tribes:** Prefer sea-bound if available; otherwise use any owned province. Pick one deterministically (first when provinces are sorted by id).
2. **Choose tile (with border-avoidance heuristic):** Using the region’s TileMapResult, find a tile (x, y) in the chosen province (cell(x, y) == provinceId). Classify candidate tiles:
   - **Class A:** tiles that are **coastal** (adjacent to a sea cell) and **not orthogonally adjacent to any other province** (orthogonal neighbours are only same province or sea).
   - **Class B:** tiles that are **interior** (not coastal) and **not orthogonally adjacent to any other province** (all orthogonal neighbours are same province).
   - **Class C:** all remaining tiles in the province.
   - **Great Powers:** pick the first tile in **Class A** (row-major scan) if any; otherwise the first in **Class B**; otherwise the first in **Class C**. This preserves the sea-bound/coastal preference while avoiding placing capitals directly on province borders when possible.
   - **Minor Nations and Tribes:** apply the same Class A → B → C preference but without requiring the province to be sea-bound or the chosen tile to be coastal.
3. **Apply capital and port/road:** Build CapitalTile(regionId, provinceId, x, y). For **Great Powers** (and for Minor Nations/Tribes when the province is sea-bound): validate sea-bound, update WorldState (tileState, portsByProvinceSeaboard) with port/road auto-build, and set the faction's capitalProvinceId and capitalTile. For **Minor Nations and Tribes** with an inland province: skip port/road auto-build; only set capitalProvinceId and capitalTile on the MinorNation/Tribe record. The border-avoidance heuristic is **purely aesthetic**; it does not change connectivity rules or extraction behaviour.

**Dependencies:** isProvinceSeaBound(topology, provinceId) and setCapital (or equivalent) in colonizethis_logic. When applying for a province in regionId, use topologyByRegion[regionId] and tileMapByRegion.

A later UI capital-choice phase can allow Great Powers to confirm or override the auto-chosen capital.
