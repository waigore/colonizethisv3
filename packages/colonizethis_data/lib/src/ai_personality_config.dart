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

/// Personality config per leader id. Used by colonizethis_ai for goal and utility scoring.
const Map<String, PersonalityDomainWeights> personalityDomainWeights = {
  'victoria': PersonalityDomainWeights(economy: 70, military: 30, diplomacy: 80, research: 50),
  'napoleon': PersonalityDomainWeights(economy: 50, military: 90, diplomacy: 30, research: 50),
  'isabella': PersonalityDomainWeights(economy: 70, military: 50, diplomacy: 40, research: 60),
  'henry': PersonalityDomainWeights(economy: 80, military: 20, diplomacy: 70, research: 60),
  'deruyter': PersonalityDomainWeights(economy: 90, military: 30, diplomacy: 70, research: 50),
  'frederick': PersonalityDomainWeights(economy: 40, military: 80, diplomacy: 50, research: 60),
  'gustavus': PersonalityDomainWeights(economy: 50, military: 70, diplomacy: 50, research: 60),
};

/// Goal weights per personality (leader id). Defend/expand/conquer/trade/tech/diplomacy.
const Map<String, PersonalityGoalWeights> personalityGoalWeights = {
  'victoria': PersonalityGoalWeights(defend: 30, expand: 40, conquer: 10, trade: 80, tech: 50, diplomacy: 70),
  'napoleon': PersonalityGoalWeights(defend: 40, expand: 50, conquer: 90, trade: 20, tech: 40, diplomacy: 20),
  'isabella': PersonalityGoalWeights(defend: 30, expand: 80, conquer: 40, trade: 50, tech: 60, diplomacy: 30),
  'henry': PersonalityGoalWeights(defend: 50, expand: 60, conquer: 10, trade: 90, tech: 60, diplomacy: 70),
  'deruyter': PersonalityGoalWeights(defend: 40, expand: 50, conquer: 20, trade: 90, tech: 50, diplomacy: 70),
  'frederick': PersonalityGoalWeights(defend: 80, expand: 40, conquer: 50, trade: 30, tech: 50, diplomacy: 50),
  'gustavus': PersonalityGoalWeights(defend: 50, expand: 50, conquer: 60, trade: 40, tech: 60, diplomacy: 50),
};

/// Default when leader id is unknown.
const PersonalityDomainWeights defaultDomainWeights = PersonalityDomainWeights();
const PersonalityGoalWeights defaultGoalWeights = PersonalityGoalWeights();

PersonalityDomainWeights getDomainWeightsForLeader(String leaderId) {
  return personalityDomainWeights[leaderId] ?? defaultDomainWeights;
}

PersonalityGoalWeights getGoalWeightsForLeader(String leaderId) {
  return personalityGoalWeights[leaderId] ?? defaultGoalWeights;
}
