// Tests for the GA-tunable civilian build scoring helpers (Refs #3793,
// SPEC/ai/civilian-build-planner.md § Scoring model). These pure functions are
// the single source of the civilian min-cap hard floor, replacement-urgency
// soft pull, and max-cap exclusion consumed by `pickBuildOrder`.
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('civilian build scoring helpers (Refs #3793)', () {
    test('AC8: default caps come from the GA-tunable config maps', () {
      expect(civilianBuildMinCount(kUnitTypeBuilder), 2);
      expect(civilianBuildMinCount(kUnitTypeExplorer), 1);
      expect(civilianBuildMinCount(kUnitTypeEngineer), 1);
      expect(civilianBuildMinCount(kUnitTypeSpy), 0);

      expect(civilianBuildTargetCount(kUnitTypeBuilder), 2);
      expect(civilianBuildTargetCount(kUnitTypeExplorer), 2);
      expect(civilianBuildTargetCount(kUnitTypeEngineer), 1);

      expect(civilianBuildMaxCount(kUnitTypeBuilder), 6);
      expect(civilianBuildMaxCount(kUnitTypeSpy), 3);
    });

    test('AC8: unknown type defaults — minCount 0, targetCount = minCount, '
        'no max ceiling', () {
      expect(civilianBuildMinCount('NotACivilian'), 0);
      expect(civilianBuildTargetCount('NotACivilian'), 0);
      expect(civilianBuildMaxCount('NotACivilian'), isNull);
    });

    test('AC3: count below minCount yields the min-cap hard-floor boost', () {
      final score = civilianBuildCandidateScore(kUnitTypeBuilder, 0);
      expect(
        score,
        kCivilianBuildBaseScore * kCivilianBuildMinCapScoreBoost,
      );
      expect(score, 50.0);
    });

    test('AC3: every count strictly below minCount uses the min-cap boost', () {
      // Builder minCount = 2, so counts 0 and 1 are below the floor.
      expect(civilianBuildCandidateScore(kUnitTypeBuilder, 1), 50.0);
    });

    test('AC13: replacement urgency applies between minCount and targetCount',
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
    });

    test('AC13: at or above targetCount the multiplier is neutral base', () {
      // Builder targetCount = 2.
      expect(civilianBuildCandidateScore(kUnitTypeBuilder, 2), 1.0);
      expect(civilianBuildCandidateScore(kUnitTypeBuilder, 3), 1.0);
    });

    test('ACMax: at or above maxCount is flagged for pool exclusion', () {
      // Builder maxCount = 6.
      expect(isCivilianBuildAtOrAboveMaxCount(kUnitTypeBuilder, 5), isFalse);
      expect(isCivilianBuildAtOrAboveMaxCount(kUnitTypeBuilder, 6), isTrue);
      expect(isCivilianBuildAtOrAboveMaxCount(kUnitTypeBuilder, 7), isTrue);
    });

    test('ACMax: a type with no ceiling is never excluded', () {
      expect(isCivilianBuildAtOrAboveMaxCount('NotACivilian', 9999), isFalse);
    });
  });
}
