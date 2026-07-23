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

  group('civilian build Spy tech-steal posture (Refs #3793, AC4c)', () {
    test('AC8: default tech-steal deficit is the GA-tunable config value', () {
      expect(kCivilianBuildSpyTechStealDeficit, 1);
    });

    test(
      'AC4c: a rival lead at or beyond the deficit is a tech-steal posture',
      () {
        // Own 2, rival 4 → lead 2 >= deficit 1 → posture.
        expect(
          isCivilianBuildSpyTechStealPosture(
            ownUnlockedTechCount: 2,
            maxRivalUnlockedTechCount: 4,
          ),
          isTrue,
        );
        // Exactly the default deficit (1) still qualifies.
        expect(
          isCivilianBuildSpyTechStealPosture(
            ownUnlockedTechCount: 3,
            maxRivalUnlockedTechCount: 4,
          ),
          isTrue,
        );
      },
    );

    test('AC4c: parity or a lead is not a tech-steal posture', () {
      // Equal counts → lead 0 < deficit 1 → no posture.
      expect(
        isCivilianBuildSpyTechStealPosture(
          ownUnlockedTechCount: 4,
          maxRivalUnlockedTechCount: 4,
        ),
        isFalse,
      );
      // Own ahead → negative lead → no posture.
      expect(
        isCivilianBuildSpyTechStealPosture(
          ownUnlockedTechCount: 5,
          maxRivalUnlockedTechCount: 2,
        ),
        isFalse,
      );
    });

    test('AC4c: a higher deficit restricts the posture to bigger gaps', () {
      // Lead 1 no longer qualifies at deficit 2.
      expect(
        isCivilianBuildSpyTechStealPosture(
          ownUnlockedTechCount: 3,
          maxRivalUnlockedTechCount: 4,
          deficit: 2,
        ),
        isFalse,
      );
      expect(
        isCivilianBuildSpyTechStealPosture(
          ownUnlockedTechCount: 2,
          maxRivalUnlockedTechCount: 4,
          deficit: 2,
        ),
        isTrue,
      );
    });
  });

  group('civilian build pool weight (Refs #3793, ACPool)', () {
    test(
      'ACPool/AC8: default pool weight is declared in [0.0, 1.0] and 1.0',
      () {
        expect(kCivilianBuildPoolWeight, 1.0);
        expect(kCivilianBuildPoolWeight, greaterThanOrEqualTo(0.0));
        expect(kCivilianBuildPoolWeight, lessThanOrEqualTo(1.0));
      },
    );

    test('ACPool: at the default weight the pooled score equals the per-type '
        'score for every civilian type and count (no regression)', () {
      for (final (type, count) in civilianBuildPoolParityCases) {
        expect(
          civilianBuildPooledScore(
            type,
            count,
            phaseName: kCivilianBuildPhaseColonial,
          ),
          civilianBuildCandidateScore(
            type,
            count,
            phaseName: kCivilianBuildPhaseColonial,
          ),
          reason: 'pooled == per-type at default weight for $type/$count',
        );
      }
    });

    test('ACPool: an explicit weight scales the per-type score linearly', () {
      // Builder below min cap → per-type score 50.0; pooled at 0.5 → 25.0.
      final base = civilianBuildCandidateScore(kUnitTypeBuilder, 0);
      expect(
        civilianBuildPooledScore(kUnitTypeBuilder, 0, poolWeight: 0.5),
        base * 0.5,
      );
      // A zero weight collapses the civilian score to 0 (fully ceded share).
      expect(
        civilianBuildPooledScore(kUnitTypeBuilder, 0, poolWeight: 0.0),
        0.0,
      );
    });

    test('ACPool: pool weight preserves relative ordering among civilians', () {
      // Below-min Builder (50.0) must still outrank an at-target Explorer (1.0)
      // after the same shared pool weight is applied to both.
      const weight = 0.3;
      final builder = civilianBuildPooledScore(
        kUnitTypeBuilder,
        0,
        poolWeight: weight,
      );
      final explorer = civilianBuildPooledScore(
        kUnitTypeExplorer,
        2,
        poolWeight: weight,
      );
      expect(builder, greaterThan(explorer));
      // The ratio is unchanged from the unweighted per-type ratio.
      expect(
        builder / explorer,
        civilianBuildCandidateScore(kUnitTypeBuilder, 0) /
            civilianBuildCandidateScore(kUnitTypeExplorer, 2),
      );
    });
  });
}

