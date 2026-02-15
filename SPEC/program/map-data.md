# Map Data: Topology and Tile Maps

**SPEC/program** — Format and ownership of static map data (topology, tile maps) and the describe-topology CLI. Game semantics: [SPEC/game/world-model.md](../game/world-model.md), [SPEC/game/map-topology.md](../game/map-topology.md). Tile map generation: [tile-map-generation.md](tile-map-generation.md).

---

## Topology format

**Region topology** is stored as a graph:

- **Nodes:** List of nodes with id, region id, and type (province | sea zone). Cross-region: nodes may belong to different regions.
- **Edges:** List of undirected edges (id1, id2). Semantics: P<->P (contiguous land), P<->S (province next to sea), optionally S<->S. Edges may reference nodes from different regions (cross-region adjacency).
- **Storage:** File per region or one world graph with region labels; format (e.g. JSON or YAML) is implementation-defined. Loaded at game creation; colonizethis_data owns loading and provides topology to logic and tools.

---

## Tile map format

**Per-region 2D grid (static per scenario).** Each cell: region id (province or sea zone), type (land/water), **terrain type** (for land), **resource** (optional; at most one). Resource must be allowed for that **region** and that **terrain type**; resource–region and resource–terrain rules live in colonizethis_data. Extraction level and road are **mutable** game state (keyed by region, province, tile), not part of the static tile map (or only as initial scenario state). Produced by tile-based map generation ([tile-map-generation.md](tile-map-generation.md)) or loaded from data. Not persisted in game save; static per map/scenario.

---

## CLI tool: describe topology

- **Purpose:** Load a region topology and **describe the entire map** (graph + optional map summary) and, in **interactive mode**, show **province detail** (id, region, owner, tile count, improvements). Used for inspection and debugging.
- **Place:** `tool/describe_topology/`. Thin driver over colonizethis_data (description, map summary, province list/detail logic live in the library).
- **Options:** Topology file path is required. Optional: `--interactive` (prompt for province id, show detail; q to quit), `--tile-map` (generate tile map and print map summary), `--tile-map-image [path]` (generate tile map, render to PNG with legend, write to path or temp, try to open in default image viewer; path optional; visualization/export logic in colonizethis_data), `--world-state <path>` (load world state JSON so province detail shows owner; provinces without owner are shown as **no owner**).
- **Output:** Graph description (nodes P|S with id and region; edges). If `--tile-map`: tile count per province/sea zone. If `--tile-map-image`: path to PNG; viewer opened if possible. If `--interactive`: province list then prompt; for each entered province id, formatted detail (region, owner or "no owner", tiles, improvements).
- **Run:** From repo root: `melos run describe_topology -- <path_to_topology.json> [--interactive] [--tile-map] [--tile-map-image[=path]] [--world-state <path_to_world.json>]` (paths relative to repo root).

---

## Tile-based map generation

Implemented in colonizethis_data or in a tool under `tool/` (e.g. `tool/generate_tile_map`). Algorithm and contract: [tile-map-generation.md](tile-map-generation.md). Game-side semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). Input: region topology (and optional world graph for cross-region). Output: per-region tile map (2D grid) or file written for consumption by colonizethis_data/app.
