import 'package:flutter/widgets.dart';

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
const String kE2eDefaultFleetReachPreambleAfterBootstrapStep =
    'after bootstrap';

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

