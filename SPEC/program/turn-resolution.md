# Turn Resolution

**SPEC/program** — Turn phases, state, and resolution sequence. Implementation: colonizethis_logic. World state: [SPEC/game/world-model.md](../game/world-model.md). Province ids in turn state and phase resolution use the prefixed format and lookup rules in [SPEC/game/world-model-identity.md](../game/world-model-identity.md).

---

## Turn State

**Turn state** is part of WorldState. It includes:

- **Turn number** — Integer; increments each full resolution (e.g. after end-of-turn phase). Calendar year is derived from `turnState.turnNumber` using the game's `turnTimeMapping`; no change to resolution logic.
- **Phase** — Enum indicating current step within resolution (e.g. orders, economy, combat, diplomacy, end-of-turn). Stub may use a single “resolution” phase or a minimal sequence; full phase set in [turn-resolution-phases.md](turn-resolution-phases.md).

At least one phase exists; resolver advances turn number so that “next turn” produces a new WorldState with incremented turn.

---

## Resolution Sequence

**TurnResolver** runs a defined **phase sequence**. Order of phases is fixed (see [turn-resolution-phases.md](turn-resolution-phases.md)); when combat is in scope, the full phase list includes **Minor Regiment Upgrade** after Movement and before all combat phases, followed by naval combat phases and land **Combat**. Each phase is a step; resolver executes steps in order. The **movement** phase uses **map topology** (adjacency) from colonizethis_data to validate and resolve **civilian** `MoveOrder`s and **`ArmyMoveOrder`**s ([military-armies.md](../game/military-armies.md), [movement.md](movement.md)). The **Combat** phase takes WorldState after movement and pre-combat updates, runs conflict detection and the combat resolver, and applies casualties and province flips.

**Stub:** Sequence and interfaces exist. Each phase can be no-op or minimal (e.g. end-of-turn advances turn number only) until economy, movement, and other logic are implemented.

---

## Input and Output

- **Input:** Current **WorldState** (or **Game** holding current WorldState). Optionally resolved config (colonizethis_data / GameConfig) for future phases.
- **Output:** New **WorldState** (or **Game** with updated WorldState). Immutable style: resolver returns a new instance; caller persists it and replaces current state.

Signature (conceptual): `WorldState resolve(WorldState current)` or `Game resolve(Game current)`. If Game is passed, resolver updates its WorldState and returns the same Game reference with new state, or returns a new Game; spec leaves exact signature to implementation as long as “state in, new state out” is clear.

---

## Responsibilities

- **colonizethis_logic** owns TurnResolver and phase sequence. Stub: no game rules beyond turn advance until full phases are implemented.
- **App** (or a service) calls TurnResolver when user (or AI) commits “next turn”; then persists the returned state via colonizethis_save. After each **completed** resolution, the Flutter app also mirrors the same playable state into the **auto-save** slot ([save-load.md](save-load.md) § Auto-save slot).
- **Load game** restores Game/WorldState from storage; “next turn” runs on that state and overwrites or replaces the saved state after resolve.

### Background execution (app, #2160)

The Flutter app may run **Full AI order generation**, **`mergeOrderLists`**, and full turn resolution in a **single worker isolate** via **`TurnResolutionRunner`** (`app/lib/core/services/turn_resolution_runner.dart`): the main isolate passes serialized **`Game`**, **human draft `Orders`**, combined **`MapTopology`**, and **`tileMapByRegion`** (same payload shape as before; the `orders` field is human-only until merged inside the worker). The isolate runs **`generateOrdersForGameFullAI`** (emitting coarse **`SendPort`** progress phases such as **`suggestionPools`**, staged **`aiStageA`**–**`aiStageG`**, and **`aiMerge`** before resolver phases), merges AI + human orders, then calls **`validateOrdersAndResolveTurnFromTrustedOrders`** with an **`onPhaseProgress`** callback so the UI can show live phase labels. When turn tracing is enabled, **`TurnTraceAiSection`** payloads and **`turnTraceStartedAtUtc`** are produced on the worker and returned in the terminal success message for the main isolate to decode. **Map** next-turn and **Flame-canvas** top-bar next-turn (when the map overlay is hidden) both use this runner; the app applies **`TurnResolutionResult`** on the main isolate when the session completes. See [logging/turn-resolution.md](logging/turn-resolution.md) for app-layer runner log lines and [app-event-bus.md](app-event-bus.md) for UI blocking while resolution is active. Refs **#2277**.

### Next-turn latency budget (usability)

End-to-end **next turn** (confirm through worker completion and terminal result ready for UI apply) must meet the **hard 15-second** ceiling (`kTurnProcessingWallClockBudgetMs` in **colonizethis_data**) for good usability. Normative policy lives in the Cursor rule **`.cursor/rules/colonizethis-turn-resolution-budget.mdc`** (also listed in **`AGENTS.md`** and **`.cursor/rules/routing-index.md`**). That budget governs **performance and AI suggestion throughput** only: **TurnResolver phase outcomes, order legality, and merged resolution semantics** remain authoritative per this document and [order-engine.md](order-engine.md). Heuristic caps or caching inside **suggestion enumeration** (for example move/army-move probe limits) do not change validated turn resolution; any further work to stay under budget should prefer incremental validation, memoization, and bounded search while preserving determinism. Refs **#2277**, **#2507**.

### Turn processing wall-clock budget (Refs #2507)

**Ceiling:** **15 000 ms** wall clock per measured segment on the project target environment (same class of machine as the `quality` workflow). Symbol: **`kTurnProcessingWallClockBudgetMs`** (`packages/colonizethis_data/lib/src/turn_processing_wall_clock_budget.dart`).

**Measured segment (in scope):** From immediately before **`generateOrdersForGameFullAI`** through completion of **`validateOrdersAndResolveTurnFromTrustedOrders`** returning **`TurnResolutionComplete`** — the same path as one observer turn body (`tool/run_observer_game/lib/observer_session_runner.dart`) and the app worker’s AI + trusted resolve block. **Single aggregate** ceiling for all CPU work in that segment (all GPs’ Full AI, merge, resolver phases affecting any faction).

**Excluded (out of scope):** Game **init** (`runInitGame`), isolate spawn/handoff overhead outside the measured block, **`mergeOrderLists`** when run outside the worker path under test, trace export, **`ObserverSnapshot`** / HTML, disk I/O, and main-isolate decode/apply after the worker terminal.

**Turn index:** Quality-gate perf test asserts the budget on **turn 1 only** (first resolved full turn after init) using **`GameSetupConfig.defaultConfig`** with every **`game.players`** entry marked AI-controlled (`aiControlByGpId`).

**On breach:** Treat as **release-blocking**. Emit phase splits at minimum **`full_ai_ms`** and **`resolve_ms`** (see [logging/turn-resolution.md](logging/turn-resolution.md)). Fix via perf work only — no semantic drift.

**Enforcement:** `packages/colonizethis_ai/test/perf/full_ai_first_turn_wall_clock_budget_test.dart` runs in **`tool/run_quality_gate_tests.sh`** / **`quality.yml`** package test loop for **colonizethis_ai**; hard-fails when over budget.

**Throughput regression smoke (Refs #2394):** `packages/colonizethis_logic/test/perf/resolve_turn_for_game_perf_test.dart` and `generate_orders_for_game_perf_test.dart` use a minimal two-AI fixture with generous **30 s** median ceilings — coarse guards only; the **15 s** first-turn Full AI test above is the normative gate.

---

## Stub Semantics

- Resolver has a **defined phase list** (e.g. list of enum values or named steps).
- **At least one phase** performs a minimal change: e.g. increment turn number in WorldState.
- Unit tests: resolve(currentState) returns new state; new state’s turn number is current + 1 (or equivalent); no other game logic required until full phases are implemented.

## Loaded Game Behavior

Map data required for resolution (`tileMapByRegion`, `topologyByRegion`, and combined topology used for AI) is mandatory for playable saves. Turn resolution call sites must not execute with missing topology data.

**Acceptance Criteria:**

- Given a game load attempt where required map data is missing or invalid
- When the app/service prepares turn resolution or AI order generation
- Then the app/service rejects the save with an explicit error and does not run turn resolution

- Given a playable loaded game with required map data present
- When TurnResolver runs the next turn
- Then extraction, movement, combat, and AI order generation execute with map topology provided by the loaded map data

## Campaign-complete guard

When `Game.calendarCampaignHalted` is true, `runTurnResolutionPipeline` returns a completed result without re-entering phase handlers (see [turn-time-mapping.md](../game/turn-time-mapping.md) § Campaign calendar cap and [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § End-of-turn).
