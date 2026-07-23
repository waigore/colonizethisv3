// Smooth phase weighting / hysteresis tests for civilian build scoring
// (Refs #3793 slice 9, #4121 slice D).
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/civilian_build_scoring_scenarios.dart';

void main() {
  group('smooth phase weighting / hysteresis (Refs #3793 slice 9)', () {
    test(
      'nextCivilianBuildPhaseName: canonical EXPAND→COLONIAL→DEVELOP order',
      () {
        for (final (current, next) in civilianBuildNextPhaseCases) {
          expect(nextCivilianBuildPhaseName(current), next, reason: current);
        }
      },
    );

    test('ACHyst: Builder/Explorer ramp across expand→colonial', () {
      for (final (type, progress, expected) in civilianBuildSmoothRampCases) {
        expect(
          civilianBuildPhaseMultiplierSmooth(
            type,
            kCivilianBuildPhaseExpand,
            progress,
          ),
          expected,
          reason: 'type=$type p=$progress',
        );
      }
    });

    test('ACHyst: phaseProgress is clamped to [0,1]', () {
      // Below 0 clamps to the current-phase discrete value; above 1 clamps to
      // the next-phase value.
      expect(
        civilianBuildPhaseMultiplierSmooth(
          kUnitTypeBuilder,
          kCivilianBuildPhaseExpand,
          -5.0,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplierSmooth(
          kUnitTypeBuilder,
          kCivilianBuildPhaseExpand,
          5.0,
        ),
        1.0,
      );
    });

    test('ACHyst: candidate score applies the smooth multiplier', () {
      // Builder at target (count 2) → effective base only. expand→colonial at
      // p = 0.5 gives multiplier 1.5, so score = base(1.0) × 1.5 = 1.5.
      expect(
        civilianBuildCandidateScore(
          kUnitTypeBuilder,
          2,
          phaseName: kCivilianBuildPhaseExpand,
          phaseProgress: 0.5,
        ),
        1.5,
      );
    });

    test(
      'ACHystNull: null phaseProgress equals the discrete-multiplier score',
      () {
        for (final type in civilianBuildDiscreteParityTypes) {
          for (final phase in civilianBuildDiscreteParityPhases) {
            for (final count in [0, 1, 2, 3]) {
              expect(
                civilianBuildCandidateScore(
                  type,
                  count,
                  phaseName: phase,
                  // phaseProgress omitted → null → discrete path.
                ),
                civilianBuildCandidateScore(type, count, phaseName: phase),
                reason: 'type=$type phase=$phase count=$count must be discrete',
              );
            }
          }
        }
      },
    );

    test('ACHystSpy: Spy stays phase-flat for every phaseProgress', () {
      for (final phase in [
        kCivilianBuildPhaseExpand,
        kCivilianBuildPhaseColonial,
        kCivilianBuildPhaseDevelop,
      ]) {
        for (final p in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          expect(
            civilianBuildPhaseMultiplierSmooth(kUnitTypeSpy, phase, p),
            kCivilianBuildSpyPhaseFlatMultiplier,
            reason: 'Spy must never ramp (phase=$phase p=$p)',
          );
        }
      }
    });

    test('ACHystDet: identical inputs yield identical smooth scores', () {
      final a = civilianBuildCandidateScore(
        kUnitTypeExplorer,
        2,
        phaseName: kCivilianBuildPhaseColonial,
        phaseProgress: 0.37,
      );
      final b = civilianBuildCandidateScore(
        kUnitTypeExplorer,
        2,
        phaseName: kCivilianBuildPhaseColonial,
        phaseProgress: 0.37,
      );
      expect(a, b);
    });

    test(
      'ACHyst: pooled score threads phaseProgress through the pool weight',
      () {
        const weight = 0.5;
        final pooled = civilianBuildPooledScore(
          kUnitTypeBuilder,
          2,
          phaseName: kCivilianBuildPhaseExpand,
          phaseProgress: 0.5,
          poolWeight: weight,
        );
        // base(1.0) × smooth multiplier(1.5) × poolWeight(0.5) = 0.75.
        expect(pooled, 0.75);
      },
    );
  });
}
