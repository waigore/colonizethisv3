/// Victory-pace bonuses for Full AI goal selection. SPEC/game/victory.md, SPEC/ai/ai-architecture.md.
library;

/// Old World province count required for military victory.
const int kMilitaryVictoryOldWorldProvinceThreshold = 31;

/// Region id for Old World provinces (prefixed `oldWorld|…`).
const String kOldWorldRegionId = 'oldWorld';

/// Region id for New World provinces (prefixed `newWorld|…`).
const String kNewWorldRegionId = 'newWorld';

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

/// Declare-war bonus toward an adjacent **Great Power** when far from victory.
const int kDeclareWarAdjacentGpBonusWhenFarFromVictory = 35;

/// Extra declare-war bonus toward an adjacent **minor/tribe** when far from victory.
const int kDeclareWarAdjacentMinorBonusWhenFarFromVictory = 55;

/// While `provincesToVictory` is **greater than** this value, declare-war on other
/// Great Powers is suppressed so each GP expands from minors/tribes first (observer
/// per-GP conquest AC; only 18 non-GP Old World provinces at default setup).
const int kSuppressGpDeclareWarMinProvincesToVictory = 12;

/// Old World holdings at or below this count are treated as stalled expansion
/// (observer default start is 7 provinces per GP).
const int kStalledOldWorldProvinceThreshold = 8;

/// Extra declare-war weight toward adjacent minors when stalled.
const int kDeclareWarStalledExpansionMinorBonus = 50;

/// Penalty on adjacent minor declare-war when the GP already holds many OW provinces.
const int kDeclareWarSatedExpansionMinorPenalty = 40;

/// Minimum diplomacy domain weight for the declare-war pass when stalled.
const int kDiplomacyDeclareWarMinWeightWhenStalled = 35;

/// Extra regiment build weight when OW holdings are stalled (any primary goal).
const double kBuildRegimentBonusWhenStalledExpansion = 2.5;

/// Declare-war bonus when the target still owns an adjacent invadable province.
const int kDeclareWarMinorWithInvadableProvinceBonus = 45;

/// Offer-peace bonus toward a minor/tribe at war that no longer owns invadable land.
const int kOfferPeaceFutileMinorWarBonus = 80;

/// When far from victory, defend goal bonus while Old World holdings are small.
const int kDefendBonusWhenFewOldWorldProvinces = 35;

/// Extra defend weight when at war and Old World holdings are at or below
/// [kFewOldWorldProvincesDefendThreshold] (trade-focused GPs avoid collapse).
const int kDefendBonusWhenAtWarAndFewHoldings = 45;

/// Old World province count at or below which [kDefendBonusWhenFewOldWorldProvinces] applies.
const int kFewOldWorldProvincesDefendThreshold = 6;

/// Expand-goal bonus when invadable New World tribe/minor provinces exist.
const int kColonialExpandBonusWhenInvadableNw = 18;

/// Conquer-goal bonus for colonial pressure (below OW victory floors).
const int kColonialConquerBonusWhenInvadableNw = 14;

/// Declare-war bonus toward a tribe/minor that owns adjacent New World provinces.
const int kDeclareWarColonialAdjacentTribeBonus = 40;

/// Establish-overture bonus toward a preferred colonial tribe target.
const int kEstablishOvertureColonialTribeBonus = 35;

/// Conquest army-move bonus for New World invadable destinations.
const int kConquestArmyMoveNwInvadableBonus = 18;

/// Economy-domain weight boost for cargo preference when colonial targets exist.
const int kColonialCargoPreferenceEconomyBoost = 28;

/// Extra cargo boost when the GP owns no New World provinces yet.
const int kColonialCargoPreferenceNoNwColoniesBoost = 12;

/// Naval planner weight boost when New World invasion/colonization is viable.
const int kColonialNavalWeightBonus = 22;
