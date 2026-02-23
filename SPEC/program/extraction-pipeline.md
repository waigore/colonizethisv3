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

**Input:** World state (provinces, owners, capital per player, tile map, per-tile road level / transport, ports per province/seaboard), topology (including S–S edges for sea paths).

**Algorithm:** A port is connected to the capital iff (1) capital is on the seaboard (capital tile adjacent to sea), or (2) there is a road/rail path from capital to that port. Overseas tiles are connected if they have a road path to a port in that province that is connected to the capital (by (1) or (2)). Same region: from capital tile, BFS on the tile graph (edges: adjacency; expand only from capital or tiles with road/railroad/port). Overseas: ports whose sea zone is reachable from the capital's sea zone via sea–sea edges in topology are "sea-connected"; from those ports, BFS by road/rail within the province. Transport level is read from the same per-tile state (road level; port = 4) for extraction. Re-run each turn. Blockade is currently stubbed (no effect). See [capital-and-connectivity.md](../game/capital-and-connectivity.md).

**Implementation notes:** (1) **Capital on seaboard:** If capital tile is adjacent to sea, all owned ports reachable via sea-path (BFS on topology over sea zones, S–S edges) from the capital's sea zone are connected for the overseas-tile step. (2) **Capital not on seaboard:** Only ports reachable by road/rail from capital (land BFS) count. Same-region ports: if capital on seaboard, treat as connected via sea-path graph; if not, only by road/rail path. (3) **Sea path:** From capital's port(s), collect sea zone IDs; BFS on topology over sea zones (nodes = sea zones, edges = S–S); mark all sea zones reachable from capital's zones; any port in an owned province whose sea zone is in that set is "sea-connected". Use that set for both same-region and overseas port connectivity.

**Output:** Per player, set of connected tile keys.

### Resource Extractor

**Input:** World state (tile map with terrain, resource, improvement level, transport level; ports; owners; tech caps — per [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md)), connectivity result, player prospected sets.

**Algorithm:** For each player, for each connected tile with a resource:

1. Check mineral gating: if mineral resource, tile must be in player's prospected set (per game/fog-and-exploration.md). Skip if not.
2. Production = min(improvement level, owner tech cap). Owner tech cap is derived per [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md) from the player's unlocked tech (or fallback constant).
3. Province lookup for town development cap must be **region-scoped**: resolve province only within the tile's region (game/world-model-identity.md). Do not search regions in sequence.
4. Effective yield = min(production, transport level, town development level) — transport level is the tile's road level (or 4 for port); per game/extraction-and-improvements.md.
5. Sum by commodity; split same-region vs overseas using player's capital region.

**Output:** Per player, land totals and overseas totals (commodity → quantity).

### Turn Extraction Phase

1. **Connectivity:** Recompute per-player connectivity.
2. **Extract:** Run resource extractor; obtain land and overseas totals.
3. **Land:** Add same-region totals to each player's stockpile.
4. **Sea:** Allocate overseas totals to stockpile by priority, capped by cargo holds (stub).

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Extraction (after Build/Work, before Production) |
| Upstream | World state, connectivity resolver, prospected state (fog module) |
| Downstream | Player stockpiles, overseas transport ([auto-transport.md](auto-transport.md)) |

Read-only with respect to terrain: extraction consumes improvement/road/port state produced by setup and development resolution; it does not mutate terrain.

---

## Constraints

- All extraction rules and formulas are defined in game/extraction-and-improvements.md; this module implements, not restates, them.
- Mineral gating depends on prospected state from the fog-and-exploration module.
- Connectivity must be recomputed each turn (road/port changes, conquests).
