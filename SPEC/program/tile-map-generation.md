# Tile-Based Map Generation

**SPEC/program** — Algorithm and contract for generating a per-region tile map. Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). Reference/sample (not spec): [SPEC/ideas/tile-based-map-generation.md](../ideas/tile-based-map-generation.md).

---

## Input

- **Province count (N), continent count (C), region id, sea zone id (default s1).** The initial sea zone id is used only until Pass 11; after Pass 11 the grid may contain multiple sea zone ids (s1, s2, …). No topology input. The map is generated for **one region** (oldWorld or newWorld) at a time. Terrain and resource rules use this **map-level region**; it is not per-province. Province identity is assigned in a final pass and is not used for terrain/resource.
- **Map generation parameters (centralized):** **Target tiles per province** (average land tiles per province, e.g. 30–40). **Sea fraction** (0–1; fraction of grid that is sea, e.g. 0.6 for 60:40 sea:land). **Max sea zone fraction** (default 0.05): no sea zone may contain more than this fraction of **total sea tiles**; used in Pass 11 to subdivide large sea components. **Random seed**, **border noise** (0–1). **Cluster shape** (configurable): how land-shape seeds are placed around each continent seed — **gaussian** (default), **uniformDisk**, **uniformAnnulus**. **Voronoi noise** (default on): when assigning land by distance in Pass 3, a small deterministic noise may be added so boundaries are less regular; scale/strength implementation-defined. **Continent buffer tiles** (default 2): minimum Manhattan distance from another continent's land when assigning land in organic mode. Use **`--continent-buffer N`** in CLI. 0 = legacy 1-tile check; 1+ = check all cells within Manhattan distance N. **Skip fill lakes:** when true, Pass 4 is skipped (no lake-to-land conversion). Use **`--skip-fill-lakes`** in CLI or via orchestration options (e.g. `InitGameOptions.skipFillLakes` in `init_game`). Default: false. **Join continents:** when enabled, after Pass 9 an optional join step runs if a continent has multiple land components. The generate_map CLI defaults this to off; use **`--join-continents`** to enable. Grid width/height are **derived** from N, C, and params; see § Grid size derivation.

### Configurable parameters for Pass 6 and Pass 10b

The following parameters control terrain assignment (Pass 6a, 6b) and province-aware jitter (Pass 10b). They are exposed on the map generation config used by the generator (implementation: **TileMapParams** in colonizethis_map). Defaults are implementation-defined and tuned for moderate blob size and internal variation.

- **Pass 6a (mountain ridges):** **Mountain ranges factor** — scale for number of ridge paths (~ factor × √target mountain tiles), clamped. **Mountain ranges min/max** — clamp on number of ranges. **Mountain range min length** — minimum tiles per ridge.
- **Pass 6b (region-growing):** **Terrain seeds factor** — scale for seeds per terrain (~ factor × √target), clamped. **Terrain seeds min/max** — clamp on seeds per terrain type. **Terrain macro fraction** — fraction of per-continent terrain target filled in the macro phase (remainder in micro phase).
- **Pass 6b (pattern refinement):** **Pattern min blob size** — minimum connected blob size (tiles) to consider for refinement. **Pattern max fraction per blob** — maximum fraction of a blob's tiles that may be converted to another terrain. **Pattern seed factor** — scale for pattern seeds per blob (~ factor × √blob size). **Pattern max seeds per blob** — hard cap on pattern seeds per blob. **Pattern max changes per seed** — cap on tiles converted per pattern seed. **Pattern max radius** — BFS radius limit from each pattern seed within the blob.
- **Pass 10b (jitter):** **Jitter homogeneity threshold** — minimum fraction of a province's tiles that must be one terrain for the province to be eligible for jitter. **Jitter max fraction** — maximum fraction of a province's tiles that may be changed by jitter. **Jitter probability** — per-candidate probability to apply jitter. **Jitter min province size** — minimum province tile count for jitter. **Jitter neighbor support threshold** — minimum number of neighboring tiles of the new terrain (in same province) required to apply a change.

### Grid size derivation

**Inputs:** Province count (N), target tiles per province, continent count (C), sea fraction. **Derived:** Provinces per continent = N / C; continent size (tiles) ≈ provinces per continent × target tiles per province; total land tiles = N × target tiles per province; total grid tiles = total land tiles / (1 − sea fraction). **Dimensions:** From total grid tiles and aspect ratio (e.g. 4:3), compute width and height with minimum bounds (e.g. 8×8).

---

## Output

- **Per-region 2D tile map** — Each cell has a region id (province or sea zone) and type (land/water). Land cells have **terrain type** and optional **resource**; resource placement obeys region and terrain constraints. Resource spawn rates across the region are controlled so distribution is in **inverse proportion to default market price** (see TDD 04b).
- **Inferred MapTopology** — Nodes from unique grid region ids with type province/seaZone; edges from `TileMapResult.adjacentRegionPairs()`.

---

## Voronoi assignment (reusable)

A single contract is used for land (Pass 3), province (Pass 9), and sea zone (Pass 11) assignment:

- **Input:** An explicit set of **cells** (e.g. land cells, or cells of one sea component), and a set of **seeds** each with position (x, y) and an **id** (e.g. province id, sea zone id, or continent index). Optional: **noise** (scale + seed) added to distance for irregular boundaries.
- **Output:** For each cell in the eligible set, the **id of the nearest seed** by Euclidean distance (squared for performance). Ties broken deterministically (e.g. by seed id order).
- **Reuse:** Land assignment keeps per-continent budget and no-join constraints in the generator; the nearest-seed core can call this. Province assignment = Voronoi over land cells with province seeds. Sea zone subdivision = Voronoi over each oversized sea component with seeds placed inside that component.

---

## Land assignment modes

- **Organic (default):** Interleaved seed placement and Voronoi; land grows round-by-round; continents stay separate; no outlier islands. See § Organic land assignment.
- **Seed-before-assignment (fallback):** Original Pass 2 + Pass 3; all land seeds placed first, then one global Voronoi. Enabled via **`--seed-before-assignment`**.

---

## Multi-pass pipeline

Generation runs in eleven passes in order. Province seeds are placed on the land so that Voronoi-on-land naturally produces province boundaries; no path carving.

1. **Pass 1 — Initialize grid (all sea):** All cells = sea zone id. Grid dimensions from § Grid size derivation.
2. **Pass 2 — Land seed placement (seed-before-assignment only):** Place **one continent seed** per continent (e.g. center or random in that continent's horizontal band). For each continent, generate a **cluster** of **land-shape seeds** around that continent seed. **Similar land budget per continent** (derived from N) so land blobs are balanced. **Similar number of land seeds per continent** support this. **Cluster shape:** default **Gaussian jitter** (continent seed + random offset, clipped to band); other options **uniform disk**, **uniform annulus** selectable via cluster shape parameter. When **organic** mode is used, Pass 2–3 are replaced by § Organic land assignment.

**Province-to-continent map:** Partition p1..pN across C continents so **each continent gets a similar number of provinces** (≈ N/C, remainder distributed).

**Visualization callbacks:** The generator may invoke an optional callback with (1) **land seed positions** and (2) a **parallel list of continent indices** (0, 1, …) for visualization.

3. **Pass 3 — Land assignment (seed-before-assignment only):** **Per-continent land budget:** total land budget allocated per continent (proportional to province count). For each continent, assign to **land** (sentinel) the closest `landBudget_c` cells to **that continent's** land-shape seeds only; each cell assigned at most once. **Voronoi noise (default on):** when ranking cells by distance, use a perturbed distance so boundaries are irregular.

### Organic land assignment

When organic mode is used (default), Pass 2–3 are replaced by the following steps:

- **Step 0:** Place continent seeds (same as Pass 2).
- **Step 1 (per round):** For each continent needing a seed, place one land seed **close to** that continent's existing land (or continent seed if none), **preferably away from** other continents' seeds.
- **Step 2 (per round):** Run a small-scale Voronoi (limited land budget per round); **do not** assign a cell to continent c if any cell within **continent buffer** tiles (Manhattan) is already land of another continent.
- Repeat until all required land seeds are placed.
- **Step 3 (coastline growth, thickness-first):** If land budget remains, grow coastlines by repeatedly picking a **coastal sea cell** (sea 4-adjacent to land of that continent) and converting it to land, subject to the continent buffer. For each candidate coastal sea cell, compute a **land-neighbour score** over a local neighborhood (radius ≈ 3 in grid space): count nearby land tiles belonging to the same continent and strongly penalize or discard candidates that are adjacent to land of **other** continents. At each step, select the candidate with the **highest score** (breaking ties randomly) that does **not** bring land within continent buffer of another continent, flip it to land for that continent, and update the candidate set. This prioritizes thickening bays and coves (high local land density) before extending long, thin tendrils into open ocean. Stop when budget is exhausted or no valid moves remain.

4. **Pass 4 — Fill lakes and moats:** Runs only when skip fill lakes is false. Ocean = sea cells connected to the grid boundary (flood-fill from edges). Lake = sea not in ocean. **Continent-aware lakes:** before filling a lake, determine which continents border it (land cells 4-adjacent to the lake; continent from nearest land seed). If the lake touches land from **two or more** continents, do not fill it (it is a strait). Otherwise reassign each lake cell to land (sentinel). **Moat collapsing (narrow ocean corridors):** For remaining **ocean** cells, optionally identify **moat candidates**: sea tiles whose 4-neighbourhood contains land from the **same continent in at least two directions** (e.g. N+S or E+W) and **no** land from a different continent. Such candidates represent narrow ocean moats between a continent and the outer ocean. Convert moat candidates to land (sentinel), and for both lakes and moats, optionally reassign a matching number of **coastal** land tiles (adjacent to ocean) back to sea so the overall sea fraction remains close to the configured target. When skipped, lakes and moats remain as sea.
5. **Pass 5 — Border randomization (optional):** If border noise > 0, apply boundary noise on land/sea boundary (land = sentinel).
6. **Pass 6 — Terrain assignment (mountain ridges + region-growing):**
   - **Pass 6a — Mountain ridges:** Assign `TerrainType.mountain` by generating a small number of long, snaky **ridge paths** via random walks over land cells. A per-region **mountain fraction** (from `colonizethis_data` terrain rules) controls the total mountain share of land tiles. Ridge generation is continent-aware when continent information is available and MAY thicken ridges slightly while keeping them narrow.
   - **Pass 6b — Region-growing for other terrains (multi-scale, continent-aware):** For all remaining land cells (non-mountain), assign terrain from the **map region** allowed set (oldWorld or newWorld) using **multi-scale, multi-terrain region-growing**. Per-region **terrain weights** (from `colonizethis_data`) define target fractions for plains, forest, hills, swamp, etc. Region-growing runs **per continent** (per connected land component) in two main phases followed by an optional refinement phase: a **macro phase** places a small number of seeds per terrain on that continent and grows large, coherent blobs until each terrain reaches a configurable fraction of its local target; a subsequent **micro phase** places additional refinement seeds and grows smaller patches that break up overly uniform areas while preserving the macro structure; finally, an optional **pattern refinement phase** MAY examine large blobs of a single non-mountain terrain inside each continent and carve small pockets of other non-mountain terrains into their interior (radius- and count-limited growth from a few interior seeds per blob, with strict per-blob budgets) while keeping blob shapes recognizable and per-continent terrain fractions close to the configured distribution. Any remaining non-mountain land tiles are then assigned via local neighbor-majority to avoid gaps. This yields large, organic terrain clusters on each continent, with controlled internal variation, instead of per-cell noise or mono-terrain continents.
   - Sea cells remain null terrain throughout Pass 6.
7. **Pass 7 — Resource assignment:** For each land cell with terrain, assign at most one resource from the allowed set for **map region** and terrain; weights per TDD 04b.
8. **Pass 8 — Province seed placement:** Place one seed per **province** (ids p1..pN) on the existing land (sentinel cells only). Seeds are placed per continent within that continent's land blob using province-to-continent map; ensure some seeds are near the coast for P–S adjacencies.
9. **Pass 9 — Province assignment:** For each land cell, assign province id = province whose seed is closest (Voronoi restricted to land). Replace land sentinel with that province id. Sea cells keep sea zone id. With balanced land per continent and similar province count per continent, province sizes are naturally balanced.
10. **Join step (optional, only when needed):** After Pass 9, for each continent compute the connected components of land that belong to that continent (via province id → province-to-continent map). If any continent has **more than one** land component: find a shortest path of **sea** cells between two components; reassign those path cells to **land** with a province id. Assign terrain and resource for new land cells. Join runs only when **join continents** is enabled (CLI: **`--join-continents`**).
   - **Pass 10b — Province-aware terrain jitter (optional):** After provinces are finalized (and any join step has run) and resources have been assigned, an optional jitter pass MAY run to add small-scale variation inside highly homogeneous provinces. Per province, jitter runs only if a single non-mountain terrain type dominates (above a homogeneity threshold) and the province has at least a minimum number of tiles. Candidate tiles must (a) have the dominant terrain, (b) carry **no resource**, and (c) lie on an **edge** (adjacent either to a different terrain within the same province or to a different province). For each candidate, a new non-mountain terrain is chosen **preferentially from neighboring terrains already present in the same province**, and the change is applied only if that terrain has sufficient local neighbor support (at least a small configurable number of neighbors of that terrain). Jitter is further constrained by a per-province budget (max fraction of tiles changed) and a per-tile probability, and it NEVER modifies tiles that contain resources or mountains, nor does it change province ids; this keeps resource–terrain validity and province topology intact while adding subtle edge-focused variation.
11. **Pass 11 — Sea zone subdivision:** (1) Collect all cells with the single sea zone id. Compute **4-connected components** of those sea cells (4-neighbors, no diagonals). Let S = total sea tile count. (2) For each component (processed in deterministic order, e.g. by minimum (y, x)): if component size ≤ **max sea zone fraction × S** (e.g. ≤ 0.05×S), assign one sea zone id (s1, s2, … in order). If component size > 0.05×S, **subdivide** it so each resulting zone has at most 0.05×S tiles: required zones K = ceil(componentSize / (maxSeaZoneFraction × S)); place **K seeds** inside the component (well-spread; e.g. farthest-point sampling); run **Voronoi assignment** over the component's cells with these K seeds; assign K distinct sea zone ids (next in sequence). (3) Write assigned ids back to the grid. Result: each sea zone has at most 5% of total sea tiles; topology inference sees multiple sea zone nodes and S–S edges where zones are adjacent.

### Topology inference

After all passes (including join and sea zone subdivision), infer topology: `MapTopology inferTopologyFromTileMap(TileMapResult result, String regionId, String seaZoneId)`. Collect unique region ids from the grid. **Classify node type by id:** ids matching pattern s + digits (e.g. s1, s2) are sea zones; ids matching p + digits (e.g. p1, p2) are provinces. Build edges from `TileMapResult.adjacentRegionPairs()`. The `seaZoneId` parameter is used only to identify which grid cells are "sea" before subdivision (implementation may use it for Pass 11 input; classification in inference is by id pattern for multiple sea zones).

### Generation logs

When the map generation tool (CLI) runs, it MAY output **detailed per-pass logs** (pass name, key counts). The implementation accepts an optional logger callback.

---

## Ownership and consumers

- **Implemented in:** colonizethis_map (Dart). The `generate_map` CLI under `tool/` is a thin facade over colonizethis_map and does orchestration only.
- **Consumed by:** App (at game load or scenario load); tools.
- **Not persisted in game save** — Tile maps are static per map/scenario.

---

## Reference

[SPEC/ideas/tile-based-map-generation.md](../ideas/tile-based-map-generation.md) is a **sample/reference** for design and implementation. Implementation follows **this** spec; the ideas doc is not authoritative.
