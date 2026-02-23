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

- **Input:** `game` (current state), `player` (GP), `topology` (adjacency), `baseSeed` (fallback when `game.aiSeedByGpId[player.id]` is missing; same turnSeed formula as AIPlanner).
- **Output:** `Orders` for that player only (move, build, work, research from shared heuristics, validated).

The function must be **pure and side-effect free**: it does not mutate `game` or any global state; it only inspects inputs and returns a new `Orders`.

---

## Order generation

All order types (MoveOrders, BuildUnitOrders, WorkOrders, ResearchOrders) are produced by the **shared simple heuristics** used by both AIPlanner and defaultSimGameAi:

- Build [PlayerView](player-view.md) for the player; call the **order suggestion API** for candidate move, work, build, and research orders.
- Apply the same category preference (moves → work → build → research) and **seeded random choice within category** (including research when multiple options exist).
- Apply the **diplomacy post-filter** to moves: drop moves to provinces owned by factions at peace; drop moves to minors when relation is unknown. Province owner lookup uses full province id (regionId|localId) per [world-model-identity.md](../game/world-model-identity.md).
- **Iteration cap:** Heuristics cap iterations per player per turn (constant in code, e.g. 32) to avoid unbounded loops.
- No raw construction from topology; every order comes from the suggestion API and is valid by construction after validation.

---

## Determinism

- **Per-call determinism:** Given the same `(game, player, topology, baseSeed)` and the same implied turn number, `defaultSimGameAi` must return the same `Orders`.
- **Run-level determinism:** When sim_game calls `defaultSimGameAi` in a fixed GP order each turn (see [sim-game.md](sim-game.md)), the overall sim run is reproducible for a given initial `Game`, `topology`, and `baseSeed`.
- The seed used is the same as AIPlanner's `turnSeed[P, T]` when the same game state and player are used (Option A). All randomness is derived from that turn seed; no global RNG.

---

## Acceptance criteria

- Same `(game, player, topology, baseSeed)` and turn number → same `Orders`.
- Function does not mutate `game` or global state.
- Category order (moves → work → build → research) and diplomacy post-filter are applied; province owner lookup uses full province id so moves to GPs at peace or to minors (unknown relation) are dropped correctly.
- Run-level determinism when sim calls in fixed GP order each turn.

---

## References

[sim-game.md](sim-game.md) · [ai-planner.md](ai-planner.md) · [order-engine.md](order-engine.md) · [player-view.md](player-view.md) · [combat-resolution.md](combat-resolution.md)
