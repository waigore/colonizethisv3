# Turn Resolution

**SPEC/program** — Turn phases, state, and resolution sequence. Implementation: colonizethis_logic. World state: [SPEC/game/world-model.md](../game/world-model.md). Province ids in turn state and phase resolution use the prefixed format and lookup rules in [SPEC/game/world-model-identity.md](../game/world-model-identity.md).

---

## Turn State

**Turn state** is part of WorldState. It includes:

- **Turn number** — Integer; increments each full resolution (e.g. after end-of-turn phase). Calendar year is derived from `turnState.turnNumber` using the game's `turnTimeMapping`; no change to resolution logic.
- **Phase** — Enum indicating current step within resolution (e.g. orders, economy, combat, diplomacy, end-of-turn). Stub may use a single “resolution” phase or a minimal sequence; full phase set in [turn-resolution-phases.md](turn-resolution-phases.md).

At least one phase exists; resolver advances turn number so that “next turn” produces a new WorldState with incremented turn.

---

## Resolution Sequence

**TurnResolver** runs a defined **phase sequence**. Order of phases is fixed (see [turn-resolution-phases.md](turn-resolution-phases.md)); when combat is in scope, the full phase list includes **Minor Regiment Upgrade** after Movement and before all combat phases, followed by naval combat phases and land **Combat**. Each phase is a step; resolver executes steps in order. The **movement** phase uses **map topology** (adjacency) from colonizethis_data to validate and resolve **civilian** `MoveOrder`s and **`ArmyMoveOrder`**s ([military-armies.md](../game/military-armies.md), [movement.md](movement.md)). The **Combat** phase takes WorldState after movement and pre-combat updates, runs conflict detection and the combat resolver, and applies casualties and province flips.

**Stub:** Sequence and interfaces exist. Each phase can be no-op or minimal (e.g. end-of-turn advances turn number only) until economy, movement, and other logic are implemented.

---

## Input and Output

- **Input:** Current **WorldState** (or **Game** holding current WorldState). Optionally resolved config (colonizethis_data / GameConfig) for future phases.
- **Output:** New **WorldState** (or **Game** with updated WorldState). Immutable style: resolver returns a new instance; caller persists it and replaces current state.

Signature (conceptual): `WorldState resolve(WorldState current)` or `Game resolve(Game current)`. If Game is passed, resolver updates its WorldState and returns the same Game reference with new state, or returns a new Game; spec leaves exact signature to implementation as long as “state in, new state out” is clear.

---

## Responsibilities

- **colonizethis_logic** owns TurnResolver and phase sequence. Stub: no game rules beyond turn advance until full phases are implemented.
- **App** (or a service) calls TurnResolver when user (or AI) commits “next turn”; then persists the returned state via colonizethis_save.
- **Load game** restores Game/WorldState from storage; “next turn” runs on that state and overwrites or replaces the saved state after resolve.

---

## Stub Semantics

- Resolver has a **defined phase list** (e.g. list of enum values or named steps).
- **At least one phase** performs a minimal change: e.g. increment turn number in WorldState.
- Unit tests: resolve(currentState) returns new state; new state’s turn number is current + 1 (or equivalent); no other game logic required until full phases are implemented.

## Loaded Game Behavior

When a game is **loaded from save**, the map data (`tileMapByRegion`, `topologyByRegion`) may be absent (not serialized with the game). In this case, the resolver operates with empty or null map topology:

- **Extraction Phase:** When `tileMapByRegion` is empty or null, extraction leaves stockpiles unchanged. No resources are extracted because the tile map data required to calculate yields is unavailable. This is a graceful degradation: the turn advances without crashing, but no economic progress occurs until the map is restored.

- **Movement Phase:** When `topologyByRegion` is empty or null, land movement applies no adjacency validation. Units may not be able to move to adjacent provinces because the topology data defining adjacency is missing. Sea movement similarly lacks topology for sea zone adjacency.

- **Combat Phase:** Combat resolution proceeds with available world state data. Unit strengths and casualties are calculated normally, but terrain modifiers may be unavailable without tile map data.

**Acceptance Criteria:**

- Given a game is loaded from save without serialized tileMapByRegion or topologyByRegion
- When TurnResolver runs the next turn
- Then the turn advances successfully (turn number increments, no crash)
- And extraction leaves stockpiles unchanged (graceful degradation)
- And movement is limited or blocked by missing topology

**App-Level Note:** The app may cache map data separately and re-provide it on load. If the app provides cached map data to the resolver, full extraction and movement are restored. This behavior is app-level (GameService) and not part of the core resolver contract.
