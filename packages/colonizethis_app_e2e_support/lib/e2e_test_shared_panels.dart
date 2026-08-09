import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

export 'e2e_test_shared_fleet_nav.dart';
export 'e2e_test_shared_fleet_reach_loop.dart';
export 'e2e_test_shared_panel_text_assertions.dart';
export 'e2e_test_shared_production_panel.dart';
export 'e2e_test_shared_split_home_fleet.dart';
export 'e2e_test_shared_explore_assign.dart';

// `_e2eTapFirstEnabledTransferButtonInSplitDialog` previously lived here as a
// helper for split-fleet transfer-row taps but was never wired into any caller
// (`e2eSplitHomeFleetOnce` inlines its own `enabledLeftNudge` finder for the
// `>>` / `>` transfer keys). Static analysis flagged the symbol with
// `unused_element` since at least PR #2596. The dead declaration is removed
// here rather than carried forward so the shared-helpers surface only ships
// reachable code (Refs GitHub #2336 AC1 / AC2 shared-helper hygiene).

/// Opens the civilian units panel from the empire rail or the first civilian
/// marker, closing a conflicting naval/civilian sheet first when needed.
///
/// Single canonical implementation for full-turn and fleet E2E (GitHub #2336
/// / AC2). Uses adaptive waits for rail/marker readiness instead of blind
/// idle pumps.
///
/// The full rail-or-marker outer adaptive-poll loop body (bottom-sheet
/// dismissal → dialog dismissal → rail-tap arm → marker-tap arm → bounded
/// rail/marker hit-testable pump → adaptive idle pump) lives in
/// [e2eOpenPanelViaRailOrMarker]. This function forwards civilian-specific
/// finders, the `'civilian'` opener label that the helper interpolates into
/// every phase label (`pump_until_civilian_panel_after_trigger_tap`,
/// `wait_until_civilian_rail_hit_testable`, `wait_until_civilian_marker_hit_testable`,
/// `pump_until_civilian_rail_or_marker_hit_testable`,
/// `pump_until_civilian_opener_after_sheet_close`), and the byte-equivalent
/// timeout-diagnostic prefix. Refs GitHub #2336 AC1 / AC2 / AC10 (follow-up
/// slice from PR #2787 after the inner-attempt and post-sheet-close lifts).
Future<void> e2eOpenCivilianPanel(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_civilian_open',
}) {
  return e2eOpenPanelViaRailOrMarker(
    tester,
    openerLabel: 'civilian',
    railButton: find.byKey(kEmpireCivilianUnitsButtonKey),
    markerButton: find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
    panelRoot: find.byKey(kCtE2ECivilianPanelRootKey),
    afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
    overallTimeout: timeout,
    bottomSheetCloseTimeout: bottomSheetCloseTimeout,
    perf: perf,
    timeoutMessageBuilder: (t) =>
        'Timed out after ${t.inSeconds}s waiting for a civilian panel opener '
        '(empire rail or first-civilian marker)',
  );
}

/// Default cap for naval-panel open polling (parity with civilian panel opener).
const Duration kE2eDefaultNavalOpenTimeout = Duration(seconds: 20);

/// Opens the naval units panel from the empire rail or the first fleet marker,
/// dismissing transient UI and closing conflicting sheets when needed.
///
/// Single canonical implementation for fleet E2E (GitHub #2336); mirrors
/// [e2eOpenCivilianPanel] by forwarding naval-specific finders, the
/// `'naval'` opener label, and the naval timeout-diagnostic prefix into the
/// shared [e2eOpenPanelViaRailOrMarker] outer-loop helper. The helper
/// interpolates the `pump_until_naval_panel_after_trigger_tap`,
/// `wait_until_naval_rail_hit_testable`,
/// `wait_until_naval_marker_hit_testable`,
/// `pump_until_naval_rail_or_marker_hit_testable`, and
/// `pump_until_naval_opener_after_sheet_close` phase labels verbatim from
/// the `openerLabel` argument so downstream `E2E_TIMING|phase=...` log
/// scrapers and dashboards keep attributing settle time to the naval
/// opener. Refs GitHub #2336 AC1 / AC2 / AC10 (follow-up slice from
/// PR #2787 after the inner-attempt and post-sheet-close lifts).
Future<void> e2eOpenNavalPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_naval_open',
}) {
  return e2eOpenPanelViaRailOrMarker(
    tester,
    openerLabel: 'naval',
    railButton: find.byKey(kEmpireNavalUnitsButtonKey),
    markerButton: find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey),
    panelRoot: find.byKey(kCtE2ENavalPanelRootKey),
    afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
    overallTimeout: timeout,
    bottomSheetCloseTimeout: bottomSheetCloseTimeout,
    perf: perf,
    timeoutMessageBuilder: (t) =>
        'Timed out after ${t.inSeconds}s opening naval panel '
        '(empire naval rail or first-fleet marker)',
  );
}

/// Opens a map-marker panel when [markerButton] is tappable and [panelRoot] mounts.
///
/// Shared full-turn path for tile-scoped civilian/naval markers (GitHub #2336 AC2).
Future<void> e2eOpenPanelFromMarker(
  WidgetTester tester, {
  required Finder markerButton,
  required Finder panelRoot,
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  var panelPollMs = 25;
  while (sw.elapsed < timeout) {
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    final tappable = markerButton.hitTestable();
    if (tappable.evaluate().isEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      if (panelRoot.evaluate().isNotEmpty) {
        perf?.timing('open_panel_from_marker', sw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => markerButton.hitTestable().evaluate().isNotEmpty,
        timeout: Duration(milliseconds: panelPollMs),
        perf: perf,
        phaseName: 'pump_until_marker_hit_testable_after_dismiss',
      )) {
        panelPollMs = 25;
      } else {
        panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
      }
      continue;
    }
    await tester.tap(tappable.first, warnIfMissed: false);
    // Shared post-tap mount probe: byte-equivalent to the pre-lift inline
    // "fast hit-check → one explicit pump → bounded
    // [e2ePumpUntilConditionOrIdle] (3 s cap)" recipe so a regression that
    // dropped the post-pump fast-check on `e2eOpenPanelFromMarker` would
    // surface alongside the panel-opener pins for the same recipe. The
    // helper preserves the `pump_until_marker_panel_root_after_tap` phase
    // label so downstream `E2E_TIMING|phase=...` log scrapers keep
    // attributing post-tap settle time here. Refs GitHub #2336 AC1 / AC2 /
    // AC10 (follow-up slice from PR #2782).
    if (await e2eAwaitPanelMountAfterOpenerTap(
      tester,
      panelRoot,
      timeout: const Duration(seconds: 3),
      perf: perf,
      phaseName: 'pump_until_marker_panel_root_after_tap',
    )) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    panelPollMs = 25;
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s opening marker panel. '
    'Last exception: ${tester.takeException()}',
  );
}
