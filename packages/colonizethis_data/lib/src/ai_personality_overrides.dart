/// Resolves personality weight/threshold sets for a leader, applying optional
/// per-profile [AiProfile] parameter overrides.
///
/// Implements the override-resolution rule in `SPEC/ai/ai-profile-overrides.md`:
/// a registry-keyed override value replaces the leader's hardcoded value only
/// when it differs from the registry default; a `null` override map yields the
/// leader's hardcoded values unchanged (byte-identical no-profile path).
/// Refs #3437.
library;

import 'ai_parameter_registry.dart';
import 'ai_personality_config.dart';

/// Effective value for registry key [name]: the [overrides] value when present
/// and different from the registry default, else [base].
int _resolveInt(String name, Map<String, num>? overrides, int base) {
  if (overrides == null) return base;
  final value = overrides[name];
  if (value == null) return base;
  final defaultValue = AiParameterRegistry.defaults[name];
  if (defaultValue != null && value == defaultValue) return base;
  return value.round();
}

/// Domain weights for [personalityId] with optional profile [overrides].
PersonalityDomainWeights resolveDomainWeights(
  String personalityId, {
  Map<String, num>? overrides,
}) {
  final base = getDomainWeightsForLeader(personalityId);
  if (overrides == null) return base;
  return PersonalityDomainWeights(
    economy: _resolveInt(
      'personalityDomainWeights.economy',
      overrides,
      base.economy,
    ),
    military: _resolveInt(
      'personalityDomainWeights.military',
      overrides,
      base.military,
    ),
    diplomacy: _resolveInt(
      'personalityDomainWeights.diplomacy',
      overrides,
      base.diplomacy,
    ),
    research: _resolveInt(
      'personalityDomainWeights.research',
      overrides,
      base.research,
    ),
  );
}

/// Goal weights for [personalityId] with optional profile [overrides].
PersonalityGoalWeights resolveGoalWeights(
  String personalityId, {
  Map<String, num>? overrides,
}) {
  final base = getGoalWeightsForLeader(personalityId);
  if (overrides == null) return base;
  return PersonalityGoalWeights(
    defend: _resolveInt('personalityGoalWeights.defend', overrides, base.defend),
    expand: _resolveInt('personalityGoalWeights.expand', overrides, base.expand),
    conquer: _resolveInt(
      'personalityGoalWeights.conquer',
      overrides,
      base.conquer,
    ),
    trade: _resolveInt('personalityGoalWeights.trade', overrides, base.trade),
    tech: _resolveInt('personalityGoalWeights.tech', overrides, base.tech),
    diplomacy: _resolveInt(
      'personalityGoalWeights.diplomacy',
      overrides,
      base.diplomacy,
    ),
  );
}

/// Thresholds for [personalityId] with optional profile [overrides].
PersonalityThresholds resolveThresholds(
  String personalityId, {
  Map<String, num>? overrides,
}) {
  final base = getThresholdsForLeader(personalityId);
  if (overrides == null) return base;
  return PersonalityThresholds(
    warLikelihood: _resolveInt(
      'personalityThresholds.warLikelihood',
      overrides,
      base.warLikelihood,
    ),
    peaceTendency: _resolveInt(
      'personalityThresholds.peaceTendency',
      overrides,
      base.peaceTendency,
    ),
    allianceTendency: _resolveInt(
      'personalityThresholds.allianceTendency',
      overrides,
      base.allianceTendency,
    ),
    researchNaval: _resolveInt(
      'personalityThresholds.researchNaval',
      overrides,
      base.researchNaval,
    ),
    researchMilitary: _resolveInt(
      'personalityThresholds.researchMilitary',
      overrides,
      base.researchMilitary,
    ),
    researchEconomic: _resolveInt(
      'personalityThresholds.researchEconomic',
      overrides,
      base.researchEconomic,
    ),
    researchExploration: _resolveInt(
      'personalityThresholds.researchExploration',
      overrides,
      base.researchExploration,
    ),
    researchFundingAggression: _resolveInt(
      'personalityThresholds.researchFundingAggression',
      overrides,
      base.researchFundingAggression,
    ),
    researchSlotFillAggression: _resolveInt(
      'personalityThresholds.researchSlotFillAggression',
      overrides,
      base.researchSlotFillAggression,
    ),
  );
}
