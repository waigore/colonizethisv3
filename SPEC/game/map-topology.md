# Map Topology

**SPEC/game** — Topology link semantics and cross-region connection. See [world-model.md](world-model.md) for entities; [tile-map-and-generation.md](tile-map-and-generation.md) for tile maps. Province and sea zone identity (ids in game state, lookup): [world-model-identity.md](world-model-identity.md).

---

## Region graphs

The world topology is **not** one graph. Each **region** (e.g. Old World, New World) has its **own** topology graph. Tile maps are per region (one 2D grid per region). Nodes and edges in a region graph refer only to that region; there are no direct P–P, P–S, or S–S edges between different regions. Regions connect **only** via **warp zones** (see below).

---

## Link types (within a region)

Within a region, the topology is an **undirected graph**. Nodes are **provinces (P)** or **sea zones (S)**; each has id and region id. When generating maps, topology is **inferred** from the tile map (nodes = unique region ids from the grid, edges = adjacent region pairs). Topology format and ownership: [SPEC/program/map-data.md](../program/map-data.md).

**Edges (within the same region) have two semantics:**

- **P1 <-> P2** — P1 and P2 are contiguous land provinces (neighbours). Armies move only between adjacent provinces.
- **P1 <-> S1** — Province P1 is next to sea zone S1 (coast).

**S1 <-> S2** (sea–sea, same region) define **sea paths**: movement and **connectivity** between sea zones in that region use this graph (e.g. a port in sea zone B is reachable from a port in sea zone A if there is a path of S–S edges from A to B, or A = B). No other edge types within a region. Connectivity algorithm: [extraction-pipeline.md](../program/extraction-pipeline.md). **Coastal tiles:** Land tiles in province P that are adjacent (in the grid) to a sea zone S with P<->S edge. Ships entering S reveal coastal tiles of P. See [ships-and-naval.md](ships-and-naval.md), [naval-movement-resolution.md](../program/naval-movement-resolution.md).

---

## Warp zones

**Warp zones** are sea zones that **link** one region’s map to another’s. They are the **only** way the Old World and New World (or other regions) connect.

- **Placement (generation):** On every map, the generator aims for **one warp zone per map edge**, each using a **sea zone on the edge** (a sea zone that has at least one tile on the grid boundary). If that is not possible, the **number of warp zones on each map must still be the same** so that each warp zone links to exactly one warp zone on each counterpart map.
- **Link rule:** Each warp zone connects to **exactly one** other warp zone on another map. A link is a 1:1 pairing: one sea zone on region A ↔ one sea zone on region B.
- **Multi-map:** A sea zone on a given map **can be** a warp zone that connects to **one or more** other maps. For each such other map it has exactly one linked warp zone (on that other map). So one sea zone on the Old World might link to one warp zone on the New World and optionally to one on a third region.

Sea-path reachability across regions is defined by following S–S edges **within** each region and **warp links** between regions. So: a port in the New World is connected to the capital’s sea (in the Old World) iff there is a path from the capital’s sea zone(s) via (intra-region S–S and warp links) to the New World port’s sea zone. Implementation may represent warp zones as a separate structure (e.g. warp link table: per (regionId, seaZoneId) a list of (otherRegionId, otherSeaZoneId)); see [map-data.md](../program/map-data.md).

---

## Continents and tile map generation

**Continents** are the connected components of the **land** subgraph (provinces and P–P edges only). Topology inference and continent derivation (land subgraph from inferred graph): [SPEC/program/map-data.md](../program/map-data.md). Tile map generation places **land seeds** (one per continent) to define land shape; **province seeds** are placed on the land in a later pass. No path carving. Sea zones are **capped in size**: each sea zone is at most a configurable fraction (e.g. 5%) of total sea tiles; this uses the **max sea zone fraction** map parameter (default 0.05) from [SPEC/program/tile-map-gen-config.md](../program/tile-map-gen-config.md) § Map params. Large water bodies are subdivided using Voronoi over sea seeds (Pass 11). See [SPEC/program/tile-map-gen-resources.md](../program/tile-map-gen-resources.md) § Pass 11 and [tile-map-gen-algorithm.md](../program/tile-map-gen-algorithm.md) § Voronoi assignment.

---

## Province and sea zone identity

Province ids and sea zone ids used in game state (e.g. unit location, ownership, order payloads) use the **prefixed** form (`regionId|localId`) and **region-scoped lookup**; see [world-model-identity.md](world-model-identity.md). Topology and map data may use local ids per region; resolution and game state must use prefixed ids and never look up by id alone.

---

## Movement rule

Armies move only from one province to an **adjacent** province (P<->P). Naval movement uses P<->S and optionally S<->S. Order validation uses the topology graph. Land movement adjacency and region-scoped validation are specified in [SPEC/program/movement.md](../program/movement.md). See also [SPEC/program/turn-resolution.md](../program/turn-resolution.md) and [SPEC/program/map-data.md](../program/map-data.md).

---

## Acceptance criteria

- **Region graphs:** The world topology is **multiple region graphs** (one per region). Each region has its own graph; no direct edges between nodes in different regions. Tile maps remain per region (one 2D grid per region).
- **Graph semantics (per region):** Within a region, the graph is undirected. Nodes are provinces (P) or sea zones (S); edges are P–P (land neighbours), P–S (coast), or S–S (sea paths) only. No other node or edge types within a region.
- **Warp zones:** Regions connect **only** via warp zones (sea zones that link maps). Each warp zone connects to exactly one other warp zone on another map; a sea zone can be a warp zone to one or more other maps (one link per other map). Cross-region sea-path reachability uses intra-region S–S edges plus warp links.
- **Topology source:** Topology is inferred from the tile map (nodes = unique region ids from the grid, edges = adjacent region pairs). Format and ownership: [map-data.md](../program/map-data.md).
- **Continents:** Continents are the connected components of the land subgraph (provinces and P–P edges only) **within a region**. Inference and continent derivation: [map-data.md](../program/map-data.md).
- **Province and sea zone identity:** Province and sea zone ids in game state (unit location, ownership, order payloads) use prefixed form and region-scoped lookup per [world-model-identity.md](world-model-identity.md). Topology/map data may use local ids per region; resolution and game state use prefixed ids.
- **Movement:** Armies move only between adjacent provinces (P–P). Naval movement uses P–S and S–S. Land movement adjacency and region-scoped validation are defined in [movement.md](../program/movement.md). Order validation uses the topology graph per [turn-resolution.md](../program/turn-resolution.md) and [map-data.md](../program/map-data.md).
