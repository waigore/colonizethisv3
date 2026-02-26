# Movement

**SPEC/program** — Movement rules and validation. Reference: [SPEC/game/map-topology.md](../game/map-topology.md), [turn-resolution.md](turn-resolution.md), [world-model-identity.md](../game/world-model-identity.md).

---

## Province identity (world-model-identity)

MoveOrder `destinationProvinceId` and unit `provinceId` (game state) must use **prefixed** form (`regionId|localId`). See [SPEC/game/world-model-identity.md](../game/world-model-identity.md). The map `tileKeysByRegionAndProvince[regionId]` is keyed by **prefixed** province id (as built in game setup). Validation uses **local** ids for topology lookups; game state and orders use **prefixed** ids.

---

## Scope

**Land movement:** Units move between **provinces** only (P<->P).

**Naval movement (Phase 5+):** Fleets move between **sea zones** (S<->S or P<->S for ports). Destination = sea zone id. Ship reveal runs when fleet enters sea zone. See [naval-movement-resolution.md](naval-movement-resolution.md).

---

## Adjacency

**Valid destination:** a province that is **adjacent** to the unit's current province in the **map topology**. Topology (nodes = provinces and sea zones; edges = P–P, P–S) is loaded from **colonizethis_data**. TurnResolver and order validation use the same graph. Armies move only along P–P edges (province to province).

**Multi-region / duplicate local ids:** When topology contains multiple regions, local province ids are not globally unique (e.g. `p1` may exist in both oldWorld and newWorld). Adjacency for land movement is **region-scoped**: neighbors are computed only among nodes in the **same region** as the unit. Use `neighborProvinceIdsInRegion(topology, regionId, localProvinceId)` and `isValidLandMoveInRegion(topology, regionId, fromLocal, toLocal)` so moves are validated and applied per region. See [world-model-identity.md](../game/world-model-identity.md).

---

## Validation

Before applying a move order:

- **Land units:** Destination must be a **province** (not sea zone); must be **adjacent** (P<->P edge).
- **Naval (Phase 5+):** Destination must be a **sea zone**; must be adjacent to current sea zone (S<->S or P<->S).
- Optional: movement points, passable terrain, or blocking (e.g. enemy) — per design; can be stubbed.

Invalid moves are rejected; unit location unchanged.

---

## Resolution

TurnResolver runs a **movement** step that applies validated move orders. **Application order:** Deterministic. Orders are applied by **player** (iteration order of `moveOrdersByPlayerId`), then by **order list index** within each player. This defines determinism and replay. See [turn-resolution-phases.md](turn-resolution-phases.md).

- **Civilian units:** Set the unit’s **tileKey** to a valid tile in the **destination province** (e.g. first tile in `tileKeysByRegionAndProvince[regionId][fullProvinceId]` where destination is in prefixed form); set unit **provinceId** to that prefixed id.
- **Military units:** Update the unit’s **provinceId** to the destination (prefixed; no tileKey).
- **Naval:** Movement remains at sea zone / fleet level; no tileKey for ships.

---

## Acceptance criteria

- **Land movement:** Destination is adjacent (P–P); unit `provinceId` is updated to the destination (prefixed). For civilian units, `tileKey` is set to a tile in the destination when `tileKeysByRegionAndProvince` and `regionId` are provided. Invalid moves leave unit location unchanged.
- **Validation (order engine):** Rejects non-adjacent, wrong unit/owner, and visibility violations; uses the same topology as resolution. Province id: validation uses **local** ids for topology; game state and orders use **prefixed** ids (see [world-model-identity.md](../game/world-model-identity.md)).
- **Province id:** Stored and looked up using prefixed form; `tileKeysByRegionAndProvince[regionId]` is keyed by prefixed province id.
