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
| `kCtE2EMoveFleetDialogScrollRootKey` | `MoveFleetDialog` scroll body (`SingleChildScrollView` child) for `scrollUntilVisible` on long destination lists. |
| `kGameMapNextTurnButtonKey` | Next-turn control on the map HUD (`game_screen_shared.dart`). |
| `ctE2eLastPanelSnapshot` | Province overlay: updated while open with valid `selectedTileKey`; cleared when closed. Separate **civilian / naval / production** snapshot updaters in `ct_e2e_last_panel_snapshot.dart` for those panels. |

**Code:** `app/lib/config/ct_e2e.dart`, `app/lib/config/ct_e2e_last_panel_snapshot.dart`, `app/lib/features/game/flame/game_screen_shared.dart` (next-turn key), `app/lib/features/game/flame/game_map_controls.dart` (region tab keys), `app/lib/features/game/widgets/move_fleet_dialog.dart` (move dialog scroll root).

**Expected-line mirrors:** `app/lib/test_support/civilian_units_panel_e2e_expected_lines.dart`, `naval_units_panel_e2e_expected_lines.dart`, `production_panel_e2e_expected_lines.dart` (keep aligned with widgets).

## Determinism

- E2E relies on **`GameSetupConfig.seed == 42`** (see `packages/colonizethis_data/lib/src/game_setup_config.dart`) and **`attemptIndex == 0`** on first successful `createNewGameAsync` (see `runNewGameSetupAfterLeaderPick` in `app/lib/features/shell/new_game_setup_flow.dart`).
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

- Job **`app_e2e_linux`** in `.github/workflows/quality.yml` runs after **`app_tests_shard`** and does **not** block **`quality_app_coverage`**.
- Ubuntu installs **clang / cmake / ninja / GTK** deps, enables **linux** desktop, then runs **`new_game_capital_panel_e2e_test.dart`**, **`new_game_full_turn_e2e_test.dart`**, and **`new_game_fleet_reaches_new_world_e2e_test.dart`** under **[GabrielBB/xvfb-action](https://github.com/GabrielBB/xvfb-action)** (Xvfb + `DISPLAY`).
- Widget/coverage jobs use **`flutter test test/`** only so `integration_test/` is not executed on the VM shard runner.

## Expectations helper

**`app/lib/test_support/province_panel_e2e_expected_lines.dart`** — builds ordered plain-text lines mirroring `ProvinceSeaZoneDetailOverlay` (**wide** layout). If UI copy changes, align this file with `SPEC/ui/province-sea-zone-detail-overlay.md` and the overlay widget.
