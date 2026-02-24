# Map Data: Topology and Tile Maps

**SPEC/program** — Data model for static map data (topology, tile maps). Visualization: [map-visualization.md](map-visualization.md). Game semantics: [SPEC/game/world-model.md](../game/world-model.md), [SPEC/game/map-topology.md](../game/map-topology.md). Tile map generation: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md), [tile-map-gen-resources.md](tile-map-gen-resources.md), [tile-map-gen-config.md](tile-map-gen-config.md).

---

## Responsibility

Define topology format, tile map data structures, province identity, and tile key format.

---

## Topology format

**Topology is per region**: each region has its **own** graph. There is no single world graph with cross-region edges. Regions connect **only** via **warp zones** (see [map-topology.md](../game/map-topology.md)).

**Per-region topology:**

- **Nodes:** List with id, region id, and type (province | sea zone). All nodes in a region graph belong to that region.
- **Edges:** Undirected (id1, id2). Semantics: P↔P (contiguous land), P↔S (province–sea), S↔S (sea paths). All edges are **within** the same region.
- **Warp zones:** Separate structure (warp links) that pairs a sea zone in one region with exactly one sea zone in another. Each link is 1:1; a sea zone can be a warp zone to one or more other maps (one link per other map). **Generation:** On each map, aim for **one warp zone per map edge**, each using a sea zone on the edge (tiles on the grid boundary); if not possible, the number of warp zones on each map must still be **equal** so every warp zone has exactly one counterpart on each linked map. **Warp links are produced during world generation** (after OW and NW topology are generated) per [game-setup-pipeline.md](game-setup-pipeline.md) step 4; they are stored with the init result and used when building combined topology / connectivity.
- **Storage:** File per region (and optional warp link data); format (JSON/YAML) implementation-defined. colonizethis_data owns loading. When generating maps, topology is **inferred** from the tile map per region; warp zones are **generated** and linked in the setup pipeline.

---

## Province identity and tile key format

- **Province ids:** Topology and tile maps use **local** ids (e.g. `p1`, `p2`). Game state uses **prefixed** ids (`regionId|localId`). Local ids are **not** globally unique across regions (e.g. `p1` can exist in oldWorld and newWorld). Movement and other topology queries (e.g. adjacency, connectivity) must scope by **region** when duplicate local ids exist. Always resolve by regionId + provinceId; never by province id alone. See [world-model.md](../game/world-model.md), [world-model-identity.md](../game/world-model-identity.md).
- **Tile key format:** `regionId|provinceId|x|y` for mutable game state (extraction, transport, ports). Map visualizers must convert local ids to full province ids before querying ownership.

---

## Tile map format

**Per-region 2D grid (static per scenario).** Each cell: region id (province or sea zone), type (land/water), **terrain type** (land), **resource** (optional; at most one). Resource must be allowed for region and terrain; rules in colonizethis_data. Extraction level and road are **mutable** game state (keyed by tile), not part of static tile map. Produced by [tile-map-gen-*](tile-map-gen-algorithm.md) or loaded from data. Not persisted in game save.

---

## Map generation tool

**Place:** `tool/generate_map/`. **Mode:** Generate from N and C via `--provinces`, `--continents`. Infer topology. Output: graph, summary, tile map PNG, topology DOT/PNG. **Options:** `--provinces`, `--continents`, `--region`, `--tiles-per-province`, `--sea-fraction`, `--interactive`, `--tile-map`, `--tile-map-image`, `--seed`, `--world-state`, `--join-continents`, `--seed-before-assignment`, `--skip-fill-lakes`, `--continent-buffer`. Topology graph: DOT export; map-aligned layout when tile map available. **Run:** `melos run generate_map -- [options]`. **Logging:** Operational and diagnostic output follows [ctdev-logging.md](ctdev-logging.md) (logger with `map:` prefix; errors to stderr and non-zero exit).

---

## Integration

colonizethis_data owns loading. colonizethis_map implements generation per [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Consumed by App, init_game, ctdev.

---

## Constraints

- Province identity always (regionId, provinceId). Tile-map ids are internal; game state is source of truth for ownership.
