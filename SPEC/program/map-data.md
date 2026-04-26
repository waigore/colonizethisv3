# Map Data: Topology and Tile Maps

**SPEC/program** — Data model for runtime map data (topology, tile maps). Visualization: [map-visualization.md](map-visualization.md). Game semantics: [SPEC/game/world-model.md](../game/world-model.md), [SPEC/game/map-topology.md](../game/map-topology.md). Tile map generation: [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md), [tile-map-gen-resources.md](tile-map-gen-resources.md), [tile-map-gen-config.md](tile-map-gen-config.md).

---

## Responsibility

Define topology format, tile map data structures, province identity, and tile key format.

---

## Scope (current product)

For current product, map topology and tile maps are **produced only in-memory** by the map generation tool (`generate_map`) and/or by init_game when creating a new game. **Hand-crafted or static file loading** of topology/tile maps for gameplay is **out of scope**; there is no supported path to load arbitrary map files into a running session. Persisted map data exists **only** as part of the Hive save bundle (same JSON structures; round-trip with [save-load.md](save-load.md)) for resume/playable sessions and tooling—not as a standalone map import feature.

---

## Topology format

**Topology is per region**: each region has its **own** graph. There is no single world graph with cross-region edges. Regions connect **only** via **warp zones** (see [map-topology.md](../game/map-topology.md)).

**Per-region topology:**

- **Nodes:** List with id, region id, and type (province | sea zone). All nodes in a region graph belong to that region.
- **Edges:** Undirected (id1, id2). Semantics: P↔P (contiguous land), P↔S (province–sea), S↔S (sea paths). All edges are **within** the same region.
- **Warp zones:** Separate structure (warp links) that pairs a sea zone in one region with exactly one sea zone in another. Each link is 1:1; a sea zone can be a warp zone to one or more other maps (one link per other map). **Generation:** On each map, aim for **one warp zone per map edge**, each using a sea zone on the edge (tiles on the grid boundary); if not possible, the number of warp zones on each map must still be **equal** so every warp zone has exactly one counterpart on each linked map. **Warp links are produced during world generation** (after OW and NW topology are generated) per [game-setup-pipeline.md](game-setup-pipeline.md) step 4; they are stored with the init result and used when building combined topology / connectivity.
- **Storage (current product):** Topology is **not** loaded from standalone files. It is inferred from the tile map during generation (see Map generation tool) and persisted only through save/load envelopes. `colonizethis_data` owns the topology/tile-map data structures and JSON (de)serialization used by runtime generation and save round-trip flows.

### JSON schema and loading contract

**Source of truth:** The `colonizethis_data` package owns the JSON (de)serialization via `MapTopology.toJson/fromJson`, `TopologyNode.toJson/fromJson`, and `TileMapResult.toJson/fromJson`. This section documents the current schema; any changes must update both the code and this spec.

#### MapTopology JSON

```json
{
  "nodes": [
    { "id": "p1", "regionId": "oldWorld", "type": "province" },
    { "id": "s1", "regionId": "oldWorld", "type": "seaZone" }
  ],
  "edges": [
    { "id1": "p1", "id2": "p2" },
    { "id1": "p1", "id2": "s1" }
  ]
}
```

- **`nodes`**: Array of topology nodes.
  - **`id`**: String. Local province or sea zone id (e.g. `p1`, `s1`).
  - **`regionId`**: String. Region identifier (e.g. `oldWorld`, `newWorld`).
  - **`type`**: String. Either `"province"` or `"seaZone"`.
- **`edges`**: Array of undirected edges.
  - Each edge is either an object `{ "id1": string, "id2": string }` or a 2-element list `[id1, id2]`.
  - Semantics: P↔P (contiguous land), P↔S (province–sea), S↔S (sea paths).

#### TileMapResult JSON

```json
{
  "width": 20,
  "height": 15,
  "grid": [
    ["p1", "p1", "s1", "s1"],
    ["p2", "p2", "s1", "s1"]
  ],
  "terrainGrid": [
    ["plains", "plains", null, null],
    ["forest", "hills", null, null]
  ],
  "resourceGrid": [
    [null, "gold", null, null],
    [null, null, null, null]
  ]
}
```

- **`width`**: Integer. Number of columns.
- **`height`**: Integer. Number of rows.
- **`grid`**: 2D array of strings. Each cell contains a province or sea zone id.
- **`terrainGrid`**: Optional 2D array of terrain names (e.g. `"plains"`, `"forest"`, `"hills"`). `null` = water or not set. Must match `grid` dimensions.
- **`resourceGrid`**: Optional 2D array of resource names (e.g. `"gold"`, `"spices"`). `null` = no resource. Must match `grid` dimensions.

#### Testing guidance

- **Round-trip tests:** Serialize → deserialize → compare for `MapTopology` and `TileMapResult` with small hand-crafted examples.
- **Failure mode tests:** Validate malformed JSON payloads and inconsistent dimensions for runtime JSON parsing paths used by generation/save round-trip.

---

## Province identity and tile key format

- **Province ids:** Topology and tile maps use **local** ids (e.g. `p1`, `p2`). Game state uses **prefixed** ids (`regionId|localId`). Local ids are **not** globally unique across regions (e.g. `p1` can exist in oldWorld and newWorld). Movement and other topology queries (e.g. adjacency, connectivity) must scope by **region** when duplicate local ids exist. Always resolve by regionId + provinceId; never by province id alone. See [world-model.md](../game/world-model.md), [world-model-identity.md](../game/world-model-identity.md).
- **Combined world topology:** `buildCombinedTopology` in game setup merges per-region graphs into one `MapTopology` whose **node ids and edge endpoints are prefixed** (`regionId|localId`), plus warp edges. The running app and turn resolver use this graph. Logic helpers that take a **local** province id and **regionId** for region-scoped P↔S lookup (e.g. `seaZoneIdForProvince` in colonizethis_logic) must resolve provinces and edges correctly for **both** per-region (local ids in the graph) and combined (prefixed ids) representations.
- **Tile key format:** `regionId|provinceId|x|y` for mutable game state (extraction, transport, ports). Map visualizers must convert local ids to full province ids before querying ownership.
- **Sea-zone tile bucket keys:** In `WorldState.tileKeysByRegionAndProvince`, sea-zone buckets use canonical **prefixed** ids (`regionId|localSeaZoneId`) as the second map key. Legacy saves with local sea-zone bucket keys are rejected with a runtime hard-fail during `WorldState.fromJson` load.

---

## Tile map format

**Per-region 2D grid (runtime generation + save payload).** Each cell: region id (province or sea zone), type (land/water), **terrain type** (land), **resource** (optional; at most one). Resource must be allowed for region and terrain; rules in colonizethis_data. Extraction level and road are **mutable** game state (keyed by tile), not part of tile map topology data. For current product, tile maps are produced by [tile-map-gen-*](tile-map-gen-algorithm.md) or supplied from `init_game`; required save payload map data is specified in [save-load.md](save-load.md). There is no supported gameplay path that loads tile maps from standalone static files.

**Persistence (current product):** The tile map is part of the required playable save payload together with topology and combined topology per [save-load.md](save-load.md) (keys `_tileMapByRegion`, `_topologyByRegion`, `_combinedTopology`). Saves missing required map data are invalid for gameplay load. Format and semantics of the tile map are defined in this spec; the save/load contract is in save-load.md.

---

## Map generation tool

**Place:** `tool/generate_map/`. **Mode:** Generate from N and C via `--provinces`, `--continents`. Infer topology. Always output: topology graph description and map summary on stdout. Optionally: tile map PNG (via `--tile-map-image`), topology DOT and PNG (when `--tile-map-image` or `--topology-graph` is used). **Run:** `melos run generate_map -- [options]`. **Logging:** Operational and diagnostic output follows [ctdev-logging.md](ctdev-logging.md) (logger with `map:` prefix; errors to stderr and non-zero exit).

### CLI options (current product)

| Option | Form | Default | Validation / semantics |
|--------|------|---------|------------------------|
| `--provinces` | `--provinces N` or `--provinces=N` | 60 | Positive integer; invalid → stderr message, exit 1 |
| `--continents` | `--continents M` or `--continents=M` | 3 | Integer in [2, 4]; invalid → stderr message, exit 1 |
| `--region` | `--region id` or `--region=id` | oldWorld | `oldWorld` or `newWorld` only; invalid → stderr message, exit 1 |
| `--tiles-per-province` | `--tiles-per-province N` or `=N` | 35 | Positive integer; invalid → stderr, exit 1 |
| `--sea-fraction` | `--sea-fraction F` or `=F` | 0.6 | Double in [0, 1); invalid → stderr, exit 1 |
| `--interactive` | flag | off | Prompt for province id and show detail; type `q` to quit. With `--world-state`, province detail includes owner. |
| `--tile-map-image` | `--tile-map-image` or `--tile-map-image=path` | — | If no path: write PNG to temp file, path printed. If path given: write PNG there. Tries to open in default viewer. |
| `--tile-size` | `--tile-size N` or `=N` | 24 (when PNG exported) | Pixels per cell in tile map PNG; positive integer; invalid → stderr, exit 1 |
| `--topology-graph` | `--topology-graph` or `--topology-graph=path` | — | Export topology as DOT (and PNG via neato when Graphviz installed). When only `--tile-map-image` is used (no `--topology-graph`), DOT is written to a temp path (printed on stdout). When `--topology-graph` is used with empty path and `--tile-map-image=path` is set, DOT path is derived from PNG path (e.g. `foo.png` → `foo_topology.dot`). When `--topology-graph=path` is set, that path is used. |
| `--seed` | `--seed N` or `=N` | random | Integer; invalid → stderr, exit 1 |
| `--world-state` | `--world-state path` | — | Path to world state JSON; used for ownership in interactive province detail. File must exist; missing file → stderr, exit 1 |
| `--join-continents` | flag | off | Enable join step (Pass 10) |
| `--seed-before-assignment` | flag or `=true|false` | off | Use legacy land assignment |
| `--skip-fill-lakes` | flag or `=true|false` | off | Skip Pass 4 (fill lakes) |
| `--continent-buffer` | `--continent-buffer N` or `=N` | 2 | Non-negative integer; invalid → stderr, exit 1 |

There is no separate `--tile-map` flag: topology and map summary are always produced; PNG export is requested only via `--tile-map-image`.

### Output and file semantics

- **Stdout:** Topology graph text, map summary (province and sea-zone counts from topology/tile-count helpers). With `--tile-map-image`, the PNG path is printed. With `--topology-graph` (or when writing DOT), the DOT path is printed.
- **Tile map PNG:** Only when `--tile-map-image` is present. Path: explicit path if `=path` given; otherwise temp file. Cell size: `--tile-size` or 24.
- **Topology graph:** DOT file written when `--tile-map-image` or `--topology-graph` is used. PNG from DOT via `neato` when Graphviz is installed; otherwise a warning to stderr.

### Acceptance criteria

**Topology and tile map contracts**

- **MapTopology and TileMapResult** are the single source of truth for topology and tile map format; the JSON schemas (keys, structure) are documented in this spec (Topology format, Tile map format). The `colonizethis_data` package owns (de)serialization via `MapTopology.toJson/fromJson`, `TopologyNode.toJson/fromJson`, and `TileMapResult.toJson/fromJson`; any schema change must update both code and this spec.
- **TileMapResult** defines the on-disk/in-memory format for tile maps used by tools: required keys `width`, `height`, `grid`; optional `terrainGrid`, `resourceGrid` with dimensions matching `grid`; rectangular grids; constraints are described in this spec and validated in colonizethis_data.
- **Adjacency semantics** for topology (P↔P, P↔S, S↔S) and centroid/tile-count helpers are described in this spec and in [map-topology.md](../game/map-topology.md); behaviour is testable against a small sample grid (unit tests in colonizethis_data).

**Map generation tool (generate_map)**

- All options listed in the Map generation tool section (`--provinces`, `--continents`, `--region`, `--tiles-per-province`, `--sea-fraction`, `--interactive`, `--tile-map-image`, `--tile-size`, `--topology-graph`, `--seed`, `--world-state`, `--join-continents`, `--seed-before-assignment`, `--skip-fill-lakes`, `--continent-buffer`) are supported by the CLI and validated per the table; invalid values (e.g. negative `--provinces`, out-of-range `--continents`, bad `--region`) cause exit code 1, a clear error message to stderr, and no partial output files.
- Given valid options and no invalid numeric/range values, when the user runs `melos run generate_map -- [options]`, then the tool exits with code 0 and stdout contains the topology graph section and map summary with province and sea-zone counts.
- Given `--provinces` with a non-positive value (or non-integer), when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr.
- Given `--continents` outside [2, 4], when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr (e.g. indicating the valid range).
- Given `--region` with a value other than `oldWorld` or `newWorld`, when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr.
- Given `--tile-map-image=path` and a valid run, when the tool completes, then the file at `path` exists and is a PNG; if topology graph is written, the DOT path is printed and the DOT file exists.
- Given `--world-state path` and a non-existent file, when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr.
- A basic CLI integration test (e.g. via `Process.run` or tool test) generates a small map with valid options and asserts: when `--tile-map-image` and/or `--topology-graph` are used, the tile map PNG and topology DOT files are created; stdout includes the map summary with province and sea-zone counts; the process exits with code 0.

**Integration with map-visualization and world-model**

- Ownership overlays in the game world state visualizer use the full province id (`regionId|localId`) consistently, matching [world-model-identity.md](../game/world-model-identity.md) and this spec. Operational behaviour is tested in map-visualization tests; this spec states the contract.

**Test and implementation references**

- **Unit / round-trip tests** for `MapTopology` and `TileMapResult` (de)serialization and topology helpers: `colonizethis_data` package.
- **CLI tests** for generate_map (exit codes, invalid args, output files): `tool/generate_map` (or equivalent integration test location).
- **Ownership overlay** behaviour and province id usage: map-visualization spec and tests.

---

## Integration

colonizethis_data owns the data structures and (de)serialization for topology and tile maps. For current product, map data is produced by **generation** (colonizethis_map per [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md)) or supplied from init_game, then persisted only via save/load round-trip. Static standalone map-file loading is not part of the product contract. Consumed by App, init_game, ctdev.

---

## Constraints

- Province identity always (regionId, provinceId). Tile-map ids are internal; game state is source of truth for ownership.
