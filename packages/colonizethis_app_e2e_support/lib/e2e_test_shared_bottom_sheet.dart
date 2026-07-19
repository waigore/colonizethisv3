import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Default cap for bottom-sheet close polling (GitHub #2336).
const Duration kE2eDefaultBottomSheetCloseTimeout = Duration(seconds: 5);

/// Closes an open [BottomSheet] by issuing a single back-route pop and polling
/// until the sheet leaves the widget tree.
///
/// Shared by full-turn and fleet E2E; [overallTimeout] defaults to
/// [kE2eDefaultBottomSheetCloseTimeout] (previous per-file caps).
///
/// **Why pop once:** the previous implementation called
/// [tester.binding.handlePopRoute] on every poll iteration, even while the
/// dismiss animation was already running. A single pop initiates the dismiss;
/// subsequent calls are wasted work and prevent the loop from short-circuiting
/// on the post-dismiss frame. The replacement pops once, then delegates to
/// [e2ePumpUntilConditionOrIdle] so the loop exits the moment the sheet is
/// gone. If the first pop is dropped (rare; route stack stale), a single
/// retry pop is issued before falling back to the failure path. Refs
/// GitHub #2336 (`pump-reduction` slice).
Future<void> e2eCloseBottomSheet(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) async {
  perf?.bumpCounter('close_bottom_sheet_calls');
  bool anyPanelOpen() => find.byType(BottomSheet).evaluate().isNotEmpty;

  if (!anyPanelOpen()) {
    return;
  }

  final sw = Stopwatch()..start();
  await tester.binding.handlePopRoute();
  final firstWindow = overallTimeout < const Duration(seconds: 2)
      ? overallTimeout
      : const Duration(seconds: 2);
  if (await e2ePumpUntilConditionOrIdle(
    tester,
    () => !anyPanelOpen(),
    timeout: firstWindow,
    perf: perf,
    phaseName: 'pump_until_bottom_sheet_closed_after_pop',
  )) {
    perf?.timing('close_bottom_sheet', sw.elapsed);
    return;
  }
  if (!anyPanelOpen()) {
    perf?.timing('close_bottom_sheet', sw.elapsed);
    return;
  }
  // First pop may be dropped if the route stack changed mid-frame (e.g. an
  // overlay raced the pop). Retry once, then wait out the remaining budget.
  await tester.binding.handlePopRoute();
  final remaining = overallTimeout - sw.elapsed;
  if (remaining > Duration.zero) {
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => !anyPanelOpen(),
      timeout: remaining,
      perf: perf,
      phaseName: 'pump_until_bottom_sheet_closed_after_retry',
    );
  }
  if (!anyPanelOpen()) {
    perf?.timing('close_bottom_sheet', sw.elapsed);
    return;
  }

  fail(
    'Timed out after ${overallTimeout.inSeconds}s closing bottom sheet; '
    'panels remained visible',
  );
}
