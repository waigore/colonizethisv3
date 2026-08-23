import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Implementation of [e2eOpenPanelViaRailOrMarker] (Refs #4598 Slice A).
Future<void> runE2eOpenPanelViaRailOrMarker(
  WidgetTester tester, {
  required String openerLabel,
  required Finder railButton,
  required Finder markerButton,
  required Finder panelRoot,
  required String afterSheetPanelsClearPhase,
  required String Function(Duration timeout) timeoutMessageBuilder,
  Duration overallTimeout = const Duration(seconds: 20),
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  Duration mountTimeout = const Duration(seconds: 3),
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  final timingLabel = 'open_panel_$openerLabel';
  final mountPhaseName = 'pump_until_${openerLabel}_panel_after_trigger_tap';
  final railWaitPhase = 'wait_until_${openerLabel}_rail_hit_testable';
  final markerWaitPhase = 'wait_until_${openerLabel}_marker_hit_testable';
  final railOrMarkerPumpPhase =
      'pump_until_${openerLabel}_rail_or_marker_hit_testable';
  final awaitOpenerAfterSheetClosePhase =
      'pump_until_${openerLabel}_opener_after_sheet_close';

  Future<bool> tryOpen(Finder trigger) => e2eOpenerTapTriggerAndAwaitMount(
    tester,
    trigger: trigger,
    panelRoot: panelRoot,
    mountTimeout: mountTimeout,
    mountPhaseName: mountPhaseName,
    perf: perf,
  );

  if (panelRoot.hitTestable().evaluate().isNotEmpty) {
    perf?.timing(timingLabel, sw.elapsed);
    return;
  }
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);

  var panelPollMs = 25;
  while (sw.elapsed < overallTimeout) {
    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eClosePanelOpenerSheetAndAwaitOpener(
        tester,
        primary: railButton,
        secondary: markerButton,
        afterSheetClearPhase: afterSheetPanelsClearPhase,
        awaitOpenerPhase: awaitOpenerAfterSheetClosePhase,
        perf: perf,
        bottomSheetCloseTimeout: bottomSheetCloseTimeout,
      );
      panelPollMs = 25;
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty ||
        find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      panelPollMs = 25;
      continue;
    }
    if (railButton.evaluate().isNotEmpty) {
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: railButton,
        secondary: markerButton,
        perf: perf,
        phaseName: railWaitPhase,
      );
      if (await tryOpen(railButton)) {
        perf?.timing(timingLabel, sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (markerButton.evaluate().isNotEmpty) {
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: markerButton,
        secondary: railButton,
        perf: perf,
        phaseName: markerWaitPhase,
      );
      if (await tryOpen(markerButton)) {
        perf?.timing(timingLabel, sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          railButton.hitTestable().evaluate().isNotEmpty ||
          markerButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: panelPollMs),
      perf: perf,
      phaseName: railOrMarkerPumpPhase,
    )) {
      panelPollMs = 25;
      continue;
    }
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    '${timeoutMessageBuilder(overallTimeout)}. '
    'Last exception: ${tester.takeException()}',
  );
}
