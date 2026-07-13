# Province last-turn extraction snapshot

**SPEC/program** — Persisted per-province Extraction display data written during the Extraction phase. UI contract: [province-economic-extraction-available.md](../ui/province-economic-extraction-available.md). Formula source: [extraction-and-improvements.md](../game/extraction-and-improvements.md).

## Field home

`WorldState.lastTurnProvinceExtractionByProvinceId`: map keyed by **prefixed** province id (`regionId|localId`).

Each value is `ProvinceExtractionSnapshot`:

| Field | Meaning |
|-------|---------|
| `ownerId` | Province owner at snapshot write time |
| `byCommodity` | Commodity id → `{ effective, full, tileKeys }` |

`tileKeys` lists tiles that contributed to that commodity’s full or effective totals (deterministic sort). Capital grain bonus units have **no** tile key.

## Write path

During normal `runExtractionPhase` (empty `extractedByPlayerId`), after connectivity resolve and in the same pass as `computeExtraction`, the system **rewrites** this map for Great Power provinces:

1. For each improved land tile (`improvementLevel ≥ 1`) owned by a GP, with extractable resource (minerals require prospected for that owner):
   - **full** = production = `min(improvementLevel, tech/terrain extraction cap)` clamped `[0, 4]`
   - **effective** = `0` when the tile is not capital-connected; else the shared effective-yield formula (transport then town-cap branches)
   - Attribute to the tile’s province; record the tile key when `full > 0` or `effective > 0`
2. Add `Game.capitalTileGrainBonusPerTurn` to the capital province’s grain **effective** and **full** (equal so bonus alone never creates brackets)

**Scripted override:** When `extractedByPlayerId` is non-empty, clear `lastTurnProvinceExtractionByProvinceId` to empty (no tile-accurate brackets from empire totals). See [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § Extraction override.

## Read / display gate

UI and helpers show a province snapshot only when `province.ownerId == snapshot.ownerId`. Otherwise treat as missing → Extraction `—` until the next normal Extraction write for the new owner.

## Save / load

JSON key `lastTurnProvinceExtractionByProvinceId`. Missing / null → empty map (legacy saves). Round-trip preserves effective, full, tileKeys, and ownerId.

## Available counts (not persisted)

Pure helper `provinceImprovableResourceTileCounts` over current world state after last resolution: for each province tile with a visible resource (minerals prospected for **owner**), count when `improvementLevel < extractionCapForResourceOnTerrain(owner tech, resource, terrain)`. Output keys follow `CommodityCatalog.all` order; include partially improved tiles still below cap. Not driven by draft orders.

## Acceptance criteria

- Given a normal Extraction phase completes with improved connected tiles, when the system finishes the phase, then `WorldState.lastTurnProvinceExtractionByProvinceId` contains per-province aggregates with effective, full, and tile keys for contributing tiles.
- Given an improved disconnected tile with production N, when the snapshot is built, then that commodity includes effective contribution `0` and full contribution `N` for that tile.
- Given `extractedByPlayerId` is non-empty, when Extraction runs, then `lastTurnProvinceExtractionByProvinceId` is empty afterward.
- Given a saved game with a non-empty snapshot map, when the system loads the save, then the snapshot map matches the pre-save values.
- Given a legacy save without the field, when loaded, then the map is empty.
- Given province ownership changed since the snapshot was written, when display resolves the snapshot, then the system returns no snapshot for that province (UI shows `—`).
- Given three improvable grain tiles and two improvable timber tiles under the owner’s tech/terrain caps, when Available counts are computed, then grain count is 3 and timber count is 2.
- Given an unprospected mineral tile, when Available counts are computed, then that tile is excluded.
