# Turn Resolution Phases

**SPEC/program** — Phase sequence and ordering rules. Overview: [turn-resolution.md](turn-resolution.md). Factions: [factions.md](../game/factions.md). Per-phase details: [turn-resolution-phase-details.md](turn-resolution-phase-details.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** — Gather/validate; Great Powers only submit. Merge human + AI; resolve cross-player effects before application.
2. **Diplomacy** (Phase 4+) — Before Movement so war/peace apply same turn. Overtures, Join Empire/Colony, alliances, Declare War, Peace, relation updates. [diplomacy-resolution.md](diplomacy-resolution.md)
3. **Extraction** — Tile yields to stockpile.
4. **Riches to treasury** — Riches convert to treasury at base price; removed from stockpile.
5. **Production** — Recipes and labour; outputs to stockpile.
6. **Consumption** — Military food upkeep first, then workers/navy from remainder.
7. **Research** (Phase 5+) — Read orders; validate treasury; deduct spending; add progress; complete techs. [research-resolution.md](research-resolution.md)
8. **Movement** — Apply land/naval MoveOrders and mission assignments; update unit/fleet locations.
9. **Naval Interception & Naval Combat** (Phase 6+) — Patrol/blockade/beachhead interceptions; sea battles; fleet updates. [naval-movement-resolution.md](naval-movement-resolution.md), [naval-combat-resolution.md](naval-combat-resolution.md)
10. **Combat** — Land battles; casualties; province flips (Phase 3+).
11. **Build / work** — BuildUnitOrder; WorkOrder (explore, prospect, improvements, roads, ports, forts, rails). [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md), [development-resolution.md](development-resolution.md)
12. **End-of-turn** — Fog decay; advance turn number; reset unit status.

---

## Dependency Rules

Extraction → riches to treasury → production → consumption **must** run before movement and build. Research runs after consumption so treasury is current. Build vs movement ordering is implementation-defined within that constraint.

---

## Determinism

Same TurnResolver and phase order used in main game and ctdev sim_game; identical development and exploration rules for reproducible simulations.
