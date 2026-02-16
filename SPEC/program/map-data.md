# Map Data: Topology and Tile Maps

**SPEC/program** — Format and ownership of static map data (topology, tile maps) and the generate_map CLI. Game semantics: [SPEC/game/world-model.md](../game/world-model.md), [SPEC/game/map-topology.md](../game/map-topology.md). Tile map generation: [tile-map-generation.md](tile-map-generation.md).

---

## Topology format

**Region topology** is stored as a graph:

- **Nodes:** List of nodes with id, region id, and type (province | sea zone). Cross-region: nodes may belong to different regions.
- **Edges:** List of undirected edges (id1, id2). Semantics: P<->P (contiguous land), P<->S (province next to sea), optionally S<->S. Edges may reference nodes from different regions (cross-region adjacency).
- **Storage:** File per region or one world graph with region labels; format (e.g. JSON or YAML) is implementation-defined. Loaded at game creation; colonizethis_data owns loading and provides topology to logic and tools. When generating maps, topology is **inferred** from the tile map.

---

## Tile map format

**Per-region 2D grid (static per scenario).** Each cell: region id (province or sea zone), type (land/water), **terrain type** (for land), **resource** (optional; at most one). Resource must be allowed for that **region** and that **terrain type**; resource–region and resource–terrain rules live in colonizethis_data. Extraction level and road are **mutable** game state (keyed by region, province, tile), not part of the static tile map (or only as initial scenario state). Produced by tile-based map generation ([tile-map-generation.md](tile-map-generation.md)) or loaded from data. Not persisted in game save; static per map/scenario.

---

## Map generation tool (unified)

A single tool supports end-to-end map generation. **Place:** `tool/generate_map/`.

**Mode:** Generate map from province count (N) and continent count (C) via `--provinces` and `--continents`. Infer topology from the grid. Output graph description, map summary, tile map PNG, and **topology graph** (DOT file; PNG when Graphviz installed).

**Options:** `--provinces N` (default: 60), `--continents M` (default: 3; must be 2–4), `--region oldWorld|newWorld` (default: oldWorld), `--tiles-per-province N`, `--sea-fraction F`, `--interactive`, `--tile-map`, `--tile-map-image[=path]`, `--seed <n>`, `--world-state <path>`, `--join-continents` (default off), `--seed-before-assignment` (default off), `--skip-fill-lakes` (default off), `--continent-buffer N` (default 2).

**Topology graph visualization:** Export topology to Graphviz DOT format. Write `.dot` file; render PNG with Graphviz. If Graphviz not found or fails: warn user ("Graphviz not installed; run `brew install graphviz` to render topology graph"), write `.dot` only, continue. Show topology graph PNG alongside tile map PNG when both are produced.

- **Map-aligned layout:** When a tile map is available (e.g. during map generation), nodes are positioned to match their locations on the map. Centroids (average x, y of all tiles per region id) are computed from the tile map and emitted as `pos="x,y!"` in the DOT output. Grid coordinates are scaled to **points** (neato -n expects points; 72 points = 1 inch). Default scale: 12 points per grid cell so a typical map renders at readable size. Graphviz's **neato** layout engine (part of Graphviz) supports fixed positions via the `pos` attribute; the `!` suffix marks the position as fixed.
- **Rendering:** When positions are present, use `neato -n -Tpng` (the `-n` flag tells neato to use existing positions instead of computing layout). When positions are absent (e.g. topology-only export, no tile map), fall back to `dot -Tpng` for automatic layout.
- **Node labels:** When tile counts are available, each node label is `nodeId (tileCount)` — e.g. `p25 (33)` means province p25 has 33 tiles. The number in brackets is the tile count.
- **Node size:** Nodes use fixed dimensions (width=0.2, height=0.2 inches, fixedsize=true, fontsize=8) to avoid overlap in dense graphs.

**Run:** From repo root: `melos run generate_map -- [options]`.

### Tile map PNG export

When the tool (or colonizethis_data) exports a tile map as PNG:

- **Fill:** When terrain data is present, each cell is colored by **terrain type**. Sea zones use a single **deep blue**. Land cells use a fixed color per terrain (plains, forest, hills, mountain, swamp). When terrain data is absent, fill falls back to region-based coloring (one color per province/sea zone) for backward compatibility.
- **Borders:** Borders are drawn on edges between two cells that belong to different regions. **Land borders** (province–province and province–sea) are drawn in **black**. **Sea zone borders** (sea–sea, i.e. between two different sea zone ids) are drawn in **light blue** (e.g. RGB 173, 216, 230) so sea zone boundaries are visible. Legend text should indicate: black = land borders, light blue = sea zone borders.
- **Legend:** When terrain is present, the legend lists **terrain types** with a color swatch and label. When seed positions are provided, the image MAY draw continent seeds and land seeds with per-continent coloring.
- **Resources:** When resource data is present (`result.resourceGrid != null`), each land cell that has a resource displays a single **lowercase letter** at cell center: `g` = grain, `t` = timber, `i` = iron. Letters are drawn **last** on the map (after borders and seed markers) so they remain visible. The legend includes a "Resources" section listing each letter and its resource name (e.g. "g  Grain").
- **Land seeds:** Land seeds are drawn as **small circles** at cell centers, with a **black outline** (fill + outline), so they are clearly distinguishable from the square tile cells. Continent seeds remain the larger, distinct-style markers.
- **Region id on tiles:** Each tile (cell) MAY display its **region id** (e.g. p1, s2) as text on the map for identification. The id is drawn in **red** so it stands out from terrain and borders. When resources are present, resource letters are drawn at cell center and remain visible; region id placement (e.g. top-left of cell) should avoid obscuring resource letters where possible.
- **Tile size:** **Tile size** (pixels per cell, "cell size") is configurable so that tile details are easier to see. The default cell size is **24** pixels per tile (implementation may use a larger default than previously). The generate_map tool and colonizethis_map APIs accept an optional cell size parameter; when not specified, the default is used.
- **Ownership:** Implemented in colonizethis_map (tile_map_visualization); consumed by the generate_map tool.

---

## Tile-based map generation

Implemented in colonizethis_map. Algorithm and contract: [tile-map-generation.md](tile-map-generation.md). Game-side semantics: [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). **Grid size** derived from N, C, target tiles per province, sea fraction. Input: province count (N), continent count (C), region id, map params. Output: per-region tile map (2D grid) and inferred MapTopology.
