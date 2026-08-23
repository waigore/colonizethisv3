// Clamp + determinism cases for colonial-pressure soft-weight pins (Refs #4602).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_goal_filter_colonial_pressure_support.dart';

void registerPhasePlannerColonialPressureClampCases() {
  test('deterministic across three repeated calls at the same weight '
      '(Must-have #7)', () {
    // Pure-function determinism: identical
    // `(snapshot, config, weight)` inputs must always yield
    // identical scores. The Phase 3 wiring must not introduce any
    // stochastic behaviour.
    final a = colonialPressureScoresWithWeight(0.4);
    final b = colonialPressureScoresWithWeight(0.4);
    final c = colonialPressureScoresWithWeight(0.4);
    expect(a, b, reason: 'two-call determinism at weight = 0.4');
    expect(b, c, reason: 'three-call determinism at weight = 0.4');
  });

  test('weight values outside [0.0, 1.0] are clamped to the valid range', () {
    // Defensive contract: out-of-range weights are clamped to
    // `[0.0, 1.0]` before scaling. A weight above 1.0 must not
    // amplify the legacy K floors (catastrophic over-pressure); a
    // weight below 0.0 must collapse cleanly to the hard-suppress
    // equivalent.
    final overflowScores = colonialPressureScoresWithWeight(2.0);
    final fullScores = colonialPressureScoresWithWeight(1.0);
    final underflowScores = colonialPressureScoresWithWeight(-1.0);
    final zeroScores = colonialPressureScoresWithWeight(0.0);
    expect(
      overflowScores[StrategicGoal.conquer]!,
      fullScores[StrategicGoal.conquer]!,
      reason: 'weight > 1.0 must clamp to 1.0 — no amplification.',
    );
    expect(
      overflowScores[StrategicGoal.diplomacy]!,
      fullScores[StrategicGoal.diplomacy]!,
      reason: 'weight > 1.0 must clamp to 1.0 — same diplomacy penalty.',
    );
    expect(
      underflowScores[StrategicGoal.diplomacy]!,
      zeroScores[StrategicGoal.diplomacy]!,
      reason: 'weight < 0.0 must clamp to 0.0 — no diplomacy penalty.',
    );
  });
}
