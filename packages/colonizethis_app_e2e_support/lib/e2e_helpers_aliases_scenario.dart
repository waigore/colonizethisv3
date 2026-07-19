/// AC1 facade aliases extracted from [e2e_helpers.dart] (Refs #4075 AC3).
library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// AC1 alias for [e2eEnterFleetReachScenarioReady] (Refs #2336 / #4075).
Future<E2eFleetReachScenarioPreamble> enterFleetReachScenarioReady(
  WidgetTester tester, {
  required String testName,
  required Future<void> Function() bootstrapForIntegrationTest,
  Duration maxUiResponseWait = kE2eDefaultFleetReachPreambleMaxUiResponseWait,
  Duration wallClockCap = kE2eMaxWallClock,
  Locale locale = kE2eDefaultFleetReachPreambleLocale,
  Size surfaceSize = kE2eDefaultFleetReachPreambleSurfaceSize,
  String bootstrapTimingPhase =
      kE2eDefaultFleetReachPreambleBootstrapTimingPhase,
  String afterBootstrapStep = kE2eDefaultFleetReachPreambleAfterBootstrapStep,
  String afterSplitFleetStep = kE2eDefaultFleetReachPreambleAfterSplitFleetStep,
}) => e2eEnterFleetReachScenarioReady(
  tester,
  testName: testName,
  bootstrapForIntegrationTest: bootstrapForIntegrationTest,
  maxUiResponseWait: maxUiResponseWait,
  wallClockCap: wallClockCap,
  locale: locale,
  surfaceSize: surfaceSize,
  bootstrapTimingPhase: bootstrapTimingPhase,
  afterBootstrapStep: afterBootstrapStep,
  afterSplitFleetStep: afterSplitFleetStep,
);

/// AC1 alias for [e2eFleetReachTurnLoop] (Refs #2336 / #4075).
/// AC1 alias for [e2eFleetReachTurnLoop] (Refs #2336 / #4075).
Future<E2eFleetReachLoopResult> fleetReachTurnLoop(
  WidgetTester tester,
  AppLocalizations l10n, {
  required E2ePerfLog perf,
  required void Function(String step) ensureUnderWallClock,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
  int maxTurns = kE2eDefaultFleetReachLoopMaxTurns,
}) => e2eFleetReachTurnLoop(
  tester,
  l10n,
  perf: perf,
  ensureUnderWallClock: ensureUnderWallClock,
  maxUiResponseWait: maxUiResponseWait,
  maxTurns: maxTurns,
);

/// AC1 alias for [e2eFleetReachLoopExitTestTotalMetaLabel] (Refs #2336 / #4075).
/// AC1 alias for [e2eFleetReachLoopExitTestTotalMetaLabel] (Refs #2336 / #4075).
String? fleetReachLoopExitTestTotalMetaLabel(E2eFleetReachLoopExit exit) =>
    e2eFleetReachLoopExitTestTotalMetaLabel(exit);

/// AC1 alias for [e2eExpectPanelTextsMatchSnapshot] (Refs #2336 / #4075).
/// AC1 alias for [e2eExpectPanelTextsMatchSnapshot] (Refs #2336 / #4075).
Future<void> expectPanelTextsMatchSnapshot(
  WidgetTester tester, {
  required Key panelRootKey,
  required Object? Function() snapshotReader,
  required List<String> Function() buildExpected,
  String phaseName = kE2eDefaultExpectPanelTextsPhase,
  Duration timeout = kE2eDefaultExpectPanelTextsTimeout,
  Duration snapshotReaderTimeout =
      kE2eDefaultExpectPanelTextsSnapshotReaderTimeout,
  String snapshotReaderPhaseName =
      kE2eDefaultExpectPanelTextsSnapshotReaderPhase,
  E2ePerfLog? perf,
  List<String> Function()? buildAlternativeExpected,
  List<String> ignoreActualTexts = const [],
}) => e2eExpectPanelTextsMatchSnapshot(
  tester,
  panelRootKey: panelRootKey,
  snapshotReader: snapshotReader,
  buildExpected: buildExpected,
  phaseName: phaseName,
  timeout: timeout,
  snapshotReaderTimeout: snapshotReaderTimeout,
  snapshotReaderPhaseName: snapshotReaderPhaseName,
  perf: perf,
  buildAlternativeExpected: buildAlternativeExpected,
  ignoreActualTexts: ignoreActualTexts,
);

/// AC1 alias for [e2eExpectCivilianPanelMatchesE2eSnapshot] (Refs #2336 / #4075).
/// AC1 alias for [e2eExpectCivilianPanelMatchesE2eSnapshot] (Refs #2336 / #4075).
Future<void> expectCivilianPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectCivilianPanelMatchesE2eSnapshot(tester, l10n, perf: perf);

/// AC1 alias for [e2eExpectNavalPanelMatchesE2eSnapshot] (Refs #2336 / #4075).
/// AC1 alias for [e2eExpectNavalPanelMatchesE2eSnapshot] (Refs #2336 / #4075).
Future<void> expectNavalPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  required bool expanded,
  E2ePerfLog? perf,
}) => e2eExpectNavalPanelMatchesE2eSnapshot(
  tester,
  l10n,
  expanded: expanded,
  perf: perf,
);

/// AC1 alias for [e2eExpectProductionPanelMatchesE2eSnapshot] (Refs #2336 / #4075).
/// AC1 alias for [e2eExpectProductionPanelMatchesE2eSnapshot] (Refs #2336 / #4075).
Future<void> expectProductionPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectProductionPanelMatchesE2eSnapshot(tester, l10n, perf: perf);

/// AC1 alias for [e2eExpectProvincePanelMatchesE2eSnapshot] (Refs #2336 / #4075).
/// AC1 alias for [e2eExpectProvincePanelMatchesE2eSnapshot] (Refs #2336 / #4075).
Future<void> expectProvincePanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectProvincePanelMatchesE2eSnapshot(tester, l10n, perf: perf);

/// AC1 alias for [e2eEnsureNonHomeFleetInNwAfterLoop] (Refs #2336 / #4075).
/// AC1 alias for [e2eEnsureNonHomeFleetInNwAfterLoop] (Refs #2336 / #4075).
Future<E2eFinalNavalReachCheckResult> ensureNonHomeFleetInNwAfterLoop(
  WidgetTester tester, {
  required E2ePerfLog perf,
  required String Function(Object? lastException) failureMessageBuilder,
  Duration maxUiResponseWait = kE2eDefaultFinalNavalReachCheckUiWait,
}) => e2eEnsureNonHomeFleetInNwAfterLoop(
  tester,
  perf: perf,
  failureMessageBuilder: failureMessageBuilder,
  maxUiResponseWait: maxUiResponseWait,
);

/// AC1 alias for [e2ePickFirstValidWorkTileAndAwaitOverlayClear] (Refs #2336 / #4075).
/// AC1 alias for [e2eEnterStandardE2eScenario] (Refs #2336 / #4075).
Future<E2eStandardScenarioOpener> enterStandardE2eScenario(
  WidgetTester tester, {
  required String testName,
  required Future<void> Function() bootstrapForIntegrationTest,
  Duration wallClockCap = kE2eMaxWallClock,
  Locale locale = kE2eDefaultStandardScenarioOpenerLocale,
  Size surfaceSize = kE2eDefaultStandardScenarioOpenerSurfaceSize,
  String bootstrapTimingPhase =
      kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase,
  String afterBootstrapStep =
      kE2eDefaultStandardScenarioOpenerAfterBootstrapStep,
  String? assetPreloadTimingPhase =
      kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase,
  String afterAssetPreloadStep =
      kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep,
  String? newGameToMapTimingPhase =
      kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase,
  String afterNewGameToMapStep =
      kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep,
}) => e2eEnterStandardE2eScenario(
  tester,
  testName: testName,
  bootstrapForIntegrationTest: bootstrapForIntegrationTest,
  wallClockCap: wallClockCap,
  locale: locale,
  surfaceSize: surfaceSize,
  bootstrapTimingPhase: bootstrapTimingPhase,
  afterBootstrapStep: afterBootstrapStep,
  assetPreloadTimingPhase: assetPreloadTimingPhase,
  afterAssetPreloadStep: afterAssetPreloadStep,
  newGameToMapTimingPhase: newGameToMapTimingPhase,
  afterNewGameToMapStep: afterNewGameToMapStep,
);

/// AC1 alias for [e2eRunIntegrationTestBootstrap] (Refs #2336 / #4075).
/// AC1 alias for [e2eRunIntegrationTestBootstrap] (Refs #2336 / #4075).
Future<E2eIntegrationTestBootstrapResult> runIntegrationTestBootstrap(
  WidgetTester tester, {
  required String testName,
  required Future<void> Function() bootstrapForIntegrationTest,
  Size surfaceSize = kE2eDefaultIntegrationTestBootstrapSurfaceSize,
  String bootstrapTimingPhase = kE2eDefaultIntegrationTestBootstrapTimingPhase,
}) => e2eRunIntegrationTestBootstrap(
  tester,
  testName: testName,
  bootstrapForIntegrationTest: bootstrapForIntegrationTest,
  surfaceSize: surfaceSize,
  bootstrapTimingPhase: bootstrapTimingPhase,
);
