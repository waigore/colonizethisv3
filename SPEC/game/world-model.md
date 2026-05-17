# World Model

**SPEC/game** — Core entities, both regions, and their relations. Config: [ruleset-config.md](../program/ruleset-config.md). Topology: [map-topology.md](map-topology.md). Tiles: [tile-map-and-generation.md](tile-map-and-generation.md). Province identity: [world-model-identity.md](world-model-identity.md).

---

## Regions

**Old World** (victory; e.g. 31+ provinces) and **New World** (frontier, colonies). Fixed maps per region; Asia later. Regions use stable ids (e.g. `oldWorld`, `newWorld`). New World provinces owned like Old World; **colonies** = owned New World provinces.

---

## Map Topology (summary)

Topology is **per region**: each region has its own graph. Nodes = provinces (P) and sea zones (S); edges = **P↔P** (land adjacency), **P↔S** (coast), **S↔S** (sea paths within region). Regions connect **only** via **warp zones**. Tile maps per region. See [map-topology.md](map-topology.md).

---

## Provinces and Tiles

Each province **contains** terrain tiles (terrain type, optional resource, improvements). Effective extraction = min(improvement level, owner's tech cap). Tiles in 2D grid per region; tile map produced by map generation. See [tile-map-and-generation.md](tile-map-and-generation.md).

---

## Core Entities

| Entity | Responsibility |
|--------|----------------|
| **Game** | Top-level. Game id, metadata, current **WorldState**, **Player**s (Great Powers), **Minor Nation**s, **Tribe**s, optional resolved config. May carry optional **greatPowerColorOverride** (runtime GP **player id** → RGB, seeded at setup from semantic slot order × GDD defaults) for display; when present, map visualizers and ctdev use it; when absent (legacy saves), tints may fall back to a generic palette. Carries **politicalGlyphByPlayerId** (map of faction id → 1-character political map glyph) used by map UIs for the political ownership layer; glyphs are computed once during game setup and persisted in saves. Carries **calendarCampaignHalted** when the campaign calendar cap has been reached without military victory (see [turn-time-mapping.md](turn-time-mapping.md) § Campaign calendar cap). |
| **WorldState** | Snapshot. Turn state (phase, turn), region data (provinces, units), **armies** (land military: owner, stationed province, regiment id list — see [military-armies.md](military-armies.md)), **fleets** (naval), player visibility, prospected tiles, **spy reveal timers** (playerId → provinceKey → turns until fog returns), optional **purchased tiles** (tileKey → buyer playerId for Minor/Tribe tiles purchased by GP), and **sea-zone display names** keyed by prefixed sea-zone id (`regionId|localSeaZoneId`) for UI labels. See [fog-and-exploration.md](fog-and-exploration.md). |
| **Province** | Land region. Id, region id, **owner** (faction id). Optional **townTileKey** (tile key of province's town for extraction). Tiles; neighbours from topology. |
| **SeaZone** | Water region. Id, region id. Adjacency from topology. |
| **Tile map** | Per-region 2D grid; cells → province or sea zone. |
| **Unit** | Military or civilian. Owner, type. **Land military:** each regiment unit is a member of exactly one **army** (army holds regiment ids; regiment `locationProvinceId` matches the army’s stationed province). **Canonical placement** is `locationProvinceId`: when `tileKey` is non-empty, it is derived from the tile key (`regionId|localId`); otherwise the stored province applies (e.g. military without a tile). The model exposes only `locationProvinceId` (no separate public “raw” province field). **JSON:** the wire key remains `provinceId` for saves; it always reads/writes the **canonical** `locationProvinceId`. When both `tileKey` and `provinceId` are present, load may align placement from the tile key only if the key has the canonical four-part shape and both values are prefixed province ids per [world-model-identity.md](world-model-identity.md). Naval uses fleet/sea zone as elsewhere in rules. |
| **Player** | Great Power. Id, name, stockpile, capitalProvinceId, capitalTile. Orders and victory-eligible. See [factions.md](factions.md). |
| **Orders** | Per–Great Power orders (movement, build). May be stub. |

Models: data and serialization only; no game logic.

---

## Relations and Containment (brief)

**Game** → one WorldState, many Players/Minor Nations/Tribes, optional turnTimeMapping. **Player** → Stockpile, WorkerPool. **WorldState** → region blobs (provinces, units). **Province** → owner, tiles, neighbours. **Unit** → owner; canonical location `locationProvinceId` (tile-first when `tileKey` set); JSON `provinceId` is that canonical value. **Orders** → keyed by Great Power. Topology/tile maps: static; loaded at game creation. Config: Base → difficulty → scenario; stored with game.

---

## Serialization

All entities support JSON (or equivalent) for persistence; save layer reads/writes by game id.

---

## Invariants

- Every province has region id. Every unit has owner and location.
- Province lookup: always regionId + provinceId (or prefixed id). See [world-model-identity.md](world-model-identity.md).
- Resource per tile only where region/terrain allows.
- Turn state in WorldState; resolution takes WorldState in, returns new out. See [turn-resolution.md](../program/turn-resolution.md).
- **Fleets:** Each ship hull in `WorldState.fleets` has a **unique instance id** within the save; fleet rows store instances with catalog `typeId`. Counts by type in UI or formulas are aggregations. See [ships-and-naval.md](ships-and-naval.md) § Ship instances.
- **Armies:** Each land military regiment unit id appears in **exactly one** army’s member list in `WorldState.armies` (or equivalent per-region storage per TDD). Each army has a stable **army id** for the life of the save. See [military-armies.md](military-armies.md).

- **Province capture / handover:** When the game records a **change of control** of a province from one faction to another (e.g. combat capture per [combat.md](combat.md)), the new `Province.ownerId` is always a **non-empty** faction id (another Great Power, Minor Nation, or Tribe). Handovers do not clear ownership to null/empty as the outcome of capture. A null/empty `ownerId` is reserved for **uncolonized** frontier provinces (e.g. New World before first colonization), not as the “new owner” after losing control. `province_captured` events and turn-news capture lines require both previous and new owners to be non-empty; see [game-events.md](../program/game-events.md) and [turn-news-digest.md](../program/turn-news-digest.md).

---

## Acceptance Criteria

- Given a game with at least one region configured with a stable region id such as `oldWorld` or `newWorld`  
  When the System creates or loads the Game entity for that world  
  Then the System stores the Game with a WorldState that contains region data scoped by region id, and the System keeps region ids stable across saves and loads so that any reference to `oldWorld` or `newWorld` resolves to the same logical region.

- Given a WorldState that contains at least one Province and one SeaZone for a region  
  When the System loads or serializes the WorldState  
  Then the System ensures that each Province and SeaZone has both a region id and a local id, that Provinces are marked as land regions and SeaZones as water regions, and that province neighbours and sea-zone adjacencies are derived from the topology for that region as described in [map-topology.md](map-topology.md).

- Given a WorldState with a Tile map for a region and at least one Province that owns tiles in that region  
  When the System computes effective extraction for that Province  
  Then the System uses the tiles assigned to that Province in the per-region 2D grid, applies terrain, resource, and improvement data from those tiles, and caps extraction for each tile at the owning Player’s tech cap as defined in the active ruleset.

- Given a supported resolution step that applies a **faction-to-faction** province ownership change (previous and new owner each a non-empty faction id)  
  When the System commits that change to `WorldState`  
  Then the province’s `ownerId` equals the new faction id and is non-empty, and the System does not represent a successful capture by setting `ownerId` to null or empty.

- Given a Game entity that has Players, Minor Nations, Tribes, and a WorldState with provinces and units  
  When the System serializes the Game to JSON and later reloads it by game id  
  Then the System restores the same WorldState (including province ownership, unit locations, and world-level metadata), the same set of Players, Minor Nations, and Tribes, and preserves the turn state so that a subsequent turn resolution produces the same outcomes as if the game had not been unloaded.

- Given a WorldState with a valid turn state and region blobs (provinces and units)  
  When the System executes turn resolution as described in [turn-resolution.md](../program/turn-resolution.md)  
  Then the System treats the incoming WorldState as immutable input, produces a new WorldState with updated provinces and units according to the game rules, and keeps the invariant that each province has a region id and each unit has both an owner and a location in the resulting WorldState.

- Given a WorldState that follows [military-armies.md](military-armies.md), when the System validates land military invariants, then every land military regiment unit id appears in exactly one army’s member list, each army has exactly one stationed province matching its regiments’ `locationProvinceId`, and each Great Power has exactly one Home Army at the capital when a capital exists.
