# Tile Map Generation: Resources and Provinces (Passes 7–11)

**SPEC/program** — Resource and province assignment, sea zone subdivision. Algorithm: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Config: [tile-map-gen-config.md](tile-map-gen-config.md). Game semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). Province and sea zone identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Responsibility

Assign resources and provinces to land, subdivide sea zones, infer topology.

---

## Algorithm (Passes 7–11)

7. **Pass 7 — Resource assignment:** For each land cell with terrain, assign at most one resource from allowed set (map region + terrain). Weights per [resource-terrain-region-rules.md](../game/resource-terrain-region-rules.md): spawn weight = 1 / default market price (higher price = rarer). **Multi-region resource cap:** when both-count/total ≥ cap (default 0.30), restrict to region-only when possible. Pass 7 does **not** know future **town** or **capital** tiles; any RNG resource on a cell that later becomes a town or capital is stripped during game setup per [tile-map-and-generation.md](../game/tile-map-and-generation.md) § Town and capital tile occupancy. Tiles later overwritten by [Great Power starting grain (bootstrap)](../game/tile-map-and-generation.md) § Great Power starting grain (bootstrap) are **excluded** from **both** numerator and denominator (and from **all** other cap / budget accounting) when computing or validating Pass 7 caps after that post-pass runs.

   **Guaranteed forest resource spawn (forest split, issue #3573):** forest cells (`hardwoodForest`, `scrubForest`) are a special case of Pass 7. Every forest cell **always** receives a resource (100% probability), **bypassing** the global `kTileMapResourcePlaceProbability` (default 0.40) gate that governs non-forest cells. The guaranteed resource is deterministic by terrain and region:
   - **scrubForest** (Old World and New World): always `timber`.
   - **hardwoodForest** Old World: always `timber`.
   - **hardwoodForest** New World: a weighted split of `kHardwoodForestNewWorldFursProbability` (default **0.70**) `furs` and the remainder `timber`; every NW hardwood cell receives exactly one of the two.

   **Forest guarantee vs multi-region cap (precedence):** the 100% forest guarantee takes **strict precedence** over the 30% multi-region resource cap. Guaranteed forest timber/furs placements are **excluded** from the cap's both-count / total accounting (they are never recorded into the cap state), mirroring the **Bootstrap exclusion** precedent. They therefore neither raise the cap ratio for other cells nor are suppressed by it. The 30% cap continues to apply **only** to non-forest cells. This exclusion holds for both the incremental Pass 7 cap state and any cap state rebuilt from an existing resource grid (the rebuild skips forest-terrain cells when terrain data is supplied).

8. **Pass 8 — Province seed placement:** One seed per province (p1..pN) on land. Seeds per continent using province-to-continent map; some near coast for P–S adjacencies.

9. **Pass 9 — Province assignment:** Voronoi over land; each cell → nearest province seed. Replace land sentinel with province id. Sea keeps sea zone id.

10. **Join step (optional):** When `--join-continents` enabled: if a continent has multiple land components, shortest sea path between two → reassign to land (province id), assign terrain and resource. Run after Pass 9.

10b. **Pass 10b — Province-aware terrain jitter (optional):** For homogeneous provinces (single terrain dominant, above threshold), add edge-focused variation. Candidates: dominant terrain, no resource, on edge. Pick from neighbouring terrains in same province; apply only with sufficient neighbour support. Never modify resources, mountains, or province ids.

11. **Pass 11 — Sea zone subdivision:** (1) Collect sea cells; compute 4-connected components. (2) Per component: if size ≤ maxSeaZoneFraction × S (default 0.05), assign one sea zone id (s1, s2…). If larger, subdivide via Voronoi (K seeds, well-spread). (3) Write ids to grid.

---

## Topology inference

After all passes: `MapTopology inferTopologyFromTileMap(TileMapResult result, String regionId)`. Unique region ids from grid. **Node type:** s+digits → sea zone; p+digits → province. Edges from `TileMapResult.adjacentRegionPairs()`.

---

## Integration

- **Upstream:** Land and terrain grids from [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Resource rules from config.
- **Downstream:** Map data and visualization consume `TileMapResult` and inferred topology.

---

## Constraints

- Resource rules required for Pass 7; when omitted, terrain/resource grids are null.
- Province and sea zone ids follow Voronoi; balanced land per continent yields balanced province sizes.
- **Province and sea zone identity:** This pipeline outputs **local** ids (e.g. `p1`, `p2`, `s1`, `s2`). Local ids are not globally unique across regions. Downstream consumers (map data, game state, topology lookup) must use **prefixed** form (`regionId|localId`) and resolve per [world-model-identity.md](../game/world-model-identity.md); never look up by province or sea zone id alone.

---

## Acceptance criteria

- **Pass 7 (resources):** Each land cell has **at most one** resource; any assigned resource is allowed for that cell’s **region + terrain** per [resource-terrain-region-rules.md](../game/resource-terrain-region-rules.md). Spawn weights are the inverse of default market price (higher price ⇒ lower spawn weight). Multi‑region resources respect the global cap (default **0.30**): when both‑count/total ≥ cap, resource selection prefers region‑only options when available.
- **Bootstrap exclusion:** After [Great Power starting grain (bootstrap)](../game/tile-map-and-generation.md) runs, **no** tile that is part of that guarantee is counted toward the Pass 7 multi‑region cap ratio, spawn totals, or **any** other map resource budget; any RNG resource **replaced** on those cells is likewise excluded from post‑hoc cap validation.
- **Guaranteed forest spawn (#3573):** Given a generated map, when counting `scrubForest` cells (Old World or New World), then **100%** of them hold `timber`; when counting `hardwoodForest` cells in the Old World, then 100% hold `timber`; when counting `hardwoodForest` cells in the New World, then every cell holds either `furs` or `timber` and the `furs` share approaches **0.70** over a large sample. No forest cell is ever left without a resource.
- **Forest cap exclusion (#3573):** Given the multi‑region cap accounting for a region, when guaranteed forest timber/furs are placed, then those placements are **not** counted toward the cap's both/total ratio, and the both‑resource ratio measured over **non‑forest** cells remains at or below the cap (default **0.30/0.35** tolerance) even though raw timber on the full grid exceeds it.
- **Pass 8–9 (provinces):** Exactly **one province seed per province** is placed on land. After Voronoi assignment, every land cell holds a **province id** (p+digits); the land sentinel is fully replaced. Sea cells retain their **sea zone id** (s+digits).
- **Pass 11 (sea subdivision):** Sea cells are partitioned into **4‑connected components**. For each component, if its size ≤ `maxSeaZoneFraction × S` (default **0.05** of total sea cells), it receives a single sea zone id; otherwise the component is subdivided via Voronoi into multiple ids. All sea zone ids follow the `s1`, `s2`, … pattern.
- **Topology inference:** `inferTopologyFromTileMap` builds nodes from **unique grid ids** only. Node type is inferred from the id pattern (`s` + digits = sea zone, `p` + digits = province). Edges are derived exclusively from `TileMapResult.adjacentRegionPairs()`.
- **Optional passes (Join, 10b):** When enabled, Join and province‑aware terrain jitter preserve the invariants above: province/sea ids remain valid; mountains and existing resources are not altered; resource rules and null‑grid constraints still hold. Thresholds and jitter details may be implementation‑defined.
- **Missing resource rules:** When resource rules are omitted, Pass 7 is effectively disabled and the terrain/resource grids are **null**, consistent with Constraints.
