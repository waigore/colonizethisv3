# Movement

**SPEC/program** — Movement rules and validation. Reference: [SPEC/game/map-topology.md](../game/map-topology.md), [turn-resolution.md](turn-resolution.md), [world-model-identity.md](../game/world-model-identity.md).

---

## Province identity (world-model-identity)

MoveOrder `destinationProvinceId` and unit `provinceId` (game state) must use **prefixed** form (`regionId|localId`). See [SPEC/game/world-model-identity.md](../game/world-model-identity.md). The map `tileKeysByRegionAndProvince[regionId]` is keyed by **prefixed** province id (as built in game setup). Validation uses **local** ids for topology lookups; game state and orders use **prefixed** ids.

---

## Scope

**Land movement:** Units move between **provinces** only (P<->P).

**Movement within the player's own provinces:** A move whose **destination province is owned by the ordering player** is **always allowed**. There is **no adjacency requirement**, **no cargo capacity requirement**, and **no region restriction** — the unit may move from any owned province to any other owned province anywhere in the world (same landmass, across seas, or across regions such as Old World ↔ NewWorld). This applies to both military and civilian units. These moves resolve **instantaneously** in the Movement phase: units are at their destination province at the end of that phase with no intermediate locations. Movement into provinces **not** owned by the player remains subject to adjacency and other rules below.

**Naval movement (Phase 5+):** Fleets move between **sea zones** (S<->S or P<->S for ports). Destination = sea zone id. Ship reveal runs when fleet enters sea zone. See [naval-movement-resolution.md](naval-movement-resolution.md).

---

## Adjacency

**Valid destination (when destination is not owned by the mover):** a province that is **adjacent** to the unit's current province in the **map topology**. Topology (nodes = provinces and sea zones; edges = P–P, P–S) is loaded from **colonizethis_data**. TurnResolver and order validation use the same graph. Armies move only along P–P edges (province to province). When the destination province **is** owned by the ordering player, adjacency is **not** required (see § Movement within the player's own provinces).

**Multi-region / duplicate local ids:** When topology contains multiple regions, local province ids are not globally unique (e.g. `p1` may exist in both oldWorld and newWorld). Adjacency for land movement is **region-scoped**: neighbors are computed only among nodes in the **same region** as the unit. Use `neighborProvinceIdsInRegion(topology, regionId, localProvinceId)` and `isValidLandMoveInRegion(topology, regionId, fromLocal, toLocal)` so moves are validated and applied per region. See [world-model-identity.md](../game/world-model-identity.md).

---

## Validation

Before applying a move order:

- **Land units:** Destination must be a **province** (not sea zone). If the destination province is **owned by the ordering player**, the move is valid regardless of adjacency **or region**. Otherwise the destination must be **adjacent** (P<->P edge) within the same region as the unit.
- **Naval (Phase 5+):** Destination must be a **sea zone**; must be adjacent to current sea zone (S<->S or P<->S).

Invalid moves are rejected; unit location unchanged.

---

## Resolution

TurnResolver runs a **movement** step that applies validated move orders. **Application order:** Deterministic. Orders are applied by **player** (iteration order of `moveOrdersByPlayerId`), then by **order list index** within each player. This defines determinism and replay. See [turn-resolution-phases.md](turn-resolution-phases.md).

- **Civilian units:** Set the unit’s **tileKey** to a valid tile in the **destination province** (e.g. first tile in `tileKeysByRegionAndProvince[regionId][fullProvinceId]` where destination is in prefixed form); set unit **provinceId** to that prefixed id.
- **Military units:** Update the unit’s **provinceId** to the destination (prefixed; no tileKey).
- **Naval:** Movement remains at sea zone / fleet level; no tileKey for ships.

---

## Acceptance criteria

Given a player owns three provinces `oldWorld|p1`, `oldWorld|p2`, and `oldWorld|p3` connected by a line topology (`p1`–`p2`–`p3`), and controls a land unit `u1` at `oldWorld|p1`  
When the player submits a `MoveOrder` for `u1` with `destinationProvinceId = oldWorld|p3` and the order is accepted  
Then during the Movement phase the system updates `u1.provinceId` to `oldWorld|p3` in a single turn even though `p1` and `p3` are not adjacent, and `u1` does not occupy any intermediate province at the end of the turn.

Given a player owns province `oldWorld|p1` in the Old World region and province `newWorld|p2` in the New World region, and controls a land unit `u1` at `oldWorld|p1` with both provinces fully visible to that player  
When the player submits a `MoveOrder` for `u1` with `destinationProvinceId = newWorld|p2` and the order is accepted  
Then during the Movement phase the system removes `u1` from the Old World unit list, adds `u1` to the New World unit list with `provinceId = newWorld|p2`, and the move succeeds in one turn regardless of adjacency or sea/region separation.

Given a player controls a land unit `u1` in province `oldWorld|p1` and attempts to move it to province `oldWorld|p3` that is not owned by the player and not adjacent in the topology  
When the player submits a `MoveOrder` with `destinationProvinceId = oldWorld|p3`  
Then the system rejects the order during validation, the Movement phase leaves `u1.provinceId` unchanged at `oldWorld|p1`, and no intermediate movement is applied.

Given a player controls a civilian unit `c1` with `tileKey = regionId|provinceLocalId|x|y` in province `oldWorld|p1`, and `tileKeysByRegionAndProvince[oldWorld][oldWorld|p2]` contains at least one tile key for destination province `oldWorld|p2` that the player owns  
When the player submits a `MoveOrder` for `c1` to `oldWorld|p2` and the order is accepted  
Then during the Movement phase the system updates `c1.provinceId` to `oldWorld|p2`, sets `c1.tileKey` to one of the tile keys listed for `oldWorld|p2`, and leaves `c1` unchanged if the order is later rejected.

Given a player owns province `oldWorld|p1` in the Old World region and province `newWorld|p2` in the New World region, and controls a civilian unit `c1` at `oldWorld|p1` with `tileKeysByRegionAndProvince[newWorld][newWorld|p2]` containing at least one tile key and both provinces fully visible  
When the player submits a `MoveOrder` for `c1` with `destinationProvinceId = newWorld|p2` and the order is accepted  
Then during the Movement phase the system removes `c1` from the Old World unit list, adds `c1` to the New World unit list with `provinceId = newWorld|p2`, sets `c1.tileKey` to one of the tile keys for `newWorld|p2`, and the move completes in a single turn without any intermediate positions.

Given the OrderEngine validates move orders for a player in a world with region-scoped topology and prefixed province ids  
When it evaluates a sequence of `MoveOrder` instances for that player against the current `Game` and `MapTopology`  
Then it accepts any move whose destination province is owned by that player (including cross-region moves), rejects non-adjacent moves into provinces the player does not own, rejects moves for units that do not exist or are not owned by the player, and uses local province ids only for topology lookups while storing and comparing province ids in prefixed form.
