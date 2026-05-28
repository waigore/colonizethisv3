// Unit tests for the Phase 3 soft-weight wiring of the conquest
// army-move colonial-pressure minimum-weight floor (Refs #2847).
//
// Mirrors the test pattern in:
//   - `phase_planner_economy_build_pick_soft_weight_wiring_test.dart`
//   - `phase_planner_diplomacy_declare_war_soft_weight_wiring_test.dart`
//   - `phase_planner_goal_filter_soft_weight_wiring_test.dart`
//
// Pins the contract of the new
// `conquestColonialPressureMinWeightFloor({colonialPressureWeight})`
// helper that `runConquestArmyMovePlanner` consumes as the production
// source of truth for the colonial-pressure minimum army-move weight
// floor (previously a hard-coded
// `weight = kConquestArmyMoveMinWeightWhenColonialPressure` step under
// the boolean `resolvePhaseConquestColonialPressureActive`).
//
//   - `colonialPressureWeight == 1.0` returns the legacy
//     `kConquestArmyMoveMinWeightWhenColonialPressure` value exactly
//     (identity-equal full-weight anchor; future refactors must not
//     weaken this contract).
//
//   - `colonialPressureWeight <= 0.0` returns `0` (no floor applied —
//     legacy `colonialPressure: false` equivalent; future refactors that
//     accidentally apply a floor under zero weight must fail this pin).
//
//   - Intermediate weights produce a continuous linear scaling
//     (`round(45 × w)`). The early-sprint default curve weight (0.05 at
//     OW ≤ 7) collapses the floor to `2`, well below the
//     stalled-expansion floor so the OW conquest sprint is not
//     dominated.
//
//   - The helper clamps out-of-range weights (`> 1.0 → 1.0`,
//     `< 0.0 → 0.0`) so external callers do not need to clamp upstream.
//
// The boolean Phase 2 resolver
// (`resolvePhaseConquestColonialPressureActive`) and weight resolver
// (`resolvePhaseConquestColonialPressureWeight`) remain pinned by
// `phase_planner_conquest_wiring_test.dart` and
// `phase_planner_priority_weight_resolvers_test.dart` respectively.
// This file targets only the helper that the Phase 3 slice migrated
// from the legacy hard-coded floor magnitude to the soft-phase
// weight scaling.

import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group(
    'Phase 3 conquest army-move colonial-pressure floor soft-weight '
    'wiring (Refs #2847)',
    () {
      test(
        'colonialPressureWeight = 1.0 identity-equal to legacy '
        'kConquestArmyMoveMinWeightWhenColonialPressure '
        '(full-weight anchor)',
        () {
          // The Phase 3 contract: at full weight the helper must return
          // the legacy hard-phase floor magnitude exactly. A future
          // refactor that drifts this value would weaken the COLONIAL
          // army-move pull.
          expect(
            conquestColonialPressureMinWeightFloor(colonialPressureWeight: 1.0),
            kConquestArmyMoveMinWeightWhenColonialPressure,
            reason:
                'colonialPressureWeight = 1.0 must produce the legacy '
                'kConquestArmyMoveMinWeightWhenColonialPressure '
                '($kConquestArmyMoveMinWeightWhenColonialPressure) floor '
                'exactly.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.0 returns 0 (no floor applied / '
        'regression guard)',
        () {
          // The Phase 3 contract: at zero weight no floor must apply so
          // a future refactor that mis-routes the weight read and
          // applies a non-zero floor under zero weight surfaces here.
          expect(
            conquestColonialPressureMinWeightFloor(colonialPressureWeight: 0.0),
            0,
            reason:
                'colonialPressureWeight = 0.0 must return 0 so the '
                'colonial-pressure floor does not raise the army-move '
                'pass weight (legacy colonialPressure = false '
                'equivalent).',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.5 returns round(45 × 0.5) = 23 '
        '(continuous linear scaling)',
        () {
          // Sanity pin: the helper must scale linearly between the
          // endpoints so the colonial-pressure floor tracks the
          // soft-phase NW acquisition priority continuously instead of
          // switching on/off at the EXPAND→COLONIAL boundary.
          expect(
            conquestColonialPressureMinWeightFloor(colonialPressureWeight: 0.5),
            (kConquestArmyMoveMinWeightWhenColonialPressure * 0.5).round(),
            reason:
                'colonialPressureWeight = 0.5 must scale the legacy '
                'floor by 0.5 exactly: '
                'round(${kConquestArmyMoveMinWeightWhenColonialPressure} '
                '× 0.5) = ${(kConquestArmyMoveMinWeightWhenColonialPressure * 0.5).round()}.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.05 (early-sprint default curve) '
        'collapses floor to 2 — strictly below the stalled-expansion '
        'floor',
        () {
          // The early-sprint default curve sits at
          // `newWorldAcquisition = 0.05` for OW <= 7. The colonial-pressure
          // floor at this weight must collapse to a token nudge well
          // below the stalled-expansion floor so the OW conquest sprint
          // is not dominated by colonial pulls.
          final floorAtEarlySprint = conquestColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.05,
          );
          expect(
            floorAtEarlySprint,
            (kConquestArmyMoveMinWeightWhenColonialPressure * 0.05).round(),
            reason:
                'Early-sprint floor must equal '
                'round(${kConquestArmyMoveMinWeightWhenColonialPressure} '
                '× 0.05) = ${(kConquestArmyMoveMinWeightWhenColonialPressure * 0.05).round()}.',
          );
          expect(
            floorAtEarlySprint,
            lessThan(kConquestArmyMoveMinWeightWhenStalled),
            reason:
                'Early-sprint colonial-pressure floor '
                '($floorAtEarlySprint) must be strictly less than the '
                'stalled-expansion floor '
                '($kConquestArmyMoveMinWeightWhenStalled) so the OW '
                'conquest sprint is not dominated by colonial pulls '
                'when stalled-expansion pressure applies.',
          );
        },
      );

      test(
        'colonialPressureWeight > 1.0 clamps to the full-weight anchor',
        () {
          // Defensive clamp pin: out-of-range weights must not amplify
          // the floor beyond the legacy hard-phase magnitude.
          expect(
            conquestColonialPressureMinWeightFloor(colonialPressureWeight: 2.0),
            kConquestArmyMoveMinWeightWhenColonialPressure,
            reason:
                'colonialPressureWeight > 1.0 must clamp to 1.0 and '
                'produce the legacy floor exactly so unclamped upstream '
                'callers do not overshoot the legacy magnitude.',
          );
        },
      );

      test(
        'colonialPressureWeight < 0.0 returns 0 (negative weight '
        'regression guard)',
        () {
          // Defensive clamp pin: negative weights must collapse to no
          // floor so a future refactor that produces a transient
          // negative value during weight derivation does not flip the
          // floor sign.
          expect(
            conquestColonialPressureMinWeightFloor(
              colonialPressureWeight: -1.0,
            ),
            0,
            reason:
                'colonialPressureWeight < 0.0 must clamp to 0.0 and '
                'return 0 (no floor applied).',
          );
        },
      );

      test(
        'deterministic across repeated calls with identical inputs '
        '(Must-have #7)',
        () {
          // Pure-function determinism: a future change that introduces
          // stochastic behaviour into the weight-to-floor projection
          // must fail this pin.
          final a = conquestColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.3,
          );
          final b = conquestColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.3,
          );
          final c = conquestColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.3,
          );
          expect(a, b, reason: 'two-call determinism');
          expect(b, c, reason: 'three-call determinism');
        },
      );

      test(
        'floor scales monotonically with colonialPressureWeight '
        '(non-decreasing across [0.0, 1.0])',
        () {
          // Non-decreasing contract: the floor magnitude must never
          // shrink as the soft-phase NW acquisition priority rises.
          final samples = <double>[
            0.0,
            0.05,
            0.1,
            0.2,
            0.4,
            0.6,
            0.8,
            1.0,
          ];
          var previous = -1;
          for (final w in samples) {
            final current = conquestColonialPressureMinWeightFloor(
              colonialPressureWeight: w,
            );
            expect(
              current,
              greaterThanOrEqualTo(previous),
              reason:
                  'Floor at colonialPressureWeight = $w ($current) must '
                  'be >= floor at the previous sample ($previous) — the '
                  'colonial-pressure pull is non-decreasing as the NW '
                  'acquisition priority rises.',
            );
            previous = current;
          }
        },
      );
    },
  );
}
