# Tile-Based Map Generation

**SPEC/program** — Algorithm and contract for generating a per-region tile map from topology. Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). Reference/sample (not spec): [SPEC/ideas/tile-based-map-generation.md](../ideas/tile-based-map-generation.md).

---

## Input

- **Region topology graph** — Undirected graph: nodes = provinces (P) or sea zones (S) with id and region id; edges = P<->P, P<->S (optionally S<->S). May include cross-region links for the region being generated.
- **Parameters:** Grid width/height (e.g. 200×200), random seed (reproducibility), border noise (0–1, jaggedness), optional clump factor.

---

## Output

- **Per-region 2D tile map** — Each cell has a region id (province or sea zone) and type (land/water). Land cells have **terrain type** and optional **resource**; resource placement obeys region and terrain constraints. Resource spawn rates across the region are controlled so distribution is in **inverse proportion to default market price** (see TDD 04b). Invariant: two regions share a tile edge in the grid **if and only if** they are linked in the input graph. Optional: adjacency metadata derived from the grid for validation.

---

## Algorithm steps

1. **Graph embedding** — Assign 2D coordinates to each node (e.g. force-directed layout). Connected nodes close; non-connected pushed apart. Scale to grid; add optional randomness.
2. **Seed placement** — Discretize to grid coordinates; resolve overlaps (nudge); enforce minimum distance between non-adjacent centers.
3. **Region assignment** — Assign each tile to the closest center (e.g. Voronoi-style rasterization). Produces contiguous regions; land vs water by node type.
4. **Terrain and resource assignment** — Assign terrain type per land cell. Assign at most one resource per tile from the allowed set for that region and terrain type; use spawn weights (inverse to default market price) when choosing whether/which resource to place. Validate against resource–region and resource–terrain tables.
5. **Topology enforcement** — Verify grid adjacencies match the graph. Fix missing adjacencies (carve/grow so linked regions touch). Fix extra adjacencies (separate or reassign). Iterate until match.
6. **Border randomization** — Add noise to boundary tiles (e.g. swap with neighbour with probability = border noise) for semi-random coasts and borders.
7. **Smoothing and polish** — Optional: ensure each region is one connected component; smooth coasts; validate final adjacency.

---

## Ownership and consumers

- **Implemented in:** colonizethis_data (Dart) or a dedicated tool under `tool/` (e.g. `tool/generate_tile_map`) that writes the grid to a file. Prefer colonizethis_data if the app generates maps at runtime; otherwise tool for offline generation.
- **Consumed by:** App (at game load or scenario load); tools. colonizethis_logic uses tile map or terrain data for movement costs/combat when needed (Phase 2+).
- **Not persisted in game save** — Tile maps are static per map/scenario; topology and generated grid live in colonizethis_data or asset files.

---

## Reference

[SPEC/ideas/tile-based-map-generation.md](../ideas/tile-based-map-generation.md) is a **sample/reference** for design and implementation (e.g. Voronoi, force-directed layout, topology enforcement). Implementation follows **this** spec; the ideas doc is not authoritative.
