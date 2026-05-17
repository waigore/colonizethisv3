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
const int kColonialExpandBonusWhenInvadableNw = 45;

/// Conquer-goal bonus for colonial pressure (below OW victory floors).
const int kColonialConquerBonusWhenInvadableNw = 40;

/// Declare-war bonus toward a tribe/minor that owns adjacent New World provinces.
const int kDeclareWarColonialAdjacentTribeBonus = 70;

/// Establish-overture bonus toward a preferred colonial tribe target.
const int kEstablishOvertureColonialTribeBonus = 60;

/// Establish-overture bonus toward a tribe owning a sea-reachable NW province.
const int kEstablishOvertureColonialInvadableOwnerBonus = 120;

/// Conquest army-move bonus for New World invadable destinations.
const int kConquestArmyMoveNwInvadableBonus = 35;

/// Economy-domain weight boost for cargo preference when colonial targets exist.
const int kColonialCargoPreferenceEconomyBoost = 40;

/// Extra cargo boost when the GP owns no New World provinces yet.
const int kColonialCargoPreferenceNoNwColoniesBoost = 28;

/// Naval planner weight boost when New World invasion/colonization is viable.
const int kColonialNavalWeightBonus = 55;

/// Naval move score when docking at a New World port under colonial pressure.
const int kColonialNavalMoveDockNewWorldPortScore = 180;

/// Naval move score for an NW sea zone bordering an invadable NW province.
const int kColonialNavalMovePriorityNwSeaZoneScore = 200;

/// Naval move score for any other New World sea zone destination.
const int kColonialNavalMoveNwSeaZoneScore = 140;

/// Naval move score for an Old World sea zone with a warp/adjacent link to NW seas.
const int kColonialNavalMoveGatewaySeaZoneScore = 90;

/// Declare-war bonus when the target owns a sea-reachable invadable NW province.
const int kDeclareWarColonialInvadableOwnerBonus = 110;

/// Goal bonuses when the GP still owns fewer than this many NW provinces.
const int kColonialFewNwProvincesThreshold = 8;

/// Extra conquer weight when below [kColonialFewNwProvincesThreshold] NW holdings.
const int kColonialConquerBonusWhenFewNwProvinces = 55;

/// Penalty to diplomacy goal weight while sea-reachable NW targets exist and
/// holdings are below [kColonialFewNwProvincesThreshold].
const int kColonialDiplomacyGoalPenaltyWhenPressure = 45;

/// Penalty to trade goal weight under the same colonial pressure.
const int kColonialTradeGoalPenaltyWhenPressure = 25;

/// Floor for `expand` under colonial pressure (does not reduce OW floors).
const int kMinimumColonialExpandScoreWhenPressure = 90;

/// Floor for `conquer` under colonial pressure (does not reduce OW floors).
const int kMinimumColonialConquerScoreWhenPressure = 95;

/// Minimum declare-war diplomacy pass weight under colonial pressure.
const int kDiplomacyDeclareWarMinWeightWhenColonialPressure = 55;

/// Minimum conquest army-move pass weight under colonial pressure.
const int kConquestArmyMoveMinWeightWhenColonialPressure = 45;

/// Full AI explore-work score bonus when the target tile is in the New World.
const int kExploreWorkScoreBonusNewWorld = 80;

/// Full AI build-improvement score for an unimproved extractable resource tile.
const int kBuildImprovementExtractableResourceScore = 450;

/// Extra build-improvement score on unimproved extractable tiles in the NW region.
const int kBuildImprovementNewWorldResourceBonus = 120;

/// Additional build-improvement score when the tile is in a GP-owned NW province
/// (observer turn-150 improvement gate; Refs #2509).
const int kBuildImprovementOwnedNewWorldResourceBonus = 120;

/// Merchant purchase_land score for NW tribe/minor tiles (colonial acquisition).
const int kPurchaseLandNewWorldTribeWorkScore = 320;

/// Merchant purchase_land score for other NW tiles.
const int kPurchaseLandNewWorldOtherWorkScore = 160;

/// Civilian work economy threshold cap when colonial targets are visible.
const int kColonialCivilianWorkThresholdCap = 22;

/// Build-order economy threshold cap when the GP owns any NW provinces.
const int kColonialBuildOrderThresholdWhenOwnedNw = 18;

/// Lower build threshold when the GP owns NW provinces and acquisition targets
/// remain (late-game improvement pacing for observer turn-150 gate; Refs #2509).
const int kColonialBuildOrderThresholdWhenOwnedNwUnderPressure = 15;

/// Naval mission score when [NavalMissionOrder.targetPortId] is a New World port.
const int kColonialNavalMissionNwPortScore = 160;

/// Naval mission score when [NavalMissionOrder.targetProvinceId] is in the NW.
const int kColonialNavalMissionNwProvinceScore = 130;

/// Naval mission score for beachhead missions under colonial pressure.
const int kColonialNavalMissionBeachheadScore = 100;

/// Extra declare-war weight for **tribes** owning sea-reachable NW provinces so
/// they outrank adjacent Old World minor targets under colonial pressure.
const int kDeclareWarColonialNwTribeDominanceBonus = 100;

/// Declare-war penalty toward Old World minors with no sea-reachable NW
/// provinces while colonial pressure is active.
const int kDeclareWarColonialPressureOwMinorPenalty = 50;
