# World Model

**SPEC/game** — Core entities, both regions, and their relations. Config: [ruleset-config.md](../program/ruleset-config.md). Topology: [map-topology.md](map-topology.md). Tiles: [tile-map-and-generation.md](tile-map-and-generation.md). Province identity: [world-model-identity.md](world-model-identity.md).

---

## Regions

**Old World** (victory; e.g. 31+ provinces) and **New World** (frontier, colonies). Fixed maps per region; Asia later. Regions use stable ids (e.g. `oldWorld`, `newWorld`). New World provinces owned like Old World; **colonies** = owned New World provinces.

---

## Map Topology (summary)

Graph: nodes = provinces (P) and sea zones (S); edges = **P↔P** (land adjacency), **P↔S** (coast). World topology is one graph; tile maps per region. See [map-topology.md](map-topology.md).

---

## Provinces and Tiles

Each province **contains** terrain tiles (terrain type, optional resource, improvements). Effective extraction = min(improvement level, owner's tech cap). Tiles in 2D grid per region; tile map produced by map generation. See [tile-map-and-generation.md](tile-map-and-generation.md).

---

## Core Entities

| Entity | Responsibility |
|--------|----------------|
| **Game** | Top-level. Game id, metadata, current **WorldState**, **Player**s (Great Powers), **Minor Nation**s, **Tribe**s, optional resolved config. May carry optional **greatPowerColorOverride** (setup-time GP map colours) for display; when present, map visualizers and ctdev use it; when absent, GDD default colours apply. |
| **WorldState** | Snapshot. Turn state (phase, turn), region data (provinces, units), player visibility, prospected tiles, **spy reveal timers** (playerId → provinceKey → turns until fog returns), optional **purchased tiles** (tileKey → buyer playerId for Minor/Tribe tiles purchased by GP). See [fog-and-exploration.md](fog-and-exploration.md). |
| **Province** | Land region. Id, region id, **owner** (faction id). Optional **townTileKey** (tile key of province's town for extraction). Tiles; neighbours from topology. |
| **SeaZone** | Water region. Id, region id. Adjacency from topology. |
| **Tile map** | Per-region 2D grid; cells → province or sea zone. |
| **Unit** | Military or civilian. Owner, type. Location: civilian = tileKey; military = province id; naval = fleet/sea zone. |
| **Player** | Great Power. Id, name, stockpile, capitalProvinceId, capitalTile. Orders and victory-eligible. See [factions.md](factions.md). |
| **Orders** | Per–Great Power orders (movement, build). May be stub. |

Models: data and serialization only; no game logic.

---

## Relations and Containment (brief)

**Game** → one WorldState, many Players/Minor Nations/Tribes, optional turnTimeMapping. **Player** → Stockpile, WorkerPool. **WorldState** → region blobs (provinces, units). **Province** → owner, tiles, neighbours. **Unit** → owner; location by kind (tileKey, provinceId, fleet). **Orders** → keyed by Great Power. Topology/tile maps: static; loaded at game creation. Config: Base → difficulty → scenario; stored with game.

---

## Serialization

All entities support JSON (or equivalent) for persistence; save layer reads/writes by game id.

---

## Invariants

- Every province has region id. Every unit has owner and location.
- Province lookup: always regionId + provinceId (or prefixed id). See [world-model-identity.md](world-model-identity.md).
- Resource per tile only where region/terrain allows.
- Turn state in WorldState; resolution takes WorldState in, returns new out. See [turn-resolution.md](../program/turn-resolution.md).
