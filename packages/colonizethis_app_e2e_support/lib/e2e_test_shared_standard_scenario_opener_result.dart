import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling.dart';

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

