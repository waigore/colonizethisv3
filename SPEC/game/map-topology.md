# Map Topology

**SPEC/game** — Topology link semantics and cross-region adjacency. See [world-model.md](world-model.md) for entities; [tile-map-and-generation.md](tile-map-and-generation.md) for tile maps.

---

## Link types

The map is an **undirected graph**. Nodes are **provinces (P)** or **sea zones (S)**; each has id and region id. When generating maps, topology is **inferred** from the tile map (nodes = unique region ids from the grid, edges = adjacent region pairs). Topology format and ownership: [SPEC/program/map-data.md](../program/map-data.md).

**Edges have two semantics:**

- **P1 <-> P2** — P1 and P2 are contiguous land provinces (neighbours). Armies move only between adjacent provinces.
- **P1 <-> S1** — Province P1 is next to sea zone S1 (coast).

**S1 <-> S2** (sea–sea) define **sea paths**: movement and **connectivity** between sea zones use this graph (e.g. a port in sea zone B is reachable from a port in sea zone A if there is a path of S–S edges from A to B, or A = B). No other edge types. Connectivity algorithm: [extraction-pipeline.md](../program/extraction-pipeline.md). **Coastal tiles:** Land tiles in province P that are adjacent (in the grid) to a sea zone S with P<->S edge. Ships entering S reveal coastal tiles of P. See [ships-and-naval.md](ships-and-naval.md), [naval-movement-resolution.md](../program/naval-movement-resolution.md).

---

## Cross-region adjacency

A province or sea zone in one region can be adjacent to a province or sea zone in **another** region (e.g. Europe and Asia). The **world** topology is one graph. **Tile maps** are still per region (one 2D grid per region); cross-region links are respected when generating or validating maps.

---

## Continents and tile map generation

**Continents** are the connected components of the **land** subgraph (provinces and P–P edges only). Tile map generation places **land seeds** (one per continent) to define land shape; **province seeds** are placed on the land in a later pass. No path carving. Sea zones are **capped in size**: each sea zone is at most a configurable fraction (e.g. 5%) of total sea tiles; large water bodies are subdivided using Voronoi over sea seeds (Pass 11). See [SPEC/program/tile-map-gen-resources.md](../program/tile-map-gen-resources.md) § Pass 11 and [tile-map-gen-algorithm.md](../program/tile-map-gen-algorithm.md) § Voronoi assignment.

---

## Movement rule

Armies move only from one province to an **adjacent** province (P<->P). Naval movement uses P<->S and optionally S<->S. Order validation uses the topology graph; see [SPEC/program/turn-resolution.md](../program/turn-resolution.md) and [SPEC/program/map-data.md](../program/map-data.md).
