# Tile Map and Map Generation

**SPEC/game** — Tile map (per-region 2D grid) and tile-based map generation. See [world-model.md](world-model.md) for provinces and tiles; [map-topology.md](map-topology.md) for topology.

---

## Tile map

A **tile map** is the 2D grid for **one region**. Each cell is assigned to a **province** or **sea zone** (by id). Each **land** cell has a **terrain type** and an optional **resource** (at most one). Resource placement must satisfy **region** (oldWorld only, newWorld only, or both) and **terrain** (allowed terrain types per resource) rules. Improvements (extraction level, road) are **mutable** and stored in world state; the tile map holds static terrain and resource (and optional initial improvement state for scenarios). The grid is per region; the world has one tile map per region, not one global grid.

---

## Map generation

A **tile-based map generation** algorithm produces a tile map for a region from its **topology** (and optional cross-region links). Requirements:

- Two regions (P or S) share a tile edge in the grid **if and only if** they are linked in the topology.
- Shapes and borders are semi-random (e.g. Voronoi-style), not fixed templates.
- Generation must assign terrain and at most one resource per tile respecting region and terrain rules, and must control resource spawn rates so distribution is in inverse proportion to default market price (TDD 04b).

Input: region topology graph; optional cross-region links; params (grid size, seed, border noise). Output: per-region 2D grid (tile → province/sea zone id, terrain, optional resource).

---

## Algorithm spec

The **algorithm** (input/output, steps, ownership) is specified in the **program** spec: [SPEC/program/tile-map-generation.md](../program/tile-map-generation.md). The ideas doc ([SPEC/ideas/tile-based-map-generation.md](../../ideas/tile-based-map-generation.md)) is reference/sample only for design and implementation.
