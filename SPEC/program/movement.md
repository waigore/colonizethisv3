# Movement

**SPEC/program** — Movement rules and validation. Reference: [SPEC/game/map-topology.md](../game/map-topology.md), [turn-resolution.md](turn-resolution.md).

---

## Scope

**Land movement:** Units move between **provinces** only (P<->P).

**Naval movement (Phase 5+):** Fleets move between **sea zones** (S<->S or P<->S for ports). Destination = sea zone id. Ship reveal runs when fleet enters sea zone. See [naval-movement-resolution.md](naval-movement-resolution.md).

---

## Adjacency

**Valid destination:** a province that is **adjacent** to the unit's current province in the **map topology**. Topology (nodes = provinces and sea zones; edges = P–P, P–S) is loaded from **colonizethis_data**. TurnResolver and order validation use the same graph. Armies move only along P–P edges (province to province).

---

## Validation

Before applying a move order:

- **Land units:** Destination must be a **province** (not sea zone); must be **adjacent** (P<->P edge).
- **Naval (Phase 5+):** Destination must be a **sea zone**; must be adjacent to current sea zone (S<->S or P<->S).
- Optional: movement points, passable terrain, or blocking (e.g. enemy) — per design; can be stubbed.

Invalid moves are rejected; unit location unchanged.

---

## Resolution

TurnResolver runs a **movement** step that applies validated move orders: update each unit's location to the destination province. Order of application (e.g. by player, by unit) is deterministic. See [turn-resolution-phases.md](turn-resolution-phases.md).
