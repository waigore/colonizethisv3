import 'ai_personality_types.dart';

// Personality tables per leader id. SPEC/ai/ai-personalities.md.

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
