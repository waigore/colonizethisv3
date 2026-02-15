# World Model

**SPEC/game** — Core entities, both regions, and their relations. Derived from GDD/TDD. Implementation: [colonizethis_models](../program/repo-and-packages.md). Config loading: [SPEC/program/ruleset-config.md](../program/ruleset-config.md). Map topology: [map-topology.md](map-topology.md). Tile map and generation: [tile-map-and-generation.md](tile-map-and-generation.md).

---

## Regions

MVP has two regions (per [mvp-scope.md](../project/mvp-scope.md)):

- **Old World** — Victory is decided here (e.g. control 31+ provinces).
- **New World** — Frontier for resources, riches, and colonies. Fixed maps per region; Asia is post-MVP.

Each region has a fixed set of provinces and sea zones. Regions are identified by an enum or stable id (e.g. `oldWorld`, `newWorld`).

---

## New World and Colonies

New World provinces can be **owned** by a player (same ownership model as Old World). Extraction and production work identically in both regions: owned province tiles produce resources that flow to the owner's stockpile. **Colonies** are simply owned New World provinces; there is no separate colony entity. Asia is post-MVP.

---

## Map Topology (summary)

The map is a graph. **Nodes:** provinces (P) and sea zones (S); each has id and region id. **Edges** are undirected links: **P1 <-> P2** (contiguous land; armies move only between adjacent provinces); **P1 <-> S1** (province next to sea). Provinces/sea zones can be adjacent **across regions** (e.g. Europe–Asia). World topology is one graph; tile maps are per region. See [map-topology.md](map-topology.md).

---

## Provinces, Tiles, and Tile Map

**Logically:** Each province **contains** a set of **terrain tiles**. Each tile has a **terrain type**, at most one **resource** (region- and terrain-constrained per GDD 04b), and **improvements** (extraction level, road). Effective extraction = min(improvement level, owner's tech-allowed max). **Geospatially:** Tiles live in a **2D grid**. The grid is **per region** — each region has its own grid; tiles are assigned to provinces or sea zones; grid adjacency respects the topology. A **tile map** is the 2D grid for one region, produced by tile-based map generation from topology. See [tile-map-and-generation.md](tile-map-and-generation.md).

---

## Core Entities

| Entity | Responsibility |
|--------|----------------|
| **Game** | Top-level container. Holds game id, metadata, current **WorldState**, list of **Player**s, and optional reference to resolved config (game load). |
| **WorldState** | Snapshot at a point in time. Holds **turn state** (phase, turn number), and **region data** (provinces and units per region). |
| **Province** | Land region. Id, region id, owner. Contains tiles (terrain, optional resource, improvements). Effective extraction capped by owner's tech. Neighbours from topology. |
| **SeaZone** | Water region. Id, region id. Adjacency from topology; naval movement Phase 2+. |
| **Tile map** | Per-region 2D grid; each cell assigned to a province or sea zone; produced by map generation from topology. |
| **Unit** | Military or civilian (Phase 2+). Id, type, owner, location (province id or sea zone id for naval), and later: strength, movement. |
| **Player** | Great Power. Id, display name, human vs AI, treasury (Phase 2+), **stockpile** (centralized commodity repository; Phase 2+), and later: relations, tech. |
| **Orders** | Per-player orders for the current turn (e.g. movement, build). Phase 1 may hold an empty or stub structure; full order types in Phase 2+. |

No game logic in models; they are data and serialization only.

---

## Relations and Containment

- **Game** → one **WorldState** (current), many **Player**s.
- **Player** → **Stockpile** (commodity quantities; Phase 2+). Extraction in provinces flows to owning player's stockpile. See [stockpiles-and-production.md](stockpiles-and-production.md).
- **Player** → **WorkerPool** (or Population; Phase 2+). Per-player population for production; distinct from Unit. See [workers-and-population.md](workers-and-population.md). Civilian units: [civilian-units.md](civilian-units.md).
- **WorldState** → two region blobs: Old World data, New World data. Each blob: list of **Province**s, list of **Unit**s (or embedded per province as needed for serialization).
- **Province** → belongs to one region; has optional **owner** (player id); contains tiles (from static tile map + mutable improvement state). Each tile: terrain type, optional resource (region- and terrain-constrained), extraction level, road; effective yield = min(improvement level, owner's tech cap). Neighbours (P and S) from topology graph.
- **SeaZone** → belongs to one region; neighbours from topology graph.
- **Unit** → has **owner** (player id), **location** (province id or sea zone id).
- **Orders** → keyed by player id (or attached to Game/WorldState for “orders for this turn”).
- **Topology and tile maps** → static per map/scenario (in colonizethis_data or loaded by tools); not stored in WorldState.

Config is loaded at **game creation** only. Resolved ruleset/config lives in colonizethis_data (program-level for MVP); app passes it into Game at load. See [ruleset-config.md](../program/ruleset-config.md): merge order Base → difficulty → scenario; output stored with the game; colonizethis_logic and colonizethis_ai consume resolved config only.

---

## Serialization

All entities support **toJson** / **fromJson** (or equivalent) for persistence. colonizethis_save uses these to read/write game state (e.g. Hive `games` box keyed by game id).

---

## Invariants (Phase 1)

- Every province has a region id. Every unit has owner and location (province id).
- Resource on a tile is allowed only in regions and terrain types specified for that resource (GDD 04b).
- Turn state (phase, turn number) lives in WorldState; TurnResolver takes WorldState in, returns new WorldState out (see [turn-resolution.md](../program/turn-resolution.md)).
