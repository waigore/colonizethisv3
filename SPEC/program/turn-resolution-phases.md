# Turn Resolution Phases

**SPEC/program** — Phase sequence and ordering rules. Overview: [turn-resolution.md](turn-resolution.md). Factions: [factions.md](../game/factions.md). Per-phase details: [turn-resolution-phase-details.md](turn-resolution-phase-details.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** — Gather/validate; Great Powers only submit. Merge human + AI; resolve cross-player effects before application.
2. **Diplomacy** — Before Movement so war/peace apply same turn. Overtures, Join Empire/Colony, alliances, Declare War, Peace, relation updates. [diplomacy-resolution.md](diplomacy-resolution.md)
3. **Extraction** — Tile yields to stockpile.
4. **Riches to treasury** — Riches convert to treasury at base price; removed from stockpile.
5. **Production** — Recipes and labour; outputs to stockpile.
6. **Consumption** — Military food upkeep first, then workers/navy from remainder.
7. **Research** — Read orders; validate treasury; deduct spending; add progress; complete techs. [research-resolution.md](research-resolution.md)
8. **Movement** — Apply land/naval MoveOrders and mission assignments; update unit/fleet locations.
9. **Naval Interception & Naval Combat** — Patrol/blockade/beachhead interceptions; sea battles; fleet updates. [naval-movement-resolution.md](naval-movement-resolution.md), [naval-combat-resolution.md](naval-combat-resolution.md)
10. **Combat** — Land battles; casualties; province flips.
11. **Build / work** — BuildUnitOrder; WorkOrder (explore, prospect, improvements, roads, ports, forts, rails). [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md), [development-resolution.md](development-resolution.md)
12. **End-of-turn** — Victory check; era-change dialogue; fog decay (Spy 5-turn + Explorer/Spy); coastal sea zone full visibility; advance turn number. See [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § End-of-turn.

---

## Dependency Rules

Extraction → riches to treasury → production → consumption **must** run before movement and build. Research runs after consumption so treasury is current. Build vs movement ordering is implementation-defined within that constraint.

---

## Blocking human input

Some phases may require input from a **human player** before resolution can continue. When that happens, turn resolution **suspends** and returns a result indicating **pending human input** (e.g. overture accept/reject for a human-controlled target faction). The **app** is responsible for: (1) presenting the decision to the human (e.g. “GP X offers Embassy; accept or reject?”); (2) collecting the response; (3) calling the **resume** API with the decision(s). The resolver then continues from the point of suspension (e.g. applies the overture decision and runs the rest of the Diplomacy phase and remaining phases). See [diplomacy-resolution.md](diplomacy-resolution.md) for overture accept/reject; [diplomacy.md](../game/diplomacy.md) for two-way overture rules.

---

## Determinism

Same TurnResolver and phase order used in main game and ctdev sim_game; identical development and exploration rules for reproducible simulations. When resolution suspends for human input, the eventual outcome depends on that input; given the same input (including human decisions on resume), the result is deterministic.

---

## Acceptance criteria

- **Phase sequence:** Given any run of TurnResolver, the system executes exactly the phases 1–12 above in that order (Orders → Diplomacy → Extraction → Riches to treasury → Production → Consumption → Research → Movement → Naval Interception & Naval Combat → Combat → Build / work → End-of-turn). No phase is skipped or reordered; no additional phases mutate game state between these steps.
- **Dependency order:** Extraction runs before Riches to treasury; Riches to treasury before Production; Production before Consumption. Extraction through Consumption complete before Movement and before Build / work. Research runs after Consumption so treasury is current. Build vs Movement relative order is implementation-defined subject to that constraint. Given a resolver run, the system does not apply extraction/riches/production/consumption effects after movement or build has started.
- **Determinism:** Given the same starting WorldState, merged orders, ruleset, and random seeds, TurnResolver produces the same resulting WorldState (and victory state) in main game and in ctdev sim_game; phase order is identical in both.
- **Implementation contract:** Per-phase behaviour is specified in [turn-resolution-phase-details.md](turn-resolution-phase-details.md); this document is the single source of truth for phase sequence and ordering. Tests may assert phase order and dependency rules by inspecting resolver behaviour or by comparing outcomes across runs.
- **Blocking:** When the Diplomacy phase encounters an overture whose target is a human-controlled Great Power, turn resolution returns a result indicating pending overture decision(s). The app must not advance the turn until it has collected the human’s response and called the resume API. When no human input is pending, resolution runs to completion and returns the final game state.
