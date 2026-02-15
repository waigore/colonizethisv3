# Map Topology

**SPEC/game** — Topology link semantics and cross-region adjacency. See [world-model.md](world-model.md) for entities; [tile-map-and-generation.md](tile-map-and-generation.md) for tile maps.

---

## Link types

The map is an **undirected graph**. Nodes are **provinces (P)** or **sea zones (S)**; each has id and region id.

**Edges have two semantics:**

- **P1 <-> P2** — P1 and P2 are contiguous land provinces (neighbours). Armies move only between adjacent provinces.
- **P1 <-> S1** — Province P1 is next to sea zone S1 (coast).

Optionally **S1 <-> S2** (sea–sea) for naval movement between sea zones (Phase 2+). No other edge types.

---

## Cross-region adjacency

A province or sea zone in one region can be adjacent to a province or sea zone in **another** region (e.g. Europe and Asia). The **world** topology is one graph. **Tile maps** are still per region (one 2D grid per region); cross-region links are respected when generating or validating maps.

---

## Movement rule

Armies move only from one province to an **adjacent** province (P<->P). Naval movement (Phase 2+) uses P<->S and optionally S<->S. Order validation and TurnResolver use topology from colonizethis_data; see [SPEC/program/turn-resolution.md](../program/turn-resolution.md) and [SPEC/program/map-data.md](../program/map-data.md).
