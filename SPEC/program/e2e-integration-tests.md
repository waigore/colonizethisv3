# End-to-end tests (`integration_test`)

**SPEC/program** — Flutter **Linux desktop** integration tests on **`ubuntu-latest`** under **Xvfb** (headless), separate from widget/unit coverage under `app/test/`.  
(`flutter test … -d chrome` is **not** used: `integration_test` does not support web targets on current stable; CI uses **`linux`**.)

## Compile-time flag: `CT_E2E`

- **Name:** `CT_E2E`
- **Default:** off (`false`)
- **Enable:** `--dart-define=CT_E2E=true` when compiling / running integration tests.
- **Purpose:** Attach **test-only** widget keys and update a **last panel snapshot** for assertion helpers. Normal `flutter run` / production builds **must not** pass this define.

## App wiring (keys & snapshot)

| Item | When active |
|------|-------------|
| `kCtE2EOpenCapitalProvinceDetailKey` | `InkWell` on the map stack opens province detail for the human **capital tile** (same as `reportMapTileTapped` + region tab). |
| `kCtE2EProvincePanelRootKey` | `KeyedSubtree` root for **in-order [Text] collection** under the wide-layout province overlay. |
| `kCtE2ECivilianPanelRootKey` | Root for civilian units bottom sheet / overlay subtree (ordered text + snapshots). |
| `kCtE2ENavalPanelRootKey` | Root for naval units bottom sheet subtree. |
| `kCtE2EProductionPanelRootKey` | Root for production screen subtree (wide layout). |
| `kCtE2ESelectFirstValidWorkTileKey` | Map overlay: pick first valid tile for civilian work-target selection (E2E). |
| `kCtE2EOpenFirstCivilianMarkerPanelKey` | Map overlay: open tile-scoped civilian panel for first civilian marker. |
| `kCtE2EOpenFirstFleetMarkerPanelKey` | Map overlay: open tile-scoped naval panel for first fleet marker. |
| `kCtE2ERegionTabNewWorldKey` | Map HUD: **New World** region `CtChoiceChip` (Keyed subtree for e2e taps / finders). |
| `kCtE2EMoveFleetDialogScrollRootKey` | `MoveFleetDialog` scroll body (`SingleChildScrollView` child); fleet e2e uses bounded drags within a strict UI-response time cap (see Determinism). |
| `kGameMapNextTurnButtonKey` | Next-turn control on the map HUD (`game_screen_shared.dart`). |
| `ctE2eLastPanelSnapshot` | Province overlay: updated while open with valid `selectedTileKey`; cleared when closed. Separate **civilian / naval / production** snapshot updaters in `ct_e2e_last_panel_snapshot.dart` for those panels. |

**Code:** `app/lib/config/ct_e2e.dart`, `app/lib/config/ct_e2e_last_panel_snapshot.dart`, `app/lib/features/game/flame/game_screen_shared.dart` (next-turn key), `app/lib/features/game/flame/game_map_controls.dart` (region tab keys), `app/lib/features/game/widgets/move_fleet_dialog.dart` (move dialog scroll root).

**Shared integration helpers:** `app/integration_test/e2e_test_shared.dart` — `e2eBootstrapNewGameToMap` / `e2eWaitForMapHudAfterNewGameStart`, `e2eWaitForNewGameEntry`, `e2eWaitUntilFound`, `e2ePumpFor`, `e2ePumpUntil`, `e2ePumpUntilFinderEmpty`, `e2eDismissTransientUi`, `e2eCloseBottomSheet`, `e2eExpandEachExpansionTileOnce`, `e2eWaitForNextTurnLabelAdvance`, `e2eCollectTextPreorder`, manifest + parallel 64px PNG verification (`e2eDiscoverRelocated64pxPngAssets`, `e2eEnsureRelocated64pxPngDecode`, `e2eDecodePngAssetPathsParallel`). Scenarios should call these instead of duplicating new-game→map polling, overlay dismissal, bottom-sheet teardown, expansion-tile fan-out, next-turn label polls, or per-file asset preload (Refs GitHub #2336).

**Expected-line mirrors:** `app/lib/test_support/civilian_units_panel_e2e_expected_lines.dart`, `naval_units_panel_e2e_expected_lines.dart`, `production_panel_e2e_expected_lines.dart` (keep aligned with widgets).

## Determinism

- E2E relies on **`GameSetupConfig.seed == 42`** (see `packages/colonizethis_data/lib/src/game_setup_config.dart`) and **`attemptIndex == 0`** on first successful `createNewGameAsync` (see `runNewGameSetupAfterLeaderPick` in `app/lib/features/shell/new_game_setup_flow.dart`).
- **`CT_E2E` new-game template:** `AppEventHandlerScope` passes a **smaller non–locked-full-init** `GameSetupConfig` into `NewGameLeaderSelectionDialog` when `kCtE2EEnabled` (`app/lib/core/services/app_event_handler_scope.dart`): fewer continents / minors / tribes and smaller OW/NW province targets than `GameSetupConfig.defaultConfig`, so Linux `integration_test` runs stay within time budgets. Production `main` and normal `flutter test` (without `CT_E2E`) still use `defaultConfig`.
- **Locked full-init note:** `GameService` may bump `mapSeed` after a first-try topology failure (`game_service.dart`), lengthening OW→NW sailing; the fleet e2e allows **35** `Next turn` taps in `new_game_fleet_reaches_new_world_e2e_test.dart` for the main reach loop.
- **CT_E2E bootstrap:** `bootstrapForIntegrationTest` skips `SessionLogBuffer.init` when `CT_E2E=true`. Full `main` still initializes the buffer for the debug log viewer; in e2e, initializing it would reset `Logger.level` / `Logger.defaultFilter` and defeat `suppressLogsForTests()`, slowing headless Linux runs.
- **NW fleet e2e region focus:** `new_game_fleet_reaches_new_world_e2e_test.dart` switches to the **New World** region tab when probing for arrival, but selects **Old World** before opening the naval panel for **Move** so split-fleet / warp orders stay aligned with OW fleets on headless Linux (same map HUD chips as `game_map_controls.dart`).
- **NW fleet e2e fail-fast waits:** `new_game_fleet_reaches_new_world_e2e_test.dart` treats **any single UI-response wait** (finder poll, naval panel open, next-turn label change after tap, move-fleet dialog steps, bottom-sheet close) as **failed if it exceeds 5 seconds**. **Overall** async setup from **Start** tap until the map HUD (`kHomeToCapitalButtonKey`) is capped separately at **60 seconds** so hung map generation still terminates. The same test **fails** if **wall-clock elapsed** from the initial post-`bootstrapForIntegrationTest` pump (before **Start** → map) exceeds **5 minutes** at checkpoints, matching the PR runtime rule.
- **Relocated 64px map icon preload:** `e2eEnsureAllRelocated64pxPngsLoad` and `e2eDiscoverRelocated64pxPngAssets` live in `app/integration_test/e2e_test_shared.dart` alongside `e2eDecodePngAssetPathsParallel` (bounded-concurrency decode). New-game E2E files that need the warm-cache pass call the shared helper instead of duplicating manifest + expectation logic (GitHub #2336 bottleneck 1 / helper dedupe).
- **Adaptive poll pacing (Refs #2336):** Long-running `integration_test` busy-wait loops (new-game bootstrap, naval/production panel open, bottom-sheet close, next-turn label polls) use shared helpers in `e2e_test_shared.dart`: `e2eAdaptivePollRampAfterIdle` ramps repeated idle `pump` steps **25→50→75→100 ms**, `e2ePumpUntilFinderEmpty` applies the same pacing until a dismiss target finder clears (post-tap snackbar / alert / move-dialog close, bounded timeout, no throw on expiry), and `e2eWaitForNewGameEntry` waits for a hit-testable **New Game** label after `bootstrapForIntegrationTest` instead of a fixed post-bootstrap pump. Fleet bundled-explore helpers (`_openCivilianPanelFleetE2e`, `_anyExplorerHasEnabledExploreAssignFleetE2e` in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`) use the same ramp for panel-open and **Explore** row polls. Linux headless runs advance fewer idle frames per second while preserving the same hard timeout caps above.
- **PR runtime rule (hard cap):** The `app_e2e_linux` lane must enforce a **5-minute wall-clock cap** per e2e scenario path used for PR quality checks. Any integration test path exceeding 5 minutes must fail fast and emit timing markers so the regression is attributable.
- **NW fleet reach + bundled Explore (#1869):** Reach = naval snapshot (or panel fallback) shows the fleet in NW. Post-bundle loop continues until a **P–S coastal** NW sea zone **or** fogged NW land appears (open ocean alone is insufficient). PlayerView stays aligned with `SPEC/program/fog-and-exploration-resolution.md` via ship-reveal indexing and `applyFogDecay(..., navalCoastalIntelTopology:)` in logic.
- **Fleet + Explorer bundled explore (#1869):** Post-NW presence: open Civilian Units, **Assign** Explorer, assert **Explore** is enabled (`ListTile.enabled`) without a prior Explorer-only **Move**. A `skip`ped test holds the legacy Move-then-Explore staging AC separately.
- Assertions use **English** `AppLocalizations` (**`Locale('en')`**, matching `MaterialApp` lookup in `app/lib/app.dart`).

## Local run

**Linux** (matches CI; needs GTK dev packages per [Flutter Linux setup](https://docs.flutter.dev/platform-integration/linux/setup)):

```bash
cd app
flutter config --enable-linux-desktop
flutter test integration_test/new_game_capital_panel_e2e_test.dart \
  -d linux \
  --dart-define=CT_E2E=true

# New World naval reach:
flutter test integration_test/new_game_fleet_reaches_new_world_e2e_test.dart \
  -d linux \
  --dart-define=CT_E2E=true
```

Headed runs: **`-d macos`** or **`-d linux`** in a graphical session.

## CI

- **`app_build_linux`** (`quality.yml`, parallel to **`app_tests_shard`**, shared **`app_tests_cache`**): Ubuntu deps, **`flutter build linux --release --no-pub`**, then **`git`** check that tracked **`app/lib/l10n/*.dart`** match gen output (Refs #2074).
- PR **`quality`** does not run **`app_e2e_linux`**; e2e is separate workflows plus local runs.
- Shards run **`flutter test test/`** only (`integration_test/` excluded).

## Expectations helper

**`app/lib/test_support/province_panel_e2e_expected_lines.dart`** — mirrors `ProvinceSeaZoneDetailOverlay` (wide); sync with `SPEC/ui/province-sea-zone-detail-overlay.md` when copy changes.
