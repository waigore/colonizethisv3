// Unit tests for the Phase 3 soft-weight wiring of the naval planner
// colonial-pressure weight bonus and minimum-weight floor (Refs #2847).
//
// Mirrors the test pattern in:
//   - `phase_planner_conquest_colonial_pressure_floor_soft_weight_wiring_test.dart`
//   - `phase_planner_economy_build_pick_soft_weight_wiring_test.dart`
//   - `phase_planner_diplomacy_declare_war_soft_weight_wiring_test.dart`
//   - `phase_planner_goal_filter_soft_weight_wiring_test.dart`
//
// Pins the contract of the two new helpers that
// `computeNavalRunGate` consumes as the production source of truth for
// the colonial-pressure weight bonus and minimum-weight floor
// (previously hard-coded `weight += kColonialNavalWeightBonus` and
// `weight = kColonialNavalMinWeightWhenPressure` steps under the
// boolean `PhaseNavalDirectiveResolution.colonialPreferenceActive`):
//
//   - `navalColonialPressureWeightBonus({colonialPressureWeight})`
//   - `navalColonialPressureMinWeightFloor({colonialPressureWeight})`
//
// Contract pins (mirroring the conquest army-move colonial-pressure
// floor wiring contract):
//
//   - `colonialPressureWeight == 1.0` returns the legacy
//     `kColonialNavalWeightBonus` / `kColonialNavalMinWeightWhenPressure`
//     value exactly (identity-equal full-weight anchor; future
//     refactors must not weaken this contract).
//
//   - `colonialPressureWeight <= 0.0` returns `0` (no bonus / floor
//     applied — legacy `colonialPreferenceActive: false` equivalent;
//     future refactors that accidentally apply a bonus / floor under
//     zero weight must fail this pin).
//
//   - Intermediate weights produce a continuous linear scaling
//     (`round(magnitude × w)`). The early-sprint default curve weight
//     (0.05 at OW ≤ 7) collapses the floor / bonus to `<= 4`, well
//     below `kNavalRunMinWeight` (25) so the early OW conquest sprint
//     cannot engage the naval pass on the colonial-pressure floor
//     alone. The resource-need override weight (0.60 when
//     treasury / NW / cargo predicates hold) lifts the floor to `51`,
//     above `kNavalRunMinWeight`, engaging naval planning under
//     EXPAND-lock recovery.
//
//   - The helpers clamp out-of-range weights (`> 1.0 → 1.0`,
//     `< 0.0 → 0.0`) so external callers do not need to clamp upstream.
//
// The boolean Phase 2 directive
// (`PhaseNavalDirectiveResolution.colonialPreferenceActive`) and the
// weight resolver (`resolvePhaseNavalColonialPressureWeight`) are pinned
// by the directive resolver / priority-weight resolver tests
// respectively. This file targets only the bonus / floor helpers that
// the Phase 3 slice migrated from the legacy hard-coded magnitudes to
// the soft-phase weight scaling.

import 'package:colonizethis_ai/src/planning/naval_planner.dart'
    show kNavalRunMinWeight;
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart'
    show kPhasePriorityNwTreasuryRecoveryFloor;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group(
    'Phase 3 naval colonial-pressure weight bonus soft-weight wiring '
    '(Refs #2847)',
    () {
      test(
        'colonialPressureWeight = 1.0 identity-equal to legacy '
        'kColonialNavalWeightBonus (full-weight anchor)',
        () {
          // The Phase 3 contract: at full weight the helper must return
          // the legacy hard-phase bonus magnitude exactly. A future
          // refactor that drifts this value would weaken the
          // COLONIAL / COLONIAL-lite naval boost.
          expect(
            navalColonialPressureWeightBonus(colonialPressureWeight: 1.0),
            kColonialNavalWeightBonus,
            reason:
                'colonialPressureWeight = 1.0 must produce the legacy '
                'kColonialNavalWeightBonus ($kColonialNavalWeightBonus) '
                'bonus exactly.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.0 returns 0 (no bonus applied / '
        'regression guard)',
        () {
          // The Phase 3 contract: at zero weight no bonus must apply so
          // a future refactor that mis-routes the weight read and
          // applies a non-zero bonus under zero weight surfaces here.
          expect(
            navalColonialPressureWeightBonus(colonialPressureWeight: 0.0),
            0,
            reason:
                'colonialPressureWeight = 0.0 must return 0 so the '
                'colonial-pressure bonus does not raise the naval-pass '
                'weight (legacy colonialPreferenceActive = false '
                'equivalent).',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.5 returns round(65 × 0.5) '
        '(continuous linear scaling)',
        () {
          // Sanity pin: the helper must scale linearly between the
          // endpoints so the colonial-pressure naval boost tracks the
          // soft-phase NW acquisition priority continuously instead of
          // switching on/off at the EXPAND→COLONIAL boundary.
          expect(
            navalColonialPressureWeightBonus(colonialPressureWeight: 0.5),
            (kColonialNavalWeightBonus * 0.5).round(),
            reason:
                'colonialPressureWeight = 0.5 must scale the legacy '
                'bonus by 0.5 exactly: '
                'round($kColonialNavalWeightBonus × 0.5) = '
                '${(kColonialNavalWeightBonus * 0.5).round()}.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.05 (early-sprint default curve) '
        'collapses bonus to a token nudge below kNavalRunMinWeight',
        () {
          // The early-sprint default curve sits at
          // `newWorldAcquisition = 0.05` for OW <= 7. The
          // colonial-pressure bonus at this weight must collapse to a
          // token nudge so the OW conquest sprint cannot engage the
          // naval pass on the colonial-pressure bonus alone (the floor
          // helper carries the equivalent contract for the run gate).
          final bonusAtEarlySprint = navalColonialPressureWeightBonus(
            colonialPressureWeight: 0.05,
          );
          expect(
            bonusAtEarlySprint,
            (kColonialNavalWeightBonus * 0.05).round(),
            reason:
                'Early-sprint bonus must equal '
                'round($kColonialNavalWeightBonus × 0.05) = '
                '${(kColonialNavalWeightBonus * 0.05).round()}.',
          );
          expect(
            bonusAtEarlySprint,
            lessThan(kNavalRunMinWeight),
            reason:
                'Early-sprint colonial-pressure bonus '
                '($bonusAtEarlySprint) must be strictly less than '
                'kNavalRunMinWeight ($kNavalRunMinWeight) so the early '
                'OW conquest sprint cannot engage the naval pass on the '
                'colonial-pressure bonus alone.',
          );
        },
      );

      test(
        'colonialPressureWeight > 1.0 clamps to the full-weight anchor',
        () {
          // Defensive clamp pin: out-of-range weights must not amplify
          // the bonus beyond the legacy hard-phase magnitude.
          expect(
            navalColonialPressureWeightBonus(colonialPressureWeight: 2.0),
            kColonialNavalWeightBonus,
            reason:
                'colonialPressureWeight > 1.0 must clamp to 1.0 and '
                'produce the legacy bonus exactly so unclamped upstream '
                'callers do not overshoot the legacy magnitude.',
          );
        },
      );

      test(
        'colonialPressureWeight < 0.0 returns 0 (negative weight '
        'regression guard)',
        () {
          // Defensive clamp pin: negative weights must collapse to no
          // bonus so a future refactor that produces a transient
          // negative value during weight derivation does not flip the
          // bonus sign.
          expect(
            navalColonialPressureWeightBonus(colonialPressureWeight: -1.0),
            0,
            reason:
                'colonialPressureWeight < 0.0 must clamp to 0.0 and '
                'return 0 (no bonus applied).',
          );
        },
      );

      test(
        'deterministic across repeated calls with identical inputs '
        '(Must-have #7)',
        () {
          // Pure-function determinism: a future change that introduces
          // stochastic behaviour into the weight-to-bonus projection
          // must fail this pin.
          final a = navalColonialPressureWeightBonus(
            colonialPressureWeight: 0.3,
          );
          final b = navalColonialPressureWeightBonus(
            colonialPressureWeight: 0.3,
          );
          final c = navalColonialPressureWeightBonus(
            colonialPressureWeight: 0.3,
          );
          expect(a, b, reason: 'two-call determinism');
          expect(b, c, reason: 'three-call determinism');
        },
      );

      test(
        'bonus scales monotonically with colonialPressureWeight '
        '(non-decreasing across [0.0, 1.0])',
        () {
          // Non-decreasing contract: the bonus magnitude must never
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
            final current = navalColonialPressureWeightBonus(
              colonialPressureWeight: w,
            );
            expect(
              current,
              greaterThanOrEqualTo(previous),
              reason:
                  'Bonus at colonialPressureWeight = $w ($current) must '
                  'be >= bonus at the previous sample ($previous) — the '
                  'colonial-pressure boost is non-decreasing as the NW '
                  'acquisition priority rises.',
            );
            previous = current;
          }
        },
      );
    },
  );

  group(
    'Phase 3 naval colonial-pressure minimum-weight floor soft-weight '
    'wiring (Refs #2847)',
    () {
      test(
        'colonialPressureWeight = 1.0 identity-equal to legacy '
        'kColonialNavalMinWeightWhenPressure (full-weight anchor)',
        () {
          expect(
            navalColonialPressureMinWeightFloor(colonialPressureWeight: 1.0),
            kColonialNavalMinWeightWhenPressure,
            reason:
                'colonialPressureWeight = 1.0 must produce the legacy '
                'kColonialNavalMinWeightWhenPressure '
                '($kColonialNavalMinWeightWhenPressure) floor exactly.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.0 returns 0 (no floor applied / '
        'regression guard)',
        () {
          expect(
            navalColonialPressureMinWeightFloor(colonialPressureWeight: 0.0),
            0,
            reason:
                'colonialPressureWeight = 0.0 must return 0 so the '
                'colonial-pressure floor does not raise the naval-pass '
                'weight (legacy colonialPreferenceActive = false '
                'equivalent).',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.5 returns round(85 × 0.5) = 43 '
        '(continuous linear scaling)',
        () {
          expect(
            navalColonialPressureMinWeightFloor(colonialPressureWeight: 0.5),
            (kColonialNavalMinWeightWhenPressure * 0.5).round(),
            reason:
                'colonialPressureWeight = 0.5 must scale the legacy '
                'floor by 0.5 exactly: '
                'round($kColonialNavalMinWeightWhenPressure × 0.5) = '
                '${(kColonialNavalMinWeightWhenPressure * 0.5).round()}.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.05 (early-sprint default curve) '
        'collapses floor below kNavalRunMinWeight (no naval engagement '
        'on early sprint)',
        () {
          // At the early-sprint default curve the floor must collapse
          // below `kNavalRunMinWeight` so the early OW conquest sprint
          // cannot engage naval planning on the colonial-pressure floor
          // alone — preserves the OW-first behaviour the issue body
          // calls out ("19:1 ratio at OW=0..7").
          final floorAtEarlySprint = navalColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.05,
          );
          expect(
            floorAtEarlySprint,
            (kColonialNavalMinWeightWhenPressure * 0.05).round(),
            reason:
                'Early-sprint floor must equal '
                'round($kColonialNavalMinWeightWhenPressure × 0.05) = '
                '${(kColonialNavalMinWeightWhenPressure * 0.05).round()}.',
          );
          expect(
            floorAtEarlySprint,
            lessThan(kNavalRunMinWeight),
            reason:
                'Early-sprint colonial-pressure floor '
                '($floorAtEarlySprint) must be strictly less than '
                'kNavalRunMinWeight ($kNavalRunMinWeight) so the OW '
                'conquest sprint is not dominated by colonial pulls '
                'when the early-sprint default curve applies.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.60 (resource-need treasury-recovery '
        'override floor) lifts floor above kNavalRunMinWeight',
        () {
          // At the resource-need override floor (treasury / NW / cargo
          // predicates hold per § Resource-need overrides) the floor
          // must cross `kNavalRunMinWeight` so naval planning engages
          // under EXPAND-lock recovery without the GP needing to reach
          // COLONIAL first. This is the operative pin for the soft-
          // phase NW bootstrap design intent in issue #2847.
          final floorAtOverride = navalColonialPressureMinWeightFloor(
            colonialPressureWeight: kPhasePriorityNwTreasuryRecoveryFloor,
          );
          expect(
            floorAtOverride,
            (kColonialNavalMinWeightWhenPressure *
                    kPhasePriorityNwTreasuryRecoveryFloor)
                .round(),
            reason:
                'Override floor must equal '
                'round($kColonialNavalMinWeightWhenPressure × '
                '$kPhasePriorityNwTreasuryRecoveryFloor) = '
                '${(kColonialNavalMinWeightWhenPressure * kPhasePriorityNwTreasuryRecoveryFloor).round()}.',
          );
          expect(
            floorAtOverride,
            greaterThan(kNavalRunMinWeight),
            reason:
                'Resource-need override floor ($floorAtOverride) must '
                'be strictly greater than kNavalRunMinWeight '
                '($kNavalRunMinWeight) so naval planning engages under '
                'EXPAND-lock recovery without requiring the GP to reach '
                'COLONIAL first.',
          );
        },
      );

      test(
        'colonialPressureWeight > 1.0 clamps to the full-weight anchor',
        () {
          expect(
            navalColonialPressureMinWeightFloor(colonialPressureWeight: 2.0),
            kColonialNavalMinWeightWhenPressure,
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
          expect(
            navalColonialPressureMinWeightFloor(colonialPressureWeight: -1.0),
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
          final a = navalColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.3,
          );
          final b = navalColonialPressureMinWeightFloor(
            colonialPressureWeight: 0.3,
          );
          final c = navalColonialPressureMinWeightFloor(
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
            final current = navalColonialPressureMinWeightFloor(
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
