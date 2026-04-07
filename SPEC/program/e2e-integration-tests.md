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
| `ctE2eLastPanelSnapshot` | Updated while the province **overlay is open** with valid `selectedTileKey`; cleared when closed. |

**Code:** `app/lib/config/ct_e2e.dart`, `app/lib/config/ct_e2e_last_panel_snapshot.dart`.

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
```

Headed desktop on a dev machine without Xvfb: use **`-d macos`** or **`-d linux`** from a normal graphical session.

## CI

- Job **`app_e2e_linux`** in `.github/workflows/quality.yml` runs after **`app_tests_shard`** and does **not** block **`quality_app_coverage`**.
- Ubuntu installs **clang / cmake / ninja / GTK** deps, enables **linux** desktop, then runs the test under **[GabrielBB/xvfb-action](https://github.com/GabrielBB/xvfb-action)** (Xvfb + `DISPLAY`).
- Widget/coverage jobs use **`flutter test test/`** only so `integration_test/` is not executed on the VM shard runner.

## Expectations helper

**`app/lib/test_support/province_panel_e2e_expected_lines.dart`** — builds ordered plain-text lines mirroring `ProvinceSeaZoneDetailOverlay` (**wide** layout). If UI copy changes, align this file with `SPEC/ui/province-sea-zone-detail-overlay.md` and the overlay widget.
