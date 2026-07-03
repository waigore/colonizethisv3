// Parameterized contract tests for the Phase 3 soft-weight wiring of the
// colonial-pressure *threshold-cap* helpers (Refs #2847, test consolidation
// Refs #3749 § Test streamlining).
//
// Two Phase 3 helpers migrated a hard-coded colonial-pressure threshold cap
// from a binary `colonialPressure` gate to a continuous weight projection
// (`lib/src/planning/phase_planner_economy_filter.dart`). Unlike the
// `scaleWeightedBonus`-shaped helpers consolidated in
// `phase_planner_colonial_pressure_scaled_bonus_soft_weight_wiring_test.dart`,
// the two cap helpers do **not** share one projection shape — they differ in
// their off value and their monotonic direction:
//
//   - `economyColonialPressureCivilianWorkThresholdCap({colonialPressureWeight,
//     uncappedThreshold})` interpolates *down* from the uncapped threshold to
//     the legacy `kColonialCivilianWorkThresholdCap` as weight rises, so its
//     off value (weight <= 0) is the uncapped threshold and its cap is
//     **non-increasing** in weight.
//   - `economyColonialPressureBuildOrderThresholdCap({colonialPressureWeight})`
//     scales *up* from `null` (no cap) to the legacy
//     `kColonialBuildOrderThresholdWhenOwnedNwUnderPressure` as weight rises,
//     so its off value (weight <= 0) is `null` and its cap is
//     **non-decreasing** in weight.
//
// This file consolidates the previously per-helper wiring suites
// (`phase_planner_economy_civilian_threshold_cap_soft_weight_wiring_test.dart`,
// `phase_planner_economy_build_order_threshold_cap_soft_weight_wiring_test.dart`)
// into one source. The portion of the contract both helpers share (off value
// at zero weight, full-weight anchor, out-of-range clamp, determinism) is
// table-driven across both helpers; the per-helper monotonic direction, span
// interpolation, and site-specific magnitude pins (early-sprint curve,
// resource-need override floor) that justify each cap are retained as
// representative readability groups below, plus the build-order
// NW-ownership tagalong resolver pins.
//
// The boolean Phase 2 resolver (`resolvePhaseEconomyColonialPressureActive`)
// and weight resolver (`resolvePhaseEconomyColonialPressureWeight`) remain
// pinned by their own suites; this file targets only the threshold-cap
// helpers the Phase 3 slice migrated.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

/// One colonial-pressure threshold-cap helper under contract: its [label], the
/// value it returns at zero weight ([offValue] — the uncapped threshold for the
/// civilian helper, `null` for the build-order helper), the legacy full-weight
/// magnitude ([fullValue]), and a [project] adapter applying the helper for a
/// given weight.
typedef _CapHelper = ({
  String label,
  int? offValue,
  int fullValue,
  int? Function(double weight) project,
});

/// Uncapped civilian-work threshold fed to the civilian cap helper; matches the
/// default-40 bar the production caller passes (`_runEconomyDomainPlanners`).
const int _uncappedCivilianThreshold = 40;

final List<_CapHelper> _helpers = <_CapHelper>[
  (
    label: 'economyColonialPressureCivilianWorkThresholdCap',
    offValue: _uncappedCivilianThreshold,
    fullValue: kColonialCivilianWorkThresholdCap,
    project: (w) => economyColonialPressureCivilianWorkThresholdCap(
      colonialPressureWeight: w,
      uncappedThreshold: _uncappedCivilianThreshold,
    ),
  ),
  (
    label: 'economyColonialPressureBuildOrderThresholdCap',
    offValue: null,
    fullValue: kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
    project: (w) => economyColonialPressureBuildOrderThresholdCap(
      colonialPressureWeight: w,
    ),
  ),
];

void main() {
  group(
    'Phase 3 colonial-pressure threshold-cap soft-weight contract '
    '(Refs #2847; consolidated Refs #3749)',
    () {
      for (final helper in _helpers) {
        group(helper.label, () {
          test(
            'weight = 0.0 returns the off value (legacy colonialPressure = '
            'false equivalent / regression guard)',
            () {
              expect(
                helper.project(0.0),
                helper.offValue,
                reason:
                    '${helper.label}: weight = 0.0 must return the off value '
                    '(${helper.offValue}) so a future refactor that applies '
                    'the cap under zero weight surfaces here.',
              );
            },
          );

          test(
            'weight = 1.0 is identity-equal to the legacy magnitude '
            '(full-weight anchor)',
            () {
              expect(
                helper.project(1.0),
                helper.fullValue,
                reason:
                    '${helper.label}: weight = 1.0 must produce the legacy '
                    'magnitude (${helper.fullValue}) exactly so a future '
                    'refactor cannot weaken the full-weight cap.',
              );
            },
          );

          test('weight > 1.0 clamps to the full-weight anchor', () {
            expect(
              helper.project(2.0),
              helper.fullValue,
              reason:
                  '${helper.label}: weight > 1.0 must clamp to 1.0 and produce '
                  'the legacy magnitude exactly so unclamped upstream callers '
                  'do not overshoot the legacy cap.',
            );
          });

          test('deterministic across repeated calls (Must-have #7)', () {
            final a = helper.project(0.3);
            final b = helper.project(0.3);
            final c = helper.project(0.3);
            expect(a, b, reason: '${helper.label}: two-call determinism');
            expect(b, c, reason: '${helper.label}: three-call determinism');
          });
        });
      }
    },
  );

  group(
    'economyColonialPressureCivilianWorkThresholdCap span interpolation '
    '(Refs #2847)',
    () {
      const uncapped = _uncappedCivilianThreshold;

      test(
        'weight = 0.5 returns round(40 - 28 × 0.5) = 26 '
        '(continuous linear scaling)',
        () {
          final expected =
              (uncapped - (uncapped - kColonialCivilianWorkThresholdCap) * 0.5)
                  .round();
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 0.5,
              uncappedThreshold: uncapped,
            ),
            expected,
            reason:
                'weight = 0.5 must interpolate the cap linearly: '
                'round(40 - (40 - $kColonialCivilianWorkThresholdCap) × 0.5) = '
                '$expected.',
          );
        },
      );

      test(
        'weight = 0.05 (early-sprint default curve) relaxes the default-40 '
        'bar by a single point',
        () {
          final capAtEarlySprint =
              economyColonialPressureCivilianWorkThresholdCap(
                colonialPressureWeight: 0.05,
                uncappedThreshold: uncapped,
              );
          final expected =
              (uncapped - (uncapped - kColonialCivilianWorkThresholdCap) * 0.05)
                  .round();
          expect(
            capAtEarlySprint,
            expected,
            reason:
                'Early-sprint cap must equal round(40 - (40 - '
                '$kColonialCivilianWorkThresholdCap) × 0.05) = $expected.',
          );
          expect(
            capAtEarlySprint,
            greaterThan(uncapped - 2),
            reason:
                'Early-sprint cap ($capAtEarlySprint) must stay within a '
                'single point of the uncapped threshold ($uncapped) so the OW '
                'conquest sprint is not diverted by colonial pressure at '
                'OW <= 7.',
          );
        },
      );

      test(
        'weight = 0.60 (resource-need override floor) lowers the bar '
        '(Refs #2924)',
        () {
          final expected =
              (uncapped - (uncapped - kColonialCivilianWorkThresholdCap) * 0.60)
                  .round();
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 0.60,
              uncappedThreshold: uncapped,
            ),
            expected,
            reason:
                'Resource-need override floor (0.60) must lower the cap to '
                'round(40 - (40 - $kColonialCivilianWorkThresholdCap) × 0.60) = '
                '$expected.',
          );
        },
      );

      test(
        'cap scales monotonically non-increasing across [0.0, 1.0]',
        () {
          final samples = <double>[0.0, 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0];
          var previous = uncapped + 1;
          for (final w in samples) {
            final current = economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: w,
              uncappedThreshold: uncapped,
            );
            expect(
              current,
              lessThanOrEqualTo(previous),
              reason:
                  'Cap at weight = $w ($current) must be <= the previous '
                  'sample ($previous) — the civilian-work bar is '
                  'non-increasing as the NW acquisition priority rises.',
            );
            previous = current;
          }
        },
      );
    },
  );

  group(
    'economyColonialPressureBuildOrderThresholdCap scaling pins (Refs #2847)',
    () {
      test('weight = -0.5 returns null (negative-weight regression guard)', () {
        expect(
          economyColonialPressureBuildOrderThresholdCap(
            colonialPressureWeight: -0.5,
          ),
          isNull,
          reason:
              'A negative weight must return null (no cap) so a transient '
              'negative weight cannot flip the cap on.',
        );
      });

      test('weight = 0.5 scales linearly (-> 8)', () {
        expect(
          economyColonialPressureBuildOrderThresholdCap(
            colonialPressureWeight: 0.5,
          ),
          8,
        );
      });

      test('early-sprint curve weight 0.05 returns token cap 1', () {
        expect(
          economyColonialPressureBuildOrderThresholdCap(
            colonialPressureWeight: 0.05,
          ),
          1,
        );
      });

      test('resource-need override floor 0.60 returns cap 9 (Refs #2924)', () {
        expect(
          economyColonialPressureBuildOrderThresholdCap(
            colonialPressureWeight: 0.60,
          ),
          9,
        );
      });

      test('cap scales monotonically non-decreasing as weight rises', () {
        final caps = <int?>[
          for (var w = 0.05; w <= 1.0; w += 0.05)
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: w,
            ),
        ];
        for (var i = 1; i < caps.length; i++) {
          expect(
            caps[i]!,
            greaterThanOrEqualTo(caps[i - 1]!),
            reason: 'cap at step $i must not drop below prior step',
          );
        }
      });
    },
  );

  group(
    'resolvePhaseEconomyColonialBuildOrderThresholdCap NW-ownership tagalong',
    () {
      test(
        'returns null when newWorldProvincesOwned == 0 regardless of weight',
        () {
          const outcome = PhasePlanOutcome(
            phase: ObserverGoalPhase.colonial,
            priorityWeights: PhasePriorityWeights(
              oldWorldConquest: 0.1,
              newWorldAcquisition: 1.0,
              oldWorldCivilian: 0.1,
              newWorldCivilian: 0.9,
            ),
          );
          expect(
            resolvePhaseEconomyColonialBuildOrderThresholdCap(
              phasePlan: outcome,
              colonial: ColonialSummary(),
            ),
            isNull,
          );
        },
      );

      test(
        'EXPAND with early-sprint weight and NW owned returns scaled cap',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyColonialBuildOrderThresholdCap(
              phasePlan: outcome,
              colonial: ColonialSummary(newWorldProvincesOwned: 1),
            ),
            1,
          );
        },
      );
    },
  );
}
