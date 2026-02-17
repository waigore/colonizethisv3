# sim_game — Full Game Simulation Tool

**SPEC/program** — Standalone CLI that runs a full game simulation (N turns, 7 Great Powers, optional Minor Nations and Tribes) using the Phase 2+3 turn resolver. Demonstrates economy, movement, build/work, and combat. References: [turn-resolution-phases.md](turn-resolution-phases.md), [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md), [factions.md](../game/factions.md), [game-setup-pipeline.md](game-setup-pipeline.md), [turn-time-mapping.md](../game/turn-time-mapping.md), [sim-game-default-ai.md](sim-game-default-ai.md).

---

## Purpose and Scope

- **Purpose:** Deterministically simulate a complete game from an initial state to a chosen end turn (or end year). Used to verify that implemented systems (extraction, production, consumption, movement, combat, build/work) behave correctly under a simple, reproducible AI.
- **Scope:** Seven Great Powers (GPs) submit orders only; optional Minor Nations and Tribes may own provinces and defend. No human input during the run; no Phase 4 diplomacy or AI. Combat triggers when a GP's MoveOrder targets an enemy province ([combat.md](../game/combat.md)); Combat phase runs after Movement per [turn-resolution-phases.md](turn-resolution-phases.md).
- **Owner:** Program layer (Dart CLI under `tool/sim_game`), implemented as a thin facade over colonizethis_logic (resolveTurnForGame including Combat phase), colonizethis_data (topology, combat config), colonizethis_models (Game, WorldState, factions). See [repo-and-packages.md](repo-and-packages.md).

---

## CLI Interface

- Command: `melos run sim_game -- [options]`.
- Arguments:
  - `--turns <N>` (required): number of turns to simulate (turn 0 = initial state; N turns advanced).
  - `--seed <int>` (optional): RNG seed for procedural initial state and any stochastic default AI. Omit when using `--initial-state` with a fully specified state.
  - `--initial-state <path>` (optional): path to saved game or Game JSON (colonizethis_save format or equivalent). If omitted, tool builds initial state procedurally (see Initial state).
  - `--topology <path>` (optional): path to topology JSON (MapTopology). Required when initial state does not embed or reference topology.
  - `--output <path>` (optional): path for Markdown report. Default: `sim_game.md` in current working directory.
  - `--json-output <path>` (optional): path for per-turn or summary JSON log. Omit for no JSON.
  - `--end-year <Y>` (optional): stop when calendar year ≥ Y per [turn-time-mapping.md](../game/turn-time-mapping.md). May be used instead of or in addition to `--turns`.

Validation errors (missing topology when required, malformed initial state, invalid turn count) are reported clearly and abort the run.

---

## Initial State

- **With `--initial-state`:** Load Game (and topology if referenced) from file. All 7 GPs and any minors/tribes must be present as specified. Tool does not reassign ownership.
- **Without `--initial-state` (procedural):** Use the same pipeline as [init-game-tool.md](init-game-tool.md) (or a subset): generate Old World and optionally New World map from `--seed`; assign provinces to 7 GPs and optionally to Minor Nations and Tribes per [game-setup.md](../game/game-setup.md). Create initial units (e.g. one military unit per GP in that GP's capital province). Initial stockpiles and WorkerPools per GP from bounded ranges (similar to [sim-economy.md](sim-economy.md) default). Deterministic given `--seed`.

---

## Default AI and Turn Loop

Only Great Powers submit orders ([factions.md](../game/factions.md)). Per-turn behaviour is defined in [sim-game-default-ai.md](sim-game-default-ai.md): deterministic "first default action" for moves (and optionally build/work). Moving into an enemy province is an attack; combat is resolved in the Combat phase. Extraction and production inputs each turn are either supplied by script (when using a scripted initial state with per-turn overrides) or a simple default (e.g. flat extraction per GP, fixed recipe assignments) so that economy phases run. For each turn: (1) Compute orders for all GPs (default AI). (2) Compute extraction and production inputs. (3) Call Phase 3 TurnResolver (full sequence including Movement → Combat → Build/work). (4) Record state and combat outcomes.

---

## Output

- **Report (Markdown):** Run metadata (seed, turns, initial state path, topology path). Per-turn or summary: turn number, calendar year (if turn-time mapping used), notable events (combat: province, attacker, defender, casualties, province flips). Optionally: stockpile/worker deltas, province ownership changes. Written to `--output` path.
- **JSON log (optional):** Same information in machine-readable form when `--json-output` is set. Identity: run config and per-turn state (or deltas) sufficient to verify resolver behaviour.

---

## References

- [sim-economy.md](sim-economy.md) — Single-player economy tool; sim_game reuses economy phase semantics and may reuse default extraction/assignment patterns.
- [init-game-tool.md](init-game-tool.md) — Game creation; sim_game may call the same pipeline for procedural initial state.
- [orders.md](orders.md), [movement.md](movement.md) — MoveOrder into enemy province = attack.
