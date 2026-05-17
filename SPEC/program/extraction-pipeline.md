# Extraction Pipeline

## Responsibility

Computes per-player resource extraction each turn by resolving tile connectivity and applying the extraction formula from game rules. Game rules: [extraction-and-improvements.md](../game/extraction-and-improvements.md). Connectivity rules are defined in [capital-and-connectivity.md](../game/capital-and-connectivity.md).

---

## Data Model

**Connectivity result:** Per player, a set of connected tile keys (regionId, provinceId, x, y).

**Extraction result:** Per player, two maps (same-region and overseas) of commodity id → quantity.

---

## Algorithm / Flow

### Connectivity Resolver

**Input:** World state (provinces, owners, capital per player, tile map, per-tile road level / transport, ports per province/seaboard), topology (including S–S edges for sea paths), and **blockade state** (per player, the set of port provinces that are blockaded — an enemy fleet **at sea** at war with that player is on Blockade mission targeting that province and in a sea zone adjacent to it; see [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Blockade).

**Algorithm:** Resolve connectivity per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Connectivity (Game Rule): **same region** land tiles use **Road rule** and **Town rule** (4‑neighbor adjacency; tile on or next to road path to capital, or next to a **connected** town tile). **Port connection to capital** unchanged (seaboard or road/rail from capital to port; blockade). **Overseas** tiles require port/sea path **and** in‑province link per Road/Town rule. **`townDevelopmentLevel` does not** enter the connectivity resolver. Transport/path caps for extraction are read from per‑tile state (road level; port = 4). Re-run each turn.

**Implementation notes:** (1) **Capital on seaboard:** If capital tile is adjacent to sea, all owned ports reachable via sea-path (BFS on topology over sea zones, S–S edges) from the capital's sea zone are connected for the overseas-tile step. (2) **Capital not on seaboard:** Only ports reachable by road/rail from capital (land BFS) count. Same-region ports: if capital on seaboard, treat as connected via sea-path graph; if not, only by road/rail path. (3) **Sea path:** From capital's port(s), collect sea zone IDs; BFS on topology over sea zones (nodes = sea zones, edges = S–S); mark all sea zones reachable from capital's zones; any port in an owned province whose sea zone is in that set is "sea-connected". Use that set for both same-region and overseas port connectivity.

**Output:** Per player, set of connected tile keys.

### Resource Extractor

**Input:** World state (tile map with terrain, resource, improvement level, transport level; ports; owners; tech caps — per [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md)), connectivity result (including per-tile **`pathTransportCap`**), player prospected sets.

**Algorithm:** For each player, for each connected tile with a resource:

1. Check mineral gating: if mineral resource, tile must be in player's prospected set (per game/fog-and-exploration.md). Skip if not.
2. Production = min(improvement level, owner tech cap). Owner tech cap is derived per [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md) from the player's unlocked tech (or fallback constant).
3. Province lookup for town development rules must be **region-scoped**: resolve province only within the tile's region ([world-model-identity.md](../game/world-model-identity.md)). Do not search regions in sequence. If the region has no data or no province matches the full id `regionId|localId` derived from the tile key, treat as a **logic error**: log at error and **skip** that tile (no silent fallback cap).
4. **Transport cap for yield:** Use **`ConnectivityResult.pathTransportCap[tileKey]`** from the connectivity resolver when present; it is the path bottleneck (max over admissible paths of the min road/port level on each path) per [capital-and-connectivity.md](../game/capital-and-connectivity.md) and [extraction-and-improvements.md](../game/extraction-and-improvements.md). If absent for that tile, use the tile's own transport level (port = 4, else road level if > 0, else 0). Combine with production, then apply **capital vs non‑capital** rules, **road path from tile** vs **Town‑rule‑only** branch, and **`Province.townDevelopmentLevel`** per GDD; **do not** use `townDevelopmentLevel` in the connectivity resolver step.
5. Sum by commodity; split same-region vs overseas using player's capital region.

**Output:** Per player, land totals and overseas totals (commodity → quantity).

### Cargo holds

**Cargo-hold capacity** limits how much overseas extraction is delivered to the stockpile each turn. Capacity per player = sum of `cargoHold` for all ships in that player's **home fleet** (in port at the capital province; see [auto-transport.md](auto-transport.md), [ships-and-naval.md](../game/ships-and-naval.md)). When the player has no home fleet or the sum is zero, the implementation uses a **hard-coded sensible default** (e.g. 24 units per turn); this default is documented in code and follows GDD convention-over-configuration (no config system for this value until requirements change). Overseas extraction is allocated to the stockpile by category priority until the capacity is exhausted; the rest is not delivered that turn.

### Turn Extraction Phase

1. **Connectivity:** Recompute per-player connectivity.
2. **Extract:** Run resource extractor; obtain land and overseas totals.
3. **Land:** Add same-region totals to each player's stockpile.
4. **Sea:** Allocate overseas totals to stockpile by priority, capped by **cargo holds** (see § Cargo holds); any overseas quantity beyond that cap is not delivered this turn.

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Extraction runs **after Orders and before Riches to treasury** per [turn-resolution-phases.md](turn-resolution-phases.md). |
| Upstream | World state, connectivity resolver, prospected state (fog module) |
| Downstream | Player stockpiles, overseas transport ([auto-transport.md](auto-transport.md)) |

Read-only with respect to terrain: extraction consumes improvement/road/port state produced by setup and development resolution; it does not mutate terrain.

---

## Acceptance criteria

- **Phase order:** Extraction runs in the position defined in [turn-resolution-phases.md](turn-resolution-phases.md) (after Orders, before Riches to treasury, Consumption, and Production).
- **Connectivity:** Recomputed every turn; no caching across turns. Input: world state, topology, tile maps; output: per-player connected tile set and path transport cap. The resolver implements **Road rule** and **Town rule** per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Connectivity (Game Rule); **`townDevelopmentLevel` is not** an input to connectivity.
- **Province lookup:** Town development **yield** rules use province lookup **region-scoped**: resolve province only within the tile's region ([world-model-identity.md](../game/world-model-identity.md)). Do not search regions in sequence.
- **Province missing (logic error):** Given a tile key in the connected set with a valid tile map and extractable resource for its region, when the system resolves the full province id `regionId|localId` from the tile key and no `Province` with that id exists in that region's data, then the system logs an error whose message includes `extraction province missing` (the logic logger emits a `logic:` prefix) and the tile contributes **no** extraction quantity for that turn (the system does not apply a default town-development cap).
- **Path transport cap:** Given a player's [ConnectivityResult] includes `pathTransportCap` with an entry for a connected tile key, when the resource extractor computes transport-limited yield for that tile before applying town-development caps per GDD, then the system uses that map entry as the transport cap for the min with production (falling back to the tile-only transport level only when the map has no entry for that key).
- **Mineral gating:** Mineral resources only from tiles in the player's prospected set (fog-and-exploration). Non-minerals do not require prospecting.
- **Land vs overseas:** Same-region totals added to stockpile; overseas totals allocated by priority up to cargo-hold capacity, then to stockpile; any excess overseas is not delivered that turn.
- **Blockade connectivity:** When computing connectivity, blockaded port provinces (per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Blockade) are excluded: no tiles in a blockaded port province are connected for that player. When the capital province is blockaded, overseas and same-region sea-only connections are severed; implementation must pass blockade state into the connectivity resolver.
- **Cargo holds:** Overseas delivery cap = sum of home-fleet ship cargoHold at capital port, or a hard-coded sensible default when that sum is zero; implementation accords with [auto-transport.md](auto-transport.md).
- **Logging:** Extraction and connectivity resolution log per [ctdev-logging.md](ctdev-logging.md) (e.g. `logic: extraction compute start/end`, `logic: connectivity resolve start/end`).

---

## Constraints

- All extraction rules and formulas are defined in game/extraction-and-improvements.md; this module implements, not restates, them.
- Mineral gating depends on prospected state from the fog-and-exploration module.
- Connectivity must be recomputed each turn (road/port changes, conquests).
- **Implementation alignment:** The connectivity resolver must accept blockade state (set of blockaded port provinces per player, derived from **at-sea** fleet missions per [ships-and-naval.md](../game/ships-and-naval.md)) and apply the rules in [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Blockade. Cargo-hold capacity must be derived from home fleet (in port at capital) with a documented hard-coded default when the fleet has no cargo capacity (see § Cargo holds).
