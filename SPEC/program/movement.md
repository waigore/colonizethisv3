# Movement

**SPEC/program** — Movement rules and validation. Reference: [SPEC/game/map-topology.md](../game/map-topology.md), [turn-resolution.md](turn-resolution.md).

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

TurnResolver runs a **movement** step that applies validated move orders. Order of application (e.g. by player, by unit) is deterministic. See [turn-resolution-phases.md](turn-resolution-phases.md).

- **Civilian units:** Set the unit’s **tileKey** to a valid tile in the **destination province** (e.g. first tile in `tileKeysByRegionAndProvince[regionId][order.destinationProvinceId]`); province is derived from tileKey.
- **Military units:** Update the unit’s **provinceId** to the destination (no tileKey).
- **Naval:** Movement remains at sea zone / fleet level; no tileKey for ships.
