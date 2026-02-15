# Turn Resolution

**SPEC/program** — Turn phases, state, and resolution sequence. Implementation: colonizethis_logic. World state: [SPEC/game/world-model.md](../game/world-model.md).

---

## Turn State

**Turn state** is part of WorldState. It includes:

- **Turn number** — Integer; increments each full resolution (e.g. after end-of-turn phase).
- **Phase** — Enum indicating current step within resolution (e.g. orders, economy, combat, diplomacy, end-of-turn). Phase 1 stub may use a single “resolution” phase or a minimal sequence; full phase set aligns with GDD for Phase 2+.

Phase 1: at least one phase exists; resolver advances turn number (and optionally phase) so that “next turn” produces a new WorldState with incremented turn.

---

## Resolution Sequence

**TurnResolver** runs a defined **phase sequence**. Order of phases is fixed (e.g. orders → economy → movement → combat → diplomacy → end-of-turn). Each phase is a step; resolver executes steps in order. The **movement** phase (Phase 2+) uses **map topology** (adjacency) from colonizethis_data to validate and resolve moves (e.g. armies only to adjacent provinces).

**Phase 1 stub:** Sequence and interfaces exist. Each phase is **no-op or minimal** (e.g. end-of-turn advances turn number only). No economy, combat, or diplomacy logic until Phase 2+.

---

## Input and Output

- **Input:** Current **WorldState** (or **Game** holding current WorldState). Optionally resolved config (colonizethis_data / GameConfig) for future phases.
- **Output:** New **WorldState** (or **Game** with updated WorldState). Immutable style: resolver returns a new instance; caller persists it and replaces current state.

Signature (conceptual): `WorldState resolve(WorldState current)` or `Game resolve(Game current)`. If Game is passed, resolver updates its WorldState and returns the same Game reference with new state, or returns a new Game; spec leaves exact signature to implementation as long as “state in, new state out” is clear.

---

## Responsibilities

- **colonizethis_logic** owns TurnResolver and phase sequence. No game rules beyond turn advance in Phase 1.
- **App** (or a service) calls TurnResolver when user (or AI) commits “next turn”; then persists the returned state via colonizethis_save.
- **Load game** restores Game/WorldState from storage; “next turn” runs on that state and overwrites or replaces the saved state after resolve.

---

## Stub Semantics (Phase 1)

- Resolver has a **defined phase list** (e.g. list of enum values or named steps).
- **At least one phase** performs a minimal change: e.g. increment turn number in WorldState.
- Unit tests: resolve(currentState) returns new state; new state’s turn number is current + 1 (or equivalent); no other game logic required.
