// Tests for the GA-tunable civilian build scoring helpers (Refs #3793,
// SPEC/ai/civilian-build-planner.md § Scoring model). These pure functions are
// the single source of the civilian min-cap hard floor, replacement-urgency
// soft pull, and max-cap exclusion consumed by `pickBuildOrder`.
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/civilian_build_scoring_scenarios.dart';

void main() {
  group('civilian build scoring helpers (Refs #3793)', () {
    test('AC8: default caps come from the GA-tunable config maps', () {
      for (final (type, min) in civilianBuildMinCountCases) {
        expect(civilianBuildMinCount(type), min, reason: type);
      }

      for (final (type, target) in civilianBuildTargetCountCases) {
        expect(civilianBuildTargetCount(type), target, reason: type);
      }

      for (final (type, max) in civilianBuildMaxCountCases) {
        expect(civilianBuildMaxCount(type), max, reason: type);
      }
    });

    test('AC8: unknown type defaults — minCount 0, targetCount = minCount, '
        'no max ceiling', () {
      expect(civilianBuildMinCount('NotACivilian'), 0);
      expect(civilianBuildTargetCount('NotACivilian'), 0);
      expect(civilianBuildMaxCount('NotACivilian'), isNull);
    });

    test(
      'AC3: counts strictly below minCount use the min-cap hard-floor boost',
      () {
        // Builder minCount = 2, so counts 0 and 1 are below the floor.
        for (final count in civilianBuildBelowMinCounts) {
          final score = civilianBuildCandidateScore(kUnitTypeBuilder, count);
          expect(
            score,
            kCivilianBuildBaseScore * kCivilianBuildMinCapScoreBoost,
            reason: 'count=$count',
          );
          expect(score, 50.0, reason: 'count=$count');
        }
      },
    );

    test(
      'AC13: replacement urgency applies between minCount and targetCount',
      () {
        // Explorer: minCount 1, targetCount 2. At count 1 (>= min, < target),
        // urgency = 1 + 0.5 * (2 - 1) = 1.5.
        final score = civilianBuildCandidateScore(kUnitTypeExplorer, 1);
        expect(
          score,
          kCivilianBuildBaseScore *
              (1.0 + kCivilianBuildReplacementUrgencyFactor * 1),
        );
        expect(score, 1.5);
      },
    );

    test('AC13: at or above targetCount the multiplier is neutral base', () {
      // Builder targetCount = 2.
      for (final count in [2, 3]) {
        expect(
          civilianBuildCandidateScore(kUnitTypeBuilder, count),
          1.0,
          reason: 'count=$count',
        );
      }
    });

    test('ACMax: at or above maxCount is flagged for pool exclusion', () {
      // Builder maxCount = 6.
      const cases = <(int, bool)>[(5, false), (6, true), (7, true)];
      for (final (count, atOrAbove) in cases) {
        expect(
          isCivilianBuildAtOrAboveMaxCount(kUnitTypeBuilder, count),
          atOrAbove,
          reason: 'count=$count',
        );
      }
    });

    test('ACMax: a type with no ceiling is never excluded', () {
      expect(isCivilianBuildAtOrAboveMaxCount('NotACivilian', 9999), isFalse);
    });
  });

  group('civilian build phase multiplier (Refs #3793, AC4)', () {
    test('phase keys default to the neutral base multiplier', () {
      // Null / unknown phase, or a type the phase does not favor → base.
      const cases = <(String, String?)>[
        (kUnitTypeBuilder, null),
        (kUnitTypeBuilder, 'nope'),
        (kUnitTypeEngineer, kCivilianBuildPhaseExpand),
      ];
      for (final (type, phase) in cases) {
        expect(
          civilianBuildPhaseMultiplier(type, phase),
          1.0,
          reason: 'type=$type phase=$phase',
        );
      }
    });

    test('AC4: each phase favors its documented civilian types', () {
      for (final (type, phase, expected) in civilianBuildPhaseFavorCases) {
        expect(
          civilianBuildPhaseMultiplier(type, phase),
          expected,
          reason: 'type=$type phase=$phase',
        );
      }
    });

    test(
      'AC4: phase multiplier folds into the candidate score at target count',
      () {
        // Builder targetCount 2 → replacement urgency neutral. In EXPAND the
        // favored multiplier (2.0) lifts the base score; outside its favored
        // phase the score stays at the neutral base.
        expect(
          civilianBuildCandidateScore(
            kUnitTypeBuilder,
            2,
            phaseName: kCivilianBuildPhaseExpand,
          ),
          kCivilianBuildBaseScore * kCivilianBuildPhaseMultiplierFavored,
        );
        expect(
          civilianBuildCandidateScore(
            kUnitTypeBuilder,
            2,
            phaseName: kCivilianBuildPhaseDevelop,
          ),
          kCivilianBuildBaseScore,
        );
      },
    );

    test('AC4: phase multiplier never overrides the min-cap hard floor', () {
      // A below-min Builder still gets the full min-cap boost, scaled by the
      // phase multiplier (favored), so it dominates regardless of phase.
      final expandScore = civilianBuildCandidateScore(
        kUnitTypeBuilder,
        0,
        phaseName: kCivilianBuildPhaseExpand,
      );
      expect(
        expandScore,
        kCivilianBuildBaseScore *
            kCivilianBuildPhaseMultiplierFavored *
            kCivilianBuildMinCapScoreBoost,
      );
      // Even in a non-favored phase the below-min floor (50.0) still exceeds the
      // favored at-target score (2.0).
      final developScore = civilianBuildCandidateScore(
        kUnitTypeBuilder,
        0,
        phaseName: kCivilianBuildPhaseDevelop,
      );
      expect(developScore, greaterThan(expandScore / 10));
      expect(developScore, 50.0);
    });
  });
}
