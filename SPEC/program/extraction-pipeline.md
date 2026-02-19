# Extraction Pipeline

## Responsibility

Computes per-player resource extraction each turn by resolving tile connectivity and applying the extraction formula from game rules. Game rules: [extraction-and-improvements.md](../game/extraction-and-improvements.md).

---

## Data Model

**Connectivity result:** Per player, a set of connected tile keys (regionId, provinceId, x, y).

**Extraction result:** Per player, two maps (same-region and overseas) of commodity id → quantity.

---

## Algorithm / Flow

### Connectivity Resolver

**Input:** World state (provinces, owners, capital per player, tile map, per-tile roads/transport, ports per province/seaboard), topology.

**Algorithm:** From each player's capital tile, BFS on the tile graph. Tiles are nodes; edges require adjacency plus road/railroad path to capital (same region) or road path to a port on the correct seaboard (overseas). Re-run each turn. Phase 2: blockade stub (no effect).

**Output:** Per player, set of connected tile keys.

### Resource Extractor

**Input:** World state (tile map with terrain, resource, improvement level, transport level; ports; owners; tech caps), connectivity result, player prospected sets.

**Algorithm:** For each player, for each connected tile with a resource:

1. Check mineral gating: if mineral resource, tile must be in player's prospected set (per game/fog-and-exploration.md). Skip if not.
2. Production = min(improvement level, owner tech cap).
3. Effective yield = min(production, transport level) — per game/extraction-and-improvements.md.
4. Sum by commodity; split same-region vs overseas using player's capital region.

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
