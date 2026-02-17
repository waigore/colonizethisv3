# sim_game — Default AI Behaviour

**SPEC/program** — Deterministic default AI used by [sim-game.md](sim-game.md). Only Great Powers submit orders; behaviour is reproducible given seed and world state. References: [factions.md](../game/factions.md), [orders.md](orders.md), [movement.md](movement.md), [combat.md](../game/combat.md).

---

## Purpose

Define a **pure function** that, given the current game state and a single Great Power, produces that player’s orders for one turn in sim_game. No strategic logic; the goal is to exercise the turn resolver (movement, combat, build/work) in a reproducible way so that combat and economy both fire under simple “toy” behaviour.

---

## Function Signature

Conceptual signature (Dart, colonizethis_logic):

```dart
Orders defaultSimGameAi({
  required Game game,
  required Player player,
  required MapTopology topology,
  required int baseSeed,
});
```

- **Input:**
  - `game` — full current game state at the start of the turn.
  - `player` — the Great Power for whom we are generating orders.
  - `topology` — map adjacency information for movement validation.
  - `baseSeed` — deterministic base seed for pseudo-random choices.
- **Output:**
  - An `Orders` value that may contain MoveOrders and (optionally) build/work orders **for that player only**.

The function must be **pure and side-effect free**: it does not mutate `game` or any global state; it only inspects inputs and returns a new `Orders`.

---

## MoveOrders

Within `defaultSimGameAi`, movement is generated as follows:

- **Unit iteration:** For the given `player`, iterate that player’s units in a fixed, stable order (e.g. by `unit.id`).
- **Valid destinations:** For each unit that can move this turn:
  - Compute adjacent provinces using `topology` and the unit’s current province (same region; land adjacency only per [movement.md](movement.md)).
  - Filter destinations to those that are reachable and valid this turn (no additional pathfinding; one-step moves only).
- **Destination choice:** For each unit:
  - Build a list of valid destinations ordered deterministically (e.g. sorted by province id).
  - Optionally apply a **pseudo-random shuffle** driven by a PRNG seeded from `(baseSeed, player.id, unit.id, currentTurnNumber)` so that different runs can explore different patterns while remaining reproducible.
  - Choose at most one destination per unit; if the chosen destination is enemy-owned, this is an attack and combat will trigger in the Combat phase ([combat.md](../game/combat.md)).
- **Constraints:**
  - At most one MoveOrder per unit per turn.
  - If no valid destination exists, emit no MoveOrder for that unit.

---

## BuildUnitOrders and WorkOrders

- **BuildUnitOrder (optional but recommended):**
  - At most one build per GP per turn.
  - Example rule:
    - Find the first GP-owned province by province id that is valid for spawning a military unit.
    - If `player.workerPool` and `player.stockpile` meet a simple threshold (e.g. at least one free worker and enough generic resources), queue a build for a basic regiment type available at the player’s `militaryLevel`.
  - Choice of province and unit type must be deterministic given `game`, `player`, and `baseSeed`.

- **WorkOrder (optional):**
  - At most one WorkOrder per GP per turn.
  - Example rule:
    - Pick the first civilian unit by unit id that is idle.
    - Assign it to a simple, fixed improvement type (e.g. upgrade a nearby resource tile) if such a target exists.
  - Deterministic given state; may use the same PRNG as MoveOrders.

- If BuildUnitOrders and WorkOrders are omitted, sim_game still remains valid; movement (and thus combat) alone will exercise the resolver.

---

## Determinism

- **Per-call determinism:** Given the same `(game, player, topology, baseSeed)` and the same implied turn number, `defaultSimGameAi` must return the same `Orders`.
- **Run-level determinism:** When sim_game calls `defaultSimGameAi` in a fixed GP order each turn (see [sim-game.md](sim-game.md)), the overall sim run is reproducible for a given initial `Game`, `topology`, and `baseSeed`.
- The AI must not read from or write to any global RNG; all randomness is derived from a PRNG seeded from `(baseSeed, player.id, currentTurnNumber[, unit.id])`.

---

## References

- [sim-game.md](sim-game.md) — Consuming spec; turn loop invokes this behaviour to obtain Orders each turn.
- [combat-resolution.md](combat-resolution.md) — Attacker = faction that moved in; defender = province owner. Default AI does not need to know combat outcome when choosing moves.
