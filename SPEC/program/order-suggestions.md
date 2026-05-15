# Order Suggestion API

**SPEC/program** — Enumerates valid candidate orders for AI and tooling. Validator: [order-engine.md](order-engine.md). Order types: [orders.md](orders.md).

---

## Responsibility

Given a player, their current valid order list, and game context, enumerate **candidate orders** (move, build, work, research, naval, diplomatic) guaranteed to be accepted if appended.

---

## Inputs

- `Game` and `MapTopology` (full world state and topology).
- `playerId` for the acting Great Power.
- Current `Orders` for that player (assumed valid prefix).
- A `PlayerView` for `playerId` (see [player-view.md](player-view.md)) — sole source of visibility.

---

## Guarantees

For every suggested order `o`, appending it to the current list and validating via `validatePlayerOrdersWithContext` yields `accepted`. The internal candidate-acceptance pipeline used to enumerate suggestions is the **incremental candidate validation primitive** described in § Incremental candidate validation. The primitive is required to produce the same `accepted` / `rejected` decision per candidate as full-pass `validatePlayerOrdersWithContext` (see [order-engine.md](order-engine.md) § Validation), so the observable suggestion contract is unchanged.

**Throughput bounds (Full AI):** Enumeration for some families (notably **`suggestMoveOrders`** / **`suggestArmyMoveOrders`**) may apply **deterministic probe or acceptance caps** so Full AI completes within the next-turn usability budget ([turn-resolution.md](turn-resolution.md) § Next-turn latency budget). A capped pass still validates each emitted candidate via the incremental primitive; it may omit some engine-valid destinations that would appear only after exhaustive scan. Explorer work candidates remain subject to § Work orders (`suggestWorkOrders`) row completeness rules unless a separate spec slice narrows them for performance.

**Throughput regression smoke (Refs #2394):** `packages/colonizethis_logic/test/perf/generate_orders_for_game_perf_test.dart` runs `generateOrdersForGame` on a minimal two-AI fixture with warmup iterations, records sampled durations, and asserts the median stays below a generous fixed ceiling so catastrophic batch-path regressions fail in `dart test` / package CI. It does not assert tight latency targets; profiling and phase budgets remain governed by [turn-resolution.md](turn-resolution.md) and [logging/turn-resolution.md](logging/turn-resolution.md).

**Shared unit index (naval, Refs #2394):** `OrderSuggestionAPI.suggestNavalMoveOrders` and `suggestNavalMissionOrders` accept an optional `unitsById` argument: a read-only map of every unit in `Game.worldState` keyed by unit id (the same shape as `unitsByIdFromWorld` in logic). When the caller supplies it, the implementation uses that map for incremental naval validation instead of rebuilding it inside the call. When omitted, the implementation builds the map as before. Observable candidate lists and accept/reject decisions for a fixed `(Game, topology, PlayerView, Orders)` tuple must not depend on whether the caller passed a map or omitted it, provided the supplied map matches the current world state.

**Army Move picker shared projection (Refs #2394):** `armyMovePickerDestinations` accepts optional `playerView` and `unitsById` with the same contract as `IncrementalCandidateValidator.forPlayer`: when supplied and consistent with current `Game` / `MapTopology` / `playerId`, internal validators reuse them instead of embedding `buildPlayerView` / `unitsByIdFromWorld` scans. Observable destination lists for a fixed tuple must not depend on whether these optional arguments were passed.

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

---

## Rules

- **Province / tile identity:** Province ids and tile keys in suggested orders (destination province, targetTileKey, spawn province, fleet/sea zone ids) use the **prefixed** form and resolution rules per [world-model-identity.md](../game/world-model-identity.md) (same as [orders.md](orders.md)).
- **Work orders (`suggestWorkOrders`):** For civilian **workers** (Builder, Engineer, Rail Builder), candidate work targets use the same tile scope as validation: any **player-controlled** tile (owned province or `purchasedTilesByTileKey`) that passes visibility and the order engine, not only tiles in the unit’s current province (see [civilian-units.md](../game/civilian-units.md): civilians may act on a tile other than their current tile). **Explorers:** `explore` and `prospect` candidates consider **all relevant provinces** (sorted), not only the unit’s current province. The API returns **every** engine-valid `explore` row (one accepted row per qualifying province, in sorted province order, without stopping after the first) and **every** engine-valid `prospect` row (each accepted mineral-eligible tile in each visible province; provinces sorted, tiles sorted within province). Full AI consumes this full per-unit set for Explorer explore/prospect scoring and selection (Refs #2082). Explorer explore-row `E_score` uses `E_unknown = min(24, 3×U)` where `U` is the count of land tiles in that row’s target province that are `unknown` in `PlayerView`. For `explore`, relevance is constrained by per-player **partially revealed province semantics**: provinces where the player has at least one tile at `fogged`/`fullyVisible` and at least one tile at `unknown`. Logic computes this scope from authoritative game state + `PlayerView`; app integration may maintain an app-owned per-player selection cache that stays semantics-aligned with this definition. Eligibility uses **bundle-aware** checks where a leg may be required: province visibility gates, **authoritative province land tiles** from `WorldState.tileKeysByRegionAndProvince` (same class of data as `tilesInProvince` in the implementation), plus **`PlayerView.visibilityForTile`** for “still useful” / residual exploration value — do **not** exclude `explore` solely from “stored visibility keys only” when inland tiles lack keys but exploration remains useful per authoritative tiles. When a bundle leg is required, the implicit bundled **move** destination within the destination province prefers the order `targetTileKey` when that tile is **MoveValidator**-legal; otherwise it falls back to the first **MoveValidator**-legal land tile in deterministic sorted province tile order (bounded scan). The same preference+fallback rule applies in movement-phase implicit relocation so suggestion validation and execution stay aligned (Refs #1916, #1964). When a bundle leg is required, Explorer candidates may include cross-region non-owned destinations only when the destination is **not Great Power-owned** (Minor / Tribe / unowned) and move visibility / diplomatic-war gates pass; GP-owned destinations still follow GP entry constraints. **Spies** and **Merchants** keep their existing rules-specific enumeration. **Performance:** `suggestWorkOrders` may cache, per invocation, the pre-filtered + visibility-sorted tile list keyed by `workTarget` so each distinct work target is computed once per call; per-unit acceptance still runs the order engine over that list until the first valid tile is found. Summary **debug** lines (no per-tile spam): see § Suggestion observability.
- **Work order tile selection (`getValidWorkOrderTileKeysWithVisibility`):** For UI tile selection, apply the work-target-specific pre-filter table (e.g. `build_improvement`: owned or purchased tiles with a resource; prospect-required minerals must also pass order-engine validation including prospection (unprospected mineral tiles are excluded); `prospect`: land tiles that are mineral-eligible and not yet prospected — then visibility and order engine). Not every work target is limited to owned/purchased tiles.
- **Visibility:** Uses PlayerView only; may not inspect hidden tiles or enemy units directly. Checks per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). Undiscovered factions are **never** valid diplomatic targets for order suggestions.
- **Determinism:** Fixed inputs produce the same set and ordering of suggestions.
- **Build orders:** `suggestBuildOrders` returns affordable, valid build-unit orders for both **military (regiment)** and **naval (ship)** unit types. Each candidate is validated (treasury, stockpile, tech, capital) via the order engine. Ordering is deterministic (e.g. by unit type id).
- **Naval mission orders (`suggestNavalMissionOrders`):** For each eligible fleet, the system tries each value of `FleetMission` (serialized as `FleetMission.name` on `NavalMissionOrder.mission`) and keeps candidates accepted by the order engine. Adding or renaming enum values in [ships-and-naval.md](../game/ships-and-naval.md) therefore updates suggestion enumeration without a separate hardcoded mission list.
- **Diplomatic orders (`suggestDiplomaticOrders`):** Suggests valid diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, Grant Aid, Set Subsidy) targeting factions the player knows about. Each candidate is validated with the order engine (`addDiplomaticOrderWithContext`), same as other suggestion families. Optional `tileMapByRegion` matches `suggestWorkOrders` for API symmetry. Visibility rules per [regional discovery model](../game/diplomacy.md):
  - **GP↔GP:** Always visible (global knowledge of major powers).
  - **GP↔Minor:** Always visible (same region/Old World).
  - **GP↔Tribe:** Only if discovered (diplomatic relation exists or province visibility).
- **Primary vs economic suggestions per target:** For each known target **T**, candidates follow `_diplomaticCandidatesForTargetOrdered` (`offerPeace`, `alliance`, `establishOverture`, `grantAid`, `setSubsidy`, `declareWar`). The implementation uses **two passes**: (1) consider **only** non-economic types in that order; append the **first** that passes the order engine against a **trial** list (see below) and **stop** the primary pass. (2) Consider **only** `grantAid` and `setSubsidy` in candidate order; append each that passes against the trial list after step (1), updating the trial after each acceptance. **Grant before subsidy** when both are valid: `grantAid` precedes `setSubsidy` in the template. Multiple entries toward the same **T** in **L** are only as allowed by [orders.md](orders.md) (e.g. one `grantAid` + one `setSubsidy` when no non-economic suggestion was accepted for **T**).
- **Working list:** Initialize **workingOrders** from `currentOrders`. For each **T**, set **trialOrders** = **workingOrders**; run the two passes; then assign **workingOrders** = **trialOrders** so treasury and caps reflect suggestions accepted earlier in the same invocation. Pending orders in `currentOrders` constrain what can be suggested; removing a pending order restores eligibility per engine validation.
- **Throughput (Refs #2394):** For each target **T**, the system builds one `IncrementalCandidateValidator` per fixed **trialOrders** prefix for the non-economic pass and one for the economic pass (after the primary pass may update **trialOrders**), reusing that instance for every candidate in the pass. Observable suggestions and acceptance decisions remain identical to per-candidate `isDiplomaticOrderAccepted` probes against the same prefix.

**Acceptance criteria (diplomatic suggestions)**

- Given fixed `Game`, `MapTopology`, `PlayerView`, and `Orders` for player P, when `suggestDiplomaticOrders` returns a list L, then when the system appends every order in L to P’s diplomatic slot **in list order** onto a copy of those `Orders` and runs `validatePlayerOrdersWithContext` for P on the combined list, every validation result is **accepted**.
- Given `currentOrders` already includes a non-economic diplomatic order from P to target T, when `suggestDiplomaticOrders` runs with those `currentOrders`, then L contains **no** order with `targetFactionId == T`.
- Given `currentOrders` includes only a valid pending `grantAid` from P to T, when `suggestDiplomaticOrders` runs, then L **may** include a `setSubsidy` toward T if the engine accepts it when merged with `currentOrders`.
- Given `currentOrders` includes no diplomatic order to T, when a prior call returned suggestions toward T and the player removed all diplomatic orders to T from the draft, when `suggestDiplomaticOrders` runs again with the updated `currentOrders`, then the system **may** again include valid suggestions toward T subject to game rules and engine validation.

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

## Selected-unit availability (`getAvailableWorkTargetsForUnit`)

**Purpose:** Human-shell **per-unit** work availability (which work targets have ≥1 valid tile) without broad per-player `suggestWorkOrders` enumeration. Return type `AvailableWorkTargetsForUnit` holds `assignable`, optional `blockedReason`, and `validTileKeysByTarget` (only targets with non-empty tile sets).

**Rules:** When the unit has **any** pending `WorkOrder` in `currentOrders` for `view.playerId`, or `unit.currentWork != null`, or the unit is absent from `view.ownUnits`, the API returns not assignable with a stable `blockedReason` token and **does not** run per-candidate tile probing / order-engine loops for availability. Optional `workTargetFilter` limits evaluation to one work target id.

**Acceptance criteria**

- Given a civilian unit with a pending draft `WorkOrder` for that `unitId` on the current turn, when `getAvailableWorkTargetsForUnit` or `getValidWorkOrderTileKeysWithVisibility` runs for that unit, then the system returns empty target/tile availability for new assignments for that call without order-engine candidate-tile probing attributable to that unit.
- Given Dart source under `app/lib`, when repository lint rule `repo.app_lib_no_broad_suggest_work_orders` runs, then no `.dart` file under `app/lib` contains a `suggestWorkOrders(` call site (Refs #2133; full enumeration remains available to AI, `integration_test`, and other non-`app/lib` tooling).

---

## Suggestion observability (debug)

When diagnosing why a civilian work target is missing from Assign / AI suggestions, `suggestWorkOrders` may emit **summary-only** `logger` **`debug`** lines (prefix `logic.order_suggestion`, token `suggest_work`): **per unit** (`unitId`, `unitType`, `region`, `at` province) and **per work target** one line with `outcome=` `included` or `excluded`, optional `tile=`, and for exclusions a **stable** `reason=` token (e.g. `visibility`, `no_valid_tile`, `no_single_hop`, `duplicate_pending`, `engine_rejected`, `not_applicable`). When more than one suggestion row is included in a single evaluation pass (e.g. Explorer `explore` across provinces or `prospect` across tiles), that line uses `includedCount=<n>` and `tile=-` instead of emitting one line per row. **No** per-candidate-tile log flood. Optional `suggestWorkOrders detail preview` lines must remain **bounded** (capped length with truncation marker when candidate count is large; Refs #2133). Tests in `colonizethis_logic` assert the contract for representative fixtures (Refs GitHub #1869, #2277).
