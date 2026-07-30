import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Next interval after an idle poll pump in E2E busy-wait loops (25→50→75→100 ms).
/// Aligns with [e2eWaitUntilFound] backoff (`SPEC/program/e2e-integration-tests.md`, #2336).
int e2eAdaptivePollRampAfterIdle(int previousMs) {
  if (previousMs < 100) {
    return previousMs + 25;
  }
  return 100;
}

class E2ePerfLog {
  E2ePerfLog(this.testName);

  final String testName;
  final Map<String, int> _counters = <String, int>{};

  void bumpCounter(String name, {int by = 1, String? meta}) {
    _counters[name] = (_counters[name] ?? 0) + by;
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_COUNTER|test=$testName|name=$name|value=${_counters[name]}$metaPart',
    );
  }

  void timing(String phase, Duration elapsed, {String? meta}) {
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_TIMING|test=$testName|phase=$phase|ms=${elapsed.inMilliseconds}$metaPart',
    );
  }
}

Future<void> e2ePumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Next idle poll step for E2E `while` loops (GitHub #2336 / AC5): doubles the
/// previous pump duration until [maxMs] to reduce wasted frames on headless Linux.
int e2eNextIdlePollStepMs(int currentMs, {int maxMs = 500}) {
  final next = currentMs * 2;
  return next > maxMs ? maxMs : next;
}

/// Pumps with [e2eAdaptivePollRampAfterIdle] pacing until [finder] matches
/// nothing or [timeout] elapses.
///
/// Returns immediately when the finder is already empty. On timeout, returns
/// without throwing so callers can treat the wait as best-effort post-dismiss
/// settle (GitHub #2336 / AC5).
Future<void> e2ePumpUntilFinderEmpty(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final sw = Stopwatch()..start();
  if (finder.evaluate().isEmpty) {
    return;
  }
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: stepMs));
    if (finder.evaluate().isEmpty) {
      return;
    }
    stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
  }
}

/// Pumps until [finder] matches at least one widget or [timeout] elapses,
/// evaluating the finder before the first pump and ramping the pump interval
/// via the shared [e2eNextIdlePollStepMs] doubling backoff (25 → 500 ms cap).
/// Refs GitHub #2336 AC5 (adaptive polling) / Bottleneck 6 (single-source the
/// poll-step ramp).
Future<void> e2eWaitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) async {
  if (finder.evaluate().isNotEmpty) {
    perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
    perf?.timing(phaseName, Duration.zero, meta: 'result=found_immediate');
    return;
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have made [finder] non-empty just as `sw.elapsed` crossed
  // [timeout], so the loop's pre-pump check would never re-evaluate. Match
  // [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a successful
  // late pump still returns success instead of falling through to `fail()`.
  // Refs GitHub #2336 AC5 (adaptive polling) / busy-wait final-check fix.
  if (finder.evaluate().isNotEmpty) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=found_at_timeout');
    return;
  }
  if (diagnoseAfter > Duration.zero) {
    await e2ePumpFor(tester, diagnoseAfter);
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found_during_diagnose');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Waits until the shell shows a tappable **New Game** control (replaces a
/// fixed post-[bootstrapForIntegrationTest] pump; GitHub #2336 / AC4–AC5).
Future<void> e2eWaitForNewGameEntry(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
  E2ePerfLog? perf,
}) async {
  await e2eWaitUntilFound(
    tester,
    find.text('New Game').hitTestable(),
    timeout: timeout,
    perf: perf,
    phaseName: 'wait_for_new_game_entry',
  );
}

/// Pumps until [condition] returns true, evaluating [condition] before the
/// first pump and ramping the pump interval via the shared
/// [e2eNextIdlePollStepMs] doubling backoff (same 25 → 500 ms cap as
/// [e2eWaitUntilFound]). Refs GitHub #2336 (`pumpUntil` helper) / AC5 /
/// Bottleneck 6 (single-source the poll-step ramp).
Future<void> e2ePumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'pump_until',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter('pump_until_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (condition()) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=met');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have flipped [condition] just as `sw.elapsed` crossed
  // [timeout], so the loop's pre-pump check would never re-evaluate. Match
  // [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a successful
  // late pump still returns success instead of falling through to `fail()`.
  // Refs GitHub #2336 AC5 (adaptive polling) / busy-wait final-check fix.
  if (condition()) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=met_at_timeout');
    return;
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s in e2ePumpUntil ($phaseName). '
    'Last exception: ${tester.takeException()}',
  );
}

/// Pumps until [condition] returns true or [timeout] elapses.
///
/// Evaluates [condition] before the first pump. Uses
/// [e2eAdaptivePollRampAfterIdle] pacing (25→50→75→100 ms cap). Returns whether
/// the condition became true; does **not** throw when [timeout] expires
/// (best-effort post-tap settle; GitHub #2336).
Future<bool> e2ePumpUntilConditionOrIdle(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'pump_until_condition_or_idle',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter(
    'pump_until_condition_or_idle_calls',
    meta: 'phase=$phaseName',
  );
  if (condition()) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=immediate');
    return true;
  }
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: stepMs));
    if (condition()) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=met');
      return true;
    }
    stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  return false;
}

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

/// Returns after the first [Finder] has at least one hit-testable match.
///
/// Evaluates the finders before the first pump and ramps the pump interval via
/// the shared [e2eNextIdlePollStepMs] doubling backoff (25 → 500 ms cap). Refs
/// GitHub #2336 AC5 / Bottleneck 6 (single-source the poll-step ramp).
Future<void> e2eWaitUntilAnyFinderHitTestable(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_any',
}) async {
  if (finders.isEmpty) {
    return;
  }
  for (final finder in finders) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
      perf?.timing(phaseName, Duration.zero, meta: 'result=found_immediate');
      return;
    }
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    for (final finder in finders) {
      if (finder.hitTestable().evaluate().isNotEmpty) {
        perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
        return;
      }
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have made one of [finders] hit-testable just as `sw.elapsed`
  // crossed [timeout], so the loop's pre-pump check would never re-evaluate.
  // Match [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a
  // successful late pump still returns success instead of falling through to
  // `fail()`. Refs GitHub #2336 AC5 (adaptive polling) / busy-wait
  // final-check fix.
  for (final finder in finders) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found_at_timeout');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for any of $finders. '
    'Last exception: ${tester.takeException()}',
  );
}

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
