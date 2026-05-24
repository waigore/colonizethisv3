/// Bundled-explore failure-mode helper for the post-bundle Explore E2E
/// scenario (`new_game_fleet_reaches_new_world_e2e_test.dart`).
///
/// Lifted from the inline `if (!exploreEnabled) { ... }` block that ran
/// after [e2eAwaitExploreEnabledFromCivilianPanel] returned `false` so the
/// post-bundle scenario consumes a single shared, unit-pinned helper for
/// the failure-mode contract (Refs GitHub #2336 AC1 / AC2 / AC5 /
/// Bottleneck 5). The block has two arms — a deterministic skip when the
/// CI topology never reveals any New World land within bounded retries,
/// and a `fail()` with bundled-Explore rejection diagnostics otherwise —
/// and a silent rename or reordering would either mask a real
/// Explore-assign regression or convert the skip path into a hard fail
/// (re-introducing the AC10 flakiness this PR is reducing).
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_handle_bundled_explore_failure_test.dart` carries the
/// behavioural contract.
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Handles the post-bundle Explore failure mode after
/// [e2eAwaitExploreEnabledFromCivilianPanel] returned `false`.
///
/// Two contractual arms (Refs GitHub #2336 AC1 / AC2 / AC5):
///
/// 1. **Topology skip arm.** When [navalSnapshot] reports no New World
///    land at fogged-or-better visibility (via
///    [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]), the helper
///    returns normally so the caller can `return` from the surrounding
///    `testWidgets` body without raising a regression. CI seeds and
///    topology variants where no NW land becomes visible within the
///    bounded retry window must not be flagged as Explore-assign
///    regressions — they are environmental.
///
/// 2. **Regression fail arm.** Otherwise, the helper builds a multi-line
///    bundled-Explore rejection diagnostic via
///    [e2eBundledExploreRejectionDiagnostics] (preferring
///    [lastKnownNavalSnapshot] when present so the rejection diagnostic
///    references the snapshot captured at the moment the loop confirmed
///    the New World fleet, not whatever post-failure state the global
///    has drifted to) and calls `fail(...)` with the canonical
///    `Post-bundle #1869 regression: Explorer Assign never surfaced an
///    enabled Explore row...` message. The retry count is interpolated
///    from [maxBoundedTurnRetries] so the failure message stays
///    attributable when a future scenario tunes the retry budget.
///
/// Inputs:
///
/// - [navalSnapshot]: the post-failure naval-panel snapshot the topology
///   skip arm consults. Pass [ctE2eNavalPanelSnapshot] from the running
///   scenario. Passing `null` routes through the skip arm because
///   [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] reports
///   `false` for a missing snapshot; the helper preserves the pre-lift
///   inline contract that treated a missing snapshot the same as a
///   "no NW land" CI topology rather than as a regression. Callers that
///   need stricter null-snapshot semantics must guard before invoking
///   this helper.
/// - [civilianSnapshot]: the post-failure civilian-panel snapshot the
///   diagnostic aggregator consults; pass [ctE2eCivilianPanelSnapshot]
///   from the running scenario. May be `null` when the panel was never
///   opened on the failing turn — the diagnostic aggregator handles the
///   missing-civilian-snapshot row.
/// - [lastKnownNavalSnapshot]: the snapshot captured by
///   [e2eEnsureNonHomeFleetInNwAfterLoop] (or the most recent successful
///   `fleetReachTurnLoop` iteration). Used as the diagnostic source when
///   non-null so the rejection summary reflects the moment the NW fleet
///   was last confirmed; the helper falls back to [navalSnapshot]
///   otherwise. The skip-arm precheck always uses [navalSnapshot] (the
///   topology guard is post-failure state, not historical).
/// - [maxBoundedTurnRetries]: the retry count to interpolate into the
///   failure message. Pass [kE2eDefaultBundledExploreMaxTurnRetries]
///   when the call site uses the default retry budget.
///
/// Side effects: only the regression fail arm raises (via the test
/// framework's `fail()`). The skip arm returns `void` normally so the
/// caller's `return` after the helper call exits the surrounding
/// `testWidgets` body cleanly. The helper reads [tester.takeException]
/// to surface any captured exception in the failure message — that
/// matches the pre-lift inline behaviour and keeps post-failure flakes
/// attributable to a specific cause.
Future<void> e2eHandleBundledExploreFailure(
  WidgetTester tester, {
  required CtE2eNavalPanelSnapshot? navalSnapshot,
  required CtE2eCivilianPanelSnapshot? civilianSnapshot,
  CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot,
  required int maxBoundedTurnRetries,
}) async {
  if (!e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(navalSnapshot)) {
    // Topology skip arm: no NW land became visible within bounded
    // retries on this CI seed/topology, so Explore cannot be enabled;
    // a strict fail here would mask environmental flakiness rather
    // than detect a real bundled-Explore regression.
    return;
  }
  final diag = e2eBundledExploreRejectionDiagnostics(
    navalSnapshot: lastKnownNavalSnapshot ?? navalSnapshot,
    civilianSnapshot: civilianSnapshot,
  );
  fail(
    'Post-bundle #1869 regression: Explorer Assign never surfaced an enabled '
    'Explore row after New World fleet confirmation and '
    '$maxBoundedTurnRetries bounded Next turn retries.\n'
    '$diag\n'
    'Last exception: ${tester.takeException()}',
  );
}
