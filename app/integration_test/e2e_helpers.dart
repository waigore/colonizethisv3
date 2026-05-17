/// Stable public names for ColonizeThis integration/E2E helpers (GitHub #2336 AC1).
///
/// Implementations live in [e2e_test_shared.dart]; this library delegates to the
/// `e2e*` entrypoints so new scenarios can depend on the AC1 checklist names
/// (`openProductionPanel`, `waitForNextTurnLabelAdvance`, etc.).
library;

import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';
import 'e2e_test_shared_bootstrap.dart';

/// Re-export shared polling / settle entrypoints so scenarios depend on this
/// barrel only (GitHub #2336 AC2).
export 'e2e_test_shared.dart' show
    E2ePerfLog,
    e2eAdaptivePollRampAfterIdle,
    e2eNewWorldRegionChipAppearsSelected,
    e2eOldWorldRegionChipAppearsSelected,
    e2ePumpUntil,
    e2ePumpUntilConditionOrIdle,
    e2eWaitForNewGameEntry,
    e2eWaitForNextTurnLabelAdvance,
    e2eWaitUntilAnyFinderHitTestable,
    e2eOpenProductionPanel,
    e2eOpenPanelFromMarker;

Future<void> pumpFor(WidgetTester tester, Duration total) =>
    e2ePumpFor(tester, total);

Future<void> waitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) =>
    e2eWaitUntilFound(
      tester,
      finder,
      timeout: timeout,
      diagnoseAfter: diagnoseAfter,
      perf: perf,
      phaseName: phaseName,
    );

Future<void> dismissTransientUi(
  WidgetTester tester, {
  E2ePerfLog? perf,
}) =>
    e2eDismissTransientUi(tester, perf: perf);

Future<void> openCivilianPanel(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_civilian_open',
}) =>
    e2eOpenCivilianPanel(
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
}) =>
    e2eOpenNavalPanel(
      tester,
      perf: perf,
      timeout: timeout,
      bottomSheetCloseTimeout: bottomSheetCloseTimeout,
    );

Future<void> openProductionPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 20),
}) =>
    e2eOpenProductionPanel(tester, perf: perf, timeout: timeout);

Future<void> openPanelFromMarker(
  WidgetTester tester, {
  required Finder markerButton,
  required Finder panelRoot,
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
}) =>
    e2eOpenPanelFromMarker(
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
}) =>
    e2eWaitForNextTurnLabelAdvance(
      tester,
      turnLabelBefore: turnLabelBefore,
      timeout: timeout,
      perf: perf,
    );

Future<void> closeBottomSheet(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) =>
    e2eCloseBottomSheet(
      tester,
      perf: perf,
      overallTimeout: overallTimeout,
    );

Future<void> bootstrapNewGameToMap(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallCap = const Duration(seconds: 60),
}) =>
    e2eBootstrapNewGameToMap(tester, perf: perf, overallCap: overallCap);

void collectTextPreorder(Element element, List<String> out) =>
    e2eCollectTextPreorder(element, out);

Future<void> expandEachExpansionTileOnce(WidgetTester tester) =>
    e2eExpandEachExpansionTileOnce(tester);

Future<void> splitHomeFleetOnce(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration openNavalTimeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) =>
    e2eSplitHomeFleetOnce(
      tester,
      l10n,
      perf: perf,
      openNavalTimeout: openNavalTimeout,
      bottomSheetCloseTimeout: bottomSheetCloseTimeout,
    );

Future<void> tapFirstAssignInCivilianPanel(WidgetTester tester) =>
    e2eTapFirstAssignInCivilianPanel(tester);

Future<void> tapAssignOnCivilianRowWithTitle(
  WidgetTester tester,
  String unitTypeTitle,
) =>
    e2eTapAssignOnCivilianRowWithTitle(tester, unitTypeTitle);

Future<void> ensureAllRelocated64pxPngsLoad() =>
    e2eEnsureAllRelocated64pxPngsLoad();

Future<void> ensureAllRelocated64pxPngsLoadSuiteOnce() =>
    e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
