/// Victory-pace bonuses for Full AI goal selection. SPEC/game/victory.md, SPEC/ai/ai-architecture.md.
library;

/// Old World province count required for military victory.
const int kMilitaryVictoryOldWorldProvinceThreshold = 31;

/// Region id for Old World provinces (prefixed `oldWorld|…`).
const String kOldWorldRegionId = 'oldWorld';

/// Provinces still needed to reach military victory from [oldWorldOwned].
int provincesToVictoryFromOldWorldOwned(int oldWorldOwned) {
  final gap =
      kMilitaryVictoryOldWorldProvinceThreshold - oldWorldOwned;
  return gap < 0 ? 0 : gap;
}

/// Deterministic conquer-goal bonus from victory pace (0 when at/above threshold).
int conquerScoreBonusForProvincesToVictory(int provincesToVictory) {
  if (provincesToVictory <= 0) return 0;
  return (provincesToVictory * 2).clamp(0, 40);
}

/// Extra conquer weight when within 12 provinces of military victory.
int endgameConquerScoreBonus(int provincesToVictory) {
  if (provincesToVictory <= 12) return 25;
  return 0;
}

/// Expand-goal bonus when invadable Old World targets exist.
const int kExpandBonusWhenInvadableProvinces = 15;

/// When behind victory pace by more than this many provinces, conquer score is floored.
const int kConquerScoreFloorProvincesToVictoryThreshold = 20;

/// Minimum `conquer` goal score when [provincesToVictory] exceeds
/// [kConquerScoreFloorProvincesToVictoryThreshold] (after agenda modifiers).
const int kMinimumConquerScoreWhenFarFromVictory = 35;

/// Declare-war relation cap for minor/tribe targets when far from military victory
/// (peacemaker agenda caps do not block minor conquest).
const int kDeclareWarMinorMaxRelationWhenFarFromVictory = 100;

/// Bonus to declare-war scoring toward a weak-neighbor Great Power when war desire is high.
const int kDeclareWarGpWeakNeighborBonus = 12;

/// Minimum war-desire score (0..100) for [kDeclareWarGpWeakNeighborBonus].
const int kDeclareWarGpWeakNeighborMinWarDesire = 55;

/// Extra build weight for regiments when behind military victory pace.
const double kBuildRegimentBonusWhenBehindVictoryPace = 1.5;

/// Provinces-to-victory threshold for [kBuildRegimentBonusWhenBehindVictoryPace].
const int kBuildRegimentVictoryPaceThreshold = 10;

/// Declare-war relation cap for **Great Power** targets that own provinces
/// topologically adjacent to the attacker when far from military victory.
const int kDeclareWarGpMaxRelationWhenFarFromVictory = 85;

/// Score bonus for `declareWar` toward a faction that owns an adjacent Old
/// World province (topology), so AI does not declare on distant minors only.
const int kDeclareWarAdjacentOwnerBonus = 28;

/// Extra declare-war bonus for low-[warLikelihood] personalities when far from
/// victory and the target owns adjacent Old World provinces.
const int kDeclareWarLowWarLikelihoodAdjacentBonus = 20;

/// Personality [warLikelihood] at or below this uses
/// [kDeclareWarLowWarLikelihoodAdjacentBonus].
const int kDeclareWarLowWarLikelihoodThreshold = 35;

/// When far from victory, reduce trade goal weight by at most this amount so
/// conquer/expand can compete for trade-focused leaders.
const int kTradeGoalPenaltyCapWhenFarFromVictory = 30;

/// When far from victory, suppress declare-war on factions that do not own a
/// topologically adjacent Old World province (distant minors are useless).
const int kDeclareWarNonAdjacentSuppressedScore = 0;
