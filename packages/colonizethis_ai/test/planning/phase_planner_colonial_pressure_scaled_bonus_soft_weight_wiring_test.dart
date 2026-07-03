// Parameterized contract tests for the Phase 3 soft-weight wiring of the
// `scaleWeightedBonus`-shaped colonial-pressure helpers (Refs #2847, test
// consolidation Refs #3749 § Test streamlining).
//
// Several Phase 3 helpers migrated a hard-coded magnitude that previously
// activated on a binary `colonialPressure` / `nwAcquisitionWeight > 0.0` gate
// to a continuous `scaleWeightedBonus(weight, baseConstant)` projection
// (`lib/src/planning/planning_helpers.dart`). They all share one contract:
//
//   - `weight == 1.0` returns the legacy `baseConstant` exactly (identity-equal
//     full-weight anchor; future refactors must not weaken this contract).
//   - `weight <= 0.0` returns `0` (legacy `colonialPressure: false` /
//     `nwAcquisitionWeight <= 0.0` equivalent; a refactor that mis-routes the
//     weight read and applies a non-zero magnitude under zero weight fails).
//   - intermediate weights scale linearly (`round(baseConstant × weight)`).
//   - out-of-range weights clamp (`> 1.0 -> 1.0`, `< 0.0 -> 0.0`) so callers do
//     not need to pre-clamp.
//   - the projection is pure / deterministic and non-decreasing across
//     `[0.0, 1.0]`.
//
// This file consolidates the previously per-helper wiring suites
// (`phase_planner_conquest_colonial_pressure_floor_soft_weight_wiring_test.dart`,
// `phase_planner_naval_colonial_pressure_floor_soft_weight_wiring_test.dart`,
// `phase_planner_diplomacy_nw_tribe_bonus_soft_weight_wiring_test.dart`) into one
// table-driven contract test so the shared contract lives in a single place,
// while the domain-specific threshold relationships that justify each magnitude
// are retained as representative readability pins below.
//
// The boolean Phase 2 resolvers and the per-domain weight resolvers
// (`resolvePhase*ColonialPressureActive`, `resolvePhase*ColonialPressureWeight`,
// etc.) remain pinned by their own resolver suites; this file targets only the
// scaled-magnitude helpers the Phase 3 slice migrated. The structurally
// different soft-weight consumers keep their dedicated suites: the economy
// threshold caps (null / span-interpolation contracts) are consolidated in
// `phase_planner_threshold_cap_soft_weight_wiring_test.dart`, and the
// behavioural `pickBuildOrder` / `evaluateStrategicGoalScores` /
// `computeDiplomaticCandidateScores` integration pins live in their own
// `*_cargo_bonus_test.dart` / `*_colonial_pressure_test.dart` /
// `*_nw_suppression_test.dart` / `*_ow_bonus_scaling_test.dart` files (these
// are behavioural integration pins, not the `scaleWeightedBonus` contract, so
// they are intentionally excluded from the two `*soft_weight_wiring_test.dart`
// parameterized contract files).

import 'package:colonizethis_ai/src/planning/naval_planner.dart'
    show kNavalRunMinWeight;
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart'
    show kPhasePriorityNwTreasuryRecoveryFloor;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

/// One `scaleWeightedBonus`-shaped helper under contract: its [label], the
/// legacy full-weight [baseConstant], and a [project] adapter applying the
/// helper for a given weight.
typedef _ScaledBonusHelper = ({
  String label,
  int baseConstant,
  int Function(double weight) project,
});

/// Early-sprint default soft curve plateau (`newWorldAcquisition = 0.05` for
/// `oldWorldProvincesOwned <= 7`); shared by the per-helper early-sprint pins.
const double _earlySprintWeight = 0.05;

final List<_ScaledBonusHelper> _helpers = <_ScaledBonusHelper>[
  (
    label: 'conquestColonialPressureMinWeightFloor',
    baseConstant: kConquestArmyMoveMinWeightWhenColonialPressure,
    project: (w) => conquestColonialPressureMinWeightFloor(
      colonialPressureWeight: w,
    ),
  ),
  (
    label: 'navalColonialPressureWeightBonus',
    baseConstant: kColonialNavalWeightBonus,
    project: (w) => navalColonialPressureWeightBonus(colonialPressureWeight: w),
  ),
  (
    label: 'navalColonialPressureMinWeightFloor',
    baseConstant: kColonialNavalMinWeightWhenPressure,
    project: (w) =>
        navalColonialPressureMinWeightFloor(colonialPressureWeight: w),
  ),
  (
    label: 'declareWarColonialNwTribeDominanceBonus',
    baseConstant: kDeclareWarColonialNwTribeDominanceBonus,
    project: (w) =>
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: w),
  ),
  (
    label: 'declareWarColonialNwTribePriorityOverOwMinorBonus',
    baseConstant: kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
    project: (w) => declareWarColonialNwTribePriorityOverOwMinorBonus(
      nwAcquisitionWeight: w,
    ),
  ),
];

void main() {
  group(
    'Phase 3 colonial-pressure scaled-bonus soft-weight contract '
    '(Refs #2847; consolidated Refs #3749)',
    () {
      for (final helper in _helpers) {
        group(helper.label, () {
          test(
            'weight = 1.0 is identity-equal to the legacy magnitude '
            '(full-weight anchor)',
            () {
              expect(
                helper.project(1.0),
                helper.baseConstant,
                reason:
                    '${helper.label}: weight = 1.0 must produce the legacy '
                    'magnitude (${helper.baseConstant}) exactly so a future '
                    'refactor cannot weaken the full-weight pull.',
              );
            },
          );

          test('weight = 0.0 returns 0 (regression guard)', () {
            expect(
              helper.project(0.0),
              0,
              reason:
                  '${helper.label}: weight = 0.0 must return 0 (legacy '
                  'colonialPressure = false / nwAcquisitionWeight <= 0.0 '
                  'equivalent) so a mis-routed weight read surfaces here.',
            );
          });

          test('weight = 0.5 scales linearly (round(K × 0.5))', () {
            expect(
              helper.project(0.5),
              (helper.baseConstant * 0.5).round(),
              reason:
                  '${helper.label}: weight = 0.5 must scale the legacy '
                  'magnitude by 0.5 exactly: '
                  'round(${helper.baseConstant} × 0.5) = '
                  '${(helper.baseConstant * 0.5).round()}.',
            );
          });

          test(
            'early-sprint default curve weight (0.05) scales linearly',
            () {
              expect(
                helper.project(_earlySprintWeight),
                (helper.baseConstant * _earlySprintWeight).round(),
                reason:
                    '${helper.label}: early-sprint weight '
                    '($_earlySprintWeight) must collapse the magnitude to '
                    'round(${helper.baseConstant} × $_earlySprintWeight) = '
                    '${(helper.baseConstant * _earlySprintWeight).round()} so '
                    'the OW conquest sprint stays dominant.',
              );
            },
          );

          test('weight > 1.0 clamps to the full-weight anchor', () {
            expect(
              helper.project(2.0),
              helper.baseConstant,
              reason:
                  '${helper.label}: weight > 1.0 must clamp to 1.0 and '
                  'produce the legacy magnitude exactly so unclamped upstream '
                  'callers do not overshoot.',
            );
          });

          test('weight < 0.0 returns 0 (negative-weight regression guard)', () {
            expect(
              helper.project(-1.0),
              0,
              reason:
                  '${helper.label}: weight < 0.0 must clamp to 0.0 and '
                  'return 0 so a transient negative weight cannot flip the '
                  'magnitude sign.',
            );
          });

          test('deterministic across repeated calls (Must-have #7)', () {
            final a = helper.project(0.3);
            final b = helper.project(0.3);
            final c = helper.project(0.3);
            expect(a, b, reason: '${helper.label}: two-call determinism');
            expect(b, c, reason: '${helper.label}: three-call determinism');
          });

          test(
            'non-decreasing across [0.0, 1.0] (monotonic scaling)',
            () {
              const samples = <double>[
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
                final current = helper.project(w);
                expect(
                  current,
                  greaterThanOrEqualTo(previous),
                  reason:
                      '${helper.label}: magnitude at weight = $w ($current) '
                      'must be >= the previous sample ($previous) — the '
                      'colonial-pressure pull is non-decreasing as the NW '
                      'acquisition priority rises.',
                );
                previous = current;
              }
            },
          );
        });
      }
    },
  );

  group(
    'Phase 3 colonial-pressure domain threshold relationships (Refs #2847)',
    () {
      test(
        'conquest early-sprint floor is strictly below the stalled-expansion '
        'floor',
        () {
          // The early-sprint colonial-pressure floor must stay a token nudge
          // below the stalled-expansion floor so the OW conquest sprint is not
          // dominated by colonial pulls when stalled-expansion pressure
          // applies.
          expect(
            conquestColonialPressureMinWeightFloor(
              colonialPressureWeight: _earlySprintWeight,
            ),
            lessThan(kConquestArmyMoveMinWeightWhenStalled),
            reason:
                'Early-sprint conquest colonial-pressure floor must be '
                'strictly less than kConquestArmyMoveMinWeightWhenStalled '
                '($kConquestArmyMoveMinWeightWhenStalled).',
          );
        },
      );

      test(
        'naval early-sprint bonus and floor stay below kNavalRunMinWeight '
        '(no naval engagement on the early OW sprint)',
        () {
          expect(
            navalColonialPressureWeightBonus(
              colonialPressureWeight: _earlySprintWeight,
            ),
            lessThan(kNavalRunMinWeight),
            reason:
                'Early-sprint naval colonial-pressure bonus must be strictly '
                'less than kNavalRunMinWeight ($kNavalRunMinWeight) so the '
                'early OW conquest sprint cannot engage the naval pass on the '
                'colonial-pressure bonus alone.',
          );
          expect(
            navalColonialPressureMinWeightFloor(
              colonialPressureWeight: _earlySprintWeight,
            ),
            lessThan(kNavalRunMinWeight),
            reason:
                'Early-sprint naval colonial-pressure floor must be strictly '
                'less than kNavalRunMinWeight ($kNavalRunMinWeight) so the OW '
                'conquest sprint is not diverted into naval planning.',
          );
        },
      );

      test(
        'naval resource-need override floor (0.60) lifts the floor above '
        'kNavalRunMinWeight (EXPAND-lock recovery engagement)',
        () {
          // At the resource-need treasury-recovery override the floor must
          // cross kNavalRunMinWeight so naval planning engages under
          // EXPAND-lock recovery without the GP needing to reach COLONIAL.
          expect(
            navalColonialPressureMinWeightFloor(
              colonialPressureWeight: kPhasePriorityNwTreasuryRecoveryFloor,
            ),
            greaterThan(kNavalRunMinWeight),
            reason:
                'Resource-need override floor '
                '($kPhasePriorityNwTreasuryRecoveryFloor) must lift the naval '
                'floor strictly above kNavalRunMinWeight ($kNavalRunMinWeight) '
                'so naval planning engages under EXPAND-lock recovery.',
          );
        },
      );
    },
  );
}
