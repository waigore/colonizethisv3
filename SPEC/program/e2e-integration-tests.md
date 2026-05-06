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

**Expected-line mirrors:** `app/lib/test_support/civilian_units_panel_e2e_expected_lines.dart`, `naval_units_panel_e2e_expected_lines.dart`, `production_panel_e2e_expected_lines.dart` (keep aligned with widgets).

## Determinism

- E2E relies on **`GameSetupConfig.seed == 42`** (see `packages/colonizethis_data/lib/src/game_setup_config.dart`) and **`attemptIndex == 0`** on first successful `createNewGameAsync` (see `runNewGameSetupAfterLeaderPick` in `app/lib/features/shell/new_game_setup_flow.dart`).
- **`CT_E2E` new-game template:** `AppEventHandlerScope` passes a **smaller non–locked-full-init** `GameSetupConfig` into `NewGameLeaderSelectionDialog` when `kCtE2EEnabled` (`app/lib/core/services/app_event_handler_scope.dart`): fewer continents / minors / tribes and smaller OW/NW province targets than `GameSetupConfig.defaultConfig`, so Linux `integration_test` runs stay within time budgets. Production `main` and normal `flutter test` (without `CT_E2E`) still use `defaultConfig`.
- **Locked full-init note:** `GameService` may still regenerate maps with a bumped `mapSeed` (`effectiveSeed + 100003`, …) after a topology/assigner failure on the first try (`app/lib/core/services/game_service.dart`). That can lengthen coast→warp→New World sailing versus a first-try seed-42 pair; the New World fleet e2e therefore allows a **higher Next-turn budget** than the nominal seed alone would suggest (currently **35** `Next turn` taps in `new_game_fleet_reaches_new_world_e2e_test.dart` for the main reach loop).
- **CT_E2E bootstrap:** `bootstrapForIntegrationTest` skips `SessionLogBuffer.init` when `CT_E2E=true`. Full `main` still initializes the buffer for the debug log viewer; in e2e, initializing it would reset `Logger.level` / `Logger.defaultFilter` and defeat `suppressLogsForTests()`, slowing headless Linux runs.
- **NW fleet e2e region focus:** `new_game_fleet_reaches_new_world_e2e_test.dart` switches to the **New World** region tab when probing for arrival, but selects **Old World** before opening the naval panel for **Move** so split-fleet / warp orders stay aligned with OW fleets on headless Linux (same map HUD chips as `game_map_controls.dart`).
- **NW fleet e2e fail-fast waits:** `new_game_fleet_reaches_new_world_e2e_test.dart` treats **any single UI-response wait** (finder poll, naval panel open, next-turn label change after tap, move-fleet dialog steps, bottom-sheet close) as **failed if it exceeds 5 seconds**. **Overall** async setup from **Start** tap until the map HUD (`kHomeToCapitalButtonKey`) is capped separately at **60 seconds** so hung map generation still terminates. The same test **fails** if **wall-clock elapsed** from the initial post-`bootstrapForIntegrationTest` pump (before **Start** → map) exceeds **5 minutes** at checkpoints, matching the PR runtime rule.
- **PR runtime rule (hard cap):** The `app_e2e_linux` lane must enforce a **5-minute wall-clock cap** per e2e scenario path used for PR quality checks. Any integration test path exceeding 5 minutes must fail fast and emit timing markers so the regression is attributable.
- **NW fleet reach + bundled Explore (#1869):** The main loop treats a non–home fleet as having **reached** the New World when the **naval snapshot** (or naval panel UI fallback) shows that fleet in the New World (same as the standalone fleet test). The **post-bundle** test then runs a **second** bounded loop (more `Next turn` / naval **Move** steps) until the snapshot shows either a **P–S coastal** New World sea zone (so ship reveal can paint adjacent land) **or** any New World land-province tile at least **fogged** in the human player view—open-ocean arrival alone is not enough for bundled Explore. **Ship reveal** tile indexing and **fog decay** preservation (`landTileKeysForProvinceBucket`, `applyFogDecay(..., navalCoastalIntelTopology:)` in `colonizethis_logic`) keep PlayerView aligned with `SPEC/program/fog-and-exploration-resolution.md`.
- **Fleet + Explorer bundled explore (GitHub #1869):** The same file adds a **post-bundle** integration test: after a **non–home** human fleet is present in the **New World** (reuse split + move loop), the test opens the **Civilian Units** panel, **Assign** on an **Explorer**, and asserts the **Explore** menu row is **enabled** (`ListTile.enabled`) so cross-province bundled targets can be chosen **without** a prior Explorer-only **Move** turn. A **separate** `skip`ped test documents the **interim** pre-bundle **Move-then-Explore** staging AC so the file never combines 6a and 6b in one ambiguous conditional.
- Assertions use **English** `AppLocalizations` (**`Locale('en')`**, matching `MaterialApp` lookup in `app/lib/app.dart`).

## Local run

**Linux** (matches CI; needs GTK dev packages per [Flutter Linux setup](https://docs.flutter.dev/platform-integration/linux/setup)):

```bash
cd app
flutter config --enable-linux-desktop
flutter test integration_test/new_game_capital_panel_e2e_test.dart \
  -d linux \
  --dart-define=CT_E2E=true

# New World naval reach (multi-turn, widget-only success):
flutter test integration_test/new_game_fleet_reaches_new_world_e2e_test.dart \
  -d linux \
  --dart-define=CT_E2E=true
```

Headed desktop on a dev machine without Xvfb: use **`-d macos`** or **`-d linux`** from a normal graphical session.

## CI

- Job **`app_build_linux`** in `.github/workflows/quality.yml` runs in parallel with **`app_tests_shard`** (both need **`app_tests_cache`**). When test-relevant paths change, it restores the same pub + `gen-l10n` artifact as the shard runners, installs **clang / cmake / ninja / pkg-config / GTK / lzma** build deps on Ubuntu, then runs **`flutter build linux --release --no-pub`** under `app/`, then verifies tracked hand **`app/lib/l10n/*.dart`** files still exist and match **`git`** (Refs #2074). It is **not** a dependency of **`app_e2e_linux`**; add **`App Linux desktop build (release)`** to branch protection required checks if merges should wait on it.
- Job **`app_e2e_linux`** runs after **`app_tests_shard`** only; it remains a required gate for branch protection but is currently a **no-op** (integration suites are not executed on the PR VM for stability/speed—the step only logs that e2e is intentionally skipped). It does **not** block **`quality_app_coverage`** beyond the existing `needs` graph.
- Widget/coverage jobs use **`flutter test test/`** only so `integration_test/` is not executed on the VM shard runner.

## Expectations helper

**`app/lib/test_support/province_panel_e2e_expected_lines.dart`** — builds ordered plain-text lines mirroring `ProvinceSeaZoneDetailOverlay` (**wide** layout). If UI copy changes, align this file with `SPEC/ui/province-sea-zone-detail-overlay.md` and the overlay widget.
