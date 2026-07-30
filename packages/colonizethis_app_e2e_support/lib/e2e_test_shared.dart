import 'package:flutter_test/flutter_test.dart';

export 'e2e_test_shared_adaptive_polling.dart';
export 'e2e_test_shared_bundled_explore_failure.dart';
export 'e2e_test_shared_bundled_explore_retry.dart';
export 'e2e_test_shared_civilian_work_tile_pick.dart';
export 'e2e_test_shared_diagnostics.dart';
export 'e2e_test_shared_dismiss_alert_dialog.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell_escalation.dart';
export 'e2e_test_shared_dismiss_generic_ok.dart';
export 'e2e_test_shared_dismiss_snackbar.dart';
export 'e2e_test_shared_dismiss_transient_ui.dart';
export 'e2e_test_shared_expansion_tile.dart';
export 'e2e_test_shared_final_naval_reach_check.dart';
export 'e2e_test_shared_first_fleet_move.dart';
export 'e2e_test_shared_fleet_reach_loop_test_total_meta.dart';
export 'e2e_test_shared_fleet_reach_nw_predicates.dart';
export 'e2e_test_shared_fleet_reach_scenario_preamble.dart';
export 'e2e_test_shared_integration_test_bootstrap.dart';
export 'e2e_test_shared_next_turn_advance.dart';
export 'e2e_test_shared_panel_open_outer_loop.dart';
export 'e2e_test_shared_panel_open_post_tap_probe.dart';
export 'e2e_test_shared_panel_open_sheet_close.dart';
export 'e2e_test_shared_panel_open_trigger_attempt.dart';
export 'e2e_test_shared_panel_text_match.dart';
export 'e2e_test_shared_naval_move.dart';
export 'e2e_test_shared_panels.dart';
export 'e2e_test_shared_region_tabs.dart';
export 'e2e_test_shared_standard_scenario_opener.dart';
export 'e2e_test_shared_intro.dart';
export 'e2e_test_shared_bottom_sheet.dart';
export 'e2e_test_shared_hit_testable.dart';
export 'e2e_test_shared_civilian_taps.dart';
export 'e2e_test_shared_move_dialog_finders.dart';

// `e2eOldWorldRegionChipAppearsSelected`,
// `e2eNewWorldRegionChipAppearsSelected`,
// `e2eTapNewWorldRegionTabIfPresent`, and `e2eTapOldWorldRegionTab` live in
// `e2e_test_shared_region_tabs.dart` and are surfaced from this barrel via
// the `export` directive at the top of the file so the map region-tab
// predicate + tap-and-settle group stays separable from the panel-opener
// and panel-action helpers in this file. The extraction keeps this file
// under the repo-lint `dart_file_non_comment_line_size` budget
// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines) and matches the
// barrel-re-export pattern already used by the fleet-reach NW predicates
// (`e2e_test_shared_fleet_reach_nw_predicates.dart`), the panel-opener
// helpers (`e2e_test_shared_panel_open_*.dart`), and the panel-action
// helpers (`e2e_test_shared_panel_text_*.dart`). Refs GitHub #2336 AC1 /
// AC2 / Bottleneck 6.

// `e2eTextLooksLikeNewWorldLocationLine`,
// `e2eNavalPanelShowsNonHomeFleetInNewWorld`,
// `e2eNonHomeHumanFleetInNewWorldFromCtSnapshot`,
// `e2eFleetReachDoneFromCtSnapshotOnly`,
// `e2eHarnessDetectsNonHomeFleetInNewWorld`,
// `e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot`,
// `e2eNwCoastalProvincesAdjacentToFleetSea`,
// `e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot`, and
// `e2eExploreAssignEnabledFromCivilianSnapshot` live in
// `e2e_test_shared_fleet_reach_nw_predicates.dart` and are surfaced from this
// barrel via the `export` directive at the top of the file so the
// snapshot-first / widget-fallback fleet-in-NW detection group stays
// separable from the panel-opener and panel-action helpers in this file.
// The extraction keeps this file under the repo-lint
// `dart_file_non_comment_line_size` budget
// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines) and matches the
// barrel-re-export pattern already used by the panel-opener helpers
// (`e2e_test_shared_panel_open_*.dart`) and the panel-action helpers
// (`e2e_test_shared_panel_text_*.dart`). Refs GitHub #2336 AC1 / AC2 /
// Bottleneck 6.

/// Post-confirm turn resolution wait aligned with the 15s usability budget
/// (`colonizethis-turn-resolution-budget.mdc`).
const Duration kE2eNextTurnResolutionTimeout = Duration(seconds: 15);

/// Default 5-minute wall-clock cap per E2E scenario path.
///
/// Matches the **PR runtime rule** in `SPEC/program/e2e-integration-tests.md`
/// § Determinism and the `colonizethis-e2e-ui-stability.mdc` 5-minute rule:
/// any single integration-test scenario that exceeds this cap must fail fast
/// and emit timing markers so the regression is attributable.
const Duration kE2eMaxWallClock = Duration(minutes: 5);

/// Returns a callable wall-clock guard for the start of an E2E scenario.
///
/// Pattern:
///
/// ```dart
/// final wallClock = Stopwatch()..start();
/// final ensureUnderWallClock = e2eMakeWallClockGuard(
///   testName: 'new_game_full_turn',
///   stopwatch: wallClock,
/// );
/// // ... checkpoint after each major phase ...
/// ensureUnderWallClock('after bootstrap');
/// ```
///
/// The returned function fails the surrounding test (via `fail`) when the
/// elapsed wall-clock time exceeds [cap]. [testName] and the per-call `step`
/// label are emitted in the failure message so a regression is attributable
/// to a specific checkpoint and scenario, matching the fail-fast contract
/// documented in `SPEC/program/e2e-integration-tests.md` § Determinism
/// (Refs GitHub #2336 / `colonizethis-e2e-ui-stability.mdc`).
void Function(String step) e2eMakeWallClockGuard({
  required String testName,
  required Stopwatch stopwatch,
  Duration cap = kE2eMaxWallClock,
}) {
  return (String step) {
    if (stopwatch.elapsed > cap) {
      fail(
        '$testName exceeded ${cap.inMinutes} minute wall clock '
        'at $step (elapsed=${stopwatch.elapsed.inSeconds}s).',
      );
    }
  };
}
