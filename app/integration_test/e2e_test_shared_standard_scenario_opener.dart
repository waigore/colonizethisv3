import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';
import 'e2e_test_shared_bootstrap.dart';

/// Default surface size set by [e2eEnterStandardE2eScenario] before calling
/// the injected `bootstrapForIntegrationTest`.
///
/// Mirrors the pre-lift `await tester.binding.setSurfaceSize(const
/// Size(1280, 720))` literal used by both `testWidgets` bodies in
/// `new_game_full_turn_e2e_test.dart` and
/// `new_game_capital_panel_e2e_test.dart`. A silent drift here would change
/// Flame viewport sizing and could invalidate visibility-based locators
/// downstream. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
const Size kE2eDefaultStandardScenarioOpenerSurfaceSize = Size(1280, 720);

/// Default [Locale] passed to [lookupAppLocalizations] inside
/// [e2eEnterStandardE2eScenario].
///
/// Pre-lift full-turn and capital-panel scenarios hard-coded
/// `const Locale('en')`. Surfacing the literal as a constant lets the
/// post-lift helper accept locale overrides from future bilingual / RTL E2E
/// scenarios without forking the opener (Refs GitHub #2336 AC1 / AC2).
const Locale kE2eDefaultStandardScenarioOpenerLocale = Locale('en');

/// Default `E2E_TIMING|...|phase=...` label emitted by
/// [e2eEnterStandardE2eScenario] for the bootstrap-for-integration-test
/// timing slice.
///
/// Preserves the pre-lift `perf.timing('bootstrap_for_integration_test',
/// bootstrapSw.elapsed)` literal both `testWidgets` bodies emitted so
/// downstream `E2E_TIMING|...|phase=bootstrap_for_integration_test` log
/// scrapers / AC8 dashboards keyed on this phase remain stable across the
/// lift. Refs GitHub #2336 AC1 / AC2.
const String kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase =
    'bootstrap_for_integration_test';

/// Default `ensureUnderWallClock(...)` checkpoint label emitted by
/// [e2eEnterStandardE2eScenario] after the post-`bootstrapForIntegrationTest`
/// guard fires.
///
/// Preserves the pre-lift
/// `ensureUnderWallClock('after bootstrap_for_integration_test')` literal
/// both `testWidgets` bodies emitted so the
/// `colonizethis-e2e-ui-stability.mdc` 5-minute fail-fast attribution stays
/// keyed on the same checkpoint string across the lift. Refs GitHub #2336
/// AC1 / AC2.
const String kE2eDefaultStandardScenarioOpenerAfterBootstrapStep =
    'after bootstrap_for_integration_test';

/// Default `E2E_TIMING|...|phase=...` label emitted by
/// [e2eEnterStandardE2eScenario] for the relocated-64px PNG suite preload
/// timing slice when `assetPreloadTimingPhase` is non-null.
///
/// Preserves the pre-lift `perf.timing('asset_preload', preloadSw.elapsed)`
/// literal that the full-turn `testWidgets` body emitted. The capital-panel
/// scenario did not previously emit this slice — call sites that wish to
/// preserve byte-identical pre-lift behaviour pass `assetPreloadTimingPhase:
/// null` instead. Refs GitHub #2336 AC1 / AC2.
const String kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase =
    'asset_preload';

/// Default `ensureUnderWallClock(...)` checkpoint label emitted by
/// [e2eEnterStandardE2eScenario] after
/// [e2eEnsureAllRelocated64pxPngsLoadSuiteOnce] returns.
///
/// Preserves the pre-lift `ensureUnderWallClock('after asset_preload')`
/// literal both `testWidgets` bodies emitted so the fail-fast attribution
/// stays keyed on the same checkpoint string across the lift. Refs GitHub
/// #2336 AC1 / AC2.
const String kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep =
    'after asset_preload';

/// Default `E2E_TIMING|...|phase=...` label emitted by
/// [e2eEnterStandardE2eScenario] for the outer-stopwatch
/// `bootstrapNewGameToMap` slice.
///
/// Preserves the pre-lift `perf.timing('new_game_to_map', newGameSw.elapsed)`
/// literal both `testWidgets` bodies emitted around their
/// `bootstrapNewGameToMap` call. The inner helper
/// [e2eBootstrapNewGameToMap] also emits its own `new_game_to_map` slice; the
/// outer-stopwatch literal here preserves the legacy double emission. Pass
/// `newGameToMapTimingPhase: null` to suppress only the outer emission and
/// keep the inner one. Refs GitHub #2336 AC1 / AC2.
const String kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase =
    'new_game_to_map';

/// Default `ensureUnderWallClock(...)` checkpoint label emitted by
/// [e2eEnterStandardE2eScenario] after [e2eBootstrapNewGameToMap] returns.
///
/// Preserves the pre-lift `ensureUnderWallClock('after new_game_to_map')`
/// literal both `testWidgets` bodies emitted. Refs GitHub #2336 AC1 / AC2.
const String kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep =
    'after new_game_to_map';

/// Result of [e2eEnterStandardE2eScenario].
///
/// Carries the four post-opener handles each standard `testWidgets` body
/// (full-turn, capital-panel) consumes for the rest of the scenario:
///
/// - [perf]: scenario-scoped [E2ePerfLog] (test name forwarded from the
///   helper's `testName` argument). The helper emits the
///   `bootstrap_for_integration_test` and (optionally) `asset_preload` /
///   `new_game_to_map` timing slices into this log before returning; call
///   sites continue to drive `openCivilianPanel` / `openNavalPanel` /
///   `openProductionPanel` / `advanceOneHumanTurn` / etc. against the same
///   log so the `E2E_TIMING|test=<testName>|...` attribution stays stable.
/// - [testSw]: wall-clock stopwatch. The opener uses this same stopwatch
///   for both the [ensureUnderWallClock] guard *and* the eventual
///   `perf.timing('test_total', testSw.elapsed, ...)` slice the call site
///   emits when the test completes. This mirrors the legacy
///   full-turn / capital-panel inline blocks, which started a single
///   `testSw` stopwatch and threaded it into both consumers — distinct from
///   the fleet-reach preamble, which uses a separate `wallClock` stopwatch
///   for the guard so the bootstrap-to-new-game window does not count
///   against the 5-minute wall-clock budget.
/// - [l10n]: English [AppLocalizations] handle obtained via
///   [lookupAppLocalizations] after the post-`bootstrapNewGameToMap` guard.
///   Used by [e2eAdvanceOneHumanTurn] / [e2eSplitHomeFleetOnce] /
///   [e2eDismissCtDialogShellIfPresent] / etc. downstream.
/// - [ensureUnderWallClock]: 5-minute wall-clock guard closure produced
///   inside the helper via [e2eMakeWallClockGuard] keyed on the call site's
///   `testName`. Call sites continue to emit per-checkpoint
///   `ensureUnderWallClock('after <step>')` calls between phases per
///   `colonizethis-e2e-ui-stability.mdc` /
///   `SPEC/program/e2e-integration-tests.md` § Determinism PR runtime rule.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
class E2eStandardScenarioOpener {
  const E2eStandardScenarioOpener({
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
  /// The opener also threads this stopwatch into the [ensureUnderWallClock]
  /// guard so the bootstrap and new-game windows count against the same
  /// 5-minute budget the rest of the scenario shares.
  final Stopwatch testSw;

  /// English app localizations the rest of the scenario consumes for
  /// confirm-button labels and dialog-close text.
  final AppLocalizations l10n;

  /// Wall-clock guard closure produced by [e2eMakeWallClockGuard]. Call
  /// sites emit per-checkpoint `ensureUnderWallClock('after <step>')` calls
  /// after each major phase.
  final void Function(String step) ensureUnderWallClock;
}

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
  final perf = E2ePerfLog(testName);
  final testSw = Stopwatch()..start();
  expect(
    kCtE2EEnabled,
    isTrue,
    reason:
        'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
  );

  final ensureUnderWallClock = e2eMakeWallClockGuard(
    testName: testName,
    stopwatch: testSw,
    cap: wallClockCap,
  );

  await tester.binding.setSurfaceSize(surfaceSize);

  final bootstrapSw = Stopwatch()..start();
  await bootstrapForIntegrationTest();
  await tester.pump();
  await e2eWaitForNewGameEntry(tester, perf: perf);
  perf.timing(bootstrapTimingPhase, bootstrapSw.elapsed);
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
