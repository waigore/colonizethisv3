# Province extraction display projection

**SPEC/program** — Display-time Extraction projection for the province Economic line. UI: [province-economic-extraction-available.md](../ui/province-economic-extraction-available.md). Formula: [extraction-and-improvements.md](../game/extraction-and-improvements.md). Refs #4064 (replaces last-turn history from #4002).

## Display model

`ProvinceExtractionSnapshot` is a **non-persisted** projection DTO (name retained for API stability):

| Field | Meaning |
|-------|---------|
| `ownerId` | Current province owner used when projecting |
| `byCommodity` | Commodity id → `{ effective, full, tileKeys }` |
| `capitalGrainBonus` | Units of `Game.capitalTileGrainBonusPerTurn` folded into grain (0 if none) |

`tileKeys` lists tiles that contributed to that commodity’s full or effective totals (deterministic sort). Capital grain bonus units have **no** tile key.

## Projection path (display-time)

When the province overlay needs Extraction for `provinceId`, the system projects from the **current post-resolution** `Game` + `tileMapByRegion` + connectivity (same inputs as Extraction phase yield math), **without** applying stockpile:

1. For each improved land tile (`improvementLevel ≥ 1`) owned by the **current** GP owner of `provinceId`, with extractable resource (minerals require prospected for that owner):
   - **full** = production = `min(improvementLevel, tech/terrain extraction cap)` clamped `[0, 4]`
   - **effective** = `0` when the tile is not capital-connected; else the shared effective-yield formula
   - Attribute only tiles in `provinceId`; record the tile key when `full > 0` or `effective > 0`
2. If `provinceId` is that owner’s capital and `capitalTileGrainBonusPerTurn = B > 0`, add B to grain **effective** and **full** (equal so bonus alone never creates brackets) and set `capitalGrainBonus = B`

**Draft orders:** Projection must not apply mid-turn draft improve/road/town orders.

**Scripted extraction override:** Stockpile may use scripted empire totals; this line remains formula projection from tiles (not stockpile delta).

## Next-level Build improvement display (Refs #4627)

`computeBuildImprovementYieldPreview` is display-only. It uses the same production / path / town-development math as extraction yield for current improvement and a hypothetical `improvementLevel + 1` (tech/terrain clamped). Level 0 tiles are previewed. Mid-turn drafts are ignored. It does not change Extraction phase totals.

## Persistence

`WorldState.lastTurnProvinceExtractionByProvinceId` is **removed**. Legacy saves that still contain the JSON key are ignored on load. Extraction phase does **not** write province Extraction display data.

## Available counts (not persisted)

Pure helper `provinceImprovableResourceTileCounts` over current world state after last resolution: for each province tile with a visible resource (minerals prospected for **owner**), count when `improvementLevel < extractionCapForResourceOnTerrain(owner tech, resource, terrain)`. Output keys follow `CommodityCatalog.all` order; include partially improved tiles still below cap. Not driven by draft orders.

## Acceptance criteria

- Given a post-resolution world with improved capital-connected tiles in province P, when the system projects Extraction for P, then the projection contains per-commodity effective, full, and tile keys matching the shared production/effective formula.
- Given an improved disconnected tile with production N in province P, when the system projects Extraction for P, then that commodity includes effective contribution `0` and full contribution `N` for that tile.
- Given capital province P with `capitalTileGrainBonusPerTurn = B > 0`, when the system projects Extraction for P, then grain effective and full each include B and `capitalGrainBonus` equals B.
- Given mid-turn draft improve/road/town orders, when the system projects Extraction, then quantities match the unresolved world state (drafts ignored).
- Given province P owned by GP A with improved extractable tiles, when ownership of P changes to GP B and the system projects Extraction for P, then the projection `ownerId` is B and B’s tile contributions appear immediately (no prior Extraction-phase write required); A’s capital grain bonus no longer applies unless P remains A’s capital.
- Given a legacy save JSON that still contains `lastTurnProvinceExtractionByProvinceId`, when the system loads the save, then the field is ignored and display uses projection instead.
- Given three improvable grain tiles and two improvable timber tiles under the owner’s tech/terrain caps, when Available counts are computed, then grain count is 3 and timber count is 2.
- Given an unprospected mineral tile, when Available counts are computed, then that tile is excluded.
