# Tile Map Generation: Config and Parameters

**SPEC/program** — Configurable parameters, seed handling, grid derivation. Algorithm: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Resources: [tile-map-gen-resources.md](tile-map-gen-resources.md). Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md).

---

## Responsibility

Define map-generation inputs, configurable parameters, and grid size derivation.

---

## Input

- **Province count (N), continent count (C), region id, sea zone id (default s1).** One region per run. Province identity assigned in final passes; terrain/resource use map-level region.
- **Resource rules (optional).** When provided, Pass 6–7 run; result includes terrain and resource grids. For init_game, caller must pass resource rules (e.g. `ResourceRules.defaultRules`).
- **Map params:** Target tiles per province, sea fraction (0–1), max sea zone fraction (default 0.05), random seed, border noise, cluster shape (gaussian/uniformDisk/uniformAnnulus), Voronoi noise (default on), continent buffer tiles (default 2; `--continent-buffer N`), skip fill lakes (`--skip-fill-lakes`), join continents (`--join-continents`).

---

## Configurable parameters (TileMapParams)

**Pass 6a (mountain ridges):** Mountain ranges factor, min/max, min length per ridge.
**Pass 6b (region-growing):** Terrain seeds factor, min/max, terrain macro fraction.
**Pass 6b (pattern refinement):** Pattern min blob size, max fraction per blob, seed factor, max seeds per blob, max changes per seed, max radius.
**Pass 6b.5 (noise perturbation):** `terrainVariation` (range `0.0`–`1.0`, **default `0.5`**) — controls the expected interior-cell change fraction (`terrainVariation / 2` for noise uniformly distributed in `[-1, 1]`). `0.0` bypasses the pass entirely (byte-identical legacy output, no RNG advance). `1.0` perturbs ~50% of eligible interior cells. Operates only on blobs of size `>= patternMinBlobSize`; never modifies mountains or blob-edge cells.
**Pass 10b (jitter):** Jitter homogeneity threshold, max fraction, probability, min province size, neighbour support threshold.
**Pass 7:** Multi-region resource cap fraction (default 0.30).

---

## Grid size derivation

**Inputs:** N, target tiles per province, C, sea fraction. **Derived:** Provinces per continent = N/C; continent size ≈ provinces per continent × target tiles per province; total land = N × target tiles per province; total grid = total land / (1 − sea fraction). **Dimensions:** From total grid and aspect ratio (e.g. 4:3), compute width/height (min 8×8).

---

## Output

Per-region 2D tile map: region id, type (land/water), terrain, optional resource. Inferred MapTopology from `TileMapResult.adjacentRegionPairs()`.

---

## Integration

Implemented in colonizethis_map. Consumed by App (game/scenario load), tools. Tile maps static per map/scenario; not persisted in save.

---

## Constraints

- Grid dimensions derived; no topology input. The archived document [SPEC/archive/tile-based-map-generation.md](../archive/tile-based-map-generation.md) is non-normative historical background; this spec and tile-map-gen-algorithm.md are authoritative.
