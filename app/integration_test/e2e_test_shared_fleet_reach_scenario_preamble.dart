import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';
import 'e2e_test_shared_bootstrap.dart';

/// Default per-call UI-response budget forwarded by
/// [e2eEnterFleetReachScenarioReady] into the post-bootstrap
/// [e2eSplitHomeFleetOnce] and [e2eCloseBottomSheet] calls.
///
/// Mirrors the legacy private `_kMaxUiResponseWait = Duration(seconds: 5)` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart`. The fleet scenarios
/// reuse the same literal throughout the rest of the test body (loop, final
/// naval check, bundled-Explore wait), so the preamble must default to the
/// same value or the post-bootstrap split-fleet path would silently drift to
/// a different budget than every other UI-response wait in the same
/// scenario. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
const Duration kE2eDefaultFleetReachPreambleMaxUiResponseWait = Duration(
  seconds: 5,
);

/// Default [Locale] passed to [lookupAppLocalizations] inside
/// [e2eEnterFleetReachScenarioReady].
///
/// Pre-lift fleet scenarios hard-coded `const Locale('en')`. Surfacing the
/// literal as a constant lets the post-lift helper accept locale overrides
/// from future bilingual / RTL E2E scenarios without forking the preamble
/// (Refs GitHub #2336 AC1 / AC2).
const Locale kE2eDefaultFleetReachPreambleLocale = Locale('en');

/// Default surface size set by [e2eEnterFleetReachScenarioReady] before
/// calling the injected `bootstrapForIntegrationTest`.
///
/// Mirrors the pre-lift `await tester.binding.setSurfaceSize(const
/// Size(1280, 720))` literal used by both fleet `testWidgets` bodies in
/// `new_game_fleet_reaches_new_world_e2e_test.dart`. A silent drift here
/// would change Flame viewport sizing under both scenarios and could
/// invalidate visibility-based locators downstream. Refs GitHub #2336 AC1 /
/// AC2.
const Size kE2eDefaultFleetReachPreambleSurfaceSize = Size(1280, 720);

/// Default `E2E_TIMING|...|phase=...` label emitted by
/// [e2eEnterFleetReachScenarioReady] for the bootstrap-for-integration-test
/// timing slice.
///
/// Preserves the pre-lift `perf.timing('bootstrap_for_integration_test',
/// bootstrapSw.elapsed)` literal both fleet `testWidgets` bodies emitted so
/// downstream `E2E_TIMING|...|phase=bootstrap_for_integration_test` log
/// scrapers / AC8 dashboards keyed on this phase remain stable across the
/// lift. Refs GitHub #2336 AC1 / AC2.
const String kE2eDefaultFleetReachPreambleBootstrapTimingPhase =
    'bootstrap_for_integration_test';

/// Default `ensureUnderWallClock(...)` checkpoint label emitted by
/// [e2eEnterFleetReachScenarioReady] after the post-`bootstrapNewGameToMap`
/// guard fires.
///
/// Preserves the pre-lift `ensureUnderWallClock('after bootstrap')` literal
/// both fleet `testWidgets` bodies emitted so the
/// `colonizethis-e2e-ui-stability.mdc` 5-minute fail-fast attribution stays
/// keyed on the same checkpoint string across the lift. Refs GitHub #2336
/// AC1 / AC2.
const String kE2eDefaultFleetReachPreambleAfterBootstrapStep = 'after bootstrap';

/// Default `ensureUnderWallClock(...)` checkpoint label emitted by
/// [e2eEnterFleetReachScenarioReady] after the post-`splitHomeFleetOnce` /
/// `closeBottomSheet` guard fires.
///
/// Preserves the pre-lift `ensureUnderWallClock('after split fleet')` literal
/// both fleet `testWidgets` bodies emitted so the
/// `colonizethis-e2e-ui-stability.mdc` 5-minute fail-fast attribution stays
/// keyed on the same checkpoint string across the lift. Refs GitHub #2336
/// AC1 / AC2.
const String kE2eDefaultFleetReachPreambleAfterSplitFleetStep =
    'after split fleet';

/// Result of [e2eEnterFleetReachScenarioReady].
///
/// Carries the four post-preamble handles each fleet `testWidgets` body
/// consumes for the rest of the scenario:
///
/// - [perf]: scenario-scoped [E2ePerfLog] (test name forwarded from the
///   helper's `testName` argument). The helper emits the
///   `bootstrap_for_integration_test` timing slice into this log before
///   returning; call sites continue to drive
///   `splitHomeFleetOnce` / `closeBottomSheet` / `fleetReachTurnLoop` /
///   `advanceOneHumanTurn` / etc. against the same log so the
///   `E2E_TIMING|test=<testName>|...` attribution stays stable.
/// - [testSw]: wall-clock stopwatch the call site stops at
///   `perf.timing('test_total', testSw.elapsed, ...)` time. Started by the
///   helper before the `expect(kCtE2EEnabled, isTrue, ...)` gate so the
///   final `test_total` slice covers the same span the pre-lift inline
///   blocks did.
/// - [l10n]: English [AppLocalizations] handle obtained via
///   [lookupAppLocalizations] after the post-`bootstrapNewGameToMap` guard.
///   Used by [e2eAdvanceOneHumanTurn] / [e2eSplitHomeFleetOnce] /
///   [e2eDismissCtDialogShellIfPresent] / etc. downstream.
/// - [ensureUnderWallClock]: 5-minute wall-clock guard closure produced
///   inside the helper (`e2eMakeWallClockGuard(testName: ..., stopwatch: ...,
///   cap: ...)`). Call sites pass it through to
///   `fleetReachTurnLoop(ensureUnderWallClock: ...)` and emit per-checkpoint
///   `ensureUnderWallClock('after <step>')` calls between phases per
///   `colonizethis-e2e-ui-stability.mdc` / `SPEC/program/e2e-integration-tests.md`
///   § Determinism PR runtime rule.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
class E2eFleetReachScenarioPreamble {
  const E2eFleetReachScenarioPreamble({
    required this.perf,
    required this.testSw,
    required this.l10n,
    required this.ensureUnderWallClock,
  });

  /// Scenario-scoped perf log; downstream phases continue to forward it
  /// into shared helpers so the `E2E_TIMING|test=<testName>|...` attribution
  /// remains stable.
  final E2ePerfLog perf;

  /// Wall-clock stopwatch started inside the helper at the
  /// `expect(kCtE2EEnabled, isTrue, ...)` gate. Call sites stop measuring
  /// against it at `perf.timing('test_total', testSw.elapsed, ...)` time.
  final Stopwatch testSw;

  /// English app localizations the rest of the scenario consumes for
  /// confirm-button labels and dialog-close text.
  final AppLocalizations l10n;

  /// Wall-clock guard closure produced by [e2eMakeWallClockGuard]. Call
  /// sites pass it into `fleetReachTurnLoop(ensureUnderWallClock: ...)` and
  /// emit per-checkpoint `ensureUnderWallClock('after <step>')` calls.
  final void Function(String step) ensureUnderWallClock;
}

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
  String afterSplitFleetStep =
      kE2eDefaultFleetReachPreambleAfterSplitFleetStep,
}) async {
  final perf = E2ePerfLog(testName);
  final testSw = Stopwatch()..start();
  expect(
    kCtE2EEnabled,
    isTrue,
    reason:
        'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
  );

  await tester.binding.setSurfaceSize(surfaceSize);
  final bootstrapSw = Stopwatch()..start();
  await bootstrapForIntegrationTest();
  await tester.pump();
  await e2eWaitForNewGameEntry(tester, perf: perf);
  perf.timing(bootstrapTimingPhase, bootstrapSw.elapsed);
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
