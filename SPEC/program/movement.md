# Movement

**SPEC/program** — Movement rules and validation. Reference: [SPEC/game/map-topology.md](../game/map-topology.md), [SPEC/game/military-armies.md](../game/military-armies.md), [turn-resolution.md](turn-resolution.md), [world-model-identity.md](../game/world-model-identity.md).

---

## Province identity (world-model-identity)

`MoveOrder` / `ArmyMoveOrder` `destinationProvinceId` and unit `provinceId` (game state) must use **prefixed** form (`regionId|localId`). See [SPEC/game/world-model-identity.md](../game/world-model-identity.md). The map `tileKeysByRegionAndProvince[regionId]` is keyed by **prefixed** province id (as built in game setup). Validation uses **local** ids for topology lookups; game state and orders use **prefixed** ids.

---

## Scope

**Land movement — civilians:** Civilian **units** move between **provinces** only (P<->P), via `MoveOrder`.

**Land movement — military:** **Armies** move between provinces; each `ArmyMoveOrder` moves **all** regiments in that army together ([orders.md](orders.md)). The Home Army **cannot** leave the capital province ([military-armies.md](../game/military-armies.md)).

**Movement within the player's own provinces:** A move whose **destination province is owned by the ordering player** is **always allowed**. There is **no adjacency requirement**, **no cargo capacity requirement**, and **no region restriction** — the mover may go from any owned province to any other owned province anywhere in the world (same landmass, across seas, or across regions such as Old World ↔ NewWorld). This applies to **civilian units** and to **armies** (non-Home). These moves resolve **instantaneously** in the Movement phase: units are at their destination province at the end of that phase with no intermediate locations. Movement into provinces **not** owned by the player remains subject to adjacency and other rules below.

**Naval movement (Phase 5+):** Fleets move between **sea zones** (S<->S or P<->S for ports). Destination = sea zone id. Ship reveal runs when fleet enters sea zone. See [naval-movement-resolution.md](naval-movement-resolution.md).

---

## Adjacency

**Valid destination (when destination is not owned by the mover):** a province that is **adjacent** to the **current** province (civilian unit or army station) in the **map topology**. Topology (nodes = provinces and sea zones; edges = P–P, P–S) is loaded from **colonizethis_data**. TurnResolver and order validation use the same graph. Land military moves only along P–P edges (province to province). When the destination province **is** owned by the ordering player, adjacency is **not** required (see § Movement within the player's own provinces).

**Multi-region / duplicate local ids:** When topology contains multiple regions, local province ids are not globally unique (e.g. `p1` may exist in both oldWorld and newWorld). Adjacency for land movement is **region-scoped**: neighbors are computed only among nodes in the **same region** as the **unit or army**. Use `neighborProvinceIdsInRegion(topology, regionId, localProvinceId)` and `isValidLandMoveInRegion(topology, regionId, fromLocal, toLocal)` so moves are validated and applied per region. See [world-model-identity.md](../game/world-model-identity.md).

---

## Validation

Before applying a move order:

- **Civilian land:** Destination must be a **province** (not sea zone). If the destination province is **owned by the ordering player**, the move is valid regardless of adjacency **or region**. Otherwise the destination must be **adjacent** (P<->P edge) within the same region as the unit.
- **Army land:** Same as civilian, but the mover is the **army**; reject if army is the **Home Army** and destination is not the capital province. If the destination province is **owned by the ordering player**, the move is valid regardless of adjacency **or region**. Otherwise the destination must be **adjacent** within the same region as the army’s current province.
- **Naval (Phase 5+):** Destination must be a **sea zone**; must be adjacent to current sea zone (S<->S or P<->S).

Invalid moves are rejected; unit/army location unchanged.

---

## Resolution

TurnResolver runs a **movement** step that applies validated **civilian** `MoveOrder`s and **ArmyMoveOrder`s (and naval orders). **Application order:** Deterministic. Orders are applied by **player** (iteration order per TDD), then by **order list index** within each player. This defines determinism and replay. See [turn-resolution-phases.md](turn-resolution-phases.md).

- **Civilian units:** Set the unit’s **tileKey** to a valid tile in the **destination province** (e.g. first tile in `tileKeysByRegionAndProvince[regionId][fullProvinceId]` where destination is in prefixed form); set unit **provinceId** to that prefixed id.
- **Armies:** For each regiment id in the army, set **provinceId** to the destination (prefixed; no tileKey). Update the army’s **stationed province** to the same id.
- **Naval:** Movement remains at sea zone / fleet level; no tileKey for ships.

---

## Acceptance criteria

Given a player owns three provinces `oldWorld|p1`, `oldWorld|p2`, and `oldWorld|p3` connected by a line topology (`p1`–`p2`–`p3`), and controls a **non-Home** army `A` stationed at `oldWorld|p1` whose regiments all have `provinceId = oldWorld|p1`  
When the player submits an `ArmyMoveOrder` for `A` with `destinationProvinceId = oldWorld|p3` and the order is accepted  
Then during the Movement phase the system updates every regiment in `A` to `provinceId = oldWorld|p3` and sets army `A`’s stationed province to `oldWorld|p3` in a single turn even though `p1` and `p3` are not adjacent, with no intermediate provinces.

Given a player owns province `oldWorld|p1` in the Old World region and province `newWorld|p2` in the New World region, and controls a **non-Home** army `A` at `oldWorld|p1` with both provinces fully visible to that player  
When the player submits an `ArmyMoveOrder` for `A` with `destinationProvinceId = newWorld|p2` and the order is accepted  
Then during the Movement phase the system moves all regiment ids in `A` from the Old World unit list to the New World unit list with `provinceId = newWorld|p2`, updates `A`’s stationed province to `newWorld|p2`, and the move succeeds in one turn regardless of adjacency or sea/region separation.

Given a player controls a **non-Home** army `A` in province `oldWorld|p1` and attempts to move it to province `oldWorld|p3` that is not owned by the player and not adjacent in the topology  
When the player submits an `ArmyMoveOrder` with `destinationProvinceId = oldWorld|p3`  
Then the system rejects the order during validation, the Movement phase leaves every regiment in `A` at `oldWorld|p1`, and the army’s stationed province remains `oldWorld|p1`.

Given a player controls a civilian unit `c1` with `tileKey = regionId|provinceLocalId|x|y` in province `oldWorld|p1`, and `tileKeysByRegionAndProvince[oldWorld][oldWorld|p2]` contains at least one tile key for destination province `oldWorld|p2` that the player owns  
When the player submits a `MoveOrder` for `c1` to `oldWorld|p2` and the order is accepted  
Then during the Movement phase the system updates `c1.provinceId` to `oldWorld|p2`, sets `c1.tileKey` to one of the tile keys listed for `oldWorld|p2`, and leaves `c1` unchanged if the order is later rejected.

Given a player owns province `oldWorld|p1` in the Old World region and province `newWorld|p2` in the New World region, and controls a civilian unit `c1` at `oldWorld|p1` with `tileKeysByRegionAndProvince[newWorld][newWorld|p2]` containing at least one tile key and both provinces fully visible  
When the player submits a `MoveOrder` for `c1` with `destinationTileKey` set to a tile in `newWorld|p2` and the order is accepted  
Then during the Movement phase the system removes `c1` from the Old World unit list, adds `c1` to the New World unit list with `provinceId = newWorld|p2`, sets `c1.tileKey` to one of the tile keys for `newWorld|p2`, and the move completes in a single turn without any intermediate positions.

Given the OrderEngine validates **civilian** `MoveOrder` and **ArmyMoveOrder** instances for a player in a world with region-scoped topology and prefixed province ids  
When it evaluates a sequence of those orders against the current `Game` and `MapTopology`  
Then it accepts any **civilian** or **army** move whose destination province is owned by that player (including cross-region moves), rejects non-adjacent moves into provinces the player does not own, rejects **Home Army** moves whose destination is not the capital province, rejects orders for units or armies that do not exist or are not owned by the player, and uses local province ids only for topology lookups while storing and comparing province ids in prefixed form.

---

## Civilian tile moves (issue #1877; program implementation)

Civilian `MoveOrder` is **`destinationTileKey` only** on the wire; the enclosing province is derived from the tile key. **No map-topology adjacency** is used for civilian move validation or move suggestions. Legality uses the shared **`civilianMayOccupyLandTileKey`** helper (`packages/colonizethis_logic` — `civilian_tile_occupancy.dart`): tile-level purchaser override (`purchasedTilesByTileKey`), then province `ownerId` (Spy may enter another Great Power’s province-derived land without a war/diplomacy gate for movement). The Movement phase applies civilian moves via **`applyCivilianTileMoveOrdersToWorldRegions`**; **`applyMoveOrdersToRegion` is a no-op** for civilian move payloads. **`filterMoveOrdersByDiplomacy`** does not strip civilian moves (legality is enforced by the order engine and occupancy rules).

Until the narrative sections above are fully reconciled with GDD/TDD, treat this subsection as the **authoritative program behavior** for civilian tile movement.
