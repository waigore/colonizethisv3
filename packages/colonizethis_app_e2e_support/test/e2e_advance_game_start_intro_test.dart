/// Unit coverage for `e2eAdvanceGameStartIntroUntilDismissed` adaptive
/// backoff path. The helper's two idle-pump branches (loading spinner + no
/// tap target) previously paid a fixed 50ms frame per iteration; this test
/// pins the short-circuit behavior and adaptive ramp expectations introduced
/// for GitHub #2336 AC5 / pump-reduction.
///
/// The perf-attribution group at the bottom of the file pins the
/// `E2E_TIMING` / `E2E_COUNTER` markers the helper emits via [E2ePerfLog]
/// when callers thread a perf log through. The bootstrap chain
/// (`e2eBootstrapNewGameToMap` → `e2eWaitForMapHudAfterNewGameStart` →
/// `e2eAdvanceGameStartIntroUntilDismissed`) wires `perf` from the standard
/// scenario opener, so a silent regression in either the phase label, the
/// `result=...` meta tag, or the iteration counter would break the AC8
/// baseline timing pipeline (`tool/run_e2e_timing.sh` +
/// `tool/compare_e2e_timing.sh`) without surfacing in the legacy
/// short-circuit / timeout tests (which all pass `perf: null` by default).
/// Mirrors the perf-attribution pattern landed for
/// `e2eWaitForMapHudAfterNewGameStart` in PR #2960 (`app/test/
/// e2e_wait_for_map_hud_after_new_game_start_test.dart` § perf attribution).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/advance_game_start_intro_harness.dart';
import 'support/advance_game_start_intro_baseline_group.dart';
import 'support/advance_game_start_intro_multi_group.dart';
import 'support/advance_game_start_intro_perf_group.dart';

void main() {
  suppressLogsForTests();
  registerAdvanceGameStartIntroBaselineGroup();
  registerAdvanceGameStartIntroMultiLabelGroup();
  registerAdvanceGameStartIntroPerfGroup();
}
