import 'package:flutter/widgets.dart';

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

