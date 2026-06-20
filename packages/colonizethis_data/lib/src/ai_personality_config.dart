// Personality and domain weights for full AI. SPEC/ai/ai-personalities.md.

/// Domain weight set (0–100 scale; relative weights matter).
class PersonalityDomainWeights {
  const PersonalityDomainWeights({
    this.economy = 50,
    this.military = 50,
    this.diplomacy = 50,
    this.research = 50,
  });

  final int economy;
  final int military;
  final int diplomacy;
  final int research;
}

/// Goal priority set for behavior tree (relative).
class PersonalityGoalWeights {
  const PersonalityGoalWeights({
    this.defend = 25,
    this.expand = 25,
    this.conquer = 25,
    this.trade = 25,
    this.tech = 25,
    this.diplomacy = 25,
  });

  final int defend;
  final int expand;
  final int conquer;
  final int trade;
  final int tech;
  final int diplomacy;
}

/// Thresholds applied when scoring actions (declare war, accept peace, alliance, research).
/// SPEC/ai/ai-personalities.md — "Behavioral modifiers": war likelihood, peace tendency,
/// alliance tendency, research preference per category.
class PersonalityThresholds {
  const PersonalityThresholds({
    this.warLikelihood = 50,
    this.peaceTendency = 50,
    this.allianceTendency = 50,
    this.researchNaval = 50,
    this.researchMilitary = 50,
    this.researchEconomic = 50,
    this.researchExploration = 50,
    this.researchFundingAggression = 50,
    this.researchSlotFillAggression = 70,
  });

  final int warLikelihood;
  final int peaceTendency;
  final int allianceTendency;
  final int researchNaval;
  final int researchMilitary;
  final int researchEconomic;
  final int researchExploration;

  /// Scales the target uniform funding tier for Full-AI research (0–100).
  /// SPEC/ai/ai-architecture.md § Research. Refs #3472.
  final int researchFundingAggression;

  /// Target fraction of empty research slots to fill each turn (0–100) when
  /// `primaryGoal != tech`. SPEC/ai/ai-architecture.md § Research. Refs #3472.
  final int researchSlotFillAggression;
}

/// Personality config per leader id. Used by colonizethis_ai for goal and utility scoring.
const Map<String, PersonalityDomainWeights> personalityDomainWeights = {
  'victoria': PersonalityDomainWeights(
    economy: 70,
    military: 30,
    diplomacy: 80,
    research: 50,
  ),
  'napoleon': PersonalityDomainWeights(
    economy: 50,
    military: 90,
    diplomacy: 30,
    research: 50,
  ),
  'isabella': PersonalityDomainWeights(
    economy: 70,
    military: 50,
    diplomacy: 40,
    research: 60,
  ),
  'henry': PersonalityDomainWeights(
    economy: 80,
    military: 20,
    diplomacy: 70,
    research: 60,
  ),
  'deruyter': PersonalityDomainWeights(
    economy: 90,
    military: 30,
    diplomacy: 70,
    research: 50,
  ),
  'frederick': PersonalityDomainWeights(
    economy: 40,
    military: 80,
    diplomacy: 50,
    research: 60,
  ),
  'gustavus': PersonalityDomainWeights(
    economy: 50,
    military: 70,
    diplomacy: 50,
    research: 60,
  ),
};

/// Goal weights per personality (leader id). Defend/expand/conquer/trade/tech/diplomacy.
const Map<String, PersonalityGoalWeights> personalityGoalWeights = {
  'victoria': PersonalityGoalWeights(
    defend: 30,
    expand: 40,
    conquer: 10,
    trade: 80,
    tech: 50,
    diplomacy: 70,
  ),
  'napoleon': PersonalityGoalWeights(
    defend: 40,
    expand: 50,
    conquer: 90,
    trade: 20,
    tech: 40,
    diplomacy: 20,
  ),
  'isabella': PersonalityGoalWeights(
    defend: 30,
    expand: 80,
    conquer: 40,
    trade: 50,
    tech: 60,
    diplomacy: 30,
  ),
  'henry': PersonalityGoalWeights(
    defend: 50,
    expand: 60,
    conquer: 10,
    trade: 90,
    tech: 60,
    diplomacy: 70,
  ),
  'deruyter': PersonalityGoalWeights(
    defend: 40,
    expand: 50,
    conquer: 20,
    trade: 90,
    tech: 50,
    diplomacy: 70,
  ),
  'frederick': PersonalityGoalWeights(
    defend: 80,
    expand: 40,
    conquer: 50,
    trade: 30,
    tech: 50,
    diplomacy: 50,
  ),
  'gustavus': PersonalityGoalWeights(
    defend: 50,
    expand: 50,
    conquer: 60,
    trade: 40,
    tech: 60,
    diplomacy: 50,
  ),
};

/// Thresholds per leader (war/peace/alliance tendency; research category weights).
/// Used when scoring diplomatic actions and research slot choice. See SPEC/ai/ai-personalities.md.
const Map<String, PersonalityThresholds> personalityThresholds = {
  'victoria': PersonalityThresholds(
    warLikelihood: 20,
    peaceTendency: 80,
    allianceTendency: 80,
    researchMilitary: 40,
    researchNaval: 70,
    researchEconomic: 50,
    researchExploration: 60,
  ),
  'napoleon': PersonalityThresholds(
    warLikelihood: 80,
    peaceTendency: 35,
    allianceTendency: 25,
    researchMilitary: 90,
    researchNaval: 40,
    researchEconomic: 50,
    researchExploration: 40,
  ),
  'isabella': PersonalityThresholds(
    warLikelihood: 50,
    peaceTendency: 50,
    allianceTendency: 40,
    researchMilitary: 50,
    researchNaval: 60,
    researchEconomic: 60,
    researchExploration: 80,
  ),
  'henry': PersonalityThresholds(
    warLikelihood: 10,
    peaceTendency: 70,
    allianceTendency: 75,
    researchMilitary: 30,
    researchNaval: 80,
    researchEconomic: 50,
    researchExploration: 80,
  ),
  'deruyter': PersonalityThresholds(
    warLikelihood: 25,
    peaceTendency: 65,
    allianceTendency: 70,
    researchMilitary: 35,
    researchNaval: 60,
    researchEconomic: 85,
    researchExploration: 50,
  ),
  'frederick': PersonalityThresholds(
    warLikelihood: 55,
    peaceTendency: 45,
    allianceTendency: 50,
    researchMilitary: 85,
    researchNaval: 45,
    researchEconomic: 40,
    researchExploration: 45,
  ),
  'gustavus': PersonalityThresholds(
    warLikelihood: 55,
    peaceTendency: 50,
    allianceTendency: 50,
    researchMilitary: 75,
    researchNaval: 55,
    researchEconomic: 50,
    researchExploration: 55,
  ),
};

/// Default when leader id is unknown.
const PersonalityDomainWeights defaultDomainWeights =
    PersonalityDomainWeights();
const PersonalityGoalWeights defaultGoalWeights = PersonalityGoalWeights();
const PersonalityThresholds defaultThresholds = PersonalityThresholds();

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

/// Display name for personality archetype (e.g. "Fortifier", "Explorer").
/// Used by dossier basic intel. SPEC/ai/ai-dossier.md, ai-personalities.md.
const Map<String, String> personalityArchetypeDisplayName = {
  'victoria': 'Industrial Trader',
  'napoleon': 'Fortifier',
  'isabella': 'Explorer',
  'henry': 'Navigator',
  'deruyter': 'Merchant',
  'frederick': 'Defender',
  'gustavus': 'Tactician',
};

/// Returns human-readable archetype name for [leaderId], or null if unknown.
String? getArchetypeDisplayNameForLeader(String leaderId) {
  return personalityArchetypeDisplayName[leaderId];
}

/// Maximum number of evidence entries kept per dossier (per (observer, subject)).
/// When the list would exceed this cap, the oldest entries are dropped so that
/// the evidence list remains capped and chronological.
/// SPEC/ai/ai-dossier.md § Evidence list cap.
const int kMaxDossierEvidenceEntries = 50;
