# AIPlanner

## Responsibility
Generate orders for AI-controlled Great Powers. Phase 4: minimal heuristics. Phase 6: full hybrid AI. Shared infrastructure: control rules, seeding, order merge. AI behavior rules: [SPEC/ai/](../ai/).

## Data Model

### Control Rules
Each Great Power has a control type: **human-controlled** (bound to player) or **AI-controlled** (no human assigned). In single-player, all unassigned GPs are AI-controlled. Control type is part of game state (saved/loaded).

### Seeding
- Global game seed stored with game.
- Per-AI seed `aiSeed[P]` in game state; set at creation or control change.
- Per-turn: `turnSeed[P, T] = hash(globalGameSeed, aiSeed[P], T)`.
- Sub-seeds: `strategicSeed`, `tacticalSeed` (Phase 4); additional Phase 6 sub-seeds (perception, goals, economy, military, diplomacy, research, dialogue, agenda).

All AI randomness flows from these seeds. Same save + seeds → same orders and decisions.

## Algorithm / Flow

### Phase 4 (Minimal)
1. Build PlayerView for each AI GP.
2. Query order suggestion API for candidate orders (move, build/work, research).
3. Apply preferences and seeded randomness to select; see [ai-architecture.md](../ai/ai-architecture.md) for behavior rules.
4. Append to order list until no more suggestions or cap reached.
5. For Quick Battle, provide tactical actions using `tacticalSeed`; see [ai-architecture.md](../ai/ai-architecture.md).

Both AIPlanner and the sim-game default AI share the same simple heuristics core: PlayerView, order suggestion API, category order (move → work → build → research), seeded random choice, diplomacy post-filter. Entry points remain separate.

### Phase 6 (Full AI)
Full hybrid AI in `colonizethis_ai` generates orders via behavior trees, utility AI, and domain planners per [SPEC/ai/](../ai/). Same control rules, seeding, and order merge apply.

### Order Merge
Combined human + AI orders into deterministic list for turn resolution:
- Stable ordering (player id → unit id → order type).
- Human-controlled units cannot receive AI orders; AI emits at most one order per unit.
- All merged orders validated; invalid orders dropped without breaking determinism.

## Integration

- **Phase:** AI orders generated before turn resolution each turn.
- **Upstream:** PlayerView, order suggestion API, game state.
- **Downstream:** Merged orders → TurnResolver.
- **ctdev:** All GPs are AI-controlled in sim. User chooses Sim Game AI or AI Planner. Turn seed displayed for debugging. AI order history in Orders tab (read-only diagnostic). See [ctdev-app.md](ctdev-app.md).

## Acceptance criteria

- **Control rules:** Game state persists per-GP control type; AIPlanner only produces orders for AI-controlled Great Powers; human-controlled units never receive AI orders.
- **Seeding and determinism:** Per-AI seeds and per-turn `turnSeed` (with documented sub-seeds) are the only randomness inputs; given the same game state and seeds, AIPlanner produces the same strategic and tactical decisions.
- **Phase 4 behaviour:** Minimal AI uses PlayerView and the order suggestion API with the documented category order and caps; it does not construct raw orders, and Quick Battle actions depend only on `tacticalSeed` and battle state.
- **Phase 6 delegation:** Full Phase 6 AI delegates order generation to `colonizethis_ai` per [ai-architecture.md](../ai/ai-architecture.md) and [ai-systems-impl.md](ai-systems-impl.md); control rules, seeding, and order merge remain consistent with this spec.
- **Order merge:** Merged order list preserves stable ordering (player → unit → type), respects human precedence, emits at most one AI order per unit, and is fully validated and deterministic.

## Constraints
- AIPlanner only produces orders for AI-controlled GPs.
- Phase 4 out of scope: long-term strategy, complex diplomacy, economic optimization, naval orders.
- Naval orders require Phase 6 full AI.
- Phase 4 simple-heuristics remains available for ctdev toggle between Sim Game AI and AI Planner.
