# Tile Map and Map Generation

**SPEC/game** — Tile map (per-region 2D grid) and tile-based map generation. See [world-model.md](world-model.md) for provinces and tiles; [map-topology.md](map-topology.md) for topology.

---

## Tile map

A **tile map** is the 2D grid for **one region**. Each cell is assigned to a **province** or **sea zone** (by id). Each **land** cell has a **terrain type** and an optional **resource** (at most one). Resource placement must satisfy **region** (oldWorld only, newWorld only, or both) and **terrain** (allowed terrain types per resource) rules. Improvements (extraction level, road) are **mutable** and stored in world state; the tile map holds static terrain and resource (and optional initial improvement state for scenarios). The grid is per region; the world has one tile map per region, not one global grid.

---

## Map generation

The tile map is generated for **one region** (oldWorld or newWorld) at a time. Terrain and resource rules use this **map-level region**, not per-province. Province identity is assigned in the **final** pass (Voronoi on land) so province borders are smooth.

Map-first is the **only** generation method. Input = province count (N), continent count (C), region, map params. Land shape and province assignment use N and C; topology is **inferred** from the grid after Voronoi (Pass 9), optional join (Pass 10), and sea zone subdivision (Pass 11). **Each continent should have a similar number of provinces** (≈ N/C); this is achieved by partitioning province ids across continents and by using similar land budget and land seeds per continent in Pass 2–3, so Pass 9 (province assignment) naturally yields balanced province sizes.

Adjacency and strategic layout are **emergent** from the grid; no topology verification (topology = grid by construction). Future enhancement = separate procedural land generation; for now land-shape pipeline stays unchanged.

Requirements:

- Shapes and borders are semi-random (e.g. Voronoi-style), not fixed templates.
- **Province size target:** Average tiles per province is configurable (~30–40); **grid size** is chosen so the generated map respects this target.
- **Terrain:** **Terrain types differ by region** (Old World vs New World per canonical table). Terrain assignment must use only **terrain types allowed for that region**; assignment must produce **contiguous blobs** (e.g. hill ranges, forest/plains clusters), not per-cell random splotches. Implementation and region–terrain rules live in colonizethis_data.
- Generation must assign terrain and at most one resource per tile respecting region and terrain rules, and must control resource spawn rates so distribution is in inverse proportion to default market price (TDD 04b).

Input: province count (N), continent count (C), region, map params (target tiles per province, grid size or derived size, seed, border noise). Output: per-region 2D grid (tile → province/sea zone id, terrain, optional resource) and **inferred topology**. A map generation tool may export a PNG: cells colored by terrain type (sea = deep blue), land borders as black lines, sea zone borders as light blue, **region ids in red** on each tile for identification, and a legend mapping colors to terrain (and Sea). **Tile size** is configurable for readability. Full contract: SPEC/program/map-data.md § Tile map PNG export.

---

## Algorithm spec

Generation is a **multi-pass pipeline**: **land seeds** = one **continent seed** per continent plus a **cluster** of land-shape seeds around it (count derived from province count; **Gaussian jitter** by default, cluster shape configurable). **Per-continent land budget** and optional **Voronoi noise** for irregular boundaries. Fill lakes; terrain and resources by **map region** (before provinces); **province seeds on land**; **province assignment** (Pass 9) uses the same **Voronoi assignment** as sea zones. Optional **join step** after Pass 9 when a continent has multiple land components (carve land bridges). **Sea zone subdivision** (Pass 11) uses the same Voronoi assignment; sea zones are capped at a max fraction of total sea (e.g. 5%). **Topology inference** runs after all passes (including join). Full pass list and Voronoi contract: [SPEC/program/tile-map-generation.md](../program/tile-map-generation.md) § Multi-pass pipeline and § Voronoi assignment. When the CLI generates a map, it can print **detailed generation logs** per pass (pass name and key stats). The ideas doc ([SPEC/ideas/tile-based-map-generation.md](../../ideas/tile-based-map-generation.md)) is reference/sample only for design and implementation.
