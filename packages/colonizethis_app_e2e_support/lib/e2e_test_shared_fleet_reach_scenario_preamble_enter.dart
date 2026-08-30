import 'package:colonizethis_app_l10n/l10n/app_localizations_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

/// Drives the post-`IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
/// preamble shared by every fleet-reach `testWidgets` body in
/// `new_game_fleet_reaches_new_world_e2e_test.dart`.
///
/// Lifted from the duplicated 40-line block both `testWidgets` bodies
/// inlined verbatim (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6). Each
/// scenario in `new_game_fleet_reaches_new_world_e2e_test.dart` ran the
/// same sequence: `kCtE2EEnabled` gate → set surface size →
/// `bootstrapForIntegrationTest` + first pump + `waitForNewGameEntry` +
/// `bootstrap_for_integration_test` timing → relocated-64px PNG preload →
/// fresh wall-clock stopwatch + 5-minute guard → `bootstrapNewGameToMap` +
/// `after bootstrap` checkpoint → `lookupAppLocalizations` → split home
/// fleet + close bottom sheet + `after split fleet` checkpoint. The two
/// scenarios diverged only on `testName` and on whatever they did **after**
/// the preamble (fleet-reach loop vs post-bundle Explore retry). Extracting
/// the shared preamble keeps a silent rename / budget change in one place
/// instead of two, and lets the widget-test pin guard the contract.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). The widget-test pin in
/// `app/test/e2e_enter_fleet_reach_scenario_ready_test.dart` carries the
/// behavioural contract: constants, AC1 barrel signature, and
/// [E2eFleetReachScenarioPreamble] value-class shape.
///
/// Why `bootstrapForIntegrationTest` is an injected parameter: the only
/// real call site forwards `bootstrapForIntegrationTest` from
/// `package:colonizethis_app/main.dart`, but pulling that symbol into the
/// shared E2E module would couple every consumer of `e2e_test_shared.dart`
/// to the app's main entry-point — including the widget-test pins under
/// `app/test/`, which mount minimal `MaterialApp` fixtures rather than the
/// full app. Injecting the bootstrap callable keeps the shared module free
/// of the main-entry import and lets the pin file exercise the
/// callable-parameter contract without booting the real game.
///
/// Contract:
///
/// 1. Asserts `kCtE2EEnabled` is `true` and fails with the canonical
///    `--dart-define=CT_E2E=true` reason when the gate is off. Starts the
///    returned [E2eFleetReachScenarioPreamble.testSw] **before** the
///    expect so the eventual `test_total` slice covers the full span the
///    pre-lift inline blocks did.
/// 2. Sets the surface size via `tester.binding.setSurfaceSize(...)`
///    (default [kE2eDefaultFleetReachPreambleSurfaceSize] = 1280 × 720).
/// 3. Runs the injected [bootstrapForIntegrationTest] callable, awaits one
///    `tester.pump()`, then calls [e2eWaitForNewGameEntry] with the
///    scenario perf log. Emits a single
///    `E2E_TIMING|...|phase=$bootstrapTimingPhase` slice for the
///    bootstrap-through-`New Game`-entry window (default phase
///    [kE2eDefaultFleetReachPreambleBootstrapTimingPhase] =
///    `bootstrap_for_integration_test`).
/// 4. Calls [e2eEnsureAllRelocated64pxPngsLoadSuiteOnce] so the 64 px PNG
///    manifest is decoded at most once per VM (matches the pre-lift inline
///    call order).
/// 5. Creates a fresh wall-clock stopwatch, derives the
///    [E2eFleetReachScenarioPreamble.ensureUnderWallClock] guard via
///    [e2eMakeWallClockGuard] with `testName` and the [wallClockCap]
///    (default [kE2eMaxWallClock] = 5 minutes), and returns it to the call
///    site so subsequent phases keep using the same guard the pre-lift
///    inline `final ensureUnderWallClock = ...` declaration created.
/// 6. Runs [e2eBootstrapNewGameToMap] with the scenario perf log, then
///    emits `ensureUnderWallClock(afterBootstrapStep)` (default step
///    [kE2eDefaultFleetReachPreambleAfterBootstrapStep] =
///    `'after bootstrap'`).
/// 7. Looks up [AppLocalizations] via [lookupAppLocalizations] with
///    [locale] (default [kE2eDefaultFleetReachPreambleLocale] = `en`).
/// 8. Splits the home fleet once via [e2eSplitHomeFleetOnce], closes the
///    surfaced bottom sheet via [e2eCloseBottomSheet], then emits
///    `ensureUnderWallClock(afterSplitFleetStep)` (default step
///    [kE2eDefaultFleetReachPreambleAfterSplitFleetStep] =
///    `'after split fleet'`). The [maxUiResponseWait] override
///    (default [kE2eDefaultFleetReachPreambleMaxUiResponseWait] = 5 s) is
///    forwarded into both the split's `openNavalTimeout` /
///    `bottomSheetCloseTimeout` and the subsequent
///    [e2eCloseBottomSheet]'s `overallTimeout`, mirroring the pre-lift
///    forwarding.
/// 9. Returns an [E2eFleetReachScenarioPreamble] carrying the perf log,
///    the test wall-clock stopwatch, the resolved l10n handle, and the
///    wall-clock guard closure so the call site can run the rest of the
///    scenario without re-deriving any of them.
///
/// The helper does **not** start or stop the [E2eFleetReachScenarioPreamble.testSw]
/// stopwatch beyond the initial `..start()`; call sites stop measuring
/// against it at their own `perf.timing('test_total', testSw.elapsed, ...)`
/// time. This preserves the pre-lift behaviour where the
/// `testSw` accumulator covered every phase, not just the preamble.
Future<E2eFleetReachScenarioPreamble> e2eEnterFleetReachScenarioReady(
  WidgetTester tester, {
  required String testName,
  required Future<void> Function() bootstrapForIntegrationTest,
  Duration maxUiResponseWait = kE2eDefaultFleetReachPreambleMaxUiResponseWait,
  Duration wallClockCap = kE2eMaxWallClock,
  Locale locale = kE2eDefaultFleetReachPreambleLocale,
  Size surfaceSize = kE2eDefaultFleetReachPreambleSurfaceSize,
  String bootstrapTimingPhase =
      kE2eDefaultFleetReachPreambleBootstrapTimingPhase,
  String afterBootstrapStep = kE2eDefaultFleetReachPreambleAfterBootstrapStep,
  String afterSplitFleetStep = kE2eDefaultFleetReachPreambleAfterSplitFleetStep,
}) async {
  // Lifted bootstrap-through-`New Game`-entry preamble: see
  // [e2eRunIntegrationTestBootstrap] for the canonical
  // `E2ePerfLog(testName)` + `testSw` + `kCtE2EEnabled` gate +
  // `setSurfaceSize` + `bootstrapForIntegrationTest` + first pump +
  // `e2eWaitForNewGameEntry` + `bootstrap_for_integration_test` timing
  // sequence both standard / fleet preambles previously duplicated.
  // Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  final bootstrap = await e2eRunIntegrationTestBootstrap(
    tester,
    testName: testName,
    bootstrapForIntegrationTest: bootstrapForIntegrationTest,
    surfaceSize: surfaceSize,
    bootstrapTimingPhase: bootstrapTimingPhase,
  );
  final perf = bootstrap.perf;
  final testSw = bootstrap.testSw;
  await e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();

  final wallClock = Stopwatch()..start();
  final ensureUnderWallClock = e2eMakeWallClockGuard(
    testName: testName,
    stopwatch: wallClock,
    cap: wallClockCap,
  );

  await e2eBootstrapNewGameToMap(tester, perf: perf);
  ensureUnderWallClock(afterBootstrapStep);

  final l10n = lookupAppLocalizations(locale);

  await e2eSplitHomeFleetOnce(
    tester,
    l10n,
    perf: perf,
    openNavalTimeout: maxUiResponseWait,
    bottomSheetCloseTimeout: maxUiResponseWait,
  );
  await e2eCloseBottomSheet(
    tester,
    perf: perf,
    overallTimeout: maxUiResponseWait,
  );
  ensureUnderWallClock(afterSplitFleetStep);

  return E2eFleetReachScenarioPreamble(
    perf: perf,
    testSw: testSw,
    l10n: l10n,
    ensureUnderWallClock: ensureUnderWallClock,
  );
}
