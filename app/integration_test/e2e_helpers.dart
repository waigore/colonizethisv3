/// Stable public names for ColonizeThis integration/E2E helpers (GitHub #2336 AC1).
///
/// Implementations live in [e2e_test_shared.dart]; this library delegates to the
/// `e2e*` entrypoints so new scenarios can depend on the AC1 checklist names.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

export 'e2e_test_shared.dart' show E2ePerfLog;

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

Future<void> ensureAllRelocated64pxPngsLoad() =>
    e2eEnsureAllRelocated64pxPngsLoad();

Future<void> ensureAllRelocated64pxPngsLoadSuiteOnce() =>
    e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
