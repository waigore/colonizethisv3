import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('AiParameterRegistry completeness', () {
    test('exposes a non-empty, uniquely-keyed parameter list', () {
      expect(AiParameterRegistry.allParams, isNotEmpty);
      final names = AiParameterRegistry.allParams.map((p) => p.name).toList();
      expect(
        names.toSet().length,
        names.length,
        reason: 'parameter names must be unique',
      );
    });

    test('defaults map matches allParams', () {
      expect(
        AiParameterRegistry.defaults.length,
        AiParameterRegistry.allParams.length,
      );
      for (final p in AiParameterRegistry.allParams) {
        expect(AiParameterRegistry.defaults[p.name], p.defaultValue);
      }
    });

    test('registers all personality domain/goal/threshold fields', () {
      const expected = [
        'personalityDomainWeights.economy',
        'personalityDomainWeights.military',
        'personalityDomainWeights.diplomacy',
        'personalityDomainWeights.research',
        'personalityGoalWeights.defend',
        'personalityGoalWeights.expand',
        'personalityGoalWeights.conquer',
        'personalityGoalWeights.trade',
        'personalityGoalWeights.tech',
        'personalityGoalWeights.diplomacy',
        'personalityThresholds.warLikelihood',
        'personalityThresholds.peaceTendency',
        'personalityThresholds.allianceTendency',
        'personalityThresholds.researchNaval',
        'personalityThresholds.researchMilitary',
        'personalityThresholds.researchEconomic',
        'personalityThresholds.researchExploration',
      ];
      for (final name in expected) {
        expect(AiParameterRegistry.byName(name), isNotNull, reason: name);
      }
    });

    test('registers representative victory-config constants', () {
      const expected = [
        'kDeclareWarAdjacentOwnerBonus',
        'kBuildRegimentBonusWhenBehindVictoryPace',
        'kMilitaryVictoryOldWorldProvinceThreshold',
        'kConquestArmyMoveStalledGpInvadableBlockerBonus',
        'kDeclareWarStalledAnyOwMinorBonus',
      ];
      for (final name in expected) {
        expect(AiParameterRegistry.byName(name), isNotNull, reason: name);
      }
    });

    test('excludes string, infrastructure, and utility-only constants', () {
      expect(AiParameterRegistry.byName('kMaxDossierEvidenceEntries'), isNull);
      expect(AiParameterRegistry.byName('kOldWorldRegionId'), isNull);
      expect(AiParameterRegistry.byName('kNewWorldRegionId'), isNull);
    });

    // Refs #3794: civilian-work feedstock score boosts migrated from
    // planner-internal contract constants to GA-tunable victory config.
    // SPEC/ai/civilian-work-planner.md § Acceptance criteria.
    test('registers the four civilian-work feedstock score boosts', () {
      const expected = <String, int>{
        'kRegimentBuildInputFeedstockExtractionScoreBoost': 600,
        'kGrowthStageFabricFeedstockScoreBoost': 700,
        'kGrowthStageInfraFeedstockScoreBoost': 520,
        'kFeedstockMineralProspectScoreBoost': 600,
      };
      for (final entry in expected.entries) {
        final p = AiParameterRegistry.byName(entry.key);
        expect(p, isNotNull, reason: entry.key);
        expect(p!.category, AiParameterCategory.victoryConfig, reason: entry.key);
        expect(p.isInteger, isTrue, reason: entry.key);
        expect(p.defaultValue, entry.value, reason: entry.key);
        expect(
          AiParameterRegistry.defaults[entry.key],
          entry.value,
          reason: entry.key,
        );
        expect(p.minValue, 0, reason: entry.key);
        expect(
          p.maxValue,
          math.max(2000, 4 * entry.value),
          reason: entry.key,
        );
      }
    });
  });

  group('AiParameter metadata', () {
    test('every parameter has populated, ordered, described metadata', () {
      for (final p in AiParameterRegistry.allParams) {
        expect(p.name, isNotEmpty);
        expect(p.description.trim(), isNotEmpty, reason: p.name);
        expect(p.category, isNotEmpty, reason: p.name);
        expect(
          p.minValue <= p.defaultValue,
          isTrue,
          reason: '${p.name}: min ${p.minValue} > default ${p.defaultValue}',
        );
        expect(
          p.defaultValue <= p.maxValue,
          isTrue,
          reason: '${p.name}: default ${p.defaultValue} > max ${p.maxValue}',
        );
      }
    });

    test('uses one of the four known categories', () {
      const categories = {
        AiParameterCategory.personalityDomain,
        AiParameterCategory.personalityGoal,
        AiParameterCategory.personalityThreshold,
        AiParameterCategory.victoryConfig,
      };
      for (final p in AiParameterRegistry.allParams) {
        expect(categories, contains(p.category), reason: p.name);
      }
    });
  });

  group('Canonical key naming', () {
    test('personality keys are <sourceMap>.<field>', () {
      final personality = [
        ...AiParameterRegistry.byCategory(
          AiParameterCategory.personalityDomain,
        ),
        ...AiParameterRegistry.byCategory(AiParameterCategory.personalityGoal),
        ...AiParameterRegistry.byCategory(
          AiParameterCategory.personalityThreshold,
        ),
      ];
      expect(personality, isNotEmpty);
      for (final p in personality) {
        expect(p.name, contains('.'), reason: p.name);
        expect(p.name, isNot(startsWith('k')), reason: p.name);
      }
    });

    test('victory-config keys are flat Dart constant identifiers', () {
      final victory = AiParameterRegistry.byCategory(
        AiParameterCategory.victoryConfig,
      );
      expect(victory, isNotEmpty);
      for (final p in victory) {
        expect(p.name, startsWith('k'), reason: p.name);
        expect(p.name, isNot(contains('.')), reason: p.name);
      }
    });
  });

  group('Bounds rules', () {
    test('personality params are bounded [0, 100]', () {
      final personality = [
        ...AiParameterRegistry.byCategory(
          AiParameterCategory.personalityDomain,
        ),
        ...AiParameterRegistry.byCategory(AiParameterCategory.personalityGoal),
        ...AiParameterRegistry.byCategory(
          AiParameterCategory.personalityThreshold,
        ),
      ];
      for (final p in personality) {
        expect(p.isInteger, isTrue, reason: p.name);
        expect(p.minValue, 0, reason: p.name);
        expect(p.maxValue, 100, reason: p.name);
      }
    });

    test('victory-config int bounds are [0, max(2000, 4x default)]', () {
      final victoryInts = AiParameterRegistry.byCategory(
        AiParameterCategory.victoryConfig,
      ).where((p) => p.isInteger);
      expect(victoryInts, isNotEmpty);
      for (final p in victoryInts) {
        expect(p.minValue, 0, reason: p.name);
        expect(p.maxValue, math.max(2000, 4 * p.defaultValue), reason: p.name);
      }
    });

    test('victory-config double bounds are [0.0, 4x default]', () {
      final victoryDoubles = AiParameterRegistry.byCategory(
        AiParameterCategory.victoryConfig,
      ).where((p) => !p.isInteger);
      expect(victoryDoubles, isNotEmpty);
      for (final p in victoryDoubles) {
        expect(p.minValue, 0.0, reason: p.name);
        expect(p.maxValue, 4 * p.defaultValue, reason: p.name);
      }
    });
  });

  group('Registry lookups', () {
    test('byName returns the matching parameter or null', () {
      final p = AiParameterRegistry.byName('kDeclareWarAdjacentOwnerBonus');
      expect(p, isNotNull);
      expect(p!.category, AiParameterCategory.victoryConfig);
      expect(AiParameterRegistry.byName('not_a_real_parameter'), isNull);
    });

    test('byCategory partitions allParams exactly', () {
      final sumByCategory =
          [
            AiParameterCategory.personalityDomain,
            AiParameterCategory.personalityGoal,
            AiParameterCategory.personalityThreshold,
            AiParameterCategory.victoryConfig,
          ].fold<int>(
            0,
            (acc, c) => acc + AiParameterRegistry.byCategory(c).length,
          );
      expect(sumByCategory, AiParameterRegistry.allParams.length);
    });
  });
}
