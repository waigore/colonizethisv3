# Extraction Pipeline

**SPEC/program** — Connectivity resolver and resource extractor used in the extraction phase. Reference: [capital-and-connectivity.md](../game/capital-and-connectivity.md), [extraction-and-improvements.md](../game/extraction-and-improvements.md), [auto-transport.md](auto-transport.md).

---

## Connectivity Resolver

**Input:** Game state (provinces, owners, capital per player, tile map, per-tile roads, ports per province/seaboard), topology, optional blockade stub. Extraction logic is **read-only** with respect to terrain: it consumes improvement/road/port state produced by setup and development resolution and does not mutate it.

**Output:** Per player, a set of **connected** tile keys (e.g. per (regionId, provinceId, x, y)) or a per-province connected flag sufficient to know which tiles contribute to extraction.

**Algorithm:** From each player’s capital tile, run BFS on the tile graph: tiles are nodes; edges are adjacency plus “on or adjacent to road/railroad” forming a path to the capital or (for overseas) to a port on the correct seaboard. For overseas provinces, a tile is connected if there is a road path to a port in that province on the seaboard that has a sea path to the capital’s sea. Re-run each turn. Phase 2: blockade stub (no effect).

---

## Resource Extractor

**Input:** Game state (tile map: terrain, resource per cell; per-tile improvement level, per-tile road level; ports; owners; tech caps), and the connectivity result from the connectivity resolver.

**Output:** Per player: **land** totals (same-region) and **overseas** totals (different region), each a map commodity id → quantity. No direct “apply to stockpile”; that stays in turn resolution.

**Logic:** For each player, for each connected tile that has a resource: **production** = min(improvement level, owner tech cap); **effective extraction** = min(production, transport level). Sum by commodity; split by same-region vs overseas using the player’s capital region.

---

## Turn Extraction Phase (Order)

1. **Connectivity:** Recompute per-player connectivity (connectivity resolver).
2. **Extract:** Run resource extractor; obtain per-player land and overseas commodity totals.
3. **Land:** Add same-region totals to each player’s stockpile.
4. **Sea:** Allocate overseas totals to stockpile by priority, capped by cargo holds (stub); add allocated amounts to stockpile.

Existing `applyExtractionForPlayers` can be refactored to accept the extractor output (land + sea result) or remain as two steps (land add, then sea add). Owner: colonizethis_logic.
