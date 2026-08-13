/// AC1 UI panel / dismiss / turn aliases (Refs #4075 AC3 / #4344 Slice B).
library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

/// AC1 alias for [e2eDismissAlertDialogIfPresent] (Refs #2336 / #4075).
Future<bool> dismissAlertDialogIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultAlertDialogDismissTimeout,
  List<String> dismissLabels = kE2eDefaultAlertDialogDismissLabels,
}) => e2eDismissAlertDialogIfPresent(
  tester,
  perf: perf,
  dismissTimeout: dismissTimeout,
  dismissLabels: dismissLabels,
);

/// AC1 alias for [e2eDismissGenericOkIfPresent] (Refs #2336 / #4075).
Future<bool> dismissGenericOkIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultGenericOkDismissTimeout,
  String label = kE2eDefaultGenericOkLabel,
}) => e2eDismissGenericOkIfPresent(
  tester,
  perf: perf,
  dismissTimeout: dismissTimeout,
  label: label,
);

/// AC1 alias for [e2eDismissCtDialogShellBroadSweepIfPresent] (Refs #2336 / #4075).
Future<bool> dismissCtDialogShellBroadSweepIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultCtDialogShellBroadSweepDismissTimeout,
}) => e2eDismissCtDialogShellBroadSweepIfPresent(
  tester,
  perf: perf,
  dismissTimeout: dismissTimeout,
);

/// AC1 alias for [e2eDismissCtDialogShellIfPresent] (Refs #2336 / #4075).
Future<bool> dismissCtDialogShellIfPresent(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration shellCloseTimeout = kE2eDefaultCtDialogShellCloseTimeout,
  String phaseName = kE2eDefaultCtDialogShellClosePhase,
}) => e2eDismissCtDialogShellIfPresent(
  tester,
  l10n,
  perf: perf,
  shellCloseTimeout: shellCloseTimeout,
  phaseName: phaseName,
);

/// AC1 alias for [e2eDismissCtDialogShellWithPopRouteEscalation] (Refs #2336 / #4075).
Future<bool> dismissCtDialogShellWithPopRouteEscalation(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration escalationTimeout = kE2eDefaultCtDialogShellEscalationTimeout,
  String escalationPhase = kE2eDefaultCtDialogShellEscalationPhase,
}) => e2eDismissCtDialogShellWithPopRouteEscalation(
  tester,
  perf: perf,
  escalationTimeout: escalationTimeout,
  escalationPhase: escalationPhase,
);

/// AC1 alias for [e2eDismissSnackBarIfPresent] (Refs #2336 / #4075).
Future<bool> dismissSnackBarIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultSnackBarDismissTimeout,
}) => e2eDismissSnackBarIfPresent(
  tester,
  perf: perf,
  dismissTimeout: dismissTimeout,
);

Future<void> openCivilianPanel(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_civilian_open',
}) => e2eOpenCivilianPanel(
  tester,
  timeout: timeout,
  perf: perf,
  bottomSheetCloseTimeout: bottomSheetCloseTimeout,
  afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
);

Future<void> openNavalPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) => e2eOpenNavalPanel(
  tester,
  perf: perf,
  timeout: timeout,
  bottomSheetCloseTimeout: bottomSheetCloseTimeout,
);

Future<void> openProductionPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 20),
}) => e2eOpenProductionPanel(tester, perf: perf, timeout: timeout);

Future<void> openPanelFromMarker(
  WidgetTester tester, {
  required Finder markerButton,
  required Finder panelRoot,
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
}) => e2eOpenPanelFromMarker(
  tester,
  markerButton: markerButton,
  panelRoot: panelRoot,
  timeout: timeout,
  perf: perf,
);

Future<Duration> waitForNextTurnLabelAdvance(
  WidgetTester tester, {
  required String turnLabelBefore,
  required Duration timeout,
  E2ePerfLog? perf,
}) => e2eWaitForNextTurnLabelAdvance(
  tester,
  turnLabelBefore: turnLabelBefore,
  timeout: timeout,
  perf: perf,
);

Future<Duration> advanceOneHumanTurn(
  WidgetTester tester, {
  required AppLocalizations l10n,
  E2ePerfLog? perf,
  Duration timeout = kE2eNextTurnResolutionTimeout,
}) => e2eAdvanceOneHumanTurn(tester, l10n: l10n, perf: perf, timeout: timeout);

Future<void> closeBottomSheet(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) => e2eCloseBottomSheet(tester, perf: perf, overallTimeout: overallTimeout);

Future<void> bootstrapNewGameToMap(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallCap = const Duration(seconds: 60),
  String? advancedStartOptionLabel,
}) => e2eBootstrapNewGameToMap(
  tester,
  perf: perf,
  overallCap: overallCap,
  advancedStartOptionLabel: advancedStartOptionLabel,
);

void collectTextPreorder(Element element, List<String> out) =>
    e2eCollectTextPreorder(element, out);

Future<void> expandEachExpansionTileOnce(WidgetTester tester) =>
    e2eExpandEachExpansionTileOnce(tester);
