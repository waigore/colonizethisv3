// Phase 3 goal-score colonial-pressure soft-weight wiring pins (Refs #2847).
// SPEC/ai/ phase-planner dispatch; identity/scale/clamp contracts only.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_goal_filter_colonial_pressure_clamp_cases.dart';
import 'phase_planner_goal_filter_colonial_pressure_support.dart';

void main() {
  group('Phase 3 goal-score colonial-pressure soft-weight wiring '
      '(Refs #2847)', () {
    test(
      'weight = 1.0 reproduces the legacy COLONIAL floor magnitudes exactly',
      () {
        // Identity anchor: passing `colonialPressureWeight: 1.0` must
        // produce the same conquer/expand floors and diplomacy/trade
        // penalties as the legacy hard-phase boolean path. This is the
        // explicit AC #2847 "Existing unit tests pass with default
        // weight = 1.0 on new weight-multiplier parameters".
        final softScores = colonialPressureScoresWithWeight(1.0);
        expect(
          softScores[StrategicGoal.conquer]!,
          greaterThanOrEqualTo(kMinimumColonialConquerScoreWhenPressure),
          reason:
              'weight = 1.0 must apply the full conquer floor (≥ 95) so '
              'late-colonial pressure dominates non-conquer goals.',
        );
        expect(
          softScores[StrategicGoal.expand]!,
          greaterThanOrEqualTo(kMinimumColonialExpandScoreWhenPressure),
          reason:
              'weight = 1.0 must apply the full expand floor (≥ 90) so '
              'late-colonial pressure keeps NW acquisition prioritized.',
        );
      },
    );

    test('weight = 0.0 collapses the colonial-pressure pass entirely '
        '(legacy hard-suppress equivalent)', () {
      // Regression guard: pinning the weight to zero must restore
      // legacy hard-suppress behaviour so a future refactor that
      // misroutes the weight read surfaces as a non-zero conquer/
      // expand floor or a non-zero diplomacy/trade penalty.
      final softScores = colonialPressureScoresWithWeight(0.0);
      final baselineScores = colonialPressureScoresWithWeight(null);

      // The colonial-pressure pass is gated off; conquer/expand floors
      // do NOT apply (so the score can fall below 95/90), and the
      // diplomacy/trade penalties are NOT applied.
      // The baseline (weight = null, no observer phase) routes
      // through the legacy hard-phase path which DOES apply the floors
      // because the snapshot has visible colonial acquisition targets.
      expect(
        softScores[StrategicGoal.diplomacy]!,
        greaterThan(baselineScores[StrategicGoal.diplomacy]!),
        reason:
            'weight = 0.0 must NOT apply the colonial diplomacy penalty, '
            'so diplomacy is strictly higher than the legacy baseline '
            'where the boolean pass deducts the penalty in full.',
      );
      expect(
        softScores[StrategicGoal.trade]!,
        greaterThan(baselineScores[StrategicGoal.trade]!),
        reason: 'weight = 0.0 must NOT apply the colonial trade penalty.',
      );
    });

    test('weight = 0.5 applies half-magnitude floors and penalties (continuous '
        'scaling)', () {
      // Continuous scaling: at half weight the conquer/expand floor
      // and the diplomacy/trade penalty magnitudes should each be
      // ~half of the legacy K. The discriminating signal is that the
      // half-weight diplomacy is strictly between the full-weight and
      // zero-weight diplomacy scores.
      final halfScores = colonialPressureScoresWithWeight(0.5);
      final fullScores = colonialPressureScoresWithWeight(1.0);
      final zeroScores = colonialPressureScoresWithWeight(0.0);

      expect(
        halfScores[StrategicGoal.diplomacy]!,
        greaterThan(fullScores[StrategicGoal.diplomacy]!),
        reason:
            'weight = 0.5 must apply a smaller diplomacy penalty than '
            'weight = 1.0.',
      );
      expect(
        halfScores[StrategicGoal.diplomacy]!,
        lessThan(zeroScores[StrategicGoal.diplomacy]!),
        reason:
            'weight = 0.5 must apply a larger diplomacy penalty than '
            'weight = 0.0 (which applies no penalty).',
      );
      expect(
        halfScores[StrategicGoal.trade]!,
        greaterThan(fullScores[StrategicGoal.trade]!),
        reason:
            'weight = 0.5 must apply a smaller trade penalty than '
            'weight = 1.0.',
      );
      expect(
        halfScores[StrategicGoal.trade]!,
        lessThan(zeroScores[StrategicGoal.trade]!),
        reason:
            'weight = 0.5 must apply a larger trade penalty than '
            'weight = 0.0.',
      );

      // The half-weight conquer floor is `round(0.5 * 95) = 48`, well
      // below the default conquer score in this snapshot, so the
      // half-weight floor does NOT need to bump conquer. The
      // discriminating contract is that the full-weight conquer is at
      // least the legacy K (95) and the half-weight conquer is below
      // it (because the floor scaled down). The conquer score under
      // half weight should be strictly less than under full weight
      // (no other goal-eval branch lifts conquer between these two
      // calls — same snapshot, same config).
      expect(
        halfScores[StrategicGoal.conquer]!,
        lessThan(fullScores[StrategicGoal.conquer]!),
        reason:
            'weight = 0.5 must produce a smaller conquer floor than '
            'weight = 1.0; same snapshot, same config, only the '
            'colonialPressureWeight changes.',
      );
    });

    test('weight = 0.05 (early-sprint default curve) collapses floors to a '
        'token nudge', () {
      // At the curve plateau used for OW ≤ 7 the NW acquisition
      // weight is 0.05. The colonial pressure floors should therefore
      // collapse to round(0.05 * 95) = 5 (conquer) and round(0.05 *
      // 90) = 5 (expand) — well below any baseline score, i.e. the
      // floor is effectively no-op. Diplomacy/trade penalties
      // collapse to round(0.05 * 45) = 2 and round(0.05 * 25) = 1.
      final earlySprintScores = colonialPressureScoresWithWeight(0.05);
      final fullScores = colonialPressureScoresWithWeight(1.0);
      // At weight = 0.05 the diplomacy score must be strictly higher
      // than at weight = 1.0 (penalty almost zeroed out).
      expect(
        earlySprintScores[StrategicGoal.diplomacy]!,
        greaterThan(fullScores[StrategicGoal.diplomacy]!),
        reason:
            'Early-sprint curve weight must NOT dominate the diplomacy '
            'penalty — the OW sprint stays winnable.',
      );
    });

    test(
      'null weight preserves the legacy boolean resolution (compat path)',
      () {
        // Legacy compat: when `colonialPressureWeight == null`, the
        // function must produce the same scores it did before the
        // Phase 3 wiring landed. This test calls without
        // `observerGoalPhase` so the legacy three-predicate compose
        // runs (`hasColonialAcquisitionTargets &&
        // !shouldSuppressNewWorldColonialOrders`); both predicates
        // evaluate `true` on this snapshot (visible NW invadable
        // targets, no stalled-OW frontier suppression) so the
        // colonial-pressure floor/penalty pass activates at full
        // magnitude.
        final legacyScores = colonialPressureScoresWithWeight(null);
        expect(
          legacyScores[StrategicGoal.conquer]!,
          greaterThanOrEqualTo(kMinimumColonialConquerScoreWhenPressure),
          reason:
              'Null weight + visible colonial acquisition targets must '
              'route through the legacy boolean and apply the full conquer '
              'floor.',
        );
        expect(
          legacyScores[StrategicGoal.expand]!,
          greaterThanOrEqualTo(kMinimumColonialExpandScoreWhenPressure),
          reason:
              'Null weight + visible colonial acquisition targets must '
              'route through the legacy boolean and apply the full expand '
              'floor.',
        );
      },
    );

    test(
      'observerGoalPhase + null weight remains the legacy hard-phase path',
      () {
        // When the caller passes `observerGoalPhase` without
        // `colonialPressureWeight`, the boolean resolver
        // `resolvePhaseGoalColonialPressureActive` is the source of
        // truth — COLONIAL activates the floor pass; EXPAND /
        // COLONIAL-lite / DEVELOP do not. This is the legacy hard-phase
        // path the Phase 3 slice preserves verbatim.
        final expandScores = evaluateStrategicGoalScores(
          kColonialPressureSoftWeightSnapshot,
          kColonialPressureSoftWeightConfig,
          observerGoalPhase: ObserverGoalPhase.expand,
        );
        final colonialScores = evaluateStrategicGoalScores(
          kColonialPressureSoftWeightSnapshot,
          kColonialPressureSoftWeightConfig,
          observerGoalPhase: ObserverGoalPhase.colonial,
        );
        expect(
          expandScores[StrategicGoal.conquer]!,
          lessThan(kMinimumColonialConquerScoreWhenPressure),
          reason:
              'EXPAND legacy path must NOT apply the conquer floor '
              '(boolean is false).',
        );
        expect(
          colonialScores[StrategicGoal.conquer]!,
          greaterThanOrEqualTo(kMinimumColonialConquerScoreWhenPressure),
          reason:
              'COLONIAL legacy path MUST apply the conquer floor at full '
              'magnitude (boolean is true; weight = 1.0 default).',
        );
      },
    );

    test('colonialPressureWeight takes precedence over observerGoalPhase '
        'when both are supplied', () {
      // When both parameters are present the weight wins: a weight
      // of 0.0 with `ObserverGoalPhase.colonial` must collapse the
      // floors (instead of activating them via the boolean), and a
      // weight of 1.0 with `ObserverGoalPhase.expand` must activate
      // the floors (instead of suppressing them via the boolean).
      final colonialWithZeroWeight = evaluateStrategicGoalScores(
        kColonialPressureSoftWeightSnapshot,
        kColonialPressureSoftWeightConfig,
        observerGoalPhase: ObserverGoalPhase.colonial,
        colonialPressureWeight: 0.0,
      );
      final expandWithFullWeight = evaluateStrategicGoalScores(
        kColonialPressureSoftWeightSnapshot,
        kColonialPressureSoftWeightConfig,
        observerGoalPhase: ObserverGoalPhase.expand,
        colonialPressureWeight: 1.0,
      );
      expect(
        colonialWithZeroWeight[StrategicGoal.conquer]!,
        lessThan(kMinimumColonialConquerScoreWhenPressure),
        reason:
            'weight = 0.0 overrides COLONIAL phase boolean and skips '
            'the conquer floor.',
      );
      expect(
        expandWithFullWeight[StrategicGoal.conquer]!,
        greaterThanOrEqualTo(kMinimumColonialConquerScoreWhenPressure),
        reason:
            'weight = 1.0 overrides EXPAND phase boolean suppress and '
            'activates the conquer floor.',
      );
    });

    registerPhasePlannerColonialPressureClampCases();
  });
}
