/// Stable public names for ColonizeThis integration/E2E helpers (GitHub #2336 AC1).
///
/// Implementations live in [e2e_test_shared.dart]; this library delegates to the
/// `e2e*` entrypoints so new scenarios can depend on the AC1 checklist names
/// (`openProductionPanel`, `advanceOneHumanTurn`, `waitForNextTurnLabelAdvance`, etc.).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';
import 'e2e_test_shared_bootstrap.dart';

/// Re-export shared polling / settle entrypoints so scenarios depend on this
/// barrel only (GitHub #2336 AC2).
export 'e2e_test_shared.dart'
    show
        E2eFinalNavalReachCheckResult,
        E2eFirstFleetMoveOutcome,
        E2eFleetReachLoopExit,
        E2eFleetReachLoopResult,
        E2eFleetReachScenarioPreamble,
        E2ePerfLog,
        e2eAdaptivePollRampAfterIdle,
        e2eAttemptFirstFleetMoveOrCancel,
        e2eAwaitExploreEnabledFromCivilianPanel,
        e2eAwaitNwCoastalOrVisibleLandForBundledExplore,
        e2eBundledExploreRejectionDiagnostics,
        e2eCheckExploreEnabledFromCivilianPanel,
        e2eDismissCtDialogShellIfPresent,
        e2eEnsureNonHomeFleetInNwAfterLoop,
        e2eEnterFleetReachScenarioReady,
        e2eExploreAssignEnabledFromCivilianSnapshot,
        e2eExpectPanelTextsMatchSnapshot,
        e2eFleetReachDoneFromCtSnapshotOnly,
        e2eFleetReachLoopExitTestTotalMetaLabel,
        e2eFleetReachTurnLoop,
        e2eHandleBundledExploreFailure,
        e2eHarnessDetectsNonHomeFleetInNewWorld,
        e2eMakeWallClockGuard,
        e2eNewWorldRegionChipAppearsSelected,
        e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot,
        e2eNavalPanelShowsNonHomeFleetInNewWorld,
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot,
        e2eNwCoastalProvincesAdjacentToFleetSea,
        e2eOldWorldRegionChipAppearsSelected,
        e2ePickMoveDestinationAndConfirm,
        e2eTryNavalMoveSegment,
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot,
        kE2eDefaultBundledExploreMaxTurnRetries,
        kE2eDefaultBundledExploreReadinessMaxTurns,
        kE2eDefaultBundledExploreRetryIterationCounter,
        kE2eDefaultBundledExploreRetryLoopPhase,
        kE2eDefaultBundledExploreSweepWait,
        kE2eDefaultCtDialogShellCloseTimeout,
        kE2eDefaultCtDialogShellClosePhase,
        kE2eDefaultExpectPanelTextsPhase,
        kE2eDefaultExpectPanelTextsTimeout,
        kE2eDefaultFinalNavalReachCheckUiWait,
        kE2eDefaultFirstFleetMoveConfirmReadyTimeout,
        kE2eDefaultFirstFleetMoveDialogCloseTimeout,
        kE2eDefaultFirstFleetMoveDialogOpenTimeout,
        kE2eDefaultFleetCivilianOpenAfterSheetClearPhase,
        kE2eDefaultFleetReachLoopMaxTurns,
        kE2eDefaultFleetReachPreambleAfterBootstrapStep,
        kE2eDefaultFleetReachPreambleAfterSplitFleetStep,
        kE2eDefaultFleetReachPreambleBootstrapTimingPhase,
        kE2eDefaultFleetReachPreambleLocale,
        kE2eDefaultFleetReachPreambleMaxUiResponseWait,
        kE2eDefaultFleetReachPreambleSurfaceSize,
        kE2eDefaultNavalMoveSegmentUiWait,
        e2ePumpUntil,
        e2ePumpUntilConditionOrIdle,
        e2eRadioListTilesInAlertDialogs,
        e2eTapNewWorldRegionTabIfPresent,
        e2eTapOldWorldRegionTab,
        e2eTextLooksLikeNewWorldLocationLine,
        e2eWaitForNewGameEntry,
        e2eWaitForNextTurnLabelAdvance,
        e2eWaitUntilAnyFinderHitTestable,
        e2eOpenProductionPanel,
        e2eOpenPanelFromMarker,
        kE2eDefaultMoveFleetDialogBudget,
        kE2eDefaultMoveFleetWarpDragProbes,
        kE2eMaxWallClock,
        kE2eNextTurnResolutionTimeout;

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

/// Stable public name for [e2eDismissCtDialogShellIfPresent] so the
/// full-turn scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_dismiss_ct_dialog_shell.dart`.
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
}) => e2eBootstrapNewGameToMap(tester, perf: perf, overallCap: overallCap);

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
  bool navalPanelAlreadyOpen = false,
}) => e2eSplitHomeFleetOnce(
  tester,
  l10n,
  perf: perf,
  openNavalTimeout: openNavalTimeout,
  bottomSheetCloseTimeout: bottomSheetCloseTimeout,
  navalPanelAlreadyOpen: navalPanelAlreadyOpen,
);

Future<void> tapFirstAssignInCivilianPanel(WidgetTester tester) =>
    e2eTapFirstAssignInCivilianPanel(tester);

Future<void> tapAssignOnCivilianRowWithTitle(
  WidgetTester tester,
  String unitTypeTitle,
) => e2eTapAssignOnCivilianRowWithTitle(tester, unitTypeTitle);

/// Stable public name for [e2eTapMoveOnFirstNonHomeFleet] so fleet scenarios
/// consume the AC1 barrel only (Refs GitHub #2336 AC1 / AC2). Forwards to
/// the implementation in `e2e_test_shared_panels.dart`.
Future<bool> tapMoveOnFirstNonHomeFleet(WidgetTester tester) =>
    e2eTapMoveOnFirstNonHomeFleet(tester);

/// Stable public name for [e2ePickMoveDestinationAndConfirm] so fleet
/// scenarios consume the AC1 barrel only (Refs GitHub #2336 AC1 / AC2 / AC4 /
/// Bottleneck 4 / H4). Forwards to the implementation in
/// `e2e_test_shared_panels.dart`.
Future<void> pickMoveDestinationAndConfirm(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool allowWarpDestinations = true,
  Duration moveDialogBudget = kE2eDefaultMoveFleetDialogBudget,
  int maxWarpDragProbes = kE2eDefaultMoveFleetWarpDragProbes,
}) => e2ePickMoveDestinationAndConfirm(
  tester,
  l10n,
  allowWarpDestinations: allowWarpDestinations,
  moveDialogBudget: moveDialogBudget,
  maxWarpDragProbes: maxWarpDragProbes,
);

/// Stable public name for [e2eTryNavalMoveSegment] so fleet scenarios consume
/// the AC1 barrel only (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4 / H1–H4).
/// Forwards to the implementation in `e2e_test_shared_panels.dart`.
Future<void> tryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool useNewWorldMapTabFirst = false,
  bool allowWarpDestinations = true,
  bool navalPanelAlreadyOpen = false,
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
}) => e2eTryNavalMoveSegment(
  tester,
  l10n,
  useNewWorldMapTabFirst: useNewWorldMapTabFirst,
  allowWarpDestinations: allowWarpDestinations,
  navalPanelAlreadyOpen: navalPanelAlreadyOpen,
  perf: perf,
  maxUiResponseWait: maxUiResponseWait,
);

/// Stable public name for [e2eAttemptFirstFleetMoveOrCancel] so the full-turn
/// scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 2). Forwards to the implementation in
/// `e2e_test_shared_first_fleet_move.dart`.
Future<E2eFirstFleetMoveOutcome> attemptFirstFleetMoveOrCancel(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration moveDialogOpenTimeout = kE2eDefaultFirstFleetMoveDialogOpenTimeout,
  Duration confirmReadyTimeout = kE2eDefaultFirstFleetMoveConfirmReadyTimeout,
  Duration dialogCloseTimeout = kE2eDefaultFirstFleetMoveDialogCloseTimeout,
}) => e2eAttemptFirstFleetMoveOrCancel(
  tester,
  l10n,
  perf: perf,
  moveDialogOpenTimeout: moveDialogOpenTimeout,
  confirmReadyTimeout: confirmReadyTimeout,
  dialogCloseTimeout: dialogCloseTimeout,
);

/// Stable public name for [e2eAnyExplorerHasEnabledExploreAssignFleet] so
/// the fleet bundled-Explore retry loop consumes the AC1 barrel only
/// (Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5). Forwards to the
/// implementation in `e2e_test_shared_panels.dart`.
Future<bool> anyExplorerHasEnabledExploreAssignFleet(
  WidgetTester tester, {
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxPanelSweepSteps = 16,
}) => e2eAnyExplorerHasEnabledExploreAssignFleet(
  tester,
  maxUiResponseWait: maxUiResponseWait,
  maxPanelSweepSteps: maxPanelSweepSteps,
);

/// Stable public name for [e2eAwaitNwCoastalOrVisibleLandForBundledExplore]
/// so the post-bundle Explore scenario consumes the AC1 barrel only
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4). Forwards to the
/// implementation in `e2e_test_shared_panels.dart`.
Future<void> awaitNwCoastalOrVisibleLandForBundledExplore(
  WidgetTester tester,
  AppLocalizations l10n, {
  required void Function(String step) ensureUnderWallClock,
  int maxTurns = kE2eDefaultBundledExploreReadinessMaxTurns,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
}) => e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
  tester,
  l10n,
  ensureUnderWallClock: ensureUnderWallClock,
  maxTurns: maxTurns,
  maxUiResponseWait: maxUiResponseWait,
);

/// Stable public name for [e2eCheckExploreEnabledFromCivilianPanel] so the
/// post-bundle Explore scenario consumes the AC1 barrel only (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). Forwards to the implementation
/// in `e2e_test_shared_panels.dart`.
Future<bool> checkExploreEnabledFromCivilianPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  String afterSheetPanelsClearPhase =
      kE2eDefaultFleetCivilianOpenAfterSheetClearPhase,
  String phaseTimingLabel = kE2eDefaultBundledExploreRetryLoopPhase,
}) => e2eCheckExploreEnabledFromCivilianPanel(
  tester,
  perf: perf,
  maxUiResponseWait: maxUiResponseWait,
  afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
  phaseTimingLabel: phaseTimingLabel,
);

/// Stable public name for [e2eAwaitExploreEnabledFromCivilianPanel] so the
/// post-bundle Explore scenario consumes the AC1 barrel only (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). Forwards to the implementation
/// in `e2e_test_shared_bundled_explore_retry.dart`.
Future<bool> awaitExploreEnabledFromCivilianPanel(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxBoundedTurnRetries = kE2eDefaultBundledExploreMaxTurnRetries,
  String retryIterationCounter =
      kE2eDefaultBundledExploreRetryIterationCounter,
}) => e2eAwaitExploreEnabledFromCivilianPanel(
  tester,
  l10n,
  perf: perf,
  maxUiResponseWait: maxUiResponseWait,
  maxBoundedTurnRetries: maxBoundedTurnRetries,
  retryIterationCounter: retryIterationCounter,
);

Future<void> ensureAllRelocated64pxPngsLoad() =>
    e2eEnsureAllRelocated64pxPngsLoad();

Future<void> ensureAllRelocated64pxPngsLoadSuiteOnce() =>
    e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();

/// Stable public name for [e2eEnterFleetReachScenarioReady] so the two
/// fleet-reach `testWidgets` bodies in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` consume the AC1 barrel
/// only (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6). Forwards to the
/// implementation in `e2e_test_shared_fleet_reach_scenario_preamble.dart`.
///
/// The call site injects the real `bootstrapForIntegrationTest` from
/// `package:colonizethis_app/main.dart` so the shared module stays free of
/// the app's main-entry import; the widget-test pin in
/// `app/test/e2e_enter_fleet_reach_scenario_ready_test.dart` exercises the
/// callable-parameter and AC1 barrel signature contracts.
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
  String afterSplitFleetStep =
      kE2eDefaultFleetReachPreambleAfterSplitFleetStep,
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

/// Stable public name for [e2eFleetReachTurnLoop] so the two fleet-reach
/// scenarios in `new_game_fleet_reaches_new_world_e2e_test.dart` consume the
/// AC1 barrel only (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4). Forwards
/// to the implementation in `e2e_test_shared_panels.dart` — call sites map
/// the returned [E2eFleetReachLoopResult.exit] to the legacy
/// `result=reached_*` perf-timing meta labels via
/// [fleetReachLoopExitTestTotalMetaLabel].
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

/// Stable public name for [e2eFleetReachLoopExitTestTotalMetaLabel] so the
/// fleet-reach scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1
/// / AC2 / Bottleneck 4). Forwards to the implementation in
/// `e2e_test_shared_fleet_reach_loop_test_total_meta.dart`. Returns the
/// legacy `result=<branch>` string for every early-return exit and `null`
/// for [E2eFleetReachLoopExit.loopExhausted] so the caller falls through to
/// the post-loop final-naval-check path.
String? fleetReachLoopExitTestTotalMetaLabel(E2eFleetReachLoopExit exit) =>
    e2eFleetReachLoopExitTestTotalMetaLabel(exit);

/// Stable public name for [e2eExpectPanelTextsMatchSnapshot] so the
/// snapshot-text panel scenarios in `new_game_full_turn_e2e_test.dart`
/// (civilian / naval / production rails) and
/// `new_game_capital_panel_e2e_test.dart` (province panel) consume the AC1
/// barrel only (Refs GitHub #2336 AC1 / AC2). Forwards to the implementation
/// in `e2e_test_shared_panels.dart`.
Future<void> expectPanelTextsMatchSnapshot(
  WidgetTester tester, {
  required Key panelRootKey,
  required Object? snapshot,
  required List<String> Function() buildExpected,
  String phaseName = kE2eDefaultExpectPanelTextsPhase,
  Duration timeout = kE2eDefaultExpectPanelTextsTimeout,
  E2ePerfLog? perf,
  List<String> Function()? buildAlternativeExpected,
}) => e2eExpectPanelTextsMatchSnapshot(
  tester,
  panelRootKey: panelRootKey,
  snapshot: snapshot,
  buildExpected: buildExpected,
  phaseName: phaseName,
  timeout: timeout,
  perf: perf,
  buildAlternativeExpected: buildAlternativeExpected,
);

/// Stable public name for [e2eEnsureNonHomeFleetInNwAfterLoop] so the two
/// fleet-reach scenarios in `new_game_fleet_reaches_new_world_e2e_test.dart`
/// consume the AC1 barrel only (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4).
/// Forwards to the implementation in
/// `e2e_test_shared_final_naval_reach_check.dart` — call sites compose the
/// scenario-specific fail message via [failureMessageBuilder] and assign the
/// captured [E2eFinalNavalReachCheckResult.lastKnownNavalSnapshot]
/// themselves when their post-loop diagnostics need it.
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

/// Stable public name for [e2eHandleBundledExploreFailure] so the
/// post-bundle Explore scenario consumes the AC1 barrel only (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). Forwards to the implementation
/// in `e2e_test_shared_bundled_explore_failure.dart`.
Future<void> handleBundledExploreFailure(
  WidgetTester tester, {
  required CtE2eNavalPanelSnapshot? navalSnapshot,
  required CtE2eCivilianPanelSnapshot? civilianSnapshot,
  CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot,
  required int maxBoundedTurnRetries,
}) => e2eHandleBundledExploreFailure(
  tester,
  navalSnapshot: navalSnapshot,
  civilianSnapshot: civilianSnapshot,
  lastKnownNavalSnapshot: lastKnownNavalSnapshot,
  maxBoundedTurnRetries: maxBoundedTurnRetries,
);
