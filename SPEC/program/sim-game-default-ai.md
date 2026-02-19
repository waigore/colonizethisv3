# sim_game — Default AI Behaviour

**SPEC/program** — Deterministic default AI used by [sim-game.md](sim-game.md). Produces orders for one Great Power when ctdev has selected **Sim Game AI** for the run; in that mode this function is used for **all** GPs. Uses the **same channels and strategy** as the minimal AIPlanner. References: [factions.md](../game/factions.md), [orders.md](orders.md), [movement.md](movement.md), [combat.md](combat.md), [order-engine.md](order-engine.md), [player-view.md](player-view.md), [ai-planner.md](ai-planner.md).

---

## Purpose

Define a **pure function** that, given the current game state and a single Great Power, produces that player's orders for one turn in sim_game. It uses the **same channels and strategy** as the minimal AIPlanner: [PlayerView](player-view.md), the [order suggestion API](order-engine.md), valid-only orders, the same diplomacy post-filter on moves, and the **shared simple heuristics** (move/work/build/research from suggestions, same category order and seeded choice). No raw construction of orders from topology; all order types come from the suggestion API.

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
  - `baseSeed` — used as fallback when computing the turn seed when `game.aiSeedByGpId[player.id]` is missing for that GP (Option A). The function derives `turnSeed = hash(globalGameSeed, aiSeed[P], T)` with the same formula as AIPlanner; if `aiSeedByGpId[player.id]` is absent, `baseSeed` is used so that Option A (same seed when same role) holds.
- **Output:**
  - An `Orders` value containing move, build, work, and research orders **for that player only**, all produced by the shared simple heuristics and passing validation.

The function must be **pure and side-effect free**: it does not mutate `game` or any global state; it only inspects inputs and returns a new `Orders`.

---

## Order generation

All order types (MoveOrders, BuildUnitOrders, WorkOrders, ResearchOrders) are produced by the **shared simple heuristics** used by both AIPlanner and defaultSimGameAi:

- Build [PlayerView](player-view.md) for the player; call the **order suggestion API** for candidate move, work, build, and research orders.
- Apply the same category preference (moves → work → build → research) and seeded random choice within category.
- Apply the **diplomacy post-filter** to moves: drop moves to provinces owned by factions at peace; drop moves to minors when relation is unknown.
- No raw construction from topology; every order comes from the suggestion API and is valid by construction after validation.

---

## Determinism

- **Per-call determinism:** Given the same `(game, player, topology, baseSeed)` and the same implied turn number, `defaultSimGameAi` must return the same `Orders`.
- **Run-level determinism:** When sim_game calls `defaultSimGameAi` in a fixed GP order each turn (see [sim-game.md](sim-game.md)), the overall sim run is reproducible for a given initial `Game`, `topology`, and `baseSeed`.
- The seed used is the same as AIPlanner's `turnSeed[P, T]` when the same game state and player are used (Option A). All randomness is derived from that turn seed; no global RNG.

---

## References

- [sim-game.md](sim-game.md) — Consuming spec; turn loop invokes this behaviour to obtain Orders each turn.
- [ai-planner.md](ai-planner.md) — Shared simple heuristics and control rules.
- [order-engine.md](order-engine.md) — Order suggestion API.
- [player-view.md](player-view.md) — Visibility and world state for the AI.
- [combat-resolution.md](combat-resolution.md) — Attacker = faction that moved in; defender = province owner.
