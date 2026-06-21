# Tile Map Generation: Algorithm (Passes 1–6)

**SPEC/program** — Generation pipeline for landmass, terrain, and mountains. Config: [tile-map-gen-config.md](tile-map-gen-config.md). Resources and provinces: [tile-map-gen-resources.md](tile-map-gen-resources.md). Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md).

---

## Responsibility

Generate per-region landmass and terrain (passes 1–6). One region (oldWorld or newWorld) at a time. Grid dimensions from config; see [tile-map-gen-config.md](tile-map-gen-config.md) § Grid size derivation.

---

## Grid operations and traversal (canonical)

All row-major tile-grid operations route through the single `TileMapGrid` helper (`packages/colonizethis_map/lib/src/tile_map_grid.dart`): deep copy (`TileMapGrid.copy`), allocation (`filled` / `generate`), and **cell traversal**.

- **Canonical cell walk:** Generation passes (and downstream view/render walks) visit grid cells via `TileMapGrid.forEachIndex(height, width, (y, x) {…})` or `TileMapGrid.forEachCell(grid, (y, x, value) {…})` instead of hand-rolled nested `for (var y …) { for (var x …) }` loops, so the **row-major order (`y` outer, `x` inner)** that seeded generation depends on for bit-for-bit determinism has one definition. A guard (`return`) inside the visit callback is equivalent to a `continue` in the original loop body.
- **Exemptions:** Passes whose correctness requires a non-row-major order (for example the **reversed** backward sweep of the Manhattan distance transform) keep their explicit loops and are documented inline.

These constraints are enforced by `repo.map_grid_ops_central` (and the cell-iteration lint family) — see [repo-lint.md](repo-lint.md).

---

## Voronoi assignment (reusable)

Used for land (Pass 3), province (Pass 9), and sea zone (Pass 11):

- **Input:** Cells (e.g. land cells), seeds (position + id). Optional: noise (scale + seed) for irregular boundaries.
- **Output:** Per cell, id of nearest seed by Euclidean distance (squared). Ties broken deterministically.

---

## Land assignment modes

- **Organic (default):** Interleaved seed placement and Voronoi; land grows round-by-round; continents separate; no outlier islands.
- **Seed-before-assignment (fallback):** Pass 2 + Pass 3; all land seeds first, then global Voronoi. Enabled via `--seed-before-assignment`.

---

## Algorithm (Passes 1–6)

1. **Pass 1 — Initialize grid:** All cells = sea zone id. Grid size from config.

2. **Pass 2 — Land seed placement (seed-before-assignment only):** One continent seed per continent. Per continent: cluster of land-shape seeds around it. **Cluster shape:** gaussian (default), uniformDisk, uniformAnnulus. Province-to-continent map partitions p1..pN across C continents (≈ N/C each). When organic: Pass 2–3 replaced by § Organic land assignment.

3. **Pass 3 — Land assignment (seed-before-assignment only):** Per-continent land budget. For each continent, assign closest `landBudget_c` cells to that continent's land-shape seeds. Voronoi noise (default on) perturbs distance for irregular boundaries.

**Organic land assignment:** Step 0: place continent seeds. Step 1 (per round): place one land seed per continent near existing land, away from others. Step 2: small-scale Voronoi; no cell within continent buffer of another continent's land. Step 3 (coastline growth): convert coastal sea to land (highest neighbour score, thickness-first), respecting buffer.

4. **Pass 4 — Fill lakes and moats:** **Ocean vs lake (normative, pre-fill grid, 4-neighbors only):** Partition all **sea** cells (`seaZoneId`) into **4-connected sea components**. For each component **C**, build **S** = set of continent ids: for every cell in **C**, each **in-grid** cardinal neighbor that is **land** maps to a continent id via the same rule as lake fill (`continentForLandCell` from land seeds / `continentBySeedIndex`). **Out-of-bounds** (map rectangle border) contributes **no** continent id to **S**. **Strait / non-lake sea:** if **|S| ≥ 2**, do not fill **C**. **|S| = 0** (no adjacent in-grid land): **C** is not fillable as a lake; do not fill. **Candidate lakes (|S| = 1):** Let **L** = legacy **boundary-reachable sea** (4-flood from any grid-edge sea cell through sea only — the pre-1864 ocean mask). Let **G** = { components **C** with **|S| = 1** and **C ∩ L ≠ ∅** }. **Fillable lake components:** all **|S| = 1** components **except** one **excluded exterior** component chosen as follows: if **|G| ≥ 2**, exclude the **largest** by cell count (tie-break: lexicographic min `(y,x)` over cells in **C**). If **|G| = 1** with component **C₀**, exclude **C₀** only when **total sea** cell count ≥ **48** **and** **|C₀| × 100 ≥ total sea × 80** (so the main exterior ocean on normal-sized maps is not drained when a single continent touches all boundary-reachable sea). **All** other **|S| = 1** components (including rim bays smaller than the excluded exterior, and any **|S| = 1** component disjoint from **L**) are filled to land (subject to existing coastal adjustment at end of lake fill). **Ocean** among sea cells = **{ all sea } \\ { union of fillable-lake components }**; **moat collapsing** uses this same ocean set. Skip lake fill **and** moat pass together via `--skip-fill-lakes`.

**Acceptance criteria (Pass 4 ocean/lake):**

- Given a sea **4-component** classified as **fillable** per §4 (**|S| = 1** and not the excluded exterior ocean component), when Pass 4 runs with default settings, then The System fills that component to land (including rim bays that were misclassified as open ocean under edge-flood-only rules; the excluded main exterior ocean is not drained).
- Given a sea **4-component** at the map border whose orthogonal **in-grid** land neighbors include **land mapped to ≥2 distinct continents**, when Pass 4 runs, then The System does **not** fill that component as a single-continent lake (strait preserved).
- Given the post-generation grid when Pass 4 is **not** skipped, when sea cells are classified by zone id `s*`, then every sea cell lies on a **4-neighbor path** of sea cells from **some** grid-edge sea cell (no enclosed sea pocket).
- Given `skipFillLakes: true`, when generation runs, then The System skips **both** lake fill and the moat pass (unchanged aggregate flag).

5. **Pass 5 — Border randomization:** If border noise > 0, apply boundary noise on land/sea.

6. **Pass 6 — Terrain assignment:**
   - **6a — Mountain ridges:** Assign `TerrainType.mountain` via ridge paths (random walks). Per-region mountain fraction from terrain rules.
   - **6b — Region-growing:** Non-mountain land: macro phase (large blobs by terrain), micro phase (smaller patches), optional pattern refinement (pockets inside blobs). Per-region terrain weights from colonizethis_data. Sea cells stay null terrain.
   - **6b.5 — Noise perturbation (post pattern refinement):** For each connected land component, per non-mountain terrain type, find blobs whose size is **>=** `patternMinBlobSize` (smaller blobs are skipped — pattern refinement already handles those). For each interior cell of each such blob (4-neighbour fully inside blob), evaluate a smooth 2D noise field from `deterministicNoise(seed, gx, gy)` using **bilinear interpolation** of corner samples taken on a fixed grid spacing of **4 cells** (corners at `(floor(x/4)*4, floor(y/4)*4)` and the three neighbours). A cell is changed iff `noise > (1.0 - terrainVariation)`; for noise uniformly distributed in `[-1, 1]` this yields an expected interior change fraction of `terrainVariation / 2` (~25% at `0.5`, ~50% at `1.0`). Replacement terrain is picked from the other allowed non-mountain terrains by their `TerrainDistribution.nonMountainFractions` weights. Mountains, blob edge cells, and small blobs are never modified. **Bypass:** When `terrainVariation == 0.0`, the pass returns immediately at entry without sampling noise, iterating blobs, or advancing the RNG, guaranteeing byte-identical output to pre-change behaviour. Runs **after** `_refineTerrainPatternsInComponent` in the per-component flow.
   - **6c — Hardwood forest clustering (forest split, issue #3573):** A bounded post-processing pass over each connected land component, run **after** Pass 6b.5. It nudges **isolated** `hardwoodForest` cells (no 4-neighbour hardwood cell) toward existing hardwood clusters using **reciprocal hardwood↔scrub swaps only**: an isolated hardwood cell exchanges terrain types with a `scrubForest` cell that is 4-adjacent to a hardwood cell other than the source. Each swap leaves the source as scrub and the target as hardwood, so the **per-terrain cell counts** (and the R6 1:4 hardwood:scrub ratio) are exactly preserved. Hardwood cells **never** swap with `plains`, `mountain`, or any non-scrub terrain. The pass is bounded by a fixed maximum iteration count (the component's hardwood cell count) so it cannot loop forever, and it **degrades gracefully**: when no eligible scrub cell exists for an isolated hardwood cell, that cell stays in place (some hardwood may remain isolated on maps with very few hardwood tiles). Components with fewer than two hardwood cells are skipped.

**Acceptance criteria (Pass 6c — hardwood clustering):**

- Given a generated map with at least four `hardwoodForest` cells in a component, when the System completes terrain assignment, then the large majority of `hardwoodForest` cells have at least one 4-adjacent `hardwoodForest` or `scrubForest` cell (hardwood tends to cluster rather than scatter as isolated single tiles).
- Given a generated map, when comparing per-terrain cell counts before and after Pass 6c, then the `hardwoodForest` count and the `scrubForest` count are each unchanged (Pass 6c performs only reciprocal hardwood↔scrub swaps; it never converts to or from plains, mountain, or other terrains).
- Given two map-generation runs with the same `seed` and params, when the System completes terrain assignment including Pass 6c, then both runs produce identical `terrainGrid`s (the clustering pass is deterministic per seed and bounded by a fixed iteration cap).

**Acceptance criteria (Pass 6b.5 — noise perturbation):**

- Given map-generation runs Pass 6 with `terrainVariation == 0.0` for any region and seed, when the System completes terrain assignment, then the resulting `TileMapResult` is byte-identical (same per-cell terrain, same per-cell resource) to a generation run produced by the legacy pre-Pass-6b.5 pipeline (no RNG drift introduced by Pass 6b.5).
- Given map-generation runs Pass 6 with `terrainVariation > 0.0` and any seed, when the System completes terrain assignment, then no `TerrainType.mountain` cell is reassigned to a different terrain type.
- Given map-generation runs Pass 6 with `terrainVariation > 0.0`, when the System completes terrain assignment, then for every cell that lies on the **edge** of a blob (any 4-neighbour outside the blob or out of grid), the System leaves that cell's terrain unchanged.
- Given map-generation runs Pass 6 with `terrainVariation > 0.0`, when the System completes terrain assignment, then any blob with size strictly less than `patternMinBlobSize` is left unchanged by Pass 6b.5.
- Given two map-generation runs with the same `seed` and `terrainVariation` value (and otherwise identical params), when the System completes terrain assignment, then both runs produce identical `terrainGrid`s (deterministic per seed).

---

## Integration

- **Upstream:** Config params from [tile-map-gen-config.md](tile-map-gen-config.md).
- **Downstream:** [tile-map-gen-resources.md](tile-map-gen-resources.md) (Pass 7+) consumes land and terrain grids.

---

## Implementation Structure (Orchestrator + Services)

The implementation SHOULD keep `TileMapGenerator` as an orchestration layer and extract pass-family logic into focused services with explicit inputs/outputs rather than hidden inheritance state. A compliant moderate extraction groups responsibilities as:

- `LandSeedService`: Pass 2-3 seed placement and land-shape assignment.
- `LakeAndProvinceService`: Pass 4, Pass 5, and Pass 8-9 lake/moat, border noise, and province assignment.
- `TerrainResourceService`: Pass 6-7 terrain and resource assignment helpers.
- `ContinentJoinPass`: Pass 10 continent joining (land bridges). `TerrainJitterPass`: Pass 10b per-province terrain jitter. `SeaZoneSubdividePass`: Pass 11 sea-zone subdivision. (Formerly a single `JoinAndSeaService`; split into three standalone `MapGenPass` families — Refs #3588.)
- Shared graph/connectivity helpers used by services.
- Shared terrain dominance helper `mostFrequentTerrain` (`gen/terrain_dominance.dart`): the single argmax over a `Map<TerrainType, int>` consumed by both the terrain-assignment cleanup (Pass 6–7) and the terrain-jitter pass (Pass 10b), so dominance-counting is not duplicated across passes (Refs #3588). On count ties it returns the first-inserted key among the maxima, preserving generation determinism.

The orchestration contract remains unchanged: pass ordering, pass semantics, and observable outputs must match this spec and [tile-map-gen-resources.md](tile-map-gen-resources.md).

### Uniform pass entry point

Generation service families share a single pass-driving protocol so the orchestrator does not duplicate per-family setup/logging:

- **`MapGenStage`** — base contract exposing shared `params`.
- **`MapGenPass<P, R>`** (extends `MapGenStage`) — uniform entry `R run(MapGenPassContext<P> ctx)`, where `MapGenPassContext` carries `params`, the family's typed `payload` (`P`), and an optional `onLog` hook (`log(message)`).

Because the families have heterogeneous input/output shapes, each supplies its own typed payload/result rather than a single concrete signature. **At least three families** must adopt `MapGenPass`. The former multi-pass **join-sea** family (previously `MapGenStage`-only and documented as exempt) is split into three standalone single-pass families that each adopt `MapGenPass` with their own typed payload/result (Refs #3588): `ContinentJoinPass` (Pass 10, `ContinentJoinPassPayload` → `ContinentJoinPassResult`), `TerrainJitterPass` (Pass 10b, `TerrainJitterPassPayload` → `void`, in-place terrain mutation), and `SeaZoneSubdividePass` (Pass 11, `SeaZoneSubdividePassPayload` → `SeaZoneSubdividePassResult`). Together with land-seeds (Pass 2–3), lakes/provinces (Pass 4–5 lake/moat + border noise), and terrain/resource (Pass 6–7), all bound families now adopt `MapGenPass`. Adoption is enforced by `repo.map_gen_stage_protocol` (see [repo-lint.md](repo-lint.md)). `run` is behaviour-preserving: routing a pass through `run` produces byte-identical grids to the prior inline orchestration for the same inputs.

**Acceptance criteria (uniform pass entry):**

- Given a generator service family that owns a cohesive grid-in/grid-out pass, when the repository lint `repo.map_gen_stage_protocol` runs, then The System requires that family to declare `implements MapGenPass` and requires at least 3 bound families to do so, otherwise the lint fails.
- Given `TileMapGenLandSeeds.run` is invoked with a `MapGenPassContext` whose payload sets `seedBeforeAssignment = true` and an RNG seeded with value `s`, when the pass completes, then The System returns the same `grid`, `continentSeeds`, `landSeeds`, and `continentBySeedIndex` as the legacy `placeLandSeeds` + `assignLandByLandSeeds` calls made with a freshly `s`-seeded RNG.
- Given a `MapGenPassContext` with a `null` `onLog`, when `context.log(message)` is called, then The System performs no action and does not throw.
- Given a non-empty `Map<TerrainType, int>` of terrain counts, when `mostFrequentTerrain(counts)` is called, then The System returns the `TerrainType` with the strictly greatest count.
- Given terrain counts where two or more terrains share the greatest count, when `mostFrequentTerrain(counts)` is called, then The System returns the first-inserted key among those tied maxima (deterministic for a fixed insertion order).

---

## Constraints

- Grid dimensions derived; no topology input. Province identity assigned in later passes.
