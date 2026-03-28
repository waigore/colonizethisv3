# Turn Resolution Phases

**SPEC/program** — Phase sequence and ordering rules. Overview: [turn-resolution.md](turn-resolution.md). Factions: [factions.md](../game/factions.md). Per-phase details: [turn-resolution-phase-details.md](turn-resolution-phase-details.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** — Gather/validate; Great Powers only submit. Merge human + AI; resolve cross-player effects before application.
2. **Diplomacy** — Before Movement so war/peace apply same turn. Overtures, Join Empire/Colony, alliances, Declare War, Peace, **intervention** (when a GP declares war on a Minor/Tribe and another GP has Embassy or purchased land there), relation updates. [diplomacy-resolution.md](diplomacy-resolution.md)
3. **Extraction** — Tile yields to stockpile.
4. **Riches to treasury** — Riches convert to treasury at base price; removed from stockpile.
5. **Consumption** — Military food upkeep first, then workers/navy (food + luxury); strike rules per [workers-and-population.md](../game/workers-and-population.md).
6. **Production** — Recipes and idle labour; outputs to stockpile (uses post-Consumption stockpile and labour).
7. **Research** — Read orders; validate treasury; deduct spending; add progress; complete techs. [research-resolution.md](research-resolution.md)
8. **Movement** — Apply land/naval MoveOrders and mission assignments; update unit/fleet locations.
9. **Minor Regiment Upgrade** — Compute `maxGreatPowerMilitaryLevel` from post-Research Great Power buildable regiment tiers; set Old World Minor Nations `effectiveMilitaryLevel`; upgrade eligible minor land regiments in place; set Tribe `effectiveMilitaryLevel` to 1 (no parity).
10. **Naval Interception & Naval Combat** — Patrol/blockade/beachhead interceptions; sea battles; fleet updates. [naval-movement-resolution.md](naval-movement-resolution.md), [naval-combat-resolution.md](naval-combat-resolution.md)
11. **Combat** — Land battles; casualties; province flips.
12. **Build / work** — BuildUnitOrder; WorkOrder (explore, prospect, improvements, roads, ports, forts, rails). [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md), [development-resolution.md](development-resolution.md)
13. **End-of-turn** — Victory check; era-change dialogue; fog decay (Spy 5-turn + Explorer/Spy); coastal sea zone full visibility; advance turn number. See [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § End-of-turn.

---

## Dependency Rules

Extraction → riches to treasury → **consumption → production** **must** run before movement and build, in that order. Research runs after production (and consumption) so treasury is current. Build vs movement ordering is implementation-defined within that constraint.

---

## Blocking human input

Some phases may require input from a **human player** before resolution can continue. When that happens, turn resolution **suspends** and returns a result indicating **pending human input** (e.g. overture accept/reject for a human-controlled target faction, or **intervention** choices after another GP declares war on a Minor/Tribe). The **app** is responsible for: (1) presenting the decision to the human; (2) collecting the response; (3) calling the **resume** API with the decision(s). The resolver then re-enters the Diplomacy phase with the supplied decisions and runs the rest of the turn. See [diplomacy-resolution.md](diplomacy-resolution.md); [diplomacy.md](../game/diplomacy.md) § Intervention.

---

## Determinism

Same TurnResolver and phase order used in main game and ctdev sim_game; identical development and exploration rules for reproducible simulations. When resolution suspends for human input, the eventual outcome depends on that input; given the same input (including human decisions on resume), the result is deterministic.

---

## Acceptance criteria

- **Phase sequence:** Given any run of TurnResolver, the system executes exactly the phases 1–13 above in that order (Orders → Diplomacy → Extraction → Riches to treasury → Consumption → Production → Research → Movement → Minor Regiment Upgrade → Naval Interception & Naval Combat → Combat → Build / work → End-of-turn). No phase is skipped or reordered; no additional phases mutate game state between these steps.
- **Dependency order:** Extraction runs before Riches to treasury; Riches to treasury before Consumption; Consumption before Production. Extraction through Production complete before Movement and before Build / work. Research runs after Production so treasury is current. Build vs Movement relative order is implementation-defined subject to that constraint. Given a resolver run, the system does not apply extraction/riches/consumption/production effects after movement or build has started.
- **Determinism:** Given the same starting WorldState, merged orders, ruleset, and random seeds, TurnResolver produces the same resulting WorldState (and victory state) in main game and in ctdev sim_game; phase order is identical in both.
- **Implementation contract:** Per-phase behaviour is specified in [turn-resolution-phase-details.md](turn-resolution-phase-details.md); this document is the single source of truth for phase sequence and ordering. Tests may assert phase order and dependency rules by inspecting resolver behaviour or by comparing outcomes across runs.
- **Blocking:** When the Diplomacy phase encounters an overture whose target is a human-controlled Great Power, turn resolution returns **TurnResolutionPendingOvertures**. When intervention requires a human GP’s choice, turn resolution returns **TurnResolutionPendingIntervention**. The app must not advance the turn until it has collected the human’s response and called the matching resume API. When no human input is pending, resolution runs to completion and returns the final game state.
