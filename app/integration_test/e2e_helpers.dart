/// Stable public names for ColonizeThis integration/E2E helpers (GitHub #2336 AC1).
///
/// Implementations live in [e2e_test_shared.dart]; this library delegates to the
/// `e2e*` entrypoints so new scenarios can depend on the AC1 checklist names
/// (`openProductionPanel`, `advanceOneHumanTurn`, `waitForNextTurnLabelAdvance`, etc.).
library;

import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';
import 'e2e_test_shared_bootstrap.dart';

/// Re-export shared polling / settle entrypoints so scenarios depend on this
/// barrel only (GitHub #2336 AC2).
export 'e2e_test_shared.dart'
    show
        E2ePerfLog,
        e2eAdaptivePollRampAfterIdle,
        e2eAwaitNwCoastalOrVisibleLandForBundledExplore,
        e2eBundledExploreRejectionDiagnostics,
        e2eCheckExploreEnabledFromCivilianPanel,
        e2eExploreAssignEnabledFromCivilianSnapshot,
        e2eFleetReachDoneFromCtSnapshotOnly,
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
        kE2eCheckExploreEnabledFromCivilianPanelPhase,
        kE2eDefaultBundledExploreReadinessMaxTurns,
        kE2eDefaultBundledExploreSweepWait,
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

/// Stable public name for [e2eCheckExploreEnabledFromCivilianPanel] so the
/// post-bundle Explore scenario consumes the AC1 barrel only (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). Forwards to the implementation in
/// `e2e_test_shared_panels.dart`.
Future<bool> checkExploreEnabledFromCivilianPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  String waitUntilFoundPhase = 'wait_until_found_civilian_panel',
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_fleet_civilian_open',
}) => e2eCheckExploreEnabledFromCivilianPanel(
  tester,
  perf: perf,
  maxUiResponseWait: maxUiResponseWait,
  waitUntilFoundPhase: waitUntilFoundPhase,
  afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
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

Future<void> ensureAllRelocated64pxPngsLoad() =>
    e2eEnsureAllRelocated64pxPngsLoad();

Future<void> ensureAllRelocated64pxPngsLoadSuiteOnce() =>
    e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
