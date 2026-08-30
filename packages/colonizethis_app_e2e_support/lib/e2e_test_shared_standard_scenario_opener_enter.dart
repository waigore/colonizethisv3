import 'package:colonizethis_app_l10n/l10n/app_localizations_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

/// Drives the post-`IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
/// opener shared by every "standard" E2E `testWidgets` body —
/// `new_game_full_turn_e2e_test.dart` and
/// `new_game_capital_panel_e2e_test.dart`.
///
/// Lifted from the duplicated ~18-line block both `testWidgets` bodies
/// inlined verbatim (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6). Each
/// scenario ran the same sequence: scenario `perf` log + `testSw` stopwatch
/// → `kCtE2EEnabled` gate → wall-clock guard built on `testSw` →
/// `setSurfaceSize` → `bootstrapForIntegrationTest` + first pump +
/// `e2eWaitForNewGameEntry` + `bootstrap_for_integration_test` timing +
/// `after bootstrap_for_integration_test` checkpoint → relocated-64px PNG
/// suite preload (full-turn additionally times this slice as
/// `asset_preload`) + `after asset_preload` checkpoint →
/// `bootstrapNewGameToMap` + outer-stopwatch `new_game_to_map` timing +
/// `after new_game_to_map` checkpoint → `lookupAppLocalizations`. The two
/// scenarios diverged only on `testName`, on whether the asset-preload
/// slice was timed, and on whatever they did **after** the opener
/// (full-turn panel orchestration vs capital-panel province-detail flow).
/// Extracting the shared opener keeps a silent rename / budget change in
/// one place instead of two, and lets the widget-test pin guard the
/// contract.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). The widget-test pin in
/// `app/test/e2e_enter_standard_e2e_scenario_test.dart` carries the
/// behavioural contract: constants, AC1 barrel signature, and
/// [E2eStandardScenarioOpener] value-class shape.
///
/// Why `bootstrapForIntegrationTest` is an injected parameter: the only
/// real call sites forward `bootstrapForIntegrationTest` from
/// `package:colonizethis_app/main.dart`, but pulling that symbol into the
/// shared E2E module would couple every consumer of `e2e_test_shared.dart`
/// to the app's main entry-point — including the widget-test pins under
/// `app/test/`, which mount minimal `MaterialApp` fixtures rather than the
/// full app. Injecting the bootstrap callable keeps the shared module free
/// of the main-entry import and lets the pin file exercise the
/// callable-parameter contract without booting the real game. Mirrors the
/// pattern used by [e2eEnterFleetReachScenarioReady]
/// (`e2e_test_shared_fleet_reach_scenario_preamble.dart`).
///
/// Contract:
///
/// 1. Creates an [E2ePerfLog] keyed on [testName] and starts a fresh
///    [Stopwatch] for [E2eStandardScenarioOpener.testSw] **before** the
///    `expect(kCtE2EEnabled, isTrue, ...)` gate so the eventual `test_total`
///    slice covers the same span the pre-lift inline blocks did.
/// 2. Builds the [E2eStandardScenarioOpener.ensureUnderWallClock] guard via
///    [e2eMakeWallClockGuard] with [testName], the shared `testSw`, and the
///    [wallClockCap] (default [kE2eMaxWallClock] = 5 minutes). The same
///    stopwatch backs both the guard and the eventual `test_total` slice,
///    matching the legacy inline behaviour where the bootstrap-to-new-game
///    window counted against the wall-clock budget.
/// 3. Sets the surface size via `tester.binding.setSurfaceSize(...)`
///    (default [kE2eDefaultStandardScenarioOpenerSurfaceSize] = 1280 × 720).
/// 4. Runs the injected [bootstrapForIntegrationTest] callable, awaits one
///    `tester.pump()`, then calls [e2eWaitForNewGameEntry] with the scenario
///    perf log. Emits a single `E2E_TIMING|...|phase=$bootstrapTimingPhase`
///    slice for the bootstrap-through-`New Game`-entry window (default
///    phase [kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase] =
///    `bootstrap_for_integration_test`) and then emits
///    `ensureUnderWallClock(afterBootstrapStep)` (default step
///    [kE2eDefaultStandardScenarioOpenerAfterBootstrapStep] =
///    `'after bootstrap_for_integration_test'`).
/// 5. Calls [e2eEnsureAllRelocated64pxPngsLoadSuiteOnce] so the 64 px PNG
///    manifest is decoded at most once per VM. When
///    [assetPreloadTimingPhase] is non-null (default
///    [kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase] =
///    `'asset_preload'`), emits a per-phase `E2E_TIMING|...|phase=...` slice
///    around the preload call so the full-turn `asset_preload` dashboard
///    remains keyed on the same literal. Pass `null` to suppress emission
///    while preserving the underlying preload call (matches the legacy
///    capital-panel inline behaviour). Then emits
///    `ensureUnderWallClock(afterAssetPreloadStep)` (default step
///    [kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep] =
///    `'after asset_preload'`).
/// 6. Runs [e2eBootstrapNewGameToMap] with the scenario perf log (the inner
///    helper itself emits a `new_game_to_map` slice). When
///    [newGameToMapTimingPhase] is non-null (default
///    [kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase] =
///    `'new_game_to_map'`), additionally emits an outer-stopwatch
///    `E2E_TIMING|...|phase=...` slice around the call so the legacy
///    double-emission (inner + outer) both scenarios performed pre-lift is
///    preserved byte-for-byte. Pass `null` to suppress only the outer
///    emission. Then emits
///    `ensureUnderWallClock(afterNewGameToMapStep)` (default step
///    [kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep] =
///    `'after new_game_to_map'`).
/// 7. Looks up [AppLocalizations] via [lookupAppLocalizations] with
///    [locale] (default [kE2eDefaultStandardScenarioOpenerLocale] = `en`).
/// 8. Returns an [E2eStandardScenarioOpener] carrying the perf log, the
///    test wall-clock stopwatch, the resolved l10n handle, and the
///    wall-clock guard closure so the call site can run the rest of the
///    scenario without re-deriving any of them.
///
/// The helper does **not** stop the [E2eStandardScenarioOpener.testSw]
/// stopwatch beyond the initial `..start()`; call sites stop measuring
/// against it at their own `perf.timing('test_total', testSw.elapsed)`
/// time. This preserves the pre-lift behaviour where the `testSw`
/// accumulator covered every phase, not just the opener.
Future<E2eStandardScenarioOpener> e2eEnterStandardE2eScenario(
  WidgetTester tester, {
  required String testName,
  required Future<void> Function() bootstrapForIntegrationTest,
  Duration wallClockCap = kE2eMaxWallClock,
  Locale locale = kE2eDefaultStandardScenarioOpenerLocale,
  Size surfaceSize = kE2eDefaultStandardScenarioOpenerSurfaceSize,
  String bootstrapTimingPhase =
      kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase,
  String afterBootstrapStep =
      kE2eDefaultStandardScenarioOpenerAfterBootstrapStep,
  String? assetPreloadTimingPhase =
      kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase,
  String afterAssetPreloadStep =
      kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep,
  String? newGameToMapTimingPhase =
      kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase,
  String afterNewGameToMapStep =
      kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep,
}) async {
  // Lifted bootstrap-through-`New Game`-entry preamble: see
  // [e2eRunIntegrationTestBootstrap] for the canonical
  // `E2ePerfLog(testName)` + `testSw` + `kCtE2EEnabled` gate +
  // `setSurfaceSize` + `bootstrapForIntegrationTest` + first pump +
  // `e2eWaitForNewGameEntry` + `bootstrap_for_integration_test` timing
  // sequence both standard / fleet preambles previously duplicated.
  // The wall-clock guard build moves to **after** the lifted call here;
  // the pre-lift build at `expect` time was never invoked before the
  // first `ensureUnderWallClock(afterBootstrapStep)` call below (the
  // helper closure is pure), so deferring the guard construction by a
  // few statements is observably byte-equivalent. Refs GitHub #2336
  // AC1 / AC2 / Bottleneck 6.
  final bootstrap = await e2eRunIntegrationTestBootstrap(
    tester,
    testName: testName,
    bootstrapForIntegrationTest: bootstrapForIntegrationTest,
    surfaceSize: surfaceSize,
    bootstrapTimingPhase: bootstrapTimingPhase,
  );
  final perf = bootstrap.perf;
  final testSw = bootstrap.testSw;

  final ensureUnderWallClock = e2eMakeWallClockGuard(
    testName: testName,
    stopwatch: testSw,
    cap: wallClockCap,
  );
  ensureUnderWallClock(afterBootstrapStep);

  if (assetPreloadTimingPhase != null) {
    final preloadSw = Stopwatch()..start();
    await e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
    perf.timing(assetPreloadTimingPhase, preloadSw.elapsed);
  } else {
    await e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
  }
  ensureUnderWallClock(afterAssetPreloadStep);

  if (newGameToMapTimingPhase != null) {
    final newGameSw = Stopwatch()..start();
    await e2eBootstrapNewGameToMap(tester, perf: perf);
    perf.timing(newGameToMapTimingPhase, newGameSw.elapsed);
  } else {
    await e2eBootstrapNewGameToMap(tester, perf: perf);
  }
  ensureUnderWallClock(afterNewGameToMapStep);

  final l10n = lookupAppLocalizations(locale);

  return E2eStandardScenarioOpener(
    perf: perf,
    testSw: testSw,
    l10n: l10n,
    ensureUnderWallClock: ensureUnderWallClock,
  );
}
