# Tile Map Generation: Resources and Provinces (Passes 7–11)

**SPEC/program** — Resource and province assignment, sea zone subdivision. Algorithm: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Config: [tile-map-gen-config.md](tile-map-gen-config.md). Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md).

---

## Responsibility

Assign resources and provinces to land, subdivide sea zones, infer topology.

---

## Algorithm (Passes 7–11)

7. **Pass 7 — Resource assignment:** For each land cell with terrain, assign at most one resource from allowed set (map region + terrain). Weights per [resource-terrain-region-rules.md](../game/resource-terrain-region-rules.md): spawn weight = 1 / default market price (higher price = rarer). **Multi-region resource cap:** when both-count/total ≥ cap (default 0.30), restrict to region-only when possible.

8. **Pass 8 — Province seed placement:** One seed per province (p1..pN) on land. Seeds per continent using province-to-continent map; some near coast for P–S adjacencies.

9. **Pass 9 — Province assignment:** Voronoi over land; each cell → nearest province seed. Replace land sentinel with province id. Sea keeps sea zone id.

10. **Join step (optional):** When `--join-continents` enabled: if a continent has multiple land components, shortest sea path between two → reassign to land (province id), assign terrain and resource. Run after Pass 9.

10b. **Pass 10b — Province-aware terrain jitter (optional):** For homogeneous provinces (single terrain dominant, above threshold), add edge-focused variation. Candidates: dominant terrain, no resource, on edge. Pick from neighbouring terrains in same province; apply only with sufficient neighbour support. Never modify resources, mountains, or province ids.

11. **Pass 11 — Sea zone subdivision:** (1) Collect sea cells; compute 4-connected components. (2) Per component: if size ≤ maxSeaZoneFraction × S (default 0.05), assign one sea zone id (s1, s2…). If larger, subdivide via Voronoi (K seeds, well-spread). (3) Write ids to grid.

---

## Topology inference

After all passes: `MapTopology inferTopologyFromTileMap(TileMapResult result, String regionId, String seaZoneId)`. Unique region ids from grid. **Node type:** s+digits → sea zone; p+digits → province. Edges from `TileMapResult.adjacentRegionPairs()`.

---

## Integration

- **Upstream:** Land and terrain grids from [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Resource rules from config.
- **Downstream:** Map data and visualization consume `TileMapResult` and inferred topology.

---

## Constraints

- Resource rules required for Pass 7; when omitted, terrain/resource grids are null.
- Province and sea zone ids follow Voronoi; balanced land per continent yields balanced province sizes.
