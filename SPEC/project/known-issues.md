# Known issues

**SPEC/project** — Issues to tackle after the main development phases. When addressing them, implementation must stay spec-aligned (GDD/TDD and SPEC are source of truth).

---

## Issues

| # | Issue | Description | Features / modules | Date raised | Remarks | Status |
|---|------|-------------|--------------------|-------------|---------|--------|
| 1 | ~~Splotchy terrain~~ | ~~Plains, forests, hills appear scattered; should form contiguous blobs (e.g. hill ranges, forest clusters).~~ | ~~Map generation, terrain assignment; Pass 6; [tile-map-and-generation.md](../game/tile-map-and-generation.md), [tile-map-generation.md](../program/tile-map-generation.md). colonizethis_data: `terrain_region_rules`; colonizethis_map: tile map generator.~~ | ~~2026-02-15~~ | ~~GDD requires "contiguous blobs"; current Pass 6 does not fully achieve this. Consider region-growing or similar clustering.~~ | Closed |
| 2 | ~~Terrain distribution~~ | ~~Percentages of terrain types (plains, forest, hills, etc.) need tuning for better balance.~~ | ~~Map generation, Pass 6; terrain weights/config in colonizethis_data; generator in colonizethis_map.~~ | ~~2026-02-15~~ | ~~Tune weights or add explicit target fractions per region.~~ | Closed |
| 3 | Ring islands | For some params (e.g. `--continents 4`), continents sometimes have ring-shaped islands around them. | Map generation; Pass 2–4, organic land assignment, coastline growth, optional join. colonizethis_map: topology_generator, land assignment. | 2026-02-15 | Investigate seed placement or coastline-growth order; may need constraint to avoid rings. | Pending |
| 4 | Province assignment | Province boundaries are purely Voronoi-based; natural barriers (e.g. mountains) should influence province definition. | Map generation; Pass 9, Voronoi assignment. colonizethis_map: `grid_voronoi`, province seed placement, tile map generator. | 2026-02-15 | Extend spec § Voronoi assignment; consider terrain-weighted distance or post-pass split along mountain chains. | Pending |
| 5 | Flutter upgrade available | Flutter reports a new version is available; banner suggests running `flutter upgrade`. | Tooling, dev environment; root and app use Flutter SDK. | 2026-02-15 | Follow up when convenient: run `flutter upgrade`, then `flutter pub get` and verify build/tests. See release notes for breaking changes. | Pending |
| 6 | Terrain blob size | Terrain blob sizes need to be further fine-tuned: make them smaller so the generated map looks more interesting and varied. | Map generation, Pass 6; TileMapParams (terrain seeds, pattern refinement, macro fraction); colonizethis_map. | 2026-02-16 | Tune terrainSeedsFactor, terrainMacroFraction, patternMaxFractionPerBlob or add more variation; params are now configurable. | Pending |

Further issues may be added as new rows using the same columns (including #, Date raised in yyyy-MM-dd, and Status).
