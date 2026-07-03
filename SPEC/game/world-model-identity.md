# Province Identity and Lookup (Multi-Region)

**SPEC/game** — Province identity rules for a multi-region world. Part of the GDD world model. See [world-model.md](world-model.md).

---

## Why Prefixed Province Ids

In a multi-region world, **province lookup must always use regionId + provinceId**. A bare province id is not sufficient: the same local id can exist in more than one region (e.g. `p1` in Old World and `p1` in New World).

---

## Game-State Province Id Format

All province ids stored in game state (e.g. Province id, Unit province location, Player capital, order fields) use a **prefixed** form: `regionId|localId` (e.g. `oldWorld|p1`, `newWorld|nw1`). This makes every province id globally unique and prevents a province from being resolved in the wrong region.

**Unit placement in code:** The [Unit](world-model.md) model’s public canonical field is `locationProvinceId` (tile-derived when `tileKey` is set). Saves use the JSON property `provinceId` as the serialized canonical value, not a second competing concept; `fromJson` may repair drift between `tileKey` and `provinceId` only when both values are canonical prefixed province ids.

**Load strictness for province-referencing fields:** Save/load must hard-fail when any province-referencing field carries an unprefixed local id. This includes persisted province ids in `Province.id`, `Unit.provinceId`, `Army.stationedProvinceId`, and capital or order province-id fields such as `Player.capitalProvinceId`, `MinorNation.capitalProvinceId`, `Tribe.capitalProvinceId`, `ArmyMoveOrder.destinationProvinceId`, and `BuildCivilianOrder.spawnProvinceId`.

---

## Tile Key Format

Tile keys remain 4-part: `regionId|localId|x|y`. The second segment is the **local** province id (as in topology/tile maps); the full province id is `regionId|localId`.

---

## Map Visualizer Identity Rules

When turning topology/tile maps into view models (ownership fill, per-player maps, unit markers), logic MUST first derive the full province id from the region + local id before reading any game state.

- **Ownership:** Convert region + local cell id (e.g. `oldWorld` + `p1`) into `oldWorld|p1` and use that full id to query province owner.
- **Province names:** Resolve full id (`oldWorld|p1` / `newWorld|p1`) into the corresponding Province and use its display name.
- **Unit markers:** Build a map from **full** province id (`regionId|localId`) to a representative tile (x, y), then place markers by looking up units via their province id (also full). Do not key these maps by bare local ids.

---

## Lookup Rule

Province lookup **MUST** be by **full disambiguated id** (`regionId|localId`). Resolution is **region-scoped**: the system resolves the province only within the region indicated by that id. Logic must never locate a province by bare local id when the region is unknown. Do **not** infer region by searching regions in sequence or by string heuristics. If a province cannot be found in the given region, treat it as a logic error; do not fall back to another region.

**API (required):** `getProvince` and `tryGetProvince` **require** a full, prefixed province id and resolve only within that region. Non-prefixed ids are invalid: `getProvince` throws; `tryGetProvince` returns null. There is no legacy short-id resolution—do not search regions by bare local id. `getProvinceByRegion` and `tryGetProvinceByRegion` accept explicit `(regionId, localId)` for region-scoped lookup. `resolveToFullProvinceId` accepts only prefixed ids and returns the id as-is; non-prefixed id throws.

---

## Acceptance Criteria

- Given a WorldState with at least one region `oldWorld` and one region `newWorld`, and each region has a province with local id `p1`  
  When the System constructs or stores province identifiers in game state  
  Then the System represents the Old World province as `oldWorld|p1`, represents the New World province as `newWorld|p1`, and never stores or emits a bare province id `p1` without its region prefix in any field that refers to a province.

- Given a WorldState that stores a military Unit whose location is a province, and that province belongs to region `oldWorld` with local id `p3`  
  When the System serializes or deserializes the Unit’s location  
  Then the System stores the Unit location as the full id `oldWorld|p3`, and on load it resolves `oldWorld|p3` only within the `oldWorld` region without scanning other regions for a matching local id.

- Given a tile key such as `newWorld|nw7|12|5` stored in WorldState or a save file  
  When the System interprets that tile key  
  Then the System treats `newWorld` as the region id, `nw7` as the local province id, and `12` and `5` as tile coordinates, and it derives the full province id `newWorld|nw7` from the first two segments for any province-level lookup.

- Given a map visualizer that is rendering a per-region tile map for region `oldWorld` and encounters a tile whose local province id is `p4`  
  When the visualizer queries ownership, province name, or unit markers for that tile  
  Then the visualizer first constructs the full province id `oldWorld|p4`, uses that full id to look up the Province and its owner in game state, and does not attempt to resolve `p4` in any other region.

- Given any game logic that is asked to resolve a province identifier and provided with a string that does not contain a `|` prefix separator or a pair of `(regionId, provinceId)` values that match a known province  
  When the System attempts to perform the lookup  
  Then the System treats the request as a logic error and does not fall back to a default region, does not guess a region by name pattern, and does not silently resolve the identifier to a different region’s province.

- Given a save payload where any province-referencing field stores an unprefixed local id (for example `p1` instead of `oldWorld|p1`)  
  When the System deserializes game-state models  
  Then the System fails load with an explicit validation error and does not auto-repair or infer a region prefix.


---

## Implementation (TDD)

**Modules:** colonizethis_models (Game, WorldState, Province, Unit, Player, ProvinceId); colonizethis_world `WorldStateProvinceLookup` extension (`world.getProvince`, `world.tryGetProvince`, `world.getProvinceByRegion`, `world.tryGetProvinceByRegion`, `world.resolveToFullProvinceId`). Map and province identity in program layer: [map-data.md](../program/map-data.md).

**Contract:** Lookup requires full disambiguated id or explicit (regionId, localId). No short-id resolution: `getProvince`, `tryGetProvince`, and `resolveToFullProvinceId` accept only prefixed ids (non-prefixed: getProvince/resolveToFullProvinceId throw, tryGetProvince returns null). Use prefixed id (`regionId|localId`) or `getProvinceByRegion`/`tryGetProvinceByRegion`. Resolution is region-scoped within the given region; the implementation does not search other regions.

**ProvinceId helper strictness:** `ProvinceId.regionIdFrom` and `ProvinceId.localIdFrom` both require a prefixed province id (`regionId|localId`) and throw for non-prefixed input. Boundary adapters that legitimately start from local ids must derive full ids explicitly (for example with `ProvinceId.full`) before game-state lookup.

**Save/load and topology alignment:** `ProvinceId.localSegmentFromStoredGameState` returns the local province id segment whether the stored value is prefixed or still a bare local id (legacy saves, topology node ids). Use it only in those boundary contexts—not for ambiguous runtime resolution.
