# sim_game — Default AI Behaviour

**SPEC/program** — Deterministic default AI used by [sim-game.md](sim-game.md). Produces one-turn orders for a single Great Power. In Sim Game AI mode, sim_game uses this function for all GPs. It shares channels and strategy with the minimal AIPlanner.

---

## Purpose

Define a pure function that, given game state and one GP, produces that player’s one-turn orders in sim_game. It uses the same channels and strategy as minimal AIPlanner: [PlayerView](player-view.md), [order suggestion API](order-engine.md), shared simple heuristics, and diplomacy move filtering. No raw construction from topology.

---

## Function contract

`defaultSimGameAi(game, player, topology, baseSeed, { tileMapByRegion }) -> Orders`

- Input: current `game`, one GP `player`, `topology`, and `baseSeed` fallback when `aiSeedByGpId[player.id]` is missing. Optional `tileMapByRegion` matches [order-suggestions.md](order-suggestions.md) / turn resolution: when provided (e.g. sim_game controller), `suggestWorkOrders` can evaluate `build_rail` and terrain-aware `prospect`.
- Output: validated `Orders` for that player only (move/build/work/research).
- Purity: no mutation of `game` or global state.

---

## Order generation

All order types are produced by shared simple heuristics used by both AIPlanner and defaultSimGameAi:

- Build [PlayerView](player-view.md) and call the order suggestion API for candidate move/work/build/research orders (passing `tileMapByRegion` when the caller supplies it).
- Apply category order: among **move**, **work**, **build**, **research**, prefer lower-index categories except when **both** move and work have candidates — then use a **seeded fair choice** between move and work for that iteration so work (e.g. `build_rail`) is not always starved by perpetual move suggestions. Within a chosen category, use seeded random choice among candidates.
- Apply diplomacy post-filter to moves: drop moves to at-peace factions; drop moves to minors when relation is unknown. Province owner lookup uses full ids (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).
- Apply per-player iteration cap (implementation constant) to avoid unbounded loops.

---

## Determinism

- Per-call determinism: same `(game, player, topology, baseSeed)` and turn -> same `Orders`.
- Run-level determinism: fixed GP call order each turn yields reproducible runs for same initial state and seeds.
- Seed source matches AIPlanner turn seed derivation; no global RNG.

---

## Acceptance criteria

- Same `(game, player, topology, baseSeed)` and turn number -> same `Orders`.
- Function does not mutate `game` or global state.
- Category selection (including move vs work when both have candidates) and diplomacy post-filter are applied; full province ids are used for owner lookup so moves to at-peace GPs or unknown-relation minors are dropped.
- Run-level determinism holds when sim calls AI in fixed GP order.

---

## References

[sim-game.md](sim-game.md) · [ai-planner.md](ai-planner.md) · [order-engine.md](order-engine.md) · [player-view.md](player-view.md)
