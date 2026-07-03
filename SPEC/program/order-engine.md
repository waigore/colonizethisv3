# Order Engine

**SPEC/program** — Current-turn order list, validation, merge, and projected effects. Order types: [orders.md](orders.md). Suggestion API: [order-suggestions.md](order-suggestions.md).

---

## Responsibility

The order engine (colonizethis_logic) maintains the **current-turn order list per player**. Invoked on add/remove order. Does **not** apply orders to world state; that happens in TurnResolver.

---

## Validation

**Trigger:** Validation runs in **two distinct contexts**:

- **Final-order-submission context (existing):** On every add/remove via `addXxxOrderWithContext` / `removeXxxOrder`, the engine re-validates the entire list for that player against world state (costs, caps, tile/province legality, tech per [orders.md](orders.md)). This is the contract for human draft edits, scenario runners, and external/manual callers.
- **Candidate-probe context (new):** The order suggestion API exposes an **incremental candidate validation primitive** that evaluates one candidate against an already-accepted prefix without running full-list `validatePlayerOrdersWithContext`. The primitive is internal to suggestion code and does not change the public `addXxxOrderWithContext` / `validatePlayerOrdersWithContext` API surface used by the final-submission context. See [order-suggestions.md](order-suggestions.md) § Incremental candidate validation for the algorithm and equivalence guarantee.

**Scope:** The engine validates **move** (civilian), **army move**, **build**, **work**, **diplomatic**, **naval move**, and **naval mission** orders. **Research** orders are validated in the research phase (TurnResolver), not in the engine. Diplomatic orders are held and validated per-player like other order types (preconditions for war/peace, alliances, overtures, grants, and subsidies) and then passed into the merge step.

**Rule:** Validate in **submission order**. First failure rejects that order and all after it. Orders 1..N-1 remain.

**Equivalence:** For any candidate evaluated through the incremental primitive against an already-accepted `basePrefix`, the accept/reject result is identical to running `validatePlayerOrdersWithContext` over `basePrefix ⊕ candidate` and inspecting the candidate's result. The two contexts are equivalent for accept/reject decisions; they differ only in cost (incremental skips redundant re-validation of `basePrefix`).

**With context:** Uses a PlayerView for visibility rules (move/work orders). Source province = unit's location; need not be owned by player. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

Returns validation results (accepted / rejected with reason) for UI feedback.

### Validation components

Move and work-order validation are delegated to dedicated components for single-responsibility and reuse:

- **MoveValidator** (`validators/move_validator.dart`): Validates **civilian** `MoveOrder` per [orders.md](orders.md). Checks unit ownership, destination tile existence/land-ness, visibility, and shared civilian occupancy (`civilianMayOccupyLandTileKey`: tile-level control override, then province-derived GP/Minor/Tribe/unowned rules). Civilian move validation does **not** use map-topology adjacency. **ArmyMoveOrder** validation (army ownership, Home Army capital lock, adjacency/ownership/war rules) remains separate and topology-based per [movement.md](movement.md). Used by OrderEngine when validating orders.

- **WorkOrderCostCalculator** (`validators/work_order_cost_calculator.dart`): Computes work order material costs for a given target and tile (improvement/fort/road level). Returns null for steal_tech, counter_spy, purchase_land. Used by OrderEngine for work-order cost validation and for projecting work-order costs in the same validation pass.
- **WorkOrderValidator** (`validators/work_order_validator.dart`): Validates civilian work orders with per-target checks, visibility, and the **Work ⊆ Move** invariant by requiring the same shared civilian occupancy check used by `MoveValidator` for `targetTileKey`.

**Validator factory (injection):** `OrderEngine` accepts an optional `OrderValidatorFactory` on construction. When omitted, the engine uses the default factory that instantiates the standard move, army move, build, work, diplomatic, and naval validators. When set, callers (including tests) may substitute fakes or wrappers for one or more validator slots while preserving submission-order validation behavior.

**Build validation (naval):** Build orders for naval units are validated for treasury, stockpile, and the **unlocking tech** for that ship type when applicable (see [tech-tree-naval.md](../game/tech-tree-naval.md)); starting ships such as Carrack have no prerequisite. OrderEngine validates before accepting.

**Build validation (spawn province):** Build orders resolve an effective spawn province before affordability checks for **civilian** builds. **Military:** new regiments attach to **Home Army** at capital; `spawnProvinceId` is ignored unless TDD extends location choice. For naval, spawn always resolves to capital home fleet and `spawnProvinceId` is ignored. If no capital exists, military/naval build is rejected.

**Build validation (rejection reasons):** `BuildOrderValidator` forwards the `reason` from `canAffordBuild` (see [orders.md](orders.md) § **BuildUnitOrder cost validation**). Distinct strings apply per failure category; `Insufficient resources` is only for unclassified failures (unknown type/category, missing catalog).

---

## Per-Player Scope

Validation is per-player only. No cross-player conflict resolution at this stage; that happens in turn resolution.

---

## Projected Effects

Supports a **dry-run**: apply orders via the resolver (which returns **new** state); return projected effects for UI. The engine does **not** mutate the passed-in game; the caller may pass the live game. No mutation of real state.

`projectedEffects` accepts an optional `tileMapByRegion`. When omitted or empty, the dry-run uses no tile maps and **expected extraction is zero**; callers (e.g. SimGameController) may pass tile maps when available so projected extraction is non-zero. See [order-projections.md](order-projections.md).

### Injected projector seam (Refs #3290 C2)

The concrete dry-run (`projectOrderEffects`) runs the turn resolver (`resolveTurnForGame`) and therefore lives in the neutral `lib/src/projections/` core module, which sits **above** the `orders` domain in the package-split DAG. To let the `orders` domain (the future `colonizethis_orders` package) compile without importing that core module, `OrderEngine` accepts the projector as an injected dependency `OrderEffectsProjector? projector` (mirroring the existing injected `validatorFactory`). The seam is invoked in exactly two places: `projectedEffects` and trade-order validation (the non-bid treasury projection). The turn orchestrator (`turn/turn_resolver.dart`) and the app / ctdev / sim-scenario consumers construct `OrderEngine(projector: projectOrderEffects)`; the `OrderEffectsProjector` typedef and the `ProjectedEffects` value type live in the `orders` domain so the public `package:colonizethis_logic` barrel surface is unchanged.

- **Given** an `OrderEngine` constructed with `projector: projectOrderEffects`, when `projectedEffects(game, topology, playerId)` is called, then it returns the same `ProjectedEffects` the injected projector produces for those inputs (worker count, treasury delta, unit locations, stockpile deltas).
- **Given** an `OrderEngine` constructed with no `projector` (default `null`), when `projectedEffects(...)` is called, then the engine throws a `StateError` naming the missing `OrderEffectsProjector` rather than silently returning empty effects.
- **Given** an `OrderEngine` constructed with no `projector` and a player whose staged orders contain at least one `TradeOrder`, when `validatePlayerOrdersWithContext(...)` runs the trade-order phase, then the engine throws a `StateError` naming the missing `OrderEffectsProjector` (the non-bid treasury projection cannot be computed without it).
- **Given** an `OrderEngine` constructed with no `projector` and a player whose staged orders contain no `TradeOrder`, when `validatePlayerOrdersWithContext(...)` runs, then it completes without invoking the projector (the trade phase short-circuits on empty trade orders).

### ProjectedEffects fields

| Field | Required for current product | Implemented |
|-------|------------------|-------------|
| `workerCount` | Yes | Yes |
| `treasuryDelta` | Yes | Yes |
| `unitLocations` | Yes | Yes |
| `stockpileDeltas` | Yes | Yes |
| `productionByRecipe` | No (optional; when `defaultAssignments` provided) | Yes |
| `extractionByCommodity` | No (optional; deferred) | No |

---

## Turn Resolution Integration

Before applying orders, TurnResolver runs a **merge** step: combine per-player lists (human + AI) with **human over AI** precedence for conflicts. Merge includes **diplomatic** orders (human over AI per type+target), using only those diplomatic orders that passed OrderEngine validation for each player. Then resolve cross-player effects (conflict detection, diplomacy). Then apply in phase order per [turn-resolution-phases.md](turn-resolution-phases.md). The order engine does not perform merge or application.

### Trusted-source resolution

The resolver exposes **two public turn-entry points** so the per-player pre-apply validation pass (`filterAcceptedOrdersForAllPlayers` in `turn_order_acceptance.dart`) is **skipped only for callers that already validated their inputs**:

- **Untrusted entry point — `validateOrdersAndResolveTurn`:** Runs `filterAcceptedOrdersForAllPlayers` over the merged `Orders` before applying. Required for any caller whose orders may contain invalid entries (scenario runners, ad-hoc test orders, manual JSON-loaded orders, future external/manual sources). Behavior is unchanged from prior releases.
- **Trusted entry point — `validateOrdersAndResolveTurnFromTrustedOrders`:** Skips `filterAcceptedOrdersForAllPlayers` and dispatches straight to `resolveTurnForGame`. Caller contract: every order in the supplied `Orders` must already have been accepted by either (a) `OrderEngine.addXxxOrderWithContext` for human draft orders, or (b) the order suggestion API (which guarantees `validatePlayerOrdersWithContext` returns `accepted` when the suggestion is appended; see [order-suggestions.md](order-suggestions.md) § Guarantees) for AI-generated orders. Mixing untrusted orders into the trusted entry point breaks the contract; new callers must justify use of this entry point in code review.

**Worker isolate (main app next turn):** The merged `Orders` passed to `validateOrdersAndResolveTurnFromTrustedOrders` may be assembled **on the turn-resolution worker isolate**: AI orders are produced by the staged Full AI planner, combined with human draft orders via `mergeOrderLists` in `colonizethis_logic`, then resolved without returning to the Flutter main isolate first ([turn-resolution.md](turn-resolution.md), [ai-planner.md](ai-planner.md)). The trusted-path contract is unchanged—only **where** merge and planner validation run moves off the UI thread.

A separate function name (not a boolean flag on `Orders`) is the chosen mechanism so trust does not propagate silently through copies, merges, or future refactors. Each trusted-path caller is auditable by grep.

**Equivalence:** Given identical merged `Orders` inputs whose every order is `accepted` by `validatePlayerOrdersWithContext`, the trusted and untrusted entry points produce identical post-merge accepted order sets and identical resulting `WorldState`.

---

## End-of-turn order list

**(a) Clear or carry over:** After turn resolution, the current-turn order list is **cleared** (not carried over). Each turn starts with an empty order list; players submit orders for that turn; after End-of-turn those orders have been applied and are not reused for the next turn.

**(b) Responsibility:** TurnResolver does not mutate the OrderEngine or the caller's order data; it only reads orders. The **caller** (app, ctdev, or scenario runner) that owns the order list or OrderEngine is responsible for clearing or replacing it after TurnResolver returns, so that the next turn starts with a fresh order list. Merge and apply for the next turn happen when that turn's Orders phase runs (see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § End-of-turn).

---

## Determinism

Submission order is stable. Merge uses stable ordering (player id, order type, order id) for deterministic replay.

---

## Supplying Research and Diplomatic Orders (Caller Contract)

The OrderEngine validates and stores **move (civilian), army move, build, work, diplomatic, naval move, and naval mission** orders via `addMoveOrder`, `addArmyMoveOrder`, `addBuildOrder`, `addWorkOrder`, `addDiplomaticOrder`, `addNavalMoveOrder`, and `addNavalMissionOrder` (exact method names per TDD). **Research orders are not added to the engine**; they are validated and applied in the Research phase (TurnResolver) per [research-resolution.md](research-resolution.md).

### Research Orders

- **Not stored in OrderEngine.** The engine has no `addResearchOrder` method.
- **How supplied:** Research orders are passed directly to TurnResolver via `Orders.researchOrdersByPlayerId` (map of player id → list of research slot orders).
- **Caller flow:** The app/UI collects research orders separately from the tactical orders (move/build/work). At turn resolution, the caller constructs an `Orders` object with `researchOrdersByPlayerId` populated and passes this to `resolveTurnForGame(orders, ...)` or merges it with AI orders via `mergeOrderLists` before resolution.

### Diplomatic Orders

- **Stored in OrderEngine.** Use `addDiplomaticOrder` to validate and add diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, Grant Aid, Set Subsidy).
- **Validation:** The engine validates diplomatic preconditions (war/peace state, overture stage chain, treasury costs, embassy/consulate requirements) before accepting.
- **How supplied:** Diplomatic orders are part of `OrderEngine.orders.diplomaticOrdersByPlayerId` after validation. At turn resolution, `orderEngine.orders` contributes diplomatic orders to the merge.
- **Turn sequence:** Diplomatic orders are resolved in the Diplomacy phase, which runs before Movement phase. The order engine stores but does not execute them.

### Summary Table

| Order Type | OrderEngine Method | Stored in Engine | Supplied To Resolver Via |
|------------|-------------------|------------------|-------------------------|
| Move (civilian) | `addMoveOrder` | Yes | `orderEngine.orders` |
| Army move | `addArmyMoveOrder` | Yes | `orderEngine.orders` |
| Build | `addBuildOrder` | Yes | `orderEngine.orders` |
| Work | `addWorkOrder` | Yes | `orderEngine.orders` |
| Naval Move | `addNavalMoveOrder` | Yes | `orderEngine.orders` |
| Naval Mission | `addNavalMissionOrder` | Yes | `orderEngine.orders` |
| Diplomatic | `addDiplomaticOrder` | Yes | `orderEngine.orders` |
| Research | *None* | **No** | `Orders.researchOrdersByPlayerId` |

---

## Acceptance criteria

- **Validation:** On add/remove with context, the full list for that player is validated in submission order; first rejection rejects that order and all subsequent; validation results (accepted/rejected + reason) are returned for UI.
- **Diplomatic validation:** Diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, GrantAid, SetSubsidy) are validated by the engine with the same submission-order semantics as other orders. At a minimum, Declare War and Offer Peace respect current relationState preconditions, overtures respect the overture-stage chain and treasury costs, GrantAid and SetSubsidy each require an Embassy (Refs #3753 R2 — a Trade Consulate alone is not sufficient for either economic action), and `Establish Overture` orders targeting a faction currently at `AT_WAR` with the player are rejected and do not deduct treasury.
- **Research orders:** Research orders are **not** added to OrderEngine; they are supplied separately via `Orders.researchOrdersByPlayerId` and validated/applied in the Research phase (TurnResolver).
- **Caller contract:** The caller (app or ctdev) supplies civilian move, army move, build, work, diplomatic, and naval orders via OrderEngine methods; research orders are collected separately and passed to the resolver via `Orders.researchOrdersByPlayerId`.
- **Merge:** Human + AI orders merged with human over AI for conflicts; ordering is stable for deterministic replay (player id, then conflict key / order type as specified).
- **Projected effects:** Dry-run returns `ProjectedEffects` with worker count, treasury delta, unit locations, and stockpile deltas (all required for current product and implemented); no mutation of the passed-in game from the caller's perspective. See § ProjectedEffects fields for the full list and implementation status.
- **No application:** Order engine does not apply orders to world state; TurnResolver applies after merge.
- **Move validation (extracted):** Given a civilian move order whose `destinationTileKey` fails shared civilian occupancy rules (per [orders.md](orders.md)), when validated with context, then the result is rejected and the unit location remains unchanged. Military moves into GP or Minor/Tribe provinces without war (or same-turn declareWar) are rejected with the appropriate "Must declare war before attacking..." reason.
- **Work order cost (single source):** Given work orders with material costs, when validated and when projecting effects in the same pass, the same cost calculation is used via WorkOrderCostCalculator (single source of truth).
- **Work subset move:** Given a civilian work order whose `targetTileKey` the unit may not legally occupy under shared civilian occupancy rules, when validated with context, then the order engine rejects that work order before application.
- **Validator injection seam:** Given a caller constructs `OrderEngine` with a custom validator factory, when `validatePlayerOrdersWithContext` runs, then the engine uses validators from that factory for move/army/build/work/diplomatic/naval validation without changing public order-storage APIs.
- **Incremental candidate equivalence:** Given a `basePrefix` whose every order is `accepted` by `validatePlayerOrdersWithContext` for its player and a candidate `c` of a stateless type (move, army move, naval move, or naval mission), when the system evaluates `c` via the incremental candidate validation primitive (per [order-suggestions.md](order-suggestions.md) § Incremental candidate validation) and via the existing `OrderEngine(initialOrders: basePrefix).addXxxOrderWithContext(...)` path on the same inputs, then both paths return the same boolean accept/reject decision for `c`.
- **Trusted-path equivalence:** Given a merged `Orders` value whose every order is `accepted` by `validatePlayerOrdersWithContext` for its player, when the system runs `validateOrdersAndResolveTurnFromTrustedOrders` and `validateOrdersAndResolveTurn` against the same inputs, then both entry points return a `TurnResolutionComplete` whose post-merge accepted order sets per player and whose resulting `WorldState` are identical.
- **Trusted-path bypass:** Given a merged `Orders` value passed to `validateOrdersAndResolveTurnFromTrustedOrders`, when the system resolves the turn, then it does **not** invoke `filterAcceptedOrdersForAllPlayers`; orders are dispatched to the phase pipeline as-supplied.
- **Untrusted-path preservation:** Given a merged `Orders` value containing at least one rejected order, when the system runs `validateOrdersAndResolveTurn`, then `filterAcceptedOrdersForAllPlayers` removes each rejected order from the per-player order sets before phase application; the resulting `WorldState` reflects only accepted orders.

---

## Code generation (OrderEngine slots)

**Mechanical vs validation:** `validatePlayerOrdersWithContext` stays hand-written in `order_engine.dart` (per-type validators, treasury/stockpile propagation). The **slot table** (getter/updater/`OrderSlot` consts), **constructor and deep-copy wiring** (`copyInitialOrdersForEngine`, `copyOrdersSnapshotForEngine`), and **public** `addXxxOrder`, `addXxxOrderWithContext`, `removeXxxOrder` methods are **generated** into `order_engine.g.dart` from `order_engine_manifest.yaml` via `dart run tool/generate_order_engine_slots.dart`.

**Extraction shape:** `order_engine.g.dart` is a **standalone library** with explicit `import` declarations, not a `part of 'order_engine.dart'` fragment (Refs #3543; per `SPEC/program/dart-file-non-comment-line-size.md` § Extraction shape and the `repo.orders_no_part_directives` gate). The slot descriptor `OrderSlot<T>` and the `copyMapOfOrderLists` helper shared between the hand-written engine and the generated library live in `order_engine_slot.dart` (a package-internal library not re-exported from the barrel), so generation stays standalone without widening the package's public API.

**Manifest:** `packages/colonizethis_orders/lib/src/orders/order_engine_manifest.yaml` lists each **engine-managed** order kind (Dart type, `Orders` field, `copyWith` parameter name, log label, public method names) and **storage-only** fields copied with orders but not exposed as engine slots (e.g. `researchOrdersByPlayerId` — no `addResearchOrder` on `OrderEngine`).

**CI / workflow:** `melos run codegen_order_engine` regenerates output; `melos run codegen_verify` (runs `tool/verify_order_engine_codegen.sh`) must pass on PRs — committed `order_engine.g.dart` must match the generator.

**Structural guard:** The generator compares manifest field names to every `final Map<String, List<…>>` field on `Orders` in `colonizethis_models`; a mismatch fails generation so new order maps are not silently omitted.

**Implementation note:** Generated public `add*` / `remove*` methods live in a `mixin` mixed into `OrderEngine` (a `mixin on OrderEngine` would be circular). They delegate to `addOrderForSlot` / `addOrderForSlotWithContext` / `removeOrderForSlot` on the class via `(this as OrderEngine)` so slot helpers stay on the class body next to private state.

### Acceptance criteria (codegen)

- **Given** the repository has `order_engine_manifest.yaml` and `order_engine.g.dart` committed in sync, **when** a maintainer runs `dart run tool/generate_order_engine_slots.dart`, **then** `git diff` shows no changes to `order_engine.g.dart`.
- **Given** `Orders` in `colonizethis_models` defines a set of `Map<String, List<…>>` order-collection fields, **when** `order_engine_manifest.yaml` does not list exactly those fields split across `engine_slots` and `storage_only`, **then** the generator exits with non-zero status and reports the field-set mismatch.

---

## Diagnostics

ctdev uses OrderEngine to surface order validity in the Orders (AI history) tab. This is purely diagnostic and does not alter orders passed to TurnResolver.
