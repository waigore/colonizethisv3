/// AC1 facade aliases extracted from [e2e_helpers.dart] (Refs #4075 AC3).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

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

/// AC1 alias for [e2eAwaitCivilianWorkMenuMounted] (Refs #2336 / #4075).
/// AC1 alias for [e2eAwaitCivilianWorkMenuMounted] (Refs #2336 / #4075).
Future<void> awaitCivilianWorkMenuMounted(
  WidgetTester tester, {
  Duration timeout = kE2eDefaultCivilianWorkMenuMountTimeout,
  String phaseName = kE2eDefaultCivilianWorkMenuMountPhase,
  E2ePerfLog? perf,
}) => e2eAwaitCivilianWorkMenuMounted(
  tester,
  timeout: timeout,
  phaseName: phaseName,
  perf: perf,
);

Future<void> tapAssignOnCivilianRowWithTitle(
  WidgetTester tester,
  String unitTypeTitle,
) => e2eTapAssignOnCivilianRowWithTitle(tester, unitTypeTitle);

/// AC1 alias for [e2eTapCivilianWorkOrderLabel] (Refs #2336 / #4075).
/// AC1 alias for [e2eTapCivilianWorkOrderLabel] (Refs #2336 / #4075).
Future<void> tapCivilianWorkOrderLabel(
  WidgetTester tester,
  String workOrderLabel,
) => e2eTapCivilianWorkOrderLabel(tester, workOrderLabel);

/// AC1 alias for [e2eTapMoveOnFirstNonHomeFleet] (Refs #2336 / #4075).
/// AC1 alias for [e2eTapMoveOnFirstNonHomeFleet] (Refs #2336 / #4075).
Future<bool> tapMoveOnFirstNonHomeFleet(WidgetTester tester) =>
    e2eTapMoveOnFirstNonHomeFleet(tester);

/// AC1 alias for [e2ePickMoveDestinationAndConfirm] (Refs #2336 / #4075).
/// AC1 alias for [e2ePickMoveDestinationAndConfirm] (Refs #2336 / #4075).
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

/// AC1 alias for [e2eTryNavalMoveSegment] (Refs #2336 / #4075).
/// AC1 alias for [e2eTryNavalMoveSegment] (Refs #2336 / #4075).
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

/// AC1 alias for [e2eAttemptFirstFleetMoveOrCancel] (Refs #2336 / #4075).
/// AC1 alias for [e2eAttemptFirstFleetMoveOrCancel] (Refs #2336 / #4075).
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

/// AC1 alias for [e2eAnyExplorerHasEnabledExploreAssignFleet] (Refs #2336 / #4075).
/// AC1 alias for [e2eAnyExplorerHasEnabledExploreAssignFleet] (Refs #2336 / #4075).
Future<bool> anyExplorerHasEnabledExploreAssignFleet(
  WidgetTester tester, {
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxPanelSweepSteps = 16,
}) => e2eAnyExplorerHasEnabledExploreAssignFleet(
  tester,
  maxUiResponseWait: maxUiResponseWait,
  maxPanelSweepSteps: maxPanelSweepSteps,
);

/// AC1 alias for [e2eAwaitNwCoastalOrVisibleLandForBundledExplore] (Refs #2336 / #4075).
/// AC1 alias for [e2eAwaitNwCoastalOrVisibleLandForBundledExplore] (Refs #2336 / #4075).
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

/// AC1 alias for [e2eCheckExploreEnabledFromCivilianPanel] (Refs #2336 / #4075).
/// AC1 alias for [e2eCheckExploreEnabledFromCivilianPanel] (Refs #2336 / #4075).
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

/// AC1 alias for [e2eAwaitExploreEnabledFromCivilianPanel] (Refs #2336 / #4075).
/// AC1 alias for [e2eAwaitExploreEnabledFromCivilianPanel] (Refs #2336 / #4075).
Future<bool> awaitExploreEnabledFromCivilianPanel(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxBoundedTurnRetries = kE2eDefaultBundledExploreMaxTurnRetries,
  String retryIterationCounter = kE2eDefaultBundledExploreRetryIterationCounter,
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

/// AC1 alias for [e2eEnterFleetReachScenarioReady] (Refs #2336 / #4075).
/// AC1 alias for [e2ePickFirstValidWorkTileAndAwaitOverlayClear] (Refs #2336 / #4075).
Future<void> pickFirstValidWorkTileAndAwaitOverlayClear(
  WidgetTester tester, {
  required String appearPhase,
  required String clearPhase,
  Duration appearTimeout = kE2eDefaultCivilianWorkTileAppearTimeout,
  Duration clearTimeout = kE2eDefaultCivilianWorkTileClearTimeout,
  E2ePerfLog? perf,
}) => e2ePickFirstValidWorkTileAndAwaitOverlayClear(
  tester,
  appearPhase: appearPhase,
  clearPhase: clearPhase,
  appearTimeout: appearTimeout,
  clearTimeout: clearTimeout,
  perf: perf,
);

/// AC1 alias for [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear] (Refs #2336 / #4075).
/// AC1 alias for [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear] (Refs #2336 / #4075).
Future<bool> maybePickFirstValidWorkTileAndAwaitOverlayClear(
  WidgetTester tester, {
  required String appearPhase,
  required String clearPhase,
  required String skippedTimingLabel,
  required String skippedMeta,
  Duration appearTimeout = kE2eDefaultCivilianWorkTileAppearTimeout,
  Duration clearTimeout = kE2eDefaultCivilianWorkTileClearTimeout,
  E2ePerfLog? perf,
}) => e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear(
  tester,
  appearPhase: appearPhase,
  clearPhase: clearPhase,
  skippedTimingLabel: skippedTimingLabel,
  skippedMeta: skippedMeta,
  appearTimeout: appearTimeout,
  clearTimeout: clearTimeout,
  perf: perf,
);

/// AC1 alias for [e2eHandleBundledExploreFailure] (Refs #2336 / #4075).
/// AC1 alias for [e2eHandleBundledExploreFailure] (Refs #2336 / #4075).
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

/// AC1 alias for [e2eEnterStandardE2eScenario] (Refs #2336 / #4075).
