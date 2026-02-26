# sim_game — Full Game Simulation Mode

**SPEC/program** — Dev-only simulation mode in ctdev that runs a full game forward from an `init_game` result. References: [ctdev-app-running-game.md](ctdev-app-running-game.md), [turn-resolution-phases.md](turn-resolution-phases.md), [sim-game-default-ai.md](sim-game-default-ai.md).

---

## Responsibility

Deterministically simulate a complete game inside ctdev. Verifies that economy, movement, combat, and build/work behave correctly over many turns under a reproducible AI.

---

## Initial State

sim_game never builds its own map. The initial `Game` must come from an `init_game` run. Requirements: 6 Great Powers, configured Minors/Tribes, map topology and tile state embedded. Given the same initial Game and baseSeed, produces the same sequence of states.

---

## Simulation Modes

All GPs are AI-controlled; no human players. The user selects either **Sim Game AI** ([sim-game-default-ai.md](sim-game-default-ai.md)) or **AI Planner** ([ai-planner.md](ai-planner.md)) for order generation.

| Mode | Behavior |
|---|---|
| **Player-by-player** | Next Player generates one GP's orders at a time; Resolve Turn after all GPs have orders |
| **Turn-by-turn** | One click generates all GP orders and resolves one full turn |
| **Fast-forward 10** | Runs 10 full turns, shows aggregated summary |

All modes call `resolveTurnForGame` (full phase sequence including Combat) with combined per-player orders.

---

## Turn Loop

1. For each GP in fixed order, call the selected AI to produce `Orders`.
2. Combine all per-player orders.
3. Call `resolveTurnForGame` once.
4. Update stored `Game`; refresh map and summary.

Player-by-player pauses after step 1 per GP; fast-forward loops steps 1-4 ten times.

---

## Output

After each resolved turn: turn number, calendar year (if [turn-time-mapping.md](../game/turn-time-mapping.md) in use), combat events (province, attacker, defender, casualties, flips), and optional metrics (province counts, stockpile deltas).

---

## Integration

- Entry: ctdev Running Game screen (see [ctdev-app-running-game.md](ctdev-app-running-game.md))
- Depends on: [game-setup-pipeline.md](game-setup-pipeline.md) for init, [order-engine.md](order-engine.md) for validation
