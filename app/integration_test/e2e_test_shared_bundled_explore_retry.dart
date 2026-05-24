import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default upper bound on the bounded retry window used by
/// [e2eAwaitExploreEnabledFromCivilianPanel].
///
/// Mirrors the legacy `maxBoundedTurnRetries = 8` literal in the
/// post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart`. Linux CI can lag
/// reveal/suggestion propagation by a few turns after the New World fleet
/// arrival, so the retry window must be wide enough to absorb that lag
/// without inflating the wall-clock budget #2336 is reducing. Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5.
const int kE2eDefaultBundledExploreMaxTurnRetries = 8;

/// Default `perf.bumpCounter(...)` name used by
/// [e2eAwaitExploreEnabledFromCivilianPanel] for the per-retry-iteration
/// counter.
///
/// Mirrors the pre-lift inline `perf.bumpCounter('bundled_explore_retry_iterations')`
/// call in `new_game_fleet_reaches_new_world_e2e_test.dart` so downstream
/// `E2E_COUNTER|test=...|name=bundled_explore_retry_iterations|...` log
/// scrapers and AC8 dashboards keyed on this counter remain stable
/// across the lift (Refs GitHub #2336 AC1 / AC2). A silent rename would
/// orphan every dashboard counting bounded retry iterations.
const String kE2eDefaultBundledExploreRetryIterationCounter =
    'bundled_explore_retry_iterations';

/// Awaits an enabled Explore assign target on the civilian panel, retrying
/// up to [maxBoundedTurnRetries] turns when the initial check fails.
///
/// Lifted from the formerly inline
/// `var exploreEnabled = await checkExploreEnabledFromCivilianPanel(...);
/// for (var retryIdx = 0; !exploreEnabled && retryIdx <
/// maxBoundedTurnRetries; retryIdx++) { ... }` block in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` so the bounded
/// retry-loop contract is shared and unit-pinned (Refs GitHub #2336 AC1 /
/// AC2 / AC5 / Bottleneck 5). The post-bundle Explore scenario calls the
/// lifted form through the AC1 barrel alias
/// `awaitExploreEnabledFromCivilianPanel` (`e2e_helpers.dart`); the
/// widget-test pin in
/// `app/test/e2e_await_explore_enabled_from_civilian_panel_test.dart`
/// guards against silent regressions because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression that
/// dropped the per-iteration `bumpCounter` call would orphan every AC8
/// dashboard counting bounded retry iterations; one that swapped the
/// inner sequence would reorder Explore-enabled detection against the
/// post-turn region-tab settle and silently mask Bottleneck 5
/// regressions.
///
/// Contract:
///
/// - Calls [e2eCheckExploreEnabledFromCivilianPanel] once with [perf] and
///   [maxUiResponseWait] forwarded verbatim. Returns immediately when the
///   first check reports `true` (no retry-iteration counter bump).
/// - Otherwise enters a bounded retry loop of at most
///   [maxBoundedTurnRetries] iterations (default
///   [kE2eDefaultBundledExploreMaxTurnRetries] = 8). Each iteration:
///     1. Increments [perf]'s [retryIterationCounter] (default
///        [kE2eDefaultBundledExploreRetryIterationCounter] =
///        `bundled_explore_retry_iterations`) by one. The call is guarded
///        by `perf?.bumpCounter(...)` so the helper can run without a
///        perf log in unit-test fixtures.
///     2. Advances one human turn via [e2eAdvanceOneHumanTurn] using
///        [l10n] for the confirm-button label.
///     3. Dismisses transient UI via [e2eDismissTransientUi].
///     4. Reselects the New World region tab via
///        [e2eTapNewWorldRegionTabIfPresent] (no-op when the keyed
///        subtree is absent — matches the pre-lift contract).
///     5. Re-runs [e2eCheckExploreEnabledFromCivilianPanel] with the same
///        forwarding semantics; updates the loop's `enabled` state.
/// - Returns the final [bool] state — `true` if any iteration's check
///   succeeded, `false` if every iteration in the bounded window
///   reported `false`. The caller is responsible for the final failure
///   path (issue-#1869 regression diagnostics + bounded-retry topology
///   skip guard).
///
/// The function is **not** pure with respect to the widget tree: it
/// drives next-turn taps and panel openers as side effects. It is pure
/// with respect to its inputs in the sense that identical sequences of
/// UI responses yield identical return values (Refs #2336 AC2 / Bottleneck
/// 5 dedup goal). [perf] is nullable so unit-test fixtures can exercise
/// the contract without instantiating a perf log; the post-bundle
/// integration scenario passes the scenario perf log so retry counters
/// attribute correctly to the running test.
Future<bool> e2eAwaitExploreEnabledFromCivilianPanel(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxBoundedTurnRetries = kE2eDefaultBundledExploreMaxTurnRetries,
  String retryIterationCounter =
      kE2eDefaultBundledExploreRetryIterationCounter,
}) async {
  var enabled = await e2eCheckExploreEnabledFromCivilianPanel(
    tester,
    perf: perf,
    maxUiResponseWait: maxUiResponseWait,
  );
  for (
    var retryIdx = 0;
    !enabled && retryIdx < maxBoundedTurnRetries;
    retryIdx++
  ) {
    perf?.bumpCounter(retryIterationCounter);
    await e2eAdvanceOneHumanTurn(tester, l10n: l10n, perf: perf);
    await e2eDismissTransientUi(tester, perf: perf);
    await e2eTapNewWorldRegionTabIfPresent(tester);
    enabled = await e2eCheckExploreEnabledFromCivilianPanel(
      tester,
      perf: perf,
      maxUiResponseWait: maxUiResponseWait,
    );
  }
  return enabled;
}
