/// Machine-readable registry of tunable AI-behavior parameters.
///
/// Declares one [AiParameter] per numeric constant in
/// `ai_personality_config.dart` and `ai_victory_config.dart` that affects AI
/// behavior, with canonical key, category, integer flag, bounds, default, and
/// description. Foundational data layer for genetic-algorithm tuning. The
/// victory-config declarations live in `ai_parameter_victory_config_params.dart`
/// (imported below) to keep each file under the repo non-comment line-size gate.
/// SPEC/ai/ai-parameter-registry.md. Refs #3436.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_params.dart';
import 'ai_personality_config.dart';

export 'ai_parameter.dart';

/// Registry of all tunable AI parameters. SPEC/ai/ai-parameter-registry.md.
abstract final class AiParameterRegistry {
  /// Complete, deterministically ordered parameter list.
  static final List<AiParameter> allParams = List<AiParameter>.unmodifiable([
    ..._personalityParams,
    ...victoryConfigParams,
  ]);

  /// Name → default value for profile initialization.
  static final Map<String, num> defaults = Map<String, num>.unmodifiable({
    for (final p in allParams) p.name: p.defaultValue,
  });

  static final Map<String, AiParameter> _byName =
      Map<String, AiParameter>.unmodifiable({
        for (final p in allParams) p.name: p,
      });

  /// Params filtered to one [AiParameterCategory].
  static List<AiParameter> byCategory(String category) =>
      allParams.where((p) => p.category == category).toList(growable: false);

  /// Single-parameter lookup by canonical key, or null when unknown.
  static AiParameter? byName(String name) => _byName[name];
}

AiParameter _personality(
  String category,
  String name,
  num defaultValue,
  String description,
) => AiParameter(
  name: name,
  category: category,
  isInteger: true,
  minValue: 0,
  maxValue: 100,
  defaultValue: defaultValue,
  description: description,
);

final List<AiParameter> _personalityParams = <AiParameter>[
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.economy',
    defaultDomainWeights.economy,
    'Domain weight for economy planning.',
  ),
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.military',
    defaultDomainWeights.military,
    'Domain weight for military planning.',
  ),
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.diplomacy',
    defaultDomainWeights.diplomacy,
    'Domain weight for diplomacy planning.',
  ),
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.research',
    defaultDomainWeights.research,
    'Domain weight for research planning.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.defend',
    defaultGoalWeights.defend,
    'Goal weight for the defend strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.expand',
    defaultGoalWeights.expand,
    'Goal weight for the expand strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.conquer',
    defaultGoalWeights.conquer,
    'Goal weight for the conquer strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.trade',
    defaultGoalWeights.trade,
    'Goal weight for the trade strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.tech',
    defaultGoalWeights.tech,
    'Goal weight for the tech strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.diplomacy',
    defaultGoalWeights.diplomacy,
    'Goal weight for the diplomacy strategy.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.warLikelihood',
    defaultThresholds.warLikelihood,
    'Tendency to declare war.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.peaceTendency',
    defaultThresholds.peaceTendency,
    'Tendency to accept or offer peace.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.allianceTendency',
    defaultThresholds.allianceTendency,
    'Tendency to seek alliances.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchNaval',
    defaultThresholds.researchNaval,
    'Research preference weight for naval techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchMilitary',
    defaultThresholds.researchMilitary,
    'Research preference weight for military techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchEconomic',
    defaultThresholds.researchEconomic,
    'Research preference weight for economic techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchExploration',
    defaultThresholds.researchExploration,
    'Research preference weight for exploration techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchFundingAggression',
    defaultThresholds.researchFundingAggression,
    'Scales the Full-AI target uniform research funding tier.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchSlotFillAggression',
    defaultThresholds.researchSlotFillAggression,
    'Target fraction of empty research slots Full AI fills each turn.',
  ),
];
