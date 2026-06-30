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
      expect(score, kCivilianBuildBaseScore * kCivilianBuildMinCapScoreBoost);
      expect(score, 50.0);
    });

    test('AC3: every count strictly below minCount uses the min-cap boost', () {
      // Builder minCount = 2, so counts 0 and 1 are below the floor.
      expect(civilianBuildCandidateScore(kUnitTypeBuilder, 1), 50.0);
    });

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

  group('civilian build phase multiplier (Refs #3793, AC4)', () {
    test('phase keys default to the neutral base multiplier', () {
      // Null / unknown phase, or a type the phase does not favor → base.
      expect(civilianBuildPhaseMultiplier(kUnitTypeBuilder, null), 1.0);
      expect(civilianBuildPhaseMultiplier(kUnitTypeBuilder, 'nope'), 1.0);
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeEngineer,
          kCivilianBuildPhaseExpand,
        ),
        1.0,
      );
    });

    test('AC4: EXPAND favors Builder (and COLONIAL-lite mirrors it)', () {
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeBuilder,
          kCivilianBuildPhaseExpand,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeBuilder,
          kCivilianBuildPhaseColonialLite,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeExplorer,
          kCivilianBuildPhaseExpand,
        ),
        1.0,
      );
    });

    test('AC4: COLONIAL favors Explorer + Merchant', () {
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeExplorer,
          kCivilianBuildPhaseColonial,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeMerchant,
          kCivilianBuildPhaseColonial,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeBuilder,
          kCivilianBuildPhaseColonial,
        ),
        1.0,
      );
    });

    test('AC4: DEVELOP favors Engineer + Rail Builder', () {
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeEngineer,
          kCivilianBuildPhaseDevelop,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeRailBuilder,
          kCivilianBuildPhaseDevelop,
        ),
        2.0,
      );
      expect(
        civilianBuildPhaseMultiplier(
          kUnitTypeExplorer,
          kCivilianBuildPhaseDevelop,
        ),
        1.0,
      );
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

  group('civilian build Spy phase-flat + demand (Refs #3793, AC4b)', () {
    test(
      'AC4b: Spy multiplier is identical across all phases (phase-flat)',
      () {
        final expand = civilianBuildPhaseMultiplier(
          kUnitTypeSpy,
          kCivilianBuildPhaseExpand,
        );
        final colonial = civilianBuildPhaseMultiplier(
          kUnitTypeSpy,
          kCivilianBuildPhaseColonial,
        );
        final develop = civilianBuildPhaseMultiplier(
          kUnitTypeSpy,
          kCivilianBuildPhaseDevelop,
        );
        expect(expand, kCivilianBuildSpyPhaseFlatMultiplier);
        expect(colonial, expand);
        expect(develop, expand);
      },
    );

    test('AC4b: Spy score is phase-flat across phases when demand is off', () {
      // Spy targetCount 0 → at count 0 the score is the effective base only.
      double spyScore(String phase) =>
          civilianBuildCandidateScore(kUnitTypeSpy, 0, phaseName: phase);
      final expand = spyScore(kCivilianBuildPhaseExpand);
      expect(
        expand,
        kCivilianBuildBaseScore * kCivilianBuildSpyPhaseFlatMultiplier,
      );
      expect(spyScore(kCivilianBuildPhaseColonial), expand);
      expect(spyScore(kCivilianBuildPhaseDevelop), expand);
    });

    test(
      'AC4b: demand boost multiplies the Spy score on top of the baseline',
      () {
        final baseline = civilianBuildCandidateScore(
          kUnitTypeSpy,
          0,
          phaseName: kCivilianBuildPhaseColonial,
        );
        final boosted = civilianBuildCandidateScore(
          kUnitTypeSpy,
          0,
          phaseName: kCivilianBuildPhaseColonial,
          spyDemand: true,
        );
        expect(boosted, baseline * kCivilianBuildSpyDemandBoost);
      },
    );

    test('AC4b: demand boost applies to no non-Spy civilian type', () {
      final withDemand = civilianBuildCandidateScore(
        kUnitTypeBuilder,
        2,
        phaseName: kCivilianBuildPhaseExpand,
        spyDemand: true,
      );
      final withoutDemand = civilianBuildCandidateScore(
        kUnitTypeBuilder,
        2,
        phaseName: kCivilianBuildPhaseExpand,
      );
      expect(withDemand, withoutDemand);
    });
  });
}
