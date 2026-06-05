# Order Suggestion API

**SPEC/program** — Enumerates valid candidate orders for AI and tooling. Validator: [order-engine.md](order-engine.md). Order types: [orders.md](orders.md).

---

## Responsibility

Given a player, their current valid order list, and game context, enumerate **candidate orders** (move, build, work, research, naval, diplomatic, recruit worker) guaranteed to be accepted if appended.

---

## Inputs

- `Game` and `MapTopology` (full world state and topology).
- `playerId` for the acting Great Power.
- Current `Orders` for that player (assumed valid prefix).
- A `PlayerView` for `playerId` (see [player-view.md](player-view.md)) — sole source of visibility.

---

## Guarantees

For every suggested order `o`, appending it to the current list and validating via `validatePlayerOrdersWithContext` yields `accepted`. The internal candidate-acceptance pipeline used to enumerate suggestions is the **incremental candidate validation primitive** described in § Incremental candidate validation. The primitive is required to produce the same `accepted` / `rejected` decision per candidate as full-pass `validatePlayerOrdersWithContext` (see [order-engine.md](order-engine.md) § Validation), so the observable suggestion contract is unchanged.

**Throughput bounds (Full AI):** Enumeration for some families (notably **`suggestMoveOrders`** / **`suggestArmyMoveOrders`**) may apply **deterministic probe or acceptance caps** so Full AI completes within the next-turn usability budget ([turn-resolution.md](turn-resolution.md) § Turn processing wall-clock budget). **`suggestMoveOrders`** probes only destination tiles in the unit’s province, player-owned provinces, and adjacent non-owned provinces (per [movement.md](movement.md)); it does not scan all visible land tiles globally. A capped pass still validates each emitted candidate via the incremental primitive; it may omit some engine-valid destinations that would appear only after exhaustive scan. **Work-order probes:** `suggestWorkOrders` applies a per-player pass budget (`kMaxWorkProbeAttemptsPerPlayerPass`, default **64**), per unit per work target (`kMaxWorkProbeAttemptsPerUnitPerTarget`, default **4**), and per Explorer explore/prospect province sweep (`kMaxExploreProvinceProbesPerUnit`, default **4**). Capped passes may omit engine-valid work rows that would appear only after exhaustive scan. Explorer multi-row `explore`/`prospect` completeness applies within the capped scan order.

**Throughput regression smoke (Refs #2394):** `packages/colonizethis_logic/test/perf/generate_orders_for_game_perf_test.dart` runs `generateOrdersForGame` on a minimal two-AI fixture with warmup iterations, records sampled durations, and asserts the median stays below a generous fixed ceiling so catastrophic batch-path regressions fail in `dart test` / package CI. It does not assert tight latency targets; profiling and phase budgets remain governed by [turn-resolution.md](turn-resolution.md) and [logging/turn-resolution.md](logging/turn-resolution.md).

**Shared unit index (naval, Refs #2394):** `OrderSuggestionAPI.suggestNavalMoveOrders` and `suggestNavalMissionOrders` accept an optional `unitsById` argument: a read-only map of every unit in `Game.worldState` keyed by unit id (the same shape as `unitsByIdFromWorld` in logic). When the caller supplies it, the implementation uses that map for incremental naval validation instead of rebuilding it inside the call. When omitted, the implementation builds the map as before. Observable candidate lists and accept/reject decisions for a fixed `(Game, topology, PlayerView, Orders)` tuple must not depend on whether the caller passed a map or omitted it, provided the supplied map matches the current world state.

**Army Move picker shared projection (Refs #2394):** `armyMovePickerDestinations` accepts optional `playerView`, `unitsById`, `factionMembership`, and `sharedCandidateValidator` with the same contract as `IncrementalCandidateValidator.forPlayer`: when supplied and consistent with current `Game` / `MapTopology` / `playerId` / `currentOrders`, internal validators reuse them instead of embedding `buildPlayerView` / `unitsByIdFromWorld` / `DiplomacyFactionMembership.from` / per-call `forPlayer` setup. When `sharedCandidateValidator` is passed, it is rebound with `forBasePrefix(currentOrders)` only when its embedded `basePrefix` differs. Observable destination lists for a fixed tuple must not depend on whether these optional arguments were passed.

**Civilian tile highlight shared projection (Refs #2394):** `getValidWorkOrderTileKeys` accepts optional `view`, `unitsById`, `factionMembership`, `sharedCandidateValidator`, and `playerOwnedProvinceIds` with the same contracts as `getValidWorkOrderTileKeysWithVisibility`. Callers that enumerate valid tiles for multiple units in one panel pass should supply shared snapshots so the panel path does not rebuild `PlayerView` / validator / owned-province sets per unit.

**Civilian work alignment:** Suggestions never assume instant primary effects for `prospect` or `purchase_land`; those targets follow the same **assign → tick → complete** invariant as validation and resolution (prospected set, treasury debit, and `purchasedTilesByTileKey` only when work completes in Build/Work). Authoritative rules: [orders.md](orders.md) (Civilian deferred primary effects) and [development-resolution.md](development-resolution.md).

---

## Incremental candidate validation

**Purpose.** AI suggestion enumeration evaluates many candidates per player per turn. Running full-pass `validatePlayerOrdersWithContext` (which re-validates every existing order in the player's list, across all order types) for each probe is O(candidates × |basePrefix|) and dominated next-turn cost. The incremental primitive evaluates one candidate against an already-accepted prefix in O(1) plus the candidate-type validator's intrinsic work.

**Definitions.**

- `basePrefix` — the player's already-accepted `Orders` at the start of a suggestion pass. By the engine invariant (see [order-engine.md](order-engine.md) § Validation), every order in `basePrefix` has already been validated in submission order and accepted.
- `acceptedExtension` — an ordered list of additional candidates accepted earlier in the same suggestion pass (e.g. multiple diplomatic candidates within the diplomatic two-pass scheme above).
- `currentTrial = basePrefix ⊕ acceptedExtension` — the working list against which the next candidate is evaluated.

**Algorithm (per candidate `c`).**

1. Validate `c` against `currentTrial` using the per-type validator (move, army move, build, work, diplomatic, naval move, naval mission), reusing the same predicate logic the full-pass validator uses for the i-th order when `i = currentTrial.length`. Because `currentTrial` is fully accepted by the basePrefix invariant, `previousRejected = false` for `c`.
2. The predicate must read accumulated state derived from `currentTrial` (treasury, stockpile, dev-exclusive reservations, civilian occupancy, fleet/unit caps, diplomatic state) — the cumulative effects of all prior orders. It must **not** re-validate any order in `currentTrial`; those are already accepted.
3. If `c` is accepted, the caller may append it to `acceptedExtension` and update any cumulative state cache. Otherwise discard `c` and leave `currentTrial` unchanged.

**Equivalence guarantee.** Because (a) the full-pass validator processes orders strictly in submission order, (b) once an order is accepted at position i its acceptance is invariant under appending later orders (the validator is monotone in the prefix length), and (c) the candidate `c` would always be evaluated at position `currentTrial.length` in the full-pass approach, the incremental algorithm yields the same accept/reject decision for `c` as full-pass validation.

**Rollout per type.** The incremental primitive is introduced incrementally across candidate types. Stateless validator types (move, army move, naval move, naval mission) — whose per-type predicate does not depend on cumulative stockpile/treasury/diplomatic state from other order types — are migrated first. Stateful types (build, work, diplomatic) are migrated in follow-up slices that introduce the matching per-type cumulative-state cache. Until a type is migrated, the existing `addXxxOrderWithContext`-based probe continues to be used; the public observable `accepted`/`rejected` contract is preserved across the rollout because of the equivalence guarantee.

**Acceptance criteria (incremental candidate validation, stateless types).**

- Given a `basePrefix` whose every order is `accepted` by `validatePlayerOrdersWithContext` for player P and a candidate move `c`, when the system evaluates `c` via the incremental primitive and via `OrderEngine(initialOrders: basePrefix).addMoveOrderWithContext(...)`, then both return the same boolean accept/reject decision for `c`.
- Given a `basePrefix` whose every order is `accepted` for player P and a candidate army move `c`, when the system evaluates `c` via the incremental primitive and via the existing army-move acceptance probe, then both return the same boolean accept/reject decision for `c`.
- Given a `basePrefix` whose every order is `accepted` for player P and a candidate naval move `c`, when the system evaluates `c` via the incremental primitive and via `OrderEngine(initialOrders: basePrefix).addNavalMoveOrderWithContext(...)`, then both return the same boolean accept/reject decision for `c`.
- Given a `basePrefix` whose every order is `accepted` for player P and a candidate naval mission `c`, when the system evaluates `c` via the incremental primitive and via `OrderEngine(initialOrders: basePrefix).addNavalMissionOrderWithContext(...)`, then both return the same boolean accept/reject decision for `c`.
- Given a `basePrefix` whose every order is `accepted` for player P and a candidate `RecruitWorkerOrder` `c`, when the system evaluates `c` via the incremental primitive (`isRecruitWorkerAccepted` / `isRecruitWorkerOrderAcceptedWithValidator`) and via `OrderEngine(initialOrders: basePrefix).addRecruitWorkerOrderWithContext(...)`, then both return the same boolean accept/reject decision for `c`.

---

## Rules

- **Work suggestion pipeline (`WorkSuggestionPipeline`):** Civilian work suggestion for Explorer, Worker, Spy, and Merchant unit types uses the shared `WorkSuggestionPipeline.run()` loop in `colonizethis_logic` (`work_suggestion_pipeline.dart`). Each per-type module supplies a `candidatesProvider` callback (province sweep, tile list, or target-specific enumeration) and reuses the same incremental validation and probe-budget wiring. Explorer province sweeps and bundled-move-leg checks share helpers with movement-phase implicit civilian relocation so suggestion and resolution stay aligned. Refs #2560.

- **Province / tile identity:** Province ids and tile keys in suggested orders (destination province, targetTileKey, spawn province, fleet/sea zone ids) use the **prefixed** form and resolution rules per [world-model-identity.md](../game/world-model-identity.md) (same as [orders.md](orders.md)).
- **Work orders (`suggestWorkOrders`):** For civilian **workers** (Builder, Engineer, Rail Builder), candidate work targets use the same tile scope as validation: any **player-controlled** tile (owned province or `purchasedTilesByTileKey`) that passes visibility and the order engine, not only tiles in the unit’s current province (see [civilian-units.md](../game/civilian-units.md): civilians may act on a tile other than their current tile). **Explorers:** `explore` and `prospect` candidates consider **all relevant provinces** (sorted), not only the unit’s current province. The API returns **every** engine-valid `explore` row (one accepted row per qualifying province, in sorted province order, without stopping after the first) and **every** engine-valid `prospect` row (each accepted mineral-eligible tile in each visible province; provinces sorted, tiles sorted within province). Full AI consumes this full per-unit set for Explorer explore/prospect scoring and selection (Refs #2082). Explorer explore-row `E_score` uses `E_unknown = min(24, 3×U)` where `U` is the count of land tiles in that row’s target province that are `unknown` in `PlayerView`. For `explore`, relevance is constrained by per-player **partially revealed province semantics**: provinces where the player has at least one tile at `fogged`/`fullyVisible` and at least one tile at `unknown`. Logic computes this scope from authoritative game state + `PlayerView`; app integration may maintain an app-owned per-player selection cache that stays semantics-aligned with this definition. Eligibility uses **bundle-aware** checks where a leg may be required: province visibility gates, **authoritative province land tiles** from `WorldState.tileKeysByRegionAndProvince` (same class of data as `tilesInProvince` in the implementation), plus **`PlayerView.visibilityForTile`** for “still useful” / residual exploration value — do **not** exclude `explore` solely from “stored visibility keys only” when inland tiles lack keys but exploration remains useful per authoritative tiles. When a bundle leg is required, the implicit bundled **move** destination within the destination province prefers the order `targetTileKey` when that tile is **MoveValidator**-legal; otherwise it falls back to the first **MoveValidator**-legal land tile in deterministic sorted province tile order (bounded scan). The same preference+fallback rule applies in movement-phase implicit relocation so suggestion validation and execution stay aligned (Refs #1916, #1964). When a bundle leg is required, Explorer candidates may include cross-region non-owned destinations only when the destination is **not Great Power-owned** (Minor / Tribe / unowned) and move visibility / diplomatic-war gates pass; GP-owned destinations still follow GP entry constraints. **Spies** and **Merchants** keep their existing rules-specific enumeration. **Performance:** `suggestWorkOrders` may cache, per invocation, the pre-filtered + visibility-sorted tile list keyed by `workTarget` so each distinct work target is computed once per call; per-unit acceptance still runs the order engine over that list until the first valid tile is found. Summary **debug** lines (no per-tile spam): see § Suggestion observability.
- **Work order tile selection (`getValidWorkOrderTileKeysWithVisibility`):** For UI tile selection, apply the work-target-specific pre-filter table (e.g. `build_improvement`: owned or purchased tiles with a resource; prospect-required minerals must also pass order-engine validation including prospection (unprospected mineral tiles are excluded); `prospect`: land tiles that are mineral-eligible and not yet prospected — then visibility and order engine). Not every work target is limited to owned/purchased tiles.
- **Visibility:** Uses PlayerView only; may not inspect hidden tiles or enemy units directly. Checks per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). Undiscovered factions are **never** valid diplomatic targets for order suggestions.
- **Determinism:** Fixed inputs produce the same set and ordering of suggestions.
- **Build orders:** `suggestBuildOrders` returns affordable, valid build-unit orders for both **military (regiment)** and **naval (ship)** unit types. Each candidate is validated (treasury, stockpile, tech, capital) via the order engine. For build affordability, validation adds [pending riches treasury](turn-resolution-phases.md) (`pendingRichesTreasuryDelta` on the current stockpile) to treasury because `TurnPhase.richesToTreasury` runs before `TurnPhase.buildWork` in the same turn. Ordering is deterministic (e.g. by unit type id).
- **Recruit worker orders (`suggestRecruitWorkerOrders`):** Returns affordable, valid `RecruitWorkerOrder` candidates for `view.playerId` against the prefix in `currentOrders`, one candidate probed per [`WorkerTier`](../game/workers-and-population.md) value (`peasant`, `apprentice`, `journeyman`, `master`). Each candidate is validated via the same `RecruitWorkerOrderValidator` chain the order engine uses in the recruit worker sub-phase: the player's `WorkerPool` / `Stockpile` / `treasury` snapshot is replayed through every accepted recruit worker order in `currentOrders` (peasant reservation ledger per [workers-and-population.md](../game/workers-and-population.md) § Peasant reservation), then the candidate is validated against the post-prefix snapshot. Tech gates, treasury, paper / fabric stockpile, and consumed-peasant headcount are checked per [workers-and-population.md](../game/workers-and-population.md) § Recruiting, Training, and Disbanding. **Disband** is **not** a queued order ([workers-and-population.md](../game/workers-and-population.md) § Disband) and is therefore not enumerated here. Ordering is deterministic by `WorkerTier.index` (`peasant`, `apprentice`, `journeyman`, `master`).
- **Naval mission orders (`suggestNavalMissionOrders`):** For each eligible fleet, the system tries each value of `FleetMission` (serialized as `FleetMission.name` on `NavalMissionOrder.mission`) and keeps candidates accepted by the order engine. Adding or renaming enum values in [ships-and-naval.md](../game/ships-and-naval.md) therefore updates suggestion enumeration without a separate hardcoded mission list.
- **Diplomatic orders (`suggestDiplomaticOrders`):** Suggests valid diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, Grant Aid, Set Subsidy) targeting factions the player knows about. Each candidate is validated with the order engine (`addDiplomaticOrderWithContext`), same as other suggestion families. Optional `tileMapByRegion` matches `suggestWorkOrders` for API symmetry. Visibility rules per [regional discovery model](../game/diplomacy.md):
  - **GP↔GP:** Always visible (global knowledge of major powers).
  - **GP↔Minor:** Always visible (same region/Old World).
  - **GP↔Tribe:** If discovered (diplomatic relation exists or province tile visibility), **or** the tribe owns a New World province sea-reachable from the GP’s owned provinces/units (colonial intel; Refs #2509). Explorer `explore` province sweeps prioritize sea-reachable NW provinces (colonial intel) before other partially revealed provinces once naval coastal reveal makes them explorable.
- **Primary vs economic suggestions per target:** For each known target **T**, candidates follow `_diplomaticCandidatesForTargetOrdered` (`offerPeace`, `alliance`, `establishOverture`, `grantAid`, `setSubsidy`, `declareWar`). The implementation uses **two passes**: (1) consider **only** non-economic types in that order; append the **first** that passes the order engine against a **trial** list (see below) and **stop** the primary pass. (2) Consider **only** `grantAid` and `setSubsidy` in candidate order; append each that passes against the trial list after step (1), updating the trial after each acceptance. **Grant before subsidy** when both are valid: `grantAid` precedes `setSubsidy` in the template. Multiple entries toward the same **T** in **L** are only as allowed by [orders.md](orders.md) (e.g. one `grantAid` + one `setSubsidy` when no non-economic suggestion was accepted for **T**).
- **Declare-war-only suggestions (`suggestDeclareWarOrders`):** Full AI’s `declareWarOnly` diplomacy pass uses this API so valid `declareWar` candidates are not suppressed when `establishOverture` would win the primary pass for the same target. Returns only `declareWar` toward known at-peace factions that pass the order engine. Human/UI suggestion panels continue to use `suggestDiplomaticOrders` only.
- **Working list:** Initialize **workingOrders** from `currentOrders`. For each **T**, set **trialOrders** = **workingOrders**; run the two passes; then assign **workingOrders** = **trialOrders** so treasury and caps reflect suggestions accepted earlier in the same invocation. Pending orders in `currentOrders` constrain what can be suggested; removing a pending order restores eligibility per engine validation.
- **Throughput (Refs #2394):** For each target **T**, the system binds one `IncrementalCandidateValidator` per fixed **trialOrders** prefix for the non-economic pass and rebinds via `forBasePrefix` when the primary pass updates **trialOrders** before the economic pass; when the primary pass accepts nothing, economic probes reuse the same instance. Across targets, the pass reuses the same view/units/membership snapshot and only rebinds `basePrefix` to the accumulated **workingOrders**. Observable suggestions and acceptance decisions remain identical to per-candidate `isDiplomaticOrderAccepted` probes against the same prefix.

**Acceptance criteria (diplomatic suggestions)**

- Given fixed `Game`, `MapTopology`, `PlayerView`, and `Orders` for player P, when `suggestDiplomaticOrders` returns a list L, then when the system appends every order in L to P’s diplomatic slot **in list order** onto a copy of those `Orders` and runs `validatePlayerOrdersWithContext` for P on the combined list, every validation result is **accepted**.
- Given `currentOrders` already includes a non-economic diplomatic order from P to target T, when `suggestDiplomaticOrders` runs with those `currentOrders`, then L contains **no** order with `targetFactionId == T`.
- Given `currentOrders` includes only a valid pending `grantAid` from P to T, when `suggestDiplomaticOrders` runs, then L **may** include a `setSubsidy` toward T if the engine accepts it when merged with `currentOrders`.
- Given `currentOrders` includes no diplomatic order to T, when a prior call returned suggestions toward T and the player removed all diplomatic orders to T from the draft, when `suggestDiplomaticOrders` runs again with the updated `currentOrders`, then the system **may** again include valid suggestions toward T subject to game rules and engine validation.

**Acceptance criteria (recruit worker suggestions)**

- Given fixed `Game`, `MapTopology`, `PlayerView`, and `Orders` for a Great Power player P with `pool.peasants ≥ 1`, treasury / paper covering the apprentice cost row, and `apprentice_workers + sugar_refining` in `techUnlocked`, when `suggestRecruitWorkerOrders` runs, then the returned list contains a `RecruitWorkerOrder(targetTier: apprentice)` and the candidate is `accepted` by `OrderEngine(initialOrders: currentOrders).addRecruitWorkerOrderWithContext(...)` for that candidate.
- Given a Great Power player P whose `techUnlocked` does not contain the target tier's required techs, when `suggestRecruitWorkerOrders` runs for `currentOrders` with no recruit worker prefix, then the returned list contains **no** `RecruitWorkerOrder` with that `targetTier`.
- Given a Great Power player P whose stockpile or treasury cannot pay the cost row for a target tier (e.g. `fabric < 2` for `peasant`, or `treasury < 200` for `apprentice`), when `suggestRecruitWorkerOrders` runs for `currentOrders` with no recruit worker prefix, then the returned list contains **no** `RecruitWorkerOrder` with that `targetTier`.
- Given a Great Power player P with `pool.peasants == N` and `currentOrders.recruitWorkerOrdersByPlayerId[P]` containing exactly `N` accepted apprentice / journeyman / master recruits (each consuming a peasant per [workers-and-population.md](../game/workers-and-population.md) § Recruit), when `suggestRecruitWorkerOrders` runs, then the returned list contains **no** `RecruitWorkerOrder` whose row sets `consumesPeasant == true` (peasant reservation ledger drained), and may still contain `RecruitWorkerOrder(targetTier: peasant)` when fabric is available.
- Given any fixed `(Game, MapTopology, PlayerView, currentOrders)` tuple for player P, when `suggestRecruitWorkerOrders` returns a list L, then for each `c ∈ L` the result of `OrderEngine(initialOrders: currentOrders).addRecruitWorkerOrderWithContext(game, topology, P, c)` is `accepted`, and L is sorted ascending by `c.targetTier.index`.

---

## Consumers

- Minimal AIPlanner (see [ai-planner.md](ai-planner.md)) — passes `tileMapByRegion` when the caller provides it.
- Sim-game default AI (see [sim-game-default-ai.md](sim-game-default-ai.md)) — sim controller passes the same maps used for order validation.
- Full AI (see [ai-systems-impl.md](ai-systems-impl.md)) — domain planners pass `tileMapByRegion` through to `suggestWorkOrders` when provided. The naval domain planner may build one `unitsById` snapshot per stable `Game` and pass it to both `suggestNavalMoveOrders` and `suggestNavalMissionOrders` in the same planner invocation (Refs #2394).
- **Flutter app (`colonizethis_app`):** Riverpod providers (e.g. `availableWorkTargetIdsForUnitProvider`, optional `devExclusiveReservedWorkTileKeysProvider`) **delegate** to `colonizethis_logic` only (`getAvailableWorkTargetsForUnit` per known `unitId`). They **must not** reimplement Builder/Engineer/Merchant per-tile exclusivity or reservation rules. Reservations combine in-map `currentWork` and pending dev-exclusive work orders per [orders.md](orders.md) § WorkOrder per-tile exclusivity. **Do not** call broad `suggestWorkOrders` from panel-open or per-row Assign availability hot paths (Refs #2133).
- **Per-player work-target selection cache (`explore`, `steal_tech`, `counter_spy`, `purchase_land`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail`):** Tile-set materialization uses **`PerPlayerWorkTargetSelectionCache`** / **`WorkTargetSelectionSnapshot`** in **`colonizethis_logic`** (`src/orders/per_player_work_target_selection_cache.dart`) so the Flutter shell and **worker isolates** share identical population rules (Refs **#2277**). **Lifecycle:** each caller **constructs** its own cache instance and calls **`refresh`** at load / turn-resolution boundaries; logic exposes **no** global singleton for this map. Rules and validation remain in **`getValidWorkOrderTileKeysWithVisibility`** and the order engine.
- **Cache-first selection (app shell):** For `explore`, `steal_tech`, `counter_spy`, `purchase_land`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, and `build_rail`, the app shell reads the cached tile set when entering work-target selection mode (no live recomputation fallback in that interaction). Cache population eligibility is per-target and per-unit: `explore`, `steal_tech`, `counter_spy`, and `purchase_land` union `getValidWorkOrderTileKeysWithVisibility` across all human civilian units that support the target (same merged pattern as `explore`). Other cache-first targets include tiles from units that support the target and are `idle` with no `currentWork` and no pending work order for that unit in current draft orders.
- **Runtime stale-tile filter for cache-first protected targets (app shell):** Before rendering cached selections for `explore`, `steal_tech`, `counter_spy`, `purchase_land`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, and `build_rail`, the app shell applies a post-cache conflict filter (set subtraction on cached tile keys) using current draft orders and in-progress work so stale conflicting cached tiles are not selectable; this filter does not trigger live recomputation.

### Province Tile `Build improvement` shortcut enablement (pipeline contract A)

- **Authoritative pipeline (branch A):** The province overlay’s **`Build improvement`** row uses **`GameMapAreaStateLogic.provinceBuildImprovementActionState`**. Its **`enabled`** flag is **true** iff the human player has at least one idle Builder (no `currentWork`, type allows `build_improvement`) **and** the selected tile key appears in **`getValidWorkOrderTileKeysWithVisibility`** for **at least one** such Builder, with the **same** arguments as the civilian work-target picker: `game`, `topology` (combined map topology from map data), `PlayerView`, `unitId`, `workTarget: build_improvement`, `currentOrders`, and optional `tileMapByRegion` from loaded map data. **`showIcon`** remains improvability-only (resource + improvement level vs tech cap); it does **not** call this pipeline. Accepted consequence: an unprospected mineral tile can be shown as visible-but-disabled for this shortcut until prospection makes it assignable.
- **Relationship to `availableWorkTargetIdsForUnitProvider`:** That provider reads **`getAvailableWorkTargetsForUnit`** (selected-unit availability). Shortcut **enablement** does **not** reimplement exclusivity rules; it aligns with **per-unit** valid tile keys from **`getValidWorkOrderTileKeysWithVisibility`**, the same entrypoint used when the shell enters tile-target selection after choosing an order. Full rule coverage stays in **`colonizethis_logic`** tests (e.g. `order_engine_validate_work_build_improvement_test.dart`, `work_order_target_prechecks_test.dart`, `order_suggestion_valid_work_tiles_test.dart`).
- **CI / app tests:** App-level tests assert wiring, visibility vs enablement split, drift no-op, and **contract (A)** equivalence between **`provinceBuildImprovementActionState(...).enabled`** and the pipeline above; they do not duplicate every `WorkOrderValidator` branch. Golden snapshots (wide side panel host vs narrow bottom-sheet host) assert consistent rendering of the shortcut control in each layout shell.

### Dev-exclusive tile reservations (logic package)

- **Given** a `Game`, current-turn `Orders`, and a Great Power `playerId`, **the system** builds the set of `targetTileKey` values reserved for that player: tiles with in-progress dev work (Builder/Engineer/Merchant `currentWork`) plus `targetTileKey` of each pending work order whose target is dev-exclusive (`build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `purchase_land`).
- **When** `suggestWorkOrders` evaluates a dev-exclusive target for a unit, **the system** skips candidate tiles in that reserved set (full set, including other units’ pending orders) before order-engine validation.
- **When** `getValidWorkOrderTileKeys` / `getValidWorkOrderTileKeysWithVisibility` lists tiles for **one** unit’s tile picker, **the system** may omit that unit’s **own** pending orders from the reserved set so tiles already selected in the draft order list remain visible for that unit only; other units still treat those tiles as reserved.
- **Then** a second Builder of the same player does not receive an available `build_improvement` suggestion on a tile already targeted by the first Builder’s pending order until that order is removed.

---

## Integration

Lives in colonizethis_logic alongside the order engine. AI and tooling consume it to generate orders.

---

## Helper: Valid Work Order Tile Keys

### `getValidWorkOrderTileKeysWithVisibility`

**Purpose:** Returns the set of tile keys that are valid targets for a work order, filtering by visibility **before** calling the order engine for efficiency.

**Signature:**
```dart
Set<String> getValidWorkOrderTileKeysWithVisibility({
  required Game game,
  required MapTopology topology,
  required PlayerView view,
  required String unitId,
  required String workTarget,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
  Map<String, Unit>? unitsById,
  Set<String>? playerOwnedProvinceIds,
});
```

Optional `sharedCandidateValidator` is an **internal throughput hook** (Refs #2394): when callers enumerate many `(unitId, workTarget)` pairs against the same `game`, `view.playerId`, `currentOrders`, and `tileMapByRegion`, they may supply one validator instance built via `buildIncrementalCandidateValidator` to amortize `PlayerView` construction and shared caches. It must be built with the **same** arguments as the surrounding call; behavior is undefined if it is not. When omitted, the function constructs its own validator (default path). **Observable tile sets and acceptance decisions** must match the default path for the same inputs.

When `tileMapByRegion` is non-null (app shell, turn resolution), prospect pre-filtering and `prospect` work-order validation use the same `isMineralEligibleTile` rules as work application: prospectable terrain from tile maps combined with `resourceByTileKey` so a known non-mineral (e.g. wool on hills) is never mineral-eligible. When `tileMapByRegion` is null, eligibility uses `resourceByTileKey` and mineral ids only (no terrain-from-map branch).

**Pre-filtering by work target type:**

Before iterating candidate tiles, apply work-target-specific filters to dramatically reduce the tile set and avoid expensive order-engine validation for tiles that can never be valid:

| Work target | Province scope | Tile requirements |
|-------------|----------------|-------------------|
| `explore` | Per-player partially revealed province semantics (shell may use `PerPlayerWorkTargetSelectionCache`) | Any tile in the province (province-level work) |
| `prospect` | Land provinces (prefixed province id) | Tile must be mineral-eligible per `isMineralEligibleTile` (prospectable terrain when resolvable from tile maps; known non-mineral resources excluded); tile must **not** already appear in `WorldState.playerProspectedTiles[playerId]` |
| `build_improvement` | Owned or purchased tiles | Tile must have a resource (`resourceByTileKey` non-empty); tile controlled by player |
| `upgrade_town` | Owned provinces only | Province's town tile only |
| `build_road` | Owned or purchased tiles | Any tile controlled by player |
| `build_port` | Owned provinces only | Coastal or river tiles (adjacent to sea zone or river) |
| `build_fort` | Owned provinces only | Province's town tile only |
| `build_rail` | Owned or purchased tiles | Transport level 1 or 2; per-tile terrain resolvable from tile map; player's unlocked tech must allow rail on that terrain per [tech-tree-transport.md](../game/tech-tree-transport.md); tile controlled by player |
| `steal_tech` | Other GP capital provinces | Province must be another Great Power's capital |
| `counter_spy` | Owned provinces only | Any tile in owned province |
| `purchase_land` | Minor/Tribe provinces | Tile must have resource; tile not already purchased; player has embassy and is not at war |

**Tile control definition:** A tile is "controlled by player" when either:
- The tile's province is owned by the player, OR
- The tile appears in `WorldState.purchasedTilesByTileKey` with buyer = player (Merchant purchase)

**Behavior:**
1. Apply work-target-specific pre-filters (province scope, tile requirements) to generate a candidate tile set.
2. Further filter candidate tiles to only those with `VisibilityLevel.fullyVisible` or `VisibilityLevel.fogged` from the given `PlayerView`.
3. For remaining candidate tiles, validate via the order engine (same as `getValidWorkOrderTileKeys`).
4. Returns only tiles that pass all three filters (pre-filter, visibility, validation).

For `explore`, step (1) must use the same per-player partially-revealed-province semantics as `suggestWorkOrders` so picker and suggestion flows remain aligned.

**Why separate from `getValidWorkOrderTileKeys`:**
- `getValidWorkOrderTileKeys` is agnostic to player view (used by AI that operates on full game state).
- The app needs visibility-aware filtering to avoid expensive order-engine calls for invisible tiles.
- Pre-filtering by work-target-specific criteria dramatically reduces the candidate set before order-engine validation.

**Consumers:**
- App UI (civilian units panel for work assignment).

**Acceptance criteria (prospect tile picker and validation)**

- Given a Great Power player and a `prospect` work order candidate tile, when that tile is not mineral-eligible per game rules, then the system rejects the work order with a reason indicating the tile is not mineral-eligible for prospecting.
- Given a Great Power player and a `prospect` work order candidate tile that is already in `playerProspectedTiles` for that player, when the order engine validates the order, then the system rejects the work order with a reason indicating the tile is already prospected.
- Given `getValidWorkOrderTileKeysWithVisibility` is called for an Explorer with work target `prospect` and a non-null `tileMapByRegion`, when the player’s `PlayerView` marks a tile at least fogged, the tile is mineral-eligible, and the tile is not in `playerProspectedTiles` for that player, then the returned set may include that tile (subject to remaining order-engine rules). When the tile is already prospected or not mineral-eligible, then the returned set does not include that tile.

**Notes:**
- When `view` is `null` or visibility data is unavailable, falls back to full map iteration (same as `getValidWorkOrderTileKeys`).
- Tile keys use the standard format: `{regionId}|{provinceId}|{x}|{y}`.

---

## Feedstock-extraction priority for `build_improvement` candidates (Refs #2847 H8-extraction)

The worker suggestion pipeline (`WorkSuggestionPipeline.run`, `includeAllAccepted: false`) emits **only the first accepted** `build_improvement` candidate per Builder per pass, and the visible candidate list is sorted **lexicographically** by tile key (`sortedVisibleWorkTargetCandidates`). The lone suggested tile is therefore whichever owned/purchased resource tile sorts first by key — independent of resource. The Full-AI feedstock-extraction score boost (`kRegimentBuildInputFeedstockExtractionScoreBoost`, `selectFullAiCivilianWorkOrders`) only **re-ranks suggestions that already exist**, so it cannot route a Builder onto a feedstock tile that was never suggested.

To make the boost effective, when a player's feedstock-extraction gate is active — `feedstockExtractionResourceIdsForPlayer(game, playerId)` non-empty, i.e. the seller-side `regimentBuildInputFeedstockExtractionResourceIds` **or** the supplier-side `supplierImprovementInputFeedstockExtractionResourceIds` gate fires (see [economy-planner.md](../ai/economy-planner.md) § H8-extraction) — the `build_improvement` candidate list is **stable-partitioned** so tiles hosting an **unimproved** feedstock resource (resource id in the gate set, `improvementLevel < 1`) sort ahead of all other candidates. The single emitted suggestion then targets a feedstock tile, which the downstream score boost selects ahead of competing work.

**Co-availability ordering within the feedstock partition (Refs #2847 H8-extraction feedstock co-availability).** A multi-input improvement recipe (`castIron_from_timber_iron_coal` consumes `timber` **and** `iron`) becomes feasible only once **every** feedstock is on hand, but the pipeline emits a single `build_improvement` suggestion per Builder per pass. With a purely lexicographic feedstock partition the lone suggestion always targets the same (lex-first) feedstock resource, so a Builder keeps extracting a feedstock it already holds while the missing co-feedstock is never suggested and the multi-input recipe stays infeasible (`feasibleRuns == 0`) indefinitely — observed on seed 42 as a supplier holding `timber` while `iron` stays `0`. The feedstock partition is therefore ordered by **ascending player-held quantity** of each tile's feedstock resource (lexicographic tile key as tie-break), so the least-held feedstock — the missing co-feedstock — is suggested first. This drives the stockpile toward the co-availability the production-layer reservation (see [economy-planner.md](../ai/economy-planner.md) § Improvement-input feedstock co-availability reservation) then protects. The non-feedstock partition keeps its lexicographic order.

This ordering change is **gated**: for every ordinary player the feedstock set is empty and the candidate order is unchanged, so human-shell and non-lock-recovery suggestions are unaffected. It adds **no** new work order, bypasses **no** suggestion, visibility, probe-budget, or order-engine acceptance gate (the reordered candidates still pass the same incremental validation), and introduces **no** `ai_victory_config.dart` constant. The reordering is a pure, deterministic function of `(game, playerId, candidate list)`; identical inputs yield identical ordering.

**Acceptance criteria (feedstock-extraction `build_improvement` priority)**

- Given a player whose feedstock-extraction gate is active for resource ids `{timber, iron}` and a lexicographically-sorted `build_improvement` candidate list containing an unimproved `grain` tile sorted before an unimproved `iron` tile, when the system orders the candidates, then the `iron` tile sorts before the `grain` tile.
- Given the same player and candidate list, when the system orders the candidates, then every unimproved feedstock tile precedes every non-feedstock tile, and the relative lexicographic order within the non-feedstock group is preserved.
- Given a player whose feedstock-extraction gate is active for resource ids `{timber, iron}`, who holds `13` units of `timber` and `0` units of `iron`, and a `build_improvement` candidate list with an unimproved `timber` tile sorted (lexicographically) before an unimproved `iron` tile, when the system orders the candidates, then the unimproved `iron` tile (the least-held feedstock) sorts before the unimproved `timber` tile.
- Given a player whose feedstock-extraction gate is active for resource ids `{timber, iron}` and who holds an equal quantity of `timber` and `iron` (for example `0` of each), when the system orders two unimproved feedstock tiles hosting those resources, then the two tiles retain their relative lexicographic order (tie-break).
- Given a player whose feedstock-extraction gate is **inactive** (`feedstockExtractionResourceIdsForPlayer` empty), when the system orders the `build_improvement` candidates, then the list is returned unchanged in its lexicographic order (negative control).
- Given a player whose feedstock-extraction gate is active but whose only feedstock-resource tile is **already improved** (`improvementLevel >= 1`), when the system orders the `build_improvement` candidates, then that improved tile is not promoted and the list is returned unchanged (negative control — only unimproved feedstock tiles are prioritized).
- Given identical `(game, playerId, candidate list)` inputs, when the system orders the `build_improvement` candidates twice, then both orderings are identical (determinism).

---

## Mineral feedstock prospecting priority (Refs #2847 H8-extraction mineral feedstock prospecting)

`build_improvement` on a **mineral** resource tile (resource id in `kMineralResourceIds`, e.g. `iron`, `coal`) is rejected by `precheckBuildImprovement` (`work_order_target_prechecks.dart`) with `Mineral tile must be prospected first` until the tile is in the player's `playerProspectedTiles` set. Prospecting is an **Explorer** target (`prospect`), while `build_improvement` is a **Builder** target (`workOrderTargetsByUnitType`). The Builder feedstock-extraction boost (§ economy-planner.md H8-extraction) therefore cannot extract a mineral feedstock until a separate Explorer prospects it. On seed 42 this is the binding `castIron` co-availability blocker: a supplier freely improves its **surface** `timber` tile (no prospecting needed) but never prospects its `iron` mineral tile, so `iron` stays `0`, the `castIron_from_timber_iron_coal` recipe never becomes feasible, and the conquest economy never recovers.

To close this, `selectFullAiCivilianWorkOrders` (`packages/colonizethis_logic/lib/src/ai/full_ai_civilian_work_selection.dart`) adds a planner-internal `prospect` score boost (`kFeedstockMineralProspectScoreBoost`, sized to match the Builder feedstock boost) to a `prospect` work order whose target tile hosts an **unprospected** mineral feedstock resource — the tile resource id is in the player's active `feedstockExtractionResourceIdsForPlayer` set, is in `kMineralResourceIds`, and is absent from `playerProspectedTiles[playerId]`. An idle Explorer then prospects the feedstock mineral tile ahead of ordinary `explore` / `prospect` work, so the Builder feedstock-extraction boost has a valid (prospected) tile to improve next.

The boost is **gated** by the same self-clearing feedstock set: for every ordinary player the set is empty and Explorer scoring is unchanged; once the tile is prospected (or the gate clears), no boost applies. It adds **no** new work order, bypasses **no** suggestion, visibility, or order-engine gate, and introduces **no** `ai_victory_config.dart` constant. The boost is a pure, deterministic function of `(game, playerId, work order)`.

**Acceptance criteria (mineral feedstock prospecting priority)**

- Given a player whose feedstock-extraction gate is active for resource ids `{timber, iron}`, who has **not** prospected an owned `iron` mineral tile, and whose idle Explorer has both an `explore` work order and a `prospect` work order on that `iron` tile, when `selectFullAiCivilianWorkOrders` runs, then the selected work order is the `prospect` order on the `iron` tile.
- Given the same fixture except the `iron` tile is **already prospected** (`playerProspectedTiles[playerId]` contains it), when `selectFullAiCivilianWorkOrders` runs, then no prospect boost applies and the Explorer is assigned the `explore` work order (negative control).
- Given the same fixture except the feedstock-extraction gate is **inactive** (`feedstockExtractionResourceIdsForPlayer` empty, e.g. the peer seller is at quota), when `selectFullAiCivilianWorkOrders` runs, then no prospect boost applies and the Explorer is assigned the `explore` work order (negative control).
- Given identical inputs with the gate active and the `iron` tile unprospected, when `selectFullAiCivilianWorkOrders` runs twice, then both runs select the same `prospect` order on the `iron` tile (determinism).

---

## Old World feedstock unit reservation (Refs #2847 H8-extraction)

The co-availability ordering and mineral-prospecting boosts above can only re-rank suggestions that **exist** for a unit, and the feedstock `build_improvement` / `prospect` boosts can only select a unit that is **available** (idle, in the Old World where the feedstock tile is). On seed 42 the affluent supplier owns an unimproved Old World `iron` / `timber` feedstock tile on every gate-active turn, but each idle Builder and Explorer scores higher on **New World** owned-resource colonial work (the New World bonuses in `_buildImprovementWorkScore` / `_eScore`) and migrates there, so no unit is ever positioned to prospect or improve the Old World feedstock tile (`gpFeedstockGateIdleBuilderPresentTurns == 0` for the suppliers).

To close this, `selectFullAiCivilianWorkOrders` (`packages/colonizethis_logic/lib/src/ai/full_ai_civilian_work_selection.dart`) reserves, per active player, **at most one** idle Builder and **at most one** idle Explorer for Old World feedstock work when the player's `feedstockExtractionResourceIdsForPlayer` gate is active:

- The reserved Builder is the lexicographically-smallest idle (`currentWork == null`) Builder, reserved **only** when the player owns an **unimproved Old World** tile hosting a gate feedstock resource.
- The reserved Explorer is the lexicographically-smallest idle Explorer, reserved **only** when the player owns an **unprospected Old World mineral** tile hosting a gate feedstock resource.
- For a reserved unit, every work order whose `targetTileKey` is in the New World region (`Unit.regionIdFromTileKey == kNewWorldRegionId`) is dropped from its candidate list before scoring. The unit therefore keeps only its Old World candidates (and is selected onto the feedstock tile by the existing boosts), or — when it has no Old World candidate this turn — stays idle in the Old World rather than migrating to the New World.

The reservation is **gated** by the same self-clearing feedstock set: for every ordinary player it is empty and selection is unchanged; it self-clears once the feedstock tiles are improved/prospected or the gate clears. It only ever holds back **one** Builder and **one** Explorer, leaving every other idle unit free for New World work, so it does not regress New World colonial throughput beyond a single reserved unit of each type. It adds **no** new work order, bypasses **no** suggestion/visibility/order-engine gate, and introduces **no** `ai_victory_config.dart` constant. It is a pure, deterministic function of `(game, view.ownUnits, feedstock set)`.

**Acceptance criteria (Old World feedstock unit reservation)**

- Given a player whose feedstock-extraction gate is active for `{timber, iron}`, who owns an unimproved Old World `iron` tile, and whose lone idle Builder has both a New World `build_improvement` order and an Old World `iron` `build_improvement` order, when `selectFullAiCivilianWorkOrders` runs, then the Builder is assigned the Old World `iron` order.
- Given the same gate and two idle Builders each with only a New World `build_improvement` order, when `selectFullAiCivilianWorkOrders` runs, then the lexicographically-smallest Builder is left idle (no work order; `no_suggestions` idle event) and the other Builder keeps its New World order.
- Given the same gate, an owned unprospected Old World `iron` mineral tile, and a lone idle Explorer with both a New World `explore` order and an Old World `iron` `prospect` order, when `selectFullAiCivilianWorkOrders` runs, then the Explorer is assigned the Old World `iron` `prospect` order.
- Given the same gate and two idle Explorers each with only a New World `explore` order, when `selectFullAiCivilianWorkOrders` runs, then the lexicographically-smallest Explorer is left idle and the other Explorer keeps its New World order.
- Given the feedstock-extraction gate is **inactive** (peer seller at quota), a Builder with only a New World `build_improvement` order, when `selectFullAiCivilianWorkOrders` runs, then no reservation applies and the Builder is assigned the New World order (negative control).
- Given the gate active but the supplier's Old World feedstock tiles are all already improved, a Builder with only a New World `build_improvement` order, when `selectFullAiCivilianWorkOrders` runs, then no reservation applies and the Builder is assigned the New World order (negative control).
- Given identical inputs with the gate active, when `selectFullAiCivilianWorkOrders` runs twice, then both runs produce the same work-order list (determinism).

---

## Old World mineral feedstock prospect localization (Refs #2847 H8-extraction)

After the Old World feedstock unit reservation lands, the seed-42 supplier (`gp1` / `gp2`) still never holds `iron` (`gpCastIronFeedstockHeldAtTurn99` `iron == 0`) while surface `timber` is extracted, so domestic `castIron` over-production stays infeasible. A mineral `build_improvement` is rejected until the tile is prospected (see § Mineral feedstock prospecting priority and `work_order_target_prechecks.dart`), so the residual is one of two stages: the reserved Explorer never **prospects** the `iron` tile, or the tile is prospected but the Builder never **improves** it. Two read-only predicates split these:

- `hasIdleExplorerUnit(game, playerId)` — true iff the player owns an idle Explorer (`currentWork == null`), i.e. a unit the reservation could route onto the `iron` prospect this turn. A near-zero gate-active count localizes the break to **Explorer availability**.
- `ownsProspectedOldWorldMineralFeedstockTile(game, playerId, feedstockIds)` — true iff the player owns an **Old World** mineral feedstock tile (resource id in `feedstockIds` ∩ `kMineralResourceIds`) that is in `playerProspectedTiles[playerId]`. A non-zero count with `iron` still held `0` localizes the break **downstream** of prospecting; a flat zero confirms the prospect itself never happens.
- `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, feedstockIds)` — true iff the player owns an idle Explorer (`currentWork == null`) whose `locationProvinceId` equals the province of one of the player's owned **unprospected** Old World mineral feedstock tiles. `prospect` candidate generation in `order_suggestion_work_explorer.dart` only reaches an Explorer positioned on (or single-hop from) the feedstock province, and the Old World feedstock reservation in `full_ai_civilian_work_selection.dart` reserves the lexicographically-smallest idle Explorer **without repositioning it**. A flat zero alongside `hasIdleExplorerUnit > 0` therefore localizes the residual to reservation **positioning** (no idle Explorer ever reaches the feedstock province, so no `prospect` candidate generates); a non-zero count instead points at candidate-generation eligibility (mineral-tile gate / validator) or selection ranking for an already-positioned Explorer.

All three are pure, read-only, gate-independent functions (the caller supplies the feedstock set / observes the gate). The seed-42 S7-D diagnostic capture (`gpSupplierIdleExplorerPresentTurns` = 51/51 for gp1/gp2; `gpSupplierProspectedMineralFeedstockTileTurns` = 0/0) **refutes** the Explorer-availability and prospect-done hypotheses and pins the residual to **prospect-candidate generation/selection** for the reserved idle Explorer. `gpSupplierIdleExplorerColocatedFeedstockTileTurns` decides the remaining fork: a flat zero would confirm the reserved Explorer is never positioned on the feedstock province (fix: reposition an Explorer onto, or single-hop toward, the unprospected Old World feedstock province), while a non-zero count instead directs the next slice at the candidate-generation gate (mineral-tile eligibility / validator) or selection ranking.

**Decisive capture (seed 42, turn 100, `--run-skipped`).** `gpSupplierIdleExplorerColocatedFeedstockTileTurns` = **51 / 51** for both `gp1` and `gp2` — an idle Explorer is co-located with the owned, unprospected Old World `iron` mineral province on **every** gate-active turn — yet `gpSupplierProspectedMineralFeedstockTileTurns` stays `0 / 0` and `gpCastIronFeedstockHeldAtTurn99` `iron` stays `0`. This **refutes the reservation-positioning hypothesis**: positioning is not the constraint. The residual is therefore pinned to **`prospect`-candidate generation/selection for the already-co-located Explorer** — the next slice must inspect, for the supplier's owned unprospected Old World `iron` tile, the `prospect` gates in `order_suggestion_work_explorer.dart` (`_addProspectSuggestionIfEligible` → `_allAcceptedProspectTilesInProvince`): province visibility (`provinceHasAtLeastVisibility(..., fogged)`), mineral eligibility (`isMineralEligibleTile`), and the incremental-validator acceptance, plus whether the co-located Explorer's `prospect` row survives selection ranking against its competing `explore` rows.

**Acceptance criteria (Old World mineral feedstock prospect localization)**

- Given a player who owns an Old World `iron` mineral tile that is in `playerProspectedTiles` for that player, when `ownsProspectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `true`.
- Given a player who owns an Old World `iron` mineral tile that is **not** in `playerProspectedTiles`, when `ownsProspectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false` (negative control).
- Given a player who owns a prospected Old World `timber` (non-mineral) tile, when `ownsProspectedOldWorldMineralFeedstockTile(game, playerId, {timber})` is evaluated, then the result is `false` (only mineral feedstock tiles count).
- Given a player who owns a prospected **New World** `iron` mineral tile, when `ownsProspectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false` (Old World only).
- Given a player who owns an idle Explorer (`currentWork == null`), when `hasIdleExplorerUnit(game, playerId)` is evaluated, then the result is `true`.
- Given a player whose only Explorer has `currentWork != null`, when `hasIdleExplorerUnit(game, playerId)` is evaluated, then the result is `false`.
- Given a player who owns no Explorer unit (only a Builder), when `hasIdleExplorerUnit(game, playerId)` is evaluated, then the result is `false` (negative control).
- Given a player who owns an idle Explorer whose `locationProvinceId` equals the province of the player's owned unprospected Old World `iron` mineral tile, when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `true`.
- Given a player who owns an idle Explorer in a different province from the unprospected Old World `iron` mineral tile, when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false`.
- Given a player whose co-located Explorer has `currentWork != null`, when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false`.
- Given a player who owns an idle Explorer co-located with an Old World `iron` mineral tile that is already in `playerProspectedTiles`, when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false` (no unprospected feedstock province remains).
- Given a player who owns an idle Explorer and a co-located **New World** `iron` mineral tile (no Old World feedstock tile), when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false` (Old World only).
- Given a player who owns only a co-located idle Builder (no Explorer) and an unprospected Old World `iron` mineral tile, when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {iron})` is evaluated, then the result is `false` (Explorers only).
- Given any player and an empty `feedstockIds` set, when `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(game, playerId, {})` is evaluated, then the result is `false` (negative control).

---

## Feedstock bootstrap `castIron` waiver for level-0 `build_improvement` (Refs #2847 H8-extraction)

When the feedstock-extraction gate is active and a Builder targets an **unimproved** feedstock resource tile, the order engine and work application use the **effective** material cost from `WorkOrderCostCalculator` (player-scoped), which may omit **cast iron** for the level-0 improvement while the stockpile holds enough **lumber** but not enough **cast iron** (see [extraction-and-improvements.md](../game/extraction-and-improvements.md) § Improvement Build Costs (Builder) — H8 feedstock bootstrap). This makes feedstock-priority suggestions **affordable** on seed 42 where `gpFeedstockGateImprovementCostAffordableTurns` stayed zero solely because of the circular cast-iron dependency; it does not bypass visibility, probe budget, tech cap, or non-material validation gates.

**Acceptance criteria**

- Given the supplier-side feedstock gate active, stockpile `{lumber: 1, castIron: 0}`, and an unimproved `timber` tile as a visible `build_improvement` candidate, when `suggestWorkOrders` runs, then the emitted suggestion targets the `timber` tile (accepted under the waived cost).
- Given the gate inactive and the same stockpile, when `suggestWorkOrders` runs for a lex-first `grain` tile, then no `build_improvement` suggestion is emitted if the player cannot afford `{lumber: 1, castIron: 1}` (negative control).

---

## Selected-unit availability (`getAvailableWorkTargetsForUnit`)

**Purpose:** Human-shell **per-unit** work availability (which work targets have ≥1 valid tile) without broad per-player `suggestWorkOrders` enumeration. Return type `AvailableWorkTargetsForUnit` holds `assignable`, optional `blockedReason`, and `validTileKeysByTarget` (only targets with non-empty tile sets).

**Rules:** When the unit has **any** pending `WorkOrder` in `currentOrders` for `view.playerId`, or `unit.currentWork != null`, or the unit is absent from `view.ownUnits`, the API returns not assignable with a stable `blockedReason` token and **does not** run per-candidate tile probing / order-engine loops for availability. Optional `workTargetFilter` limits evaluation to one work target id.

**Acceptance criteria**

- Given a civilian unit with a pending draft `WorkOrder` for that `unitId` on the current turn, when `getAvailableWorkTargetsForUnit` or `getValidWorkOrderTileKeysWithVisibility` runs for that unit, then the system returns empty target/tile availability for new assignments for that call without order-engine candidate-tile probing attributable to that unit.
- Given Dart source under `app/lib`, when repository lint rule `repo.app_lib_no_broad_suggest_work_orders` runs, then no `.dart` file under `app/lib` contains a `suggestWorkOrders(` call site (Refs #2133; full enumeration remains available to AI, `integration_test`, and other non-`app/lib` tooling).

---

## Suggestion observability (debug)

When diagnosing why a civilian work target is missing from Assign / AI suggestions, `suggestWorkOrders` may emit **summary-only** `logger` **`debug`** lines (prefix `logic.order_suggestion`, token `suggest_work`): **per unit** (`unitId`, `unitType`, `region`, `at` province) and **per work target** one line with `outcome=` `included` or `excluded`, optional `tile=`, and for exclusions a **stable** `reason=` token (e.g. `visibility`, `no_valid_tile`, `no_single_hop`, `duplicate_pending`, `engine_rejected`, `not_applicable`). When more than one suggestion row is included in a single evaluation pass (e.g. Explorer `explore` across provinces or `prospect` across tiles), that line uses `includedCount=<n>` and `tile=-` instead of emitting one line per row. **No** per-candidate-tile log flood. Optional `suggestWorkOrders detail preview` lines must remain **bounded** (capped length with truncation marker when candidate count is large; Refs #2133). Tests in `colonizethis_logic` assert the contract for representative fixtures (Refs GitHub #1869, #2277).
