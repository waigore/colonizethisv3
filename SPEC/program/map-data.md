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

**Place:** `tool/generate_map/`. **Mode:** Generate from N and C via `--provinces`, `--continents`. Infer topology. Always output: topology graph description and map summary on stdout. Optionally: tile map PNG (via `--tile-map-image`), topology DOT and PNG (when `--tile-map-image` or `--topology-graph` is used). **Run:** `melos run generate_map -- [options]`. **Logging:** Operational and diagnostic output follows [ctdev-logging.md](ctdev-logging.md) (logger with `map:` prefix; errors to stderr and non-zero exit).

### CLI options (MVP)

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

- Given valid options and no invalid numeric/range values, when the user runs `melos run generate_map -- [options]`, then the tool exits with code 0 and stdout contains the topology graph section and map summary with province and sea-zone counts.
- Given `--provinces` with a non-positive value (or non-integer), when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr.
- Given `--continents` outside [2, 4], when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr (e.g. indicating the valid range).
- Given `--region` with a value other than `oldWorld` or `newWorld`, when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr.
- Given `--tile-map-image=path` and a valid run, when the tool completes, then the file at `path` exists and is a PNG; if topology graph is written, the DOT path is printed and the DOT file exists.
- Given `--world-state path` and a non-existent file, when the user runs the CLI, then the tool exits with code 1 and writes an error message to stderr.

---

## Integration

colonizethis_data owns loading. colonizethis_map implements generation per [tile-map-gen-algorithm.md](tile-map-gen-algorithm.md). Consumed by App, init_game, ctdev.

---

## Constraints

- Province identity always (regionId, provinceId). Tile-map ids are internal; game state is source of truth for ownership.
