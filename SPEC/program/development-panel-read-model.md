# Development panel read model

**SPEC/program** — Pure projection for the empire Development panel (`GAME80001`). UI: [development-panel.md](../ui/development-panel.md). Improvable definition: [province-extraction-snapshot.md](province-extraction-snapshot.md). Refs #4175.

## Projection

`buildDevelopmentPanelModel` returns a non-persisted `DevelopmentPanelModel` with Old World and New World `DevelopmentPanelRegionModel` slices.

| Field | Meaning |
|-------|---------|
| `ownedScopes` | One row per province owned by the human player in the region (always listed; empty improvable → UI shows “No improvable resources”). |
| `purchasedScopes` | Purchased tiles grouped by source province; includes `provinceOwnerDisplayName` for the province owner. |
| `landExtractionByCommodity` | Post-resolution **effective** extraction projection for connected tiles in the region (same tile-yield math as Extraction phase; no stockpile net / Production Δ). |
| `idleBuilderCount` / `idleEngineerCount` | Civilians with `status == idle`, no `currentWork`, and no pending `WorkOrder` in `currentOrders`. |
| `assignedCivilians` | Per active region: Builders/Engineers owned by the human player with a pending `WorkOrder` or in-progress `currentWork` (`status == working`), sorted by stable unit id. Each row carries `unitId`, `unitType`, `workTarget`, `targetTileKey`, `isPending`, and turn fields for UI copy. |

## Improvable (definition A)

Owned provinces: `provinceImprovableResourceTileCounts` for `(provinceId, ownerId = player)`.

Purchased land: per purchased tile key owned by the player, same cap/prospect rules as Available; grouped under source province from tile key `region|localId|x|y`.

## Visibility filter (Slice D)

When `playerView` is supplied to `buildDevelopmentPanelModel`, improvable commodity `tileKeys` include only tiles whose `PlayerView.visibilityForTile` is `fullyVisible` or `fogged` (exclude `unknown` / unrevealed). Scope rows remain listed; commodities with no visibility-known improvable tiles contribute nothing (UI shows **No improvable resources**).

## Assigned civilians (Slice D)

`buildDevelopmentAssignedCiviliansForRegion` scans `oldWorld.units` / `newWorld.units` for `kUnitTypeBuilder` and `kUnitTypeEngineer` owned by the player in the active region. Include a unit when it has a pending `WorkOrder` in `currentOrders` for that unit id, or `status == working` with non-null `currentWork`. Pending takes precedence over in-progress when both exist.

## Open-path performance (Slice E)

- `buildDevelopmentPanelBuildContext` performs a single `resolveConnectivity` pass and exposes `connectedTileKeys` for assign affordance (no duplicate connectivity resolution on panel open).
- `buildDevelopmentPanelRegionModel` builds one region slice at a time; `DevelopmentScreenBody` builds only visited region tabs (Old World on first open; New World on first tab selection).
- `DevelopmentScreenBody` builds `PlayerView` once per frame and passes it to the read model and each region map panel (no per-map `buildPlayerView`).
- Region tabs use `CtTabStrip.lazyTabBodies` so the inactive region tab (including its map) is not built until first selection.
- Panel maps call `buildInitGameMapRegionViewData` for the active region only (not full dual-region `buildInitGameMapViewData`).
- `DevelopmentPanelMapPanel` caches `DevelopmentPanelMapSnapshot` (region view data + territory outline keys) across highlight-only rebuilds; invalidates when game turn, region, player, or per-region visibility digest changes.
- First map paint is deferred to the frame after panel mount so overview/list can paint first (post-frame `mapReady` gate).
- `DevelopmentScreenBody` defers read-model projection (`buildPlayerView`, `buildDevelopmentPanelBuildContext`, per-region models) to the frame after mount so the tab strip can paint before connectivity and improvable scans run (post-frame `readModelReady` gate).
- `developmentPanelStaticContextProvider` memoizes [PlayerView] and display-name maps across draft-order churn; invalidates on game, map data, or shell player context change only.
- `developmentPanelSharedContextProvider` memoizes idle counts and connectivity slice; invalidates when draft orders change.
- `developmentPanelRegionScopesProvider` memoizes improvable scope rows and land extraction per region; invalidates on game/map/shell changes only (not draft orders).
- `developmentPanelRegionModelProvider` composes cached scopes with order-dependent idle counts and assigned civilians.
- `developmentPanelConnectivityProvider` memoizes `resolveConnectivity` separately from draft orders so assign/cancel live updates recompute idle counts without re-running connectivity scans.
- `developmentPanelAssignRowStateCacheProvider` uses **lazy** `rowStateFor` resolution (visible rows first; material-shortage scan deferred post-frame) so first-frame open does not resolve every improvable commodity; highlight-only tab rebuilds reuse cached row states (Refs #4687 Slice B).
- Development panel projection providers use **`autoDispose`** so cached maps release when `GAME80001` pops (Refs #4687 Slice B).
- **`developmentPanelSessionCacheProvider`** retains order-independent connectivity/scopes and order-dependent shared/assign caches across same-turn re-entry when game, draft orders, and fog revision are unchanged; `autoDispose` panel providers read through this session cache (Refs #4687 Slice C).
- `DevelopmentPanelScopeList` uses **`ListView.builder`** so province scope cards build on demand (Refs #4687 Slice B).
- `DevelopmentPanelMapPanel.didUpdateWidget` skips visibility digest work on highlight-only rebuilds (Refs #4687 Slice B).
- `developmentPanelVisibilityByTile` accepts optional `regionId` so panel maps do not scan both regions when rendering one minimap.

Cache invalidation: panel projections recompute when `game`, `currentOrders`, or `playerView` inputs change on rebuild; assign/cancel and fog updates remain live-immediate per Slice A–D ACs. Connectivity (`developmentPanelConnectivityProvider`) invalidates on game/map revision only — not on draft-order churn.

### Profiling summary (Slice E)

Representative fixture: dual-region save with two OW provinces (four improvable tiles) plus an amplified NW region (ten provinces × four tiles) so monolithic dual-region cost dominates and the lazy OW-only win stays ≥25% on shared CI runners (`development_panel_open_path_timing_test.dart`; median of three 50-iteration samples).

| Hotspot (pre–Slice E) | Mitigation | Measurable effect |
|----------------------|------------|-------------------|
| Eager dual-region `buildDevelopmentPanelModel` on open | Per-region `buildDevelopmentPanelRegionModel` + visited-tab gate | Lazy OW-only build ≥25% faster than monolithic dual-region on timing fixture (50 iterations; `development_panel_open_path_timing_test.dart` reports µs and % in failure reason) |
| Duplicate `resolveConnectivity` on order churn | `developmentPanelConnectivityProvider` + `buildDevelopmentPanelBuildContextFromConnectivity` | Connectivity map identity stable across order-only updates (provider + unit tests) |
| Duplicate `buildPlayerView` (screen + map) | Single `playerView` on `DevelopmentPanelStaticContext` | Eliminated per-map rebuild; [PlayerView] identity stable across order-only updates |
| `IndexedStack` mounting both region maps | `CtTabStrip.lazyTabBodies` + `_visitedRegionIds` | NW map absent until first tab visit (`development_panel_lazy_open_test.dart`) |
| Synchronous read model on first frame | Post-frame `readModelReady` gate | Tab strip paints before connectivity/improvable scans |
| Per-row material shortage scan on highlight rebuild | `developmentPanelAssignRowStateCacheProvider` + derived shortage set | Show-tile highlight `setState` does not re-run assign affordance per row (`development_panel_projection_rebuild_guard_test.dart`) |
| Full improvable scope scan on assign/cancel draft churn | `developmentPanelRegionScopesProvider` order-independent memoization | Scope rows and extraction projection identity stable across order-only updates (provider unit test) |
| Full dual-region map view-data | Per-region `buildInitGameMapRegionViewData` + session snapshot cache | Map defers one frame; re-open reuses `developmentPanelMapSnapshotProvider` when fog unchanged |

DevTools timeline captures: filter `CtAppPerf.development` (markers in `SPEC/program/flutter-performance-tracing.md` § Development panel open path). Timing tests below remain the CI profiling anchor for AC2 (measurable µs reduction on read-model build path). **AC1 peer parity:** lazy Old World read-model open path must stay within **2×** the `ProductionScreenBody` synchronous prep surrogate on the same representative fixture (`development_panel_open_path_timing_test.dart`). That peer test is **complementary**; the standing game-app ceiling is **1 000 ms full load** including the panel minimap ([ui-surface-budget.md](ui-surface-budget.md)).

### Open-path wall-clock budget (Refs #4687)

- **1.0 s open-to-interactive** is a **profile/release** (non-debug) measurement on **Linux desktop and Android emulator** binding hosts. PR evidence uses DevTools `CtAppPerf.development*` markers including `development.interactiveReady`. **Not** enforced by debug-mode `flutter test` wall-clock assertions on CI runners.
- **Repeated-entry stability** and **Flame lifecycle** are CI widget-test contracts (see UI spec ACs below).

### Shell map pause and panel map lifecycle (Refs #4687)

- While `GAME80001` is mounted, the live shell map (`MAP10001` / `GameMapArea`) **pauses** its `CtRegionMap` Flame engine via `shellMainMapPauseHoldProvider`.
- On pop, the shell map **resumes** and continues consuming the current `Game` / draft-order revision from providers (live-invalidate; no stale assign/fog state).
- Each panel `CtRegionMap` **pauses** its Flame engine on widget dispose so repeated open/close does not leave ticking engines.
- `resolveDevelopmentPanelConnectivity` resolves **human-player connectivity only** (`onlyPlayerIds: {humanPlayerId}`); read-model Assign/Show/map consume no other-GP connectivity maps.

## Acceptance criteria

- Given owned province P with three improvable grain tiles, when the read model builds, then P’s owned scope lists grain count 3 with sorted tile keys.
- Given purchased tile T in foreign province P owned by GP B, when the read model builds, then a purchased scope under P lists owner display name for B and improvable commodities for T only.
- Given connected improved grain tiles in region R, when the read model builds extraction for R, then grain effective totals match per-tile extraction projection for tiles in R.
- Given two idle Builders and one with a pending work order, when idle counts compute, then `idleBuilderCount == 1`.
- Given improvable grain on tiles `t_visible` (fullyVisible) and `t_hidden` (unknown) in the same owned scope, when the read model builds with `playerView`, then only `t_visible` contributes to the grain count and tile key set.
- Given a Builder with pending improve and an Engineer with in-progress road work in region R, when assigned civilians build for R, then both units appear sorted by unit id with correct `workTarget` and `targetTileKey`.
- Given `GAME80001` is mounted over the live game map, when the shell map Flame engine is inspected, then it is paused (`enginePaused`) until the panel route pops.
- Given the player pops `GAME80001`, when the shell map renders again, then its Flame engine is resumed and reflects the current game and draft-order revision.
- Given connectivity/scopes are already computed and game, draft orders, and fog have not changed, when the player re-opens `GAME80001` in the same turn, then panel providers reuse `developmentPanelSessionCacheProvider` entries (same object identity for connectivity, region scopes, and map snapshots in tests) so re-open avoids redundant scans.
- Given the panel region map widget is disposed, when Flame engine state is inspected in tests, then the panel map engine is paused and no live ticker remains on a disposed panel map.

## Assign selection (Slice B)

`resolveDevelopmentAssignRowState` / `selectDevelopmentImproveAssignCandidate` in `colonizethis_orders`:

- Idle Builder: `status == idle`, no `currentWork`, no pending `WorkOrder` for that unit; first by stable unit id.
- Tile priority among valid targets for the commodity:
  - When `tileMapByRegion` is supplied: same feedstock + connectivity-aware ordering as `suggestWorkOrders` `build_improvement` (`orderDevelopmentImproveTiles` in `colonizethis_orders`).
  - When `tileMapByRegion` is absent: capital-connected first, then lower `improvementLevel`, then stable tile key.
- Materials: affordability uses stockpile after deducting other pending material work orders via `replayPendingWorkResourceProjection` in `work_order_affordance_projection.dart` (same replay order as MAP assign previews and economy preview).
- Disconnected targets: Assign enabled when improve is otherwise valid; warn dialog on commit (Slice C).
- Assign preview (Refs #4472): candidate also carries `currentImprovementLevel` and `materialCosts` from `previewWorkOrderAffordAtTile`, cached once with row state. UI: [development-assign-row.md](../ui/components/development-assign-row.md).

## Road first (Slice C)

`resolveDevelopmentRoadFirstState` / `selectDevelopmentRoadFirstCandidate` in `colonizethis_orders`:

- Idle Engineer: same idle/pending rules as Builder; first by stable unit id.
- Path: shortest owned-tile BFS from improve target to any capital-connected tile; neighbor expansion sorted by tile key.
- Road tile: first legal `build_road` candidate along the path from the connected endpoint back toward the improve target.
- Materials: same pending-work stockpile projection as improve assign (`replayPendingWorkResourceProjection` in `work_order_affordance_projection.dart`).
