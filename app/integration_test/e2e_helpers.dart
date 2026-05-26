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
        E2eStandardScenarioOpener,
        e2eAdaptivePollRampAfterIdle,
        e2eAttemptFirstFleetMoveOrCancel,
        e2eAwaitCivilianWorkMenuMounted,
        e2eAwaitExploreEnabledFromCivilianPanel,
        e2eAwaitNwCoastalOrVisibleLandForBundledExplore,
        e2eAwaitPanelMountAfterOpenerTap,
        e2eAwaitPanelOpenerRailHitTestable,
        e2eBundledExploreRejectionDiagnostics,
        e2eCheckExploreEnabledFromCivilianPanel,
        e2eClosePanelOpenerSheetAndAwaitOpener,
        e2eDismissAlertDialogIfPresent,
        e2eDismissCtDialogShellBroadSweepIfPresent,
        e2eDismissCtDialogShellIfPresent,
        e2eDismissCtDialogShellWithPopRouteEscalation,
        e2eDismissSnackBarIfPresent,
        e2eEnsureNonHomeFleetInNwAfterLoop,
        e2eEnsureVisibleAndTapHitTestable,
        e2eEnterFleetReachScenarioReady,
        e2eEnterStandardE2eScenario,
        e2eExploreAssignEnabledFromCivilianSnapshot,
        e2eExpectCivilianPanelMatchesE2eSnapshot,
        e2eExpectNavalPanelMatchesE2eSnapshot,
        e2eExpectPanelTextsMatchSnapshot,
        e2eExpectProductionPanelMatchesE2eSnapshot,
        e2eExpectProvincePanelMatchesE2eSnapshot,
        e2eFleetReachDoneFromCtSnapshotOnly,
        e2eFleetReachLoopExitTestTotalMetaLabel,
        e2eFleetReachTurnLoop,
        e2eHandleBundledExploreFailure,
        e2eHarnessDetectsNonHomeFleetInNewWorld,
        e2eMakeWallClockGuard,
        e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear,
        e2eNewWorldRegionChipAppearsSelected,
        e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot,
        e2eNavalPanelShowsNonHomeFleetInNewWorld,
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot,
        e2eNwCoastalProvincesAdjacentToFleetSea,
        e2eOldWorldRegionChipAppearsSelected,
        e2eOpenerTapTriggerAndAwaitMount,
        e2eOpenPanelViaRailOrMarker,
        e2ePickFirstValidWorkTileAndAwaitOverlayClear,
        e2ePickMoveDestinationAndConfirm,
        e2eTryNavalMoveSegment,
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot,
        kE2eDefaultAlertDialogDismissLabels,
        kE2eDefaultAlertDialogDismissTimeout,
        kE2eDefaultBundledExploreMaxTurnRetries,
        kE2eDefaultBundledExploreReadinessMaxTurns,
        kE2eDefaultBundledExploreRetryIterationCounter,
        kE2eDefaultBundledExploreRetryLoopPhase,
        kE2eCivilianWorkMenuLabels,
        kE2eDefaultBundledExploreSweepWait,
        kE2eDefaultCivilianWorkMenuMountPhase,
        kE2eDefaultCivilianWorkMenuMountTimeout,
        kE2eDefaultCivilianWorkTileAppearTimeout,
        kE2eDefaultCivilianWorkTileClearTimeout,
        kE2eDefaultCtDialogShellBroadSweepDismissTimeout,
        kE2eDefaultCtDialogShellCloseTimeout,
        kE2eDefaultCtDialogShellClosePhase,
        kE2eDefaultCtDialogShellEscalationPhase,
        kE2eDefaultCtDialogShellEscalationTimeout,
        kE2eDefaultExpectPanelTextsPhase,
        kE2eDefaultExpectPanelTextsTimeout,
        kE2eExpectCivilianPanelTextsPhase,
        kE2eExpectNavalPanelTextsPhase,
        kE2eExpectProductionPanelTextsPhase,
        kE2eExpectProvincePanelTextsPhase,
        kE2eExpectProvincePanelTextsTimeout,
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
        kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep,
        kE2eDefaultStandardScenarioOpenerAfterBootstrapStep,
        kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep,
        kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase,
        kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase,
        kE2eDefaultStandardScenarioOpenerLocale,
        kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase,
        kE2eDefaultSnackBarDismissTimeout,
        kE2eDefaultStandardScenarioOpenerSurfaceSize,
        e2ePumpUntil,
        e2ePumpUntilConditionOrIdle,
        e2eRadioListTilesInAlertDialogs,
        e2eTapCivilianWorkOrderLabel,
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

/// Stable public name for [e2eEnsureVisibleAndTapHitTestable] (Refs GitHub
/// #2336 AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared.dart`. The shared defensive tap is consumed indirectly
/// by [openCivilianPanel] / [openNavalPanel] / [openProductionPanel] today;
/// the alias is re-exposed so future scenarios can compose the same
/// rail/marker tap path without duplicating the `ensureVisible` +
/// hit-testable resolve recipe.
Future<bool> ensureVisibleAndTapHitTestable(
  WidgetTester tester,
  Finder trigger,
) => e2eEnsureVisibleAndTapHitTestable(tester, trigger);

/// Stable public name for [e2eAwaitPanelMountAfterOpenerTap] (Refs GitHub
/// #2336 AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared.dart`. The shared post-tap panel-mount probe is
/// consumed indirectly by [openCivilianPanel] / [openNavalPanel] /
/// [openProductionPanel] today; the alias is re-exposed so future
/// scenarios can compose the same "fast-check → one pump → bounded poll"
/// mount probe after their own rail/marker taps without duplicating the
/// recipe.
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

/// Stable public name for [e2eClosePanelOpenerSheetAndAwaitOpener] (Refs
/// GitHub #2336 AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared_panel_open_sheet_close.dart` (re-exported via
/// `e2e_test_shared.dart`). The shared post-sheet-close cleanup recipe
/// (close sheet → poll until cleared → poll until rail/marker
/// hit-testable) is consumed indirectly by [openCivilianPanel] /
/// [openNavalPanel] today; the alias is re-exposed so future scenarios
/// can compose the same cleanup after their own opener taps without
/// duplicating the recipe.
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

/// Stable public name for [e2eOpenerTapTriggerAndAwaitMount] (Refs GitHub
/// #2336 AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared_panel_open_trigger_attempt.dart` (re-exported via
/// `e2e_test_shared.dart`). The shared inner-attempt composition
/// (panel-already-hit-testable short-circuit → defensive
/// [ensureVisibleAndTapHitTestable] tap → [awaitPanelMountAfterOpenerTap]
/// bounded mount probe) is consumed indirectly by [openCivilianPanel] /
/// [openNavalPanel] today; the alias is re-exposed so future scenarios
/// can compose the same `tryOpen` recipe after their own opener taps
/// without duplicating the three-step body.
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

/// Stable public name for [e2eOpenPanelViaRailOrMarker] (Refs GitHub #2336
/// AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared_panel_open_outer_loop.dart` (re-exported via
/// `e2e_test_shared.dart`). The shared rail-or-marker outer adaptive-poll
/// loop is consumed indirectly by [openCivilianPanel] and [openNavalPanel]
/// today; the alias is re-exposed so future panel openers that share the
/// same rail/marker structure can compose the byte-equivalent recipe
/// without duplicating the outer-loop body.
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

/// Stable public name for [e2eDismissAlertDialogIfPresent] (Refs GitHub
/// #2336 AC1 / AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_dismiss_alert_dialog.dart` (re-exported via
/// `e2e_test_shared.dart`). The shared AlertDialog-dismiss recipe is
/// consumed indirectly by [dismissTransientUi] today; the alias is
/// re-exposed so future scenarios that need a focused AlertDialog-only
/// dismissal (without triggering the SnackBar / BottomSheet / CtDialogShell
/// fallback branches of the broad sweep) can compose it directly.
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

/// Stable public name for [e2eDismissCtDialogShellBroadSweepIfPresent]
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6). Forwards to the
/// implementation in
/// `e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart`. The shared
/// English-only [CtDialogShell] dismiss recipe (`Cancel` → `Close` →
/// `Icons.close` → `Icons.arrow_back`, with `tester.binding.handlePopRoute()`
/// fallback) is consumed indirectly by [dismissTransientUi] today; the
/// alias is re-exposed so future scenarios that need a focused
/// [CtDialogShell]-only dismissal (without triggering the SnackBar /
/// AlertDialog / BottomSheet branches of the broad sweep) can compose it
/// directly.
Future<bool> dismissCtDialogShellBroadSweepIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultCtDialogShellBroadSweepDismissTimeout,
}) => e2eDismissCtDialogShellBroadSweepIfPresent(
  tester,
  perf: perf,
  dismissTimeout: dismissTimeout,
);

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

/// Stable public name for [e2eDismissCtDialogShellWithPopRouteEscalation]
/// (Refs GitHub #2336 AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared_dismiss_ct_dialog_shell_escalation.dart`. The shared
/// two-step CtDialogShell dismissal (broad-spectrum [dismissTransientUi]
/// → `handlePopRoute()` + bounded [e2ePumpUntil] when the shell survives)
/// is consumed indirectly by [openProductionPanel] today; the alias is
/// re-exposed so future panel openers that need the escalation can compose
/// the byte-equivalent recipe without duplicating the inline block.
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

/// Stable public name for [e2eDismissSnackBarIfPresent] (Refs GitHub #2336
/// AC1 / AC2 / AC10). Forwards to the implementation in
/// `e2e_test_shared_dismiss_snackbar.dart` (re-exported via
/// `e2e_test_shared.dart`). The shared SnackBar-dismiss recipe is consumed
/// indirectly by [dismissTransientUi] today; the alias is re-exposed so
/// future scenarios that need a focused SnackBar-only dismissal (without
/// triggering the AlertDialog / BottomSheet / CtDialogShell fallback
/// branches of the broad sweep) can compose it directly.
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

/// Stable public name for [e2eAwaitCivilianWorkMenuMounted] so future scenarios
/// that tap an `Assign` button (or any upstream affordance that mounts the
/// civilian work menu) consume the AC1 barrel without duplicating the
/// label-set / timeout recipe (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
/// Forwards to the implementation in `e2e_test_shared.dart`.
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

/// Stable public name for [e2eTapCivilianWorkOrderLabel] so the full-turn
/// scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1 / AC2 /
/// AC10). Forwards to the implementation in `e2e_test_shared.dart`.
Future<void> tapCivilianWorkOrderLabel(
  WidgetTester tester,
  String workOrderLabel,
) => e2eTapCivilianWorkOrderLabel(tester, workOrderLabel);

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

/// Stable public name for [e2eExpectCivilianPanelMatchesE2eSnapshot] so the
/// full-turn scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_panel_text_match.dart`. Encapsulates the civilian-panel
/// root key, [ctE2eCivilianPanelSnapshot] read, [civilianUnitsPanelExpectedTexts]
/// builder, and `wait_until_found_civilian_panel` phase label.
Future<void> expectCivilianPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectCivilianPanelMatchesE2eSnapshot(tester, l10n, perf: perf);

/// Stable public name for [e2eExpectNavalPanelMatchesE2eSnapshot] so the
/// full-turn scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_panel_text_match.dart`. Encapsulates the naval-panel
/// root key, [ctE2eNavalPanelSnapshot] read,
/// [navalUnitsPanelExpectedTexts] builder, `wait_until_found_naval_panel`
/// phase label, and the `fleetTilesExpanded`-aware `anyOf` fallback that
/// keeps post-tap settles on the collapsed mirror green.
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

/// Stable public name for [e2eExpectProductionPanelMatchesE2eSnapshot] so
/// the full-turn scenario consumes the AC1 barrel only (Refs GitHub #2336
/// AC1 / AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_panel_text_match.dart`. Encapsulates the production-panel
/// root key, [ctE2eProductionPanelSnapshot] read,
/// [productionPanelWideExpectedTexts] builder, and
/// `wait_until_found_production_panel` phase label.
Future<void> expectProductionPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectProductionPanelMatchesE2eSnapshot(tester, l10n, perf: perf);

/// Stable public name for [e2eExpectProvincePanelMatchesE2eSnapshot] so the
/// capital-panel scenario consumes the AC1 barrel only (Refs GitHub #2336
/// AC1 / AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_panel_text_match.dart`. Encapsulates the province-panel
/// root key, [ctE2eLastPanelSnapshot] read,
/// [provincePanelWideLayoutExpectedTexts] builder,
/// `open_panel_province` phase label, and the wider 30s timeout used by the
/// pre-lift inline assertion (the province panel mounts later in its
/// scenario).
Future<void> expectProvincePanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectProvincePanelMatchesE2eSnapshot(tester, l10n, perf: perf);

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

/// Stable public name for [e2ePickFirstValidWorkTileAndAwaitOverlayClear]
/// so the full-turn scenario consumes the AC1 barrel only (Refs GitHub
/// #2336 AC1 / AC2 / Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_civilian_work_tile_pick.dart`.
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

/// Stable public name for
/// [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear] so the full-turn
/// scenario consumes the AC1 barrel only (Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6). Forwards to the implementation in
/// `e2e_test_shared_civilian_work_tile_pick.dart`.
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

/// Stable public name for [e2eEnterStandardE2eScenario] so the full-turn and
/// capital-panel `testWidgets` bodies in `new_game_full_turn_e2e_test.dart`
/// and `new_game_capital_panel_e2e_test.dart` consume the AC1 barrel only
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6). Forwards to the
/// implementation in `e2e_test_shared_standard_scenario_opener.dart`.
///
/// The call site injects the real `bootstrapForIntegrationTest` from
/// `package:colonizethis_app/main.dart` so the shared module stays free of
/// the app's main-entry import; the widget-test pin in
/// `app/test/e2e_enter_standard_e2e_scenario_test.dart` exercises the
/// callable-parameter and AC1 barrel signature contracts.
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
