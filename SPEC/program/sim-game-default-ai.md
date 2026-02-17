# sim_game — Default AI Behaviour

**SPEC/program** — Deterministic "first default action" behaviour used by [sim-game.md](sim-game.md). Only Great Powers submit orders; behaviour is reproducible given seed and world state. References: [factions.md](../game/factions.md), [orders.md](orders.md), [combat.md](../game/combat.md).

---

## Purpose

Define the order and rules by which each Great Power produces orders each turn in sim_game. No strategic logic; the goal is to exercise the turn resolver (movement, combat, build/work) in a reproducible way so that combat can trigger when a move targets an enemy province.

---

## Order of Execution

- **Great Powers:** Process GPs in a fixed order (e.g. by player id lexicographically or by index in Game.players). Same order every turn.
- **Units:** For movement, process units in a fixed order per GP (e.g. by unit id). Same order every turn so that "first valid move" is well-defined.

---

## MoveOrders

- For each GP, for each military unit (and optionally each civilian unit that can move) in the chosen unit order:
  - **Valid destinations:** Adjacent provinces from topology (same region as unit's current province; land adjacency only per [movement.md](movement.md)).
  - **First default move:** The first valid destination when destinations are ordered deterministically (e.g. by province id). No preference for friendly vs enemy provinces; if the first adjacent province is enemy-owned, the move is an attack and combat will trigger in the Combat phase ([combat.md](../game/combat.md)).
- At most one MoveOrder per unit per turn. If no valid destination exists (e.g. no adjacent province), issue no move for that unit.
- Any randomness (e.g. tie-breaking) must use a RNG seeded by the sim_game `--seed` and a deterministic context (e.g. turn number, unit id) so that the same seed and state yield the same orders.

---

## BuildUnitOrders and WorkOrders

- **BuildUnitOrder:** Optional. If implemented: at most one build per GP per turn. Rule example: first GP-owned province by province id that is valid for spawn; build military unit if WorkerPool has at least one peasant, else skip or build civilian if allowed. Deterministic given state and seed.
- **WorkOrder:** Optional. If implemented: at most one work order per GP per turn. Rule example: first civilian unit by unit id that is idle; target from a fixed list (e.g. first improvement type). Deterministic given state.
- If not implemented, sim_game may emit no build or work orders; movement (and thus combat) remains in scope.

---

## Determinism

Same `--seed`, same initial state (or same procedural generation seed), and same resolver implementation must produce the same sequence of orders and the same run outcome. No external input during the run.

---

## References

- [sim-game.md](sim-game.md) — Consuming spec; turn loop invokes this behaviour to obtain Orders each turn.
- [combat-resolution.md](combat-resolution.md) — Attacker = faction that moved in; defender = province owner. Default AI does not need to know combat outcome when choosing moves.
