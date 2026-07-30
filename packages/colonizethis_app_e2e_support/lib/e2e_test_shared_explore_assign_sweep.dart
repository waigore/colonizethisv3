import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show ctE2eCivilianPanelSnapshot;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

const Duration kE2eDefaultBundledExploreSweepWait = Duration(seconds: 5);

/// Returns `true` when at least one civilian unit row exposes an **enabled**
/// `Explore` assign target reachable through the civilian panel
/// ([kCtE2ECivilianPanelRootKey]).
///
/// Lifted from the formerly private `_anyExplorerHasEnabledExploreAssignFleetE2e`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). The fleet bundled-Explore retry
/// loop in `new_game_fleet_reaches_new_world_e2e_test.dart` calls this
/// helper through the AC1 barrel alias `anyExplorerHasEnabledExploreAssignFleet`
/// up to `maxBoundedTurnRetries (8)` times per scenario, so a silent rename
/// / fail-open here would stall the retry loop on the slow `maxPanelSweepSteps
/// (16) × per-step Assign sweep` path — Bottleneck 5 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart`
/// carries the behavioural contract.
///
/// Contract:
///
/// - First, consults [e2eExploreAssignEnabledFromCivilianSnapshot] with the
///   current [ctE2eCivilianPanelSnapshot]. A non-`null` snapshot result is
///   returned verbatim (`true` / `false`); the panel-sweep walk is only
///   entered when the snapshot is `null` (no plumbing yet this turn).
/// - Expects exactly one [ListView] descendant of [kCtE2ECivilianPanelRootKey];
///   throws via [expect] otherwise (fail-fast on a malformed panel — the
///   pre-#2336 helper had the same precondition).
/// - Walks `Assign` text rows under that ListView in tree order, tapping
///   each unique button (identityHashCode-deduped) and bounded-polling for
///   an `Explore` [ListTile] to mount.
/// - When the tapped row's `Explore` tile appears and reports
///   `enabled == true`, returns `true`. When `enabled == false`, dismisses
///   the assign sheet and continues the sweep.
/// - When the sweep exhausts [maxPanelSweepSteps] (defaults to **16**, the
///   narrowed bound from issue #2336 § Bottleneck 5 / AC1; the pre-#2336
///   helper used 24), returns `false`.
/// - **Fast-path exit when the panel has stabilized** (Refs GitHub #2336
///   § Bottleneck 5 / AC5 / Proposed work item 5): when two consecutive
///   sweep steps add zero new `Assign` widgets to the `visitedAssignWidgets`
///   identity set, the helper returns `false` without paying the remaining
///   drag-and-pump cycles. The two-step buffer absorbs a single transient
///   frame where freshly dragged rows have not yet attached to the tree,
///   matching the conservative "settle once before declaring stable"
///   contract the rest of the bundled-Explore retry path uses. A single
///   empty step never short-circuits.
/// - Between sweep steps, drags the panel `Scrollable` upward by
///   `Offset(0, -180)` and pumps a single 25 ms frame so the next iteration
///   can short-circuit on freshly revealed `Assign` rows without paying a
///   leading fixed-delay settle (AC5 adaptive polling).
/// - The `Explore`-tile-settled and assign-sheet-dismissed waits are
///   bounded by [maxUiResponseWait] (5 s default, the legacy constant) and
///   a 400 ms dismissed-poll respectively; both ramp via
///   [e2eAdaptivePollRampAfterIdle].
Future<bool> e2eAnyExplorerHasEnabledExploreAssignFleet(
  WidgetTester tester, {
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxPanelSweepSteps = 16,
}) async {
  final snapshotHint = e2eExploreAssignEnabledFromCivilianSnapshot(
    ctE2eCivilianPanelSnapshot,
  );
  if (snapshotHint != null) {
    return snapshotHint;
  }

  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final exploreTile = find.widgetWithText(ListTile, 'Explore');
  // Adaptive replacement (#2336 AC5 / Bottleneck 5): the prior 300ms post-tap
  // settle plus 50ms fixed wait loop is replaced by a single condition-based
  // wait that evaluates [exploreTile] before the first pump and ramps the
  // pump interval via [e2eAdaptivePollRampAfterIdle]. The hard
  // [maxUiResponseWait] cap is preserved.
  Future<void> waitForAssignSheetSettled() async {
    final wait = Stopwatch()..start();
    var assignPollMs = 25;
    while (wait.elapsed < maxUiResponseWait) {
      if (exploreTile.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(Duration(milliseconds: assignPollMs));
      assignPollMs = e2eAdaptivePollRampAfterIdle(assignPollMs);
    }
  }

  // After [handlePopRoute] the assign sheet can take a frame or two to leave
  // the tree. Replace the prior fixed 200ms pump with a bounded adaptive
  // poll that returns as soon as the sheet finishes dismissing.
  Future<void> waitForAssignSheetDismissed() async {
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => exploreTile.evaluate().isEmpty,
      timeout: const Duration(milliseconds: 400),
      phaseName: 'pump_until_assign_sheet_dismissed',
    );
  }

  final visitedAssignWidgets = <int>{};
  // Refs GitHub #2336 § Bottleneck 5 / AC5 / Proposed work item 5: track
  // consecutive sweep steps that added zero new Assign widgets so the helper
  // can exit early once the panel has stopped revealing new rows. A
  // single empty step is tolerated to absorb one transient post-drag frame
  // before the freshly dragged rows are attached to the element tree; a
  // second consecutive empty step is treated as evidence the panel has
  // stabilized and the remaining sweep budget is unproductive.
  var consecutiveEmptyStepsAfterDrag = 0;
  for (var step = 0; step < maxPanelSweepSteps; step++) {
    final assignCandidates = find
        .descendant(of: listView, matching: find.text('Assign'))
        .evaluate()
        .toList();
    var newAssignWidgetsThisStep = 0;
    for (final assignElement in assignCandidates) {
      final marker = identityHashCode(assignElement.widget);
      if (!visitedAssignWidgets.add(marker)) {
        continue;
      }
      newAssignWidgetsThisStep++;
      final assignFinder = find.byWidget(assignElement.widget);
      try {
        await tester.ensureVisible(assignFinder);
      } catch (_) {
        continue;
      }
      await tester.tap(assignFinder.first, warnIfMissed: false);
      await waitForAssignSheetSettled();
      if (exploreTile.evaluate().isNotEmpty) {
        final enabled = tester.widget<ListTile>(exploreTile.first).enabled;
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
        if (enabled == true) {
          return true;
        }
      } else {
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
      }
    }

    if (newAssignWidgetsThisStep == 0) {
      consecutiveEmptyStepsAfterDrag++;
      if (consecutiveEmptyStepsAfterDrag >= 2) {
        return false;
      }
    } else {
      consecutiveEmptyStepsAfterDrag = 0;
    }

    await tester.drag(panelScrollable, const Offset(0, -180));
    // Adaptive replacement for the prior 120ms post-drag settle (#2336 AC5):
    // pump a single short frame and let the next iteration short-circuit if
    // new Assign rows are already visible.
    await tester.pump(const Duration(milliseconds: 25));
  }
  return false;
}
