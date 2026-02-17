# sim_game — Full Game Simulation Mode

**SPEC/program** — Dev-only simulation mode that runs a full game forward from an `init_game` result inside **ctdev**. Uses the Phase 2+3 turn resolver (including Combat phase) to demonstrate economy, movement, build/work, and combat under a simple default AI. Entry point and UI are defined in [ctdev-app.md](ctdev-app.md). References: [turn-resolution-phases.md](turn-resolution-phases.md), [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md), [factions.md](../game/factions.md), [game-setup-pipeline.md](game-setup-pipeline.md), [turn-time-mapping.md](../game/turn-time-mapping.md), [sim-game-default-ai.md](sim-game-default-ai.md).

---

## Purpose and Scope

- **Purpose:** Deterministically simulate a complete game from an `init_game`-generated state, directly inside ctdev's **Init Game Map Debug Screen**. Used to verify that implemented systems (extraction, production, consumption, movement, combat, build/work) behave correctly over many turns under a simple, reproducible AI.
- **Scope:** Seven Great Powers (GPs) submit orders only; optional Minor Nations and Tribes may own provinces and defend. No Phase 4 diplomacy or AI. Combat triggers when a GP's MoveOrder targets an enemy province ([combat.md](../game/combat.md)); Combat phase runs after Movement per [turn-resolution-phases.md](turn-resolution-phases.md).
- **Owner:** Program layer (ctdev + colonizethis_logic). sim_game is **not** a standalone CLI; it is a mode within ctdev that wraps colonizethis_logic (resolveTurnForGame including Combat phase), colonizethis_data (topology, combat config), and colonizethis_models (Game, WorldState, factions). See [repo-and-packages.md](repo-and-packages.md).

---

## Entry Point and Lifecycle

- **Start from Init Game:** sim_game always starts from a `Game` produced by the **Init Game** flow:
  - User runs init game inside ctdev (see [ctdev-app.md](ctdev-app.md)) and lands on the Init Game Map Debug Screen with an `InitGameResult`.
  - When the user is satisfied with the map and setup, they press **Start Game**.
- **Game construction:** On Start Game:
  - ctdev takes `InitGameResult.game` as the initial `Game` for simulation.
  - It also captures the `MapTopology` and any tile-map data needed by `resolveTurnForGame`.
  - A deterministic `baseSeed` is chosen (from the init seed or a UI field) for the default AI.
- **Sim Game mode:** After Start Game, ctdev enters **Sim Game mode**:
  - The same map view remains visible.
  - A small Sim Game control bar appears, allowing the user to advance the game using the modes below.
  - sim_game keeps the `Game` in memory and may optionally save debug snapshots to disk.

---

## Initial State

- **Source:** sim_game never builds its own map. The initial `Game` **must** come from an `init_game` run (either just executed in ctdev or loaded from a save created by `tool/init_game`).
- **Requirements:** The incoming `Game`:
  - Contains 7 Great Powers and any configured Minor Nations and Tribes.
  - Embeds or references the map topology and tile state required by `resolveTurnForGame`.
  - Uses Phase 2+3 rules for economy, movement, and combat.
- **Determinism:** Given the same initial `Game` and the same `baseSeed`, sim_game must produce the same sequence of states for a given sequence of user actions (which mode button is pressed and when).

---

## Simulation Modes and Turn Loop

Only Great Powers submit orders ([factions.md](../game/factions.md)). Each mode uses the same underlying pieces:

- **Default AI:** Per-GP behaviour is defined in [sim-game-default-ai.md](sim-game-default-ai.md). It is a deterministic function that, given `(Game, Player, turnNumber, baseSeed)`, returns an `Orders` object for that player only.
- **Turn resolver:** All modes call the existing Phase 3 `resolveTurnForGame` (full sequence including Movement → Combat → Build/work) with combined per-player orders and the captured topology/tile-map data.

### Player-by-player mode

- **Intent:** Let the developer watch each Great Power’s automaton choose orders one at a time before resolving the turn.
- **Loop (per turn):**
  1. Maintain an in-memory map `ordersByPlayerId`.
  2. When the user presses **Next Player**, pick the next GP without orders (fixed ordering by `Game.players` index or id).
  3. Call the default AI once for that player to produce `Orders` for the current turn.
  4. Show a short summary of that player’s orders in the Sim Game panel.
  5. After all GPs have orders, enable a **Resolve Turn** action that:
     - Combines `ordersByPlayerId` into a single `Orders` value.
     - Calls `resolveTurnForGame`.
     - Updates the stored `Game` and clears `ordersByPlayerId` for the next turn.

### Turn-by-turn mode

- **Intent:** One click advances the game by exactly one full turn for all players.
- **Loop (per turn):**
  1. On **Next Turn**, for each Great Power in fixed order:
     - Call default AI to obtain that player’s `Orders` for this turn.
  2. Combine all per-player orders into a single `Orders`.
  3. Call `resolveTurnForGame` once.
  4. Update the stored `Game` and refresh the map and per-turn summary (e.g. combat events and province flips).

### Fast-forward 10 turns

- **Intent:** Advance the simulation quickly over a small horizon to see macro effects.
- **Loop:**
  1. On **Fast-forward 10**, ctdev runs a loop for 10 iterations:
     - For each iteration, generate orders for all GPs via default AI as in Turn-by-turn mode.
     - Call `resolveTurnForGame` once.
     - Optionally accumulate a compact log (e.g. battle count, province flips, stockpile summaries).
  2. After the loop:
     - Present the final `Game` state on the map.
     - Show an aggregated summary for the 10-turn window.
- **UX:** While the loop runs, ctdev displays a simple progress indicator (e.g. “Simulating 7/10 turns…”). Intermediate map redraws are optional.

---

## Output and Instrumentation

- **In-UI summary:** After each resolved turn (or batch for fast-forward), sim_game surfaces:
  - Turn number and calendar year (if [turn-time-mapping.md](../game/turn-time-mapping.md) is in use).
  - Key combat events: province id, attacker, defender, casualties, province flips.
  - Optional high-level metrics (e.g. province counts per GP, notable stockpile deltas).
- **Optional debug logs:** Implementations may offer a “Save sim log” action that writes a Markdown or JSON summary of the current sim run to disk, but this is not required for sim_game’s core functionality.

---

## References

- [sim-economy.md](sim-economy.md) — Single-player economy tool; sim_game reuses economy phase semantics and may reuse default extraction/assignment patterns.
- [init-game-tool.md](init-game-tool.md) — Game creation; sim_game always starts from an init_game-produced Game (either created by ctdev or by the CLI and loaded into ctdev).
- [orders.md](orders.md), [movement.md](movement.md) — MoveOrder into enemy province = attack.
