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

### When to Use Each Phase

- **Phase 4 (Minimal / Simple Heuristics):** Legacy/default heuristics path retained for compatibility and diagnostics.

- **Phase 6 (Full AI):** Advanced AI for simulation, testing, or optional hard mode. Used by ctdev Sim Game when "Use Full AI" is enabled. May be offered as an optional setting in the main game (e.g., "Advanced AI" difficulty toggle). Note: Full AI requires hidden agenda assignment at game setup (see below).
- **Main app next turn:** Full AI for AI GPs runs on the **turn-resolution worker isolate** (not the Flutter UI isolate); progress ids and merge semantics are defined under **Staged strategic planner (A–G)** below ([turn-resolution.md](turn-resolution.md), [next-turn-confirmation.md](../ui/next-turn-confirmation.md)).

### Phase 4 (Minimal)
1. Build PlayerView for each AI GP.
2. Query order suggestion API for candidate orders (move, build/work, research). Callers that hold region tile maps (sim_game, app next-turn flow) pass `tileMapByRegion` into `generateOrdersForPlayer` / `generateOrdersForGame` / `defaultSimGameAi` so `suggestWorkOrders` can suggest `build_rail` and terrain-aware `prospect` the same way as [order-suggestions.md](order-suggestions.md) describes for UI and turn resolution.
3. Apply preferences and seeded randomness to select; see [ai-architecture.md](../ai/ai-architecture.md) for behavior rules. Shared simple heuristics use the same category rules as [sim-game-default-ai.md](sim-game-default-ai.md) (including seeded fair choice between move and work when both have candidates).
4. Append to order list until no more suggestions or cap reached.
5. For Quick Battle, provide tactical actions using `tacticalSeed`; see [ai-architecture.md](../ai/ai-architecture.md).

Both AIPlanner and the sim-game default AI share the same simple heuristics core: PlayerView, order suggestion API, category selection per [sim-game-default-ai.md](sim-game-default-ai.md), seeded random choice within a category, diplomacy post-filter. Entry points remain separate.

### Phase 6 (Full AI)
Full hybrid AI in `colonizethis_ai` generates orders via behavior trees, utility AI, and domain planners per [SPEC/ai/](../ai/). Same control rules, seeding, and order merge apply. `generateOrdersForPlayerFullAI` / `generateStrategicOrders` accept optional `tileMapByRegion` and pass it to `suggestWorkOrders` in domain planners so full AI sees the same rail and terrain-aware prospect eligibility as Phase 4 when maps are available.

**Hidden agenda assignment:** Games using full AI have hidden agendas assigned at setup or init, per [hidden-agendas.md](../ai/hidden-agendas.md). Before the first call to full AI order generation (`generateOrdersForPlayerFullAI`), the caller must invoke `assignHiddenAgendasForGame` (colonizethis_ai) so that `game.hiddenAgendaByGpId` is populated for all AI-controlled GPs. **Where invoked:** Main game path: `runInitGame` (colonizethis_logic init_game_orchestrator) calls `assignHiddenAgendasForGame` before returning InitGameResult, so the main app receives a game with agendas set. Sim path: ctdev `SimGameController` calls it when `useFullAI` is true (when starting a sim game). See [game-setup-pipeline.md](game-setup-pipeline.md) step 9.

#### Staged strategic planner (A–G) and worker isolate

**Orchestration:** On main-app next turn, pool build + `generateOrdersForGameFullAI` + `mergeOrderLists` + `validateOrdersAndResolveTurnFromTrustedOrders` run on the **turn-resolution worker isolate**; the UI isolate does not run broad AI/suggestion work before spawn ([turn-resolution.md](turn-resolution.md)). AI GPs are planned **sequentially**; each GP uses one **A–G** pass with a growing **`aiPrefixSoFar`**. **Tile-selection cache** = per `(playerId, workTarget)` eligible `tileKey` sets (`colonizethis_logic`, `per_player_work_target_selection_cache.dart`, app-wrapped for Riverpod). **Suggestion pool** = `List<Order>` from `OrderSuggestionAPI` after tile narrowing; stages read **pools**, not the tile map. Human and worker share the same logic APIs ([order-suggestions.md](order-suggestions.md)).

**Stages (`runDomainPlanners`, `domain_planner_orchestrator.dart`):** Each stage passes the accumulated `orders` prefix into the next suggestion call (**frozen prefix**). Baseline caps: **A** civilian `WorkOrder` via `suggestWorkOrders` + `selectFullAiCivilianWorkOrders` — **≤1** per civilian; **B** `suggestBuildOrders` — **≤1** build when thresholds pass; **C**/**D** filtered `suggestMoveOrders` / `suggestArmyMoveOrders` — **≤1** each when run; **E** `suggestNavalMoveOrders` (take **1..clamp(len,3)**) + `suggestNavalMissionOrders` (**≤1**); **F** diplomacy — **≤1**; **G** `suggestResearchOrders` — **≤1**. Coarse progress: `suggestionPools`, `aiStageA`–`aiStageG` ([next-turn-confirmation.md](../ui/next-turn-confirmation.md)).

**Trust (interpretation A):** Tentative rows use **engine-aligned incremental probes** vs **human orders + `aiPrefixSoFar`** ([order-suggestions.md](order-suggestions.md) § Incremental candidate validation, [order-engine.md](order-engine.md)). Headline invariants on the emitted AI set: **≤1** civilian work per civilian; treasury/resources sufficient for emitted rows. **Partial output:** bounded search may stop early with the feasible subset already selected.

### Order Merge
Combined human + AI orders into deterministic list for turn resolution using **`mergeOrderLists(humanOrders:, aiOrders:)`** in `packages/colonizethis_logic/lib/src/orders/order_merge.dart` (human wins on conflicts; stable ordering per file contract):
- Stable ordering (player id → unit id → order type).
- Human-controlled units cannot receive AI orders; AI emits at most one order per unit.
- All merged orders validated; invalid orders dropped without breaking determinism.

When full AI (Phase 6) runs, the economy planner produces **production assignments** and **cargo preference** per AI GP ([economy-planner.md](../ai/economy-planner.md)). The caller must pass per-player production assignments into the turn resolver (Production phase) and may pass cargo preference to the naval planner. Human production choices come from UI or saved state; merge semantics for production are per-player (each player's assignments used for that player only).

## Integration

- **Phase:** AI orders generated before turn resolution each turn.
- **Upstream:** PlayerView, order suggestion API, game state. For Phase 6 full AI: `assignHiddenAgendasForGame` must have been called at setup/init (game setup pipeline or ctdev sim controller) so that hidden agendas are set before first full AI order generation.
- **Downstream:** Merged orders → TurnResolver.
- **ctdev:** All GPs are AI-controlled in sim. User chooses Sim Game AI or AI Planner. Turn seed displayed for debugging. AI order history in Orders tab (read-only diagnostic). See [ctdev-app.md](ctdev-app.md).

## Acceptance criteria

- **Control rules:** Game state persists per-GP control type; AIPlanner only produces orders for AI-controlled Great Powers; human-controlled units never receive AI orders.
- **Seeding and determinism:** Per-AI seeds and per-turn `turnSeed` (with documented sub-seeds) are the only randomness inputs; given the same game state and seeds, AIPlanner produces the same strategic and tactical decisions.
- **Phase 4 behaviour:** Minimal AI uses PlayerView and the order suggestion API with the documented category order and caps; it does not construct raw orders, and Quick Battle actions depend only on `tacticalSeed` and battle state.
- **Phase 6 delegation:** Full Phase 6 AI delegates order generation to `colonizethis_ai` per [ai-architecture.md](../ai/ai-architecture.md) and [ai-systems-impl.md](ai-systems-impl.md); control rules, seeding, and order merge remain consistent with this spec. Games using full AI have hidden agendas assigned at setup/init; the caller (game setup or sim controller) invokes `assignHiddenAgendasForGame` before the first `generateOrdersForPlayerFullAI` call.
- **Full AI diplomacy scoring:** For GP↔GP and GP↔Minor/Tribe pairs, full AI computes per-pair war desire and inverse improve-relations desire using composite power ratio (military + province + naval), relation factors, legal relation gate, and per GP-target cooldowns; wartime re-evaluation influences continue-war vs offer-peace output.
- **Order merge:** Merged order list preserves stable ordering (player → unit → type), respects human precedence via `mergeOrderLists`, emits at most one AI order per unit, and is fully validated and deterministic.
- **Staged Full AI (main app):** Given the main app confirms next turn with Full AI enabled, when the turn-resolution worker runs, then Phase 6 planning executes stages **A–G** in order with frozen prefixes, obeys the **≤1 civilian `WorkOrder` per civilian** rule, uses **engine-aligned incremental probes** during staging, and merges AI orders with human drafts before the trusted resolver entry point ([turn-resolution.md](turn-resolution.md)).
- **Army move parity with human rules:** When AI emits `ArmyMoveOrder`, destination legality matches human rules from [movement.md](movement.md): any AI-owned province in any region is valid (cross-region allowed), and non-owned destinations follow normal adjacency/validation constraints.

## Constraints
- AIPlanner only produces orders for AI-controlled GPs.
- Phase 4 out of scope: long-term strategy, complex diplomacy, economic optimization, naval orders.
- Naval orders require Phase 6 full AI.
- Phase 4 simple-heuristics remains available for ctdev toggle between Sim Game AI and AI Planner.
