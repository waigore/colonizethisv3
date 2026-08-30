import 'ai_personality_tables.dart';
import 'ai_personality_types.dart';

/// Resolves a leader key or id to the canonical leader id used for personality
/// lookups.
///
/// - If [leaderKeyOrId] already matches a canonical id present in the
///   personality tables (e.g. `victoria`, `napoleon`), it is returned
///   unchanged.
/// - If [leaderKeyOrId] is a known variant key from the default naming config
///   (e.g. `england_leader`, `france_leader`, `spain_leader`, `portugal_leader`,
///   `netherlands_leader`, `prussia_leader`, `prussia_reserve_leader`,
///   `sweden_leader`), the corresponding canonical id is returned.
/// - Otherwise the input is returned as-is so callers fall back to the default
///   neutral personality weights and thresholds for unknown ids.
String canonicalLeaderIdForPersonality(String leaderKeyOrId) {
  if (personalityDomainWeights.containsKey(leaderKeyOrId)) {
    return leaderKeyOrId;
  }

  const variantToCanonical = <String, String>{
    'england_leader': 'victoria',
    'france_leader': 'napoleon',
    'spain_leader': 'isabella',
    'portugal_leader': 'henry',
    'netherlands_leader': 'deruyter',
    'prussia_leader': 'frederick',
    'prussia_reserve_leader': 'frederick',
    'sweden_leader': 'gustavus',
  };

  return variantToCanonical[leaderKeyOrId] ?? leaderKeyOrId;
}

/// Primary key for AI personality weight/threshold lookups: [personalityId] when
/// it names a known archetype in [personalityDomainWeights]; otherwise the
/// canonical id from [leaderKeyOrId]. SPEC/ai/ai-personalities.md.
String personalityLookupKeyForAi({
  required String leaderKeyOrId,
  String? personalityId,
}) {
  if (personalityId != null &&
      personalityId.isNotEmpty &&
      personalityDomainWeights.containsKey(personalityId)) {
    return personalityId;
  }
  return canonicalLeaderIdForPersonality(leaderKeyOrId);
}

PersonalityDomainWeights getDomainWeightsForLeader(String leaderId) {
  return personalityDomainWeights[leaderId] ?? defaultDomainWeights;
}

PersonalityGoalWeights getGoalWeightsForLeader(String leaderId) {
  return personalityGoalWeights[leaderId] ?? defaultGoalWeights;
}

PersonalityThresholds getThresholdsForLeader(String leaderId) {
  return personalityThresholds[leaderId] ?? defaultThresholds;
}

/// Returns human-readable archetype name for [leaderId], or null if unknown.
String? getArchetypeDisplayNameForLeader(String leaderId) {
  return personalityArchetypeDisplayName[leaderId];
}
