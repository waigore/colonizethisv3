// Personality weight/threshold types for full AI. SPEC/ai/ai-personalities.md.

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
