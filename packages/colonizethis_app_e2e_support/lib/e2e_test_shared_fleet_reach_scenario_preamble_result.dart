import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling.dart';

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

