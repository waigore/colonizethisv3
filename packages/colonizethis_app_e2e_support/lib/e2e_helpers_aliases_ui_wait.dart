/// AC1 UI wait / opener aliases (Refs #4075 AC3 / #4344 Slice B).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

Future<void> pumpFor(WidgetTester tester, Duration total) =>
    e2ePumpFor(tester, total);

Future<void> waitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) => e2eWaitUntilFound(
  tester,
  finder,
  timeout: timeout,
  diagnoseAfter: diagnoseAfter,
  perf: perf,
  phaseName: phaseName,
);

Future<void> dismissTransientUi(WidgetTester tester, {E2ePerfLog? perf}) =>
    e2eDismissTransientUi(tester, perf: perf);

/// AC1 alias for [e2eEnsureVisibleAndTapHitTestable] (Refs #2336 / #4075).
Future<bool> ensureVisibleAndTapHitTestable(
  WidgetTester tester,
  Finder trigger,
) => e2eEnsureVisibleAndTapHitTestable(tester, trigger);

/// AC1 alias for [e2eAwaitPanelMountAfterOpenerTap] (Refs #2336 / #4075).
Future<bool> awaitPanelMountAfterOpenerTap(
  WidgetTester tester,
  Finder panelRoot, {
  required Duration timeout,
  E2ePerfLog? perf,
  required String phaseName,
}) => e2eAwaitPanelMountAfterOpenerTap(
  tester,
  panelRoot,
  timeout: timeout,
  perf: perf,
  phaseName: phaseName,
);

/// AC1 alias for [e2eClosePanelOpenerSheetAndAwaitOpener] (Refs #2336 / #4075).
Future<void> closePanelOpenerSheetAndAwaitOpener(
  WidgetTester tester, {
  required Finder primary,
  Finder? secondary,
  required String afterSheetClearPhase,
  required String awaitOpenerPhase,
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  Duration sheetClearTimeout = const Duration(seconds: 2),
  Duration awaitOpenerTimeout = const Duration(seconds: 3),
}) => e2eClosePanelOpenerSheetAndAwaitOpener(
  tester,
  primary: primary,
  secondary: secondary,
  afterSheetClearPhase: afterSheetClearPhase,
  awaitOpenerPhase: awaitOpenerPhase,
  perf: perf,
  bottomSheetCloseTimeout: bottomSheetCloseTimeout,
  sheetClearTimeout: sheetClearTimeout,
  awaitOpenerTimeout: awaitOpenerTimeout,
);

/// AC1 alias for [e2eOpenerTapTriggerAndAwaitMount] (Refs #2336 / #4075).
Future<bool> openerTapTriggerAndAwaitMount(
  WidgetTester tester, {
  required Finder trigger,
  required Finder panelRoot,
  required Duration mountTimeout,
  required String mountPhaseName,
  E2ePerfLog? perf,
}) => e2eOpenerTapTriggerAndAwaitMount(
  tester,
  trigger: trigger,
  panelRoot: panelRoot,
  mountTimeout: mountTimeout,
  mountPhaseName: mountPhaseName,
  perf: perf,
);

/// AC1 alias for [e2eOpenPanelViaRailOrMarker] (Refs #2336 / #4075).
Future<void> openPanelViaRailOrMarker(
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
}) => e2eOpenPanelViaRailOrMarker(
  tester,
  openerLabel: openerLabel,
  railButton: railButton,
  markerButton: markerButton,
  panelRoot: panelRoot,
  afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
  timeoutMessageBuilder: timeoutMessageBuilder,
  overallTimeout: overallTimeout,
  bottomSheetCloseTimeout: bottomSheetCloseTimeout,
  mountTimeout: mountTimeout,
  perf: perf,
);

