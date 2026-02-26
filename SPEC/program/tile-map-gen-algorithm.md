# Tile Map Generation: Algorithm (Passes 1–6)

**SPEC/program** — Generation pipeline for landmass, terrain, and mountains. Config: [tile-map-gen-config.md](tile-map-gen-config.md). Resources and provinces: [tile-map-gen-resources.md](tile-map-gen-resources.md). Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md).

---

## Responsibility

Generate per-region landmass and terrain (passes 1–6). One region (oldWorld or newWorld) at a time. Grid dimensions from config; see [tile-map-gen-config.md](tile-map-gen-config.md) § Grid size derivation.

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

4. **Pass 4 — Fill lakes and moats:** Ocean = sea connected to grid boundary. Lake = sea not in ocean. Continent-aware: if lake touches two+ continents, do not fill (strait). Otherwise fill lake to land. Moat collapsing: narrow ocean moats between same-continent land converted to land. Skip via `--skip-fill-lakes`.

5. **Pass 5 — Border randomization:** If border noise > 0, apply boundary noise on land/sea.

6. **Pass 6 — Terrain assignment:**
   - **6a — Mountain ridges:** Assign `TerrainType.mountain` via ridge paths (random walks). Per-region mountain fraction from terrain rules.
   - **6b — Region-growing:** Non-mountain land: macro phase (large blobs by terrain), micro phase (smaller patches), optional pattern refinement (pockets inside blobs). Per-region terrain weights from colonizethis_data. Sea cells stay null terrain.

---

## Integration

- **Upstream:** Config params from [tile-map-gen-config.md](tile-map-gen-config.md).
- **Downstream:** [tile-map-gen-resources.md](tile-map-gen-resources.md) (Pass 7+) consumes land and terrain grids.

---

## Constraints

- Grid dimensions derived; no topology input. Province identity assigned in later passes.
