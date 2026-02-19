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
| **Game** | Top-level container. Holds game id, metadata, current **WorldState**, list of **Player**s (Great Powers), list of **Minor Nation**s, list of **Tribe**s (or single list of Factions with type), and optional reference to resolved config (game load). |
| **WorldState** | Snapshot at a point in time. Holds **turn state** (phase, turn number), **region data** (provinces and units per region), **player visibility** (per player, per tile), and **prospected tiles** (per player). See [fog-and-exploration.md](fog-and-exploration.md), [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md). |
| **Province** | Land region. Id, region id, **owner** (faction id: Great Power, Minor Nation, or Tribe). Contains tiles (terrain, optional resource, improvements). Effective extraction capped by owner's tech. Neighbours from topology. |
| **SeaZone** | Water region. Id, region id. Adjacency from topology; naval movement Phase 2+. |
| **Tile map** | Per-region 2D grid; each cell assigned to a province or sea zone; produced by map generation from topology. |
| **Unit** | Military or civilian (Phase 2+). Id, type, **owner** (faction id). **Location depends on unit kind:** **Civilian units:** location is **tileKey only** (required, format `regionId|provinceId|x|y`); province and region are derived from tileKey. **Military units (armies):** location is **provinceId** (province-level; no tileKey). **Ships (navies):** location is at **fleet / sea zone** level (no tileKey). Tile keys apply to civilians only; armies and ships interact at province/sea-zone level (movement, attacking, patrolling, etc.). |
| **Player** | Great Power. Id, display name, human vs AI, treasury (Phase 2+), **stockpile** (centralized commodity repository; Phase 2+), **capitalProvinceId**, **capitalTile** (set in capital-choice phase), and later: relations, tech. Only Great Powers submit orders and are victory-eligible. See [factions.md](factions.md). |
| **Orders** | Per–Great Power orders for the current turn (e.g. movement, build). Minor Nations and Tribes do not submit orders. Phase 1 may hold an empty or stub structure; full order types in Phase 2+. |

No game logic in models; they are data and serialization only.

---

## Relations and Containment

- **Game** → one **WorldState** (current), many **Player**s (Great Powers), many **Minor Nation**s, many **Tribe**s, optional **turnTimeMapping** (from resolved config; when absent for legacy saves, use default per [turn-time-mapping.md](turn-time-mapping.md)). Calendar year derived via `turnToYear(turnNumber, turnTimeMapping)`.
- **Player** → **Stockpile** (commodity quantities; Phase 2+). Extraction in provinces flows to owning player's stockpile. See [stockpiles-and-production.md](stockpiles-and-production.md).
- **Player** → **WorkerPool** (or Population; Phase 2+). Per-player population for production; distinct from Unit. See [workers-and-population.md](workers-and-population.md). Civilian units: [civilian-units.md](civilian-units.md).
- **Minor Nation / Tribe** → Own provinces; have capital (assigned at game setup). Do not submit orders; reactive only (defend, trade targets, diplomacy targets). See [factions.md](factions.md).
- **WorldState** → two region blobs: Old World data, New World data. Each blob: list of **Province**s, list of **Unit**s (or embedded per province as needed for serialization).
- **Province** → belongs to one region; has optional **owner** (faction id); contains tiles (from static tile map + mutable improvement state). **Mutable tile state** (keyed by region, province, tile): **improvement level** (0–4), **road level** (0 / 1 / 2; 4 for railroad or derived from port). **Ports:** one per (provinceId, seaZoneId) or per tile with port + seaZoneId; world state records which tiles have a port and for which seaboard. Each tile: terrain type, optional resource, improvement, road; effective yield = min(improvement level, owner's tech cap), then min(..., transport level). Neighbours (P and S) from topology graph. See [map-data.md](../program/map-data.md): extraction level and road are mutable game state.
- **SeaZone** → belongs to one region; neighbours from topology graph.
- **Unit** → has **owner** (faction id). **Civilian** units have **tileKey** (location; province/region derived from it). **Military** land units have **provinceId**. Naval units are located via Fleet/sea zone.
- **Orders** → keyed by Great Power id (or attached to Game/WorldState for “orders for this turn”).
- **Topology and tile maps** → static per map/scenario (in colonizethis_data or loaded by tools); not stored in WorldState.

Config is loaded at **game creation** only. Resolved ruleset/config lives in colonizethis_data (program-level for MVP); app passes it into Game at load. See [ruleset-config.md](../program/ruleset-config.md): merge order Base → difficulty → scenario; output stored with the game; colonizethis_logic and colonizethis_ai consume resolved config only.

---

## Serialization

All entities support **toJson** / **fromJson** (or equivalent) for persistence. colonizethis_save uses these to read/write game state (e.g. Hive `games` box keyed by game id).

---

## Province identity and lookup (multi-region)

In a multi-region world, **province lookup must always use regionId + provinceId**. A bare province id is not sufficient to locate a province, because the same local id can exist in more than one region (e.g. `p1` in Old World and `p1` in New World).

- **Game-state province id format:** All province ids stored in game state (e.g. `Province.id`, `Unit.provinceId`, `Player.capitalProvinceId`, order fields) use a **prefixed** form: `regionId|localId` (e.g. `oldWorld|p1`, `newWorld|nw1`). This makes every province id globally unique and prevents a province from being resolved in the wrong region.
- **Tile key format:** Tile keys remain 4-part: `regionId|localId|x|y`. The second segment is the **local** province id (as in topology/tile maps); the full province id is `regionId|localId`.
- **Map visualizers:** When turning topology/tile maps into view models (ownership fill, per-player maps, unit markers), code MUST first derive the full province id from the region + local id before reading any game state. Examples:
  - Ownership: convert `regionId` + `regionCellId` (e.g. `oldWorld` + `p1`) into `oldWorld|p1` and use that full id to query `Province.ownerId`.
  - Province names: resolve `oldWorld|p1` / `newWorld|p1` into the corresponding `Province` and use its `displayName`.
  - Unit markers: build a map from **full** province id (`regionId|localId`) to a representative tile `(x, y)`, then place markers by looking up units via `Unit.provinceId` (also full). Do not key these maps by bare local ids.
- **Lookup rule:** Code must never locate a province by province id alone. Use (regionId, provinceId) or a prefixed full id, and resolve the province only within that region. Do **not** infer region by searching oldWorld then newWorld or by string heuristics (e.g. `startsWith('newWorld')`). If a province cannot be found, treat it as a logic error (e.g. throw `StateError`); do not fall back to a default region.

---

## Invariants (Phase 1)

- Every province has a region id. Every unit has owner and location (civilian: tileKey; military: province id; naval: fleet/sea zone).
- **Province lookup:** Always use regionId + provinceId (or prefixed id); never use province id in isolation or assume a default region.
- Resource on a tile is allowed only in regions and terrain types specified for that resource (GDD 04b).
- Turn state (phase, turn number) lives in WorldState; TurnResolver takes WorldState in, returns new WorldState out (see [turn-resolution.md](../program/turn-resolution.md)).
