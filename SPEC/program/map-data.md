# Map Data: Topology and Tile Maps

**SPEC/program** — Data model for static map data (topology, tile maps). Visualization: [map-visualization.md](map-visualization.md). Game semantics: [SPEC/game/world-model.md](../game/world-model.md), [SPEC/game/map-topology.md](../game/map-topology.md). Tile map generation: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md), [tile-map-gen-resources.md](tile-map-gen-resources.md), [tile-map-gen-config.md](tile-map-gen-config.md).

---

## Responsibility

Define topology format, tile map data structures, province identity, and tile key format.

---

## Topology format

**Region topology** is stored as a graph:

- **Nodes:** List with id, region id, and type (province | sea zone). Cross-region: nodes may belong to different regions.
- **Edges:** Undirected (id1, id2). Semantics: P↔P (contiguous land), P↔S (province–sea), optionally S↔S. Edges may be cross-region.
- **Storage:** File per region or one world graph; format (JSON/YAML) implementation-defined. colonizethis_data owns loading. When generating maps, topology is **inferred** from the tile map.

---

## Province identity and tile key format

- **Province ids:** Topology and tile maps use **local** ids (e.g. `p1`, `p2`). Game state uses **prefixed** ids (`regionId|localId`). Local ids are **not** globally unique across regions (e.g. `p1` can exist in oldWorld and newWorld). Movement and other topology queries (e.g. adjacency, connectivity) must scope by **region** when duplicate local ids exist. Always resolve by regionId + provinceId; never by province id alone. See [world-model.md](../game/world-model.md), [world-model-identity.md](../game/world-model-identity.md).
- **Tile key format:** `regionId|provinceId|x|y` for mutable game state (extraction, transport, ports). Map visualizers must convert local ids to full province ids before querying ownership.

---

## Tile map format

**Per-region 2D grid (static per scenario).** Each cell: region id (province or sea zone), type (land/water), **terrain type** (land), **resource** (optional; at most one). Resource must be allowed for region and terrain; rules in colonizethis_data. Extraction level and road are **mutable** game state (keyed by tile), not part of static tile map. Produced by [tile-map-gen-*](tile-map-gen-algorithm.md) or loaded from data. Not persisted in game save.

---

## Map generation tool

**Place:** `tool/generate_map/`. **Mode:** Generate from N and C via `--provinces`, `--continents`. Infer topology. Output: graph, summary, tile map PNG, topology DOT/PNG. **Options:** `--provinces`, `--continents`, `--region`, `--tiles-per-province`, `--sea-fraction`, `--interactive`, `--tile-map`, `--tile-map-image`, `--seed`, `--world-state`, `--join-continents`, `--seed-before-assignment`, `--skip-fill-lakes`, `--continent-buffer`. Topology graph: DOT export; map-aligned layout when tile map available. **Run:** `melos run generate_map -- [options]`.

---

## Integration

colonizethis_data owns loading. colonizethis_map implements generation per [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Consumed by App, init_game, ctdev.

---

## Constraints

- Province identity always (regionId, provinceId). Tile-map ids are internal; game state is source of truth for ownership.
