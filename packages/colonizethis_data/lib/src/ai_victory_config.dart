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

/// Observer default start OW provinces per GP (Refs #2509).
const int kObserverDefaultStartOldWorldProvincesPerGp = 7;

/// Old World holdings at or below this count are treated as stalled expansion
/// (observer default start is 7 provinces per GP; 9 includes seed-42 gp6 plateau).
const int kStalledOldWorldProvinceThreshold = 9;

/// True when [oldWorldProvincesOwned] matches the observer start-size stall band.
bool isStalledOldWorldExpansion(int oldWorldProvincesOwned) =>
    oldWorldProvincesOwned > 0 &&
    oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold;

/// Goal penalties while Old World holdings remain at the observer start size.
const int kStalledDiplomacyGoalPenalty = 55;

/// Trade goal penalty paired with [kStalledDiplomacyGoalPenalty].
const int kStalledTradeGoalPenalty = 40;

/// Extra conquer goal weight while Old World expansion is stalled.
const int kStalledConquerGoalBonus = 30;

/// Extra conquer / reduced defend while critically weak but invadable OW minors
/// remain (recover after survival peace; Refs #2509).
const int kWeakGpRecoveryConquerBonus = 90;
const int kWeakGpRecoveryDefendPenalty = 30;

/// Extra declare-war weight toward adjacent minors when stalled.
const int kDeclareWarStalledExpansionMinorBonus = 75;

/// When OW expansion is stalled but invadable OW minors exist, prioritize
/// declaring on those minors over distant tribe wars (observer turn-100 gate).
const int kDeclareWarStalledOwMinorPriorityBonus = 280;

/// Extra declare-war weight toward OW minors while holdings are critically low.
const int kDeclareWarWeakGpOwMinorRecoveryBonus = 220;

/// Extra declare-war weight toward OW minors while below the observer quota
/// (7–9 OW holdings; Refs #2509).
const int kDeclareWarBelowQuotaOwMinorRecoveryBonus = 380;

/// Extra declare-war toward adjacent invadable OW minors at 8–9 OW with no GP war
/// (observer seed-42 gp5/gp6 plateau; Refs #2509).
const int kDeclareWarPlateauOwMinorBonus = 1050;

/// Extra declare-war weight toward invadable minors when 8–9 OW (one province
/// short of the turn-100 observer gate from default start; Refs #2509).
const int kDeclareWarNearObserverQuotaMinorBonus = 340;

/// Penalize tribe declare-war while OW holdings are stalled and invadable OW
/// minors remain (tribes without sea-reachable NW provinces for this GP).
const int kDeclareWarStalledExpansionTribePenalty = 100;

/// Extra declare-war weight on adjacent OW minors while minors still exist on
/// the map and the campaign is in the early expansion window (turn ≤ 30).
const int kDeclareWarEarlyExpansionMinorBonus = 260;

/// Penalize tribe declare-war in that early window while any OW minor remains.
const int kDeclareWarEarlyExpansionTribePenalty = 160;

/// Last turn (inclusive) for [kDeclareWarEarlyExpansionMinorBonus].
const int kDeclareWarEarlyExpansionMaxTurn = 100;

/// Through this turn, quota-meeting GPs must not open new wars on weaker
/// below-quota neighbors when the target is not already in a GP war (Refs #2509).
/// Pile-ons on below-quota victims already at war are suppressed at all turns.
const int kDeclareWarEarlyAntiDogpileMaxTurn = 50;

/// Penalty on adjacent minor declare-war when the GP already holds many OW provinces.
const int kDeclareWarSatedExpansionMinorPenalty = 100;

/// OW holdings at or above this count trigger [kDeclareWarSatedExpansionMinorPenalty].
const int kDeclareWarSatedExpansionMinorThreshold = 9;

/// Minimum diplomacy domain weight for the declare-war pass when stalled.
const int kDiplomacyDeclareWarMinWeightWhenStalled = 50;

/// Extra regiment build weight when OW holdings are stalled (any primary goal).
const double kBuildRegimentBonusWhenStalledExpansion = 4.0;

/// Extra regiment build weight when at war with no regiments in any army.
const double kBuildRegimentBonusWhenZeroRegimentsAtWar = 12.0;

/// Declare-war bonus when the target still owns an adjacent invadable province.
const int kDeclareWarMinorWithInvadableProvinceBonus = 45;

/// Conquest army-move passes per turn while Old World holdings are stalled
/// (one order per pass so each field army can march toward the frontier).
const int kStalledConquestArmyMovePasses = 22;

/// Max field armies created from Home Army splits when Old World expansion is
/// stalled (parallel marches toward invasion frontiers; Refs #2509).
const int kStalledConquestFieldArmySplitCap = 12;

/// While stalled and at war, build regiments until at least this many exist in
/// all armies (Home + field) so splits and invasions can proceed (Refs #2509).
const int kStalledMinRegimentCountWhenAtWar = 10;

/// Higher floor when fighting the sole GP that owns the invadable OW frontier.
const int kStalledMinRegimentCountWhenGpBlockerAtWar = 22;

/// Regiment build floor when critically weak with minor wars only (Refs #2509).
const int kStalledMinRegimentCountWhenCriticallyWeakNoGpWar = 12;

/// When stalled and below the regiment floor, prioritize regiment builds only if
/// current count is at or below this cap (avoids starving mid-tier GPs; #2509).
const int kStalledMilitaryRebuildCrisisRegimentCap = 4;

/// Extra regiment build floor per Old World province the frontier blocker leads by.
const int kStalledMinRegimentCountPerProvinceDeficitVsBlocker = 2;

/// Below this many standing regiments, a below-quota GP at peace with all
/// other Great Powers and an invadable Old World frontier is treated as
/// "insufficient to declare war" and forced to rebuild regiments via the
/// economy build pass (seed-42 gp3 turn-100 trap; Refs #2509). Sized just
/// below the at-war regiment floor so GPs that have exited a war with low
/// armies rebuild before EXPAND declare-war scoring picks a new target.
const int kBelowQuotaPeaceMinRegimentsBeforeDeclareWar = 6;

/// Economy-weight boost for [CargoPreference] when a below-quota GP at peace
/// cannot afford the cheapest regiment build even after pending riches treasury
/// (Refs #2509 EXPAND treasury-recovery).
const int kBelowQuotaPeaceTreasuryRecoveryCargoBoost = 50;

/// Offer-peace bonus toward a minor/tribe at war that no longer owns invadable land.
const int kOfferPeaceFutileMinorWarBonus = 80;

/// Penalty for offering peace to a minor that still owns invadable OW land while
/// below the observer quota at default start size (seed-42 gp4; Refs #2509).
const int kOfferPeaceBelowQuotaActiveMinorWarPenalty = 500;

/// Offer-peace bonus toward a stronger adjacent GP while Old World expansion is
/// stalled and that GP owns the invadable frontier (exit unwinnable wars; #2509).
const int kOfferPeaceStalledStrongerGpBlockerBonus = 240;

/// Offer-peace bonus toward a Great Power at war that owns none of this GP's
/// invadable Old World provinces while minors still hold invadable land
/// (exit distracting GP wars; observer seed-42 gp4/gp6; Refs #2509).
const int kOfferPeaceStalledFutileGpWarBonus = 230;

/// Default observer start OW provinces per GP plus the turn-100 conquest gate (+3).
const int kObserverConquestMinOwProvincesPerGp = 10;

/// Turn when near-quota GPs in EXPAND may enter COLONIAL-lite (Refs #2509 S10).
const int kObserverColonialLiteMinTurn = 120;

/// OW holdings at or above this while still below quota enables COLONIAL-lite.
const int kObserverColonialLiteNearQuotaOw = 9;

/// Civilian work threshold cap in DEVELOP phase (improvement-first; Refs #2509 S10).
const int kDevelopCivilianWorkThresholdCap = 5;

/// True when OW holdings have not yet met the observer per-GP conquest quota.
bool isBelowObserverConquestQuota(int oldWorldProvincesOwned) =>
    oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp;

/// At or below the turn-100 observer per-GP conquest quota (stalled band + quota).
bool isAtObserverConquestQuotaBand(int oldWorldProvincesOwned) =>
    oldWorldProvincesOwned > 0 &&
    oldWorldProvincesOwned <= kObserverConquestMinOwProvincesPerGp;

/// Stalled band or still below the turn-100 observer per-GP conquest quota.
bool isObserverConquestExpansionPressure(int oldWorldProvincesOwned) =>
    isStalledOldWorldExpansion(oldWorldProvincesOwned) ||
    isBelowObserverConquestQuota(oldWorldProvincesOwned);

/// Offer-peace toward the sole GP enemy when this GP meets the observer quota and
/// leads that enemy by at least this many OW provinces (lock gains; Refs #2509).
const int kConsolidateGainsSoleGpProvinceLead = 3;

/// Minimum OW holdings before [consolidateGainsSoleGpPeaceTarget] may fire (quota + buffer).
const int kObserverConquestConsolidateMinOwProvinces =
    kObserverConquestMinOwProvincesPerGp + 2;

/// Enemy must lead by at least this many OW provinces for
/// [unwinnableSoleGpFrontierPeaceTarget] (avoid premature sole-GP peace).
const int kUnwinnableSoleGpMinProvinceDeficit = 2;

/// Declare-war bonus on adjacent invadable OW minors while below the observer quota.
const int kDeclareWarBelowObserverQuotaMinorBonus = 480;

/// Offer-peace bonus toward any at-war Great Power when stalled with zero regiments
/// (exit unwinnable GP wars before elimination; observer seed-42 gp3; Refs #2509).
const int kOfferPeaceStalledZeroRegimentGpWarBonus = 270;

/// OW province floor for `mutualExhaustedBelowQuotaGpStalematePeaceTargets`
/// (Refs #2509). Excludes early-game / collapsed-survival GPs whose stalemate
/// is already handled by [criticalWeakGpSurvivalPeaceTargets]; targets the
/// late-stalled "8-9 plateau" band specifically.
const int kMutualExhaustedGpStalemateMinOw =
    kObserverDefaultStartOldWorldProvincesPerGp + 1;

/// Regiment ceiling under which a Great Power is treated as militarily exhausted
/// for the mutual-stalemate peace check (Refs #2509; observer seed-42 gp3/gp4
/// 3-regiment plateau). Above this threshold, the GP can still field meaningful
/// force and the war is not considered terminally exhausted.
const int kMutualExhaustedGpRegimentMax = 4;

/// Treasury ceiling (pounds) under which a Great Power is treated as economically
/// exhausted for the mutual-stalemate peace check (Refs #2509). Combined with the
/// regiment ceiling, this targets GPs that cannot rebuild offensive force while
/// the war continues.
const int kMutualExhaustedGpTreasuryMax = 30;

/// Offer-peace bonus toward the sole at-war Great Power when both sides are
/// mutual-plateau peers below the observer quota AND both are exhausted in
/// regiments and treasury (Refs #2509; observer seed-42 gp3/gp4 stalemate). Sized
/// above [kOfferPeaceStalledZeroRegimentGpWarBonus] so a mutually-exhausted
/// stalemate outranks single-side zero-regiment exits but stays below the strong
/// blocker survival bonus.
const int kOfferPeaceMutualExhaustedGpStalemateBonus = 280;

/// Regiment build floor when critically weak, below the observer quota, and at war.
const int kStalledMinRegimentCountWhenCriticallyWeakBelowQuota = 12;

/// Offer-peace bonus for [unwinnableSoleGpFrontierPeaceTarget] (Refs #2509).
const int kOfferPeaceUnwinnableSoleGpWarBonus = 250;

/// Offer-peace bonus for [consolidateGainsSoleGpPeaceTarget] (Refs #2509).
const int kOfferPeaceConsolidateGainsSoleGpWarBonus = 260;

/// When far from victory, defend goal bonus while Old World holdings are small.
const int kDefendBonusWhenFewOldWorldProvinces = 35;

/// Extra defend weight when at war and Old World holdings are at or below
/// [kFewOldWorldProvincesDefendThreshold] (trade-focused GPs avoid collapse).
const int kDefendBonusWhenAtWarAndFewHoldings = 45;

/// Old World province count at or below which [kDefendBonusWhenFewOldWorldProvinces] applies.
const int kFewOldWorldProvincesDefendThreshold = 6;

/// OW holdings at or below which a lone GP [offerPeace] may end a GP war without
/// a reciprocal offer (survival peace; matches
/// [kFewOldWorldProvincesDefendThreshold]; Refs #2509).
const int kCollapsedOldWorldProvincesSurvivalPeace =
    kFewOldWorldProvincesDefendThreshold;

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
const int kColonialNavalWeightBonus = 65;

/// Minimum naval planner domain weight under active colonial pressure.
const int kColonialNavalMinWeightWhenPressure = 85;

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
const int kBuildImprovementExtractableResourceScore = 580;

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
const int kColonialCivilianWorkThresholdCap = 12;

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

/// Additional tribe declare-war weight when colonial pressure is active and
/// Old World expansion is stalled, so NW targets beat stacked OW minor bonuses.
const int kDeclareWarColonialNwTribePriorityOverOwMinorBonus = 360;

/// Extra declare-war weight for low-[warLikelihood] leaders toward adjacent
/// invadable minors while Old World expansion is stalled.
const int kDeclareWarStalledLowWarLikelihoodMinorBonus = 180;

/// Minimum declare-war score for low-[warLikelihood] leaders toward adjacent
/// invadable minors while Old World expansion is stalled (henry / Portugal).
const int kDeclareWarStalledLowWarLikelihoodMinorFloor = 620;

/// Cap declare-war score toward NW tribes for low-[warLikelihood] leaders when
/// invadable Old World minors remain (henry clears OW minors before tribes).
const int kDeclareWarStalledLowWarLikelihoodTribeCap = 150;

/// Minimum declare-war score for any leader toward adjacent invadable minors
/// while Old World expansion is stalled and far from military victory.
const int kDeclareWarStalledAdjacentInvadableMinorFloor = 400;

/// Higher floor for critically weak GPs toward adjacent invadable OW minors.
const int kDeclareWarWeakGpAdjacentInvadableMinorFloor = 580;

/// Declare-war bonus toward OW minors when critically weak, invadable land
/// remains, and the GP is not at war with any other Great Power (Refs #2509).
const int kDeclareWarCriticalWeakNoGpWarMinorBonus = 220;

/// Declare-war penalty toward adjacent GPs while invadable Old World minors
/// remain and expansion is stalled (reduces GP dogpiles on seed-42).
const int kDeclareWarStalledGpWhenMinorsRemainPenalty = 280;

/// Declare-war penalty toward a stalled weaker neighbor GP (mid-map deadlocks).
const int kDeclareWarOnStalledWeakerNeighborPenalty = 200;

/// Suppress declare-war on adjacent GPs at or below
/// [kFewOldWorldProvincesDefendThreshold] when the attacker leads by at least
/// this many Old World provinces (observer seed-42 gp3/gp6; Refs #2509).
const int kDeclareWarAggressorSuppressWeakGpLeadThreshold = 4;

/// Offer-peace bonus toward the invadable OW frontier GP while holdings are
/// critically low and that GP leads by
/// [kDeclareWarAggressorSuppressWeakGpLeadThreshold] or more (Refs #2509).
const int kOfferPeaceWeakVsInvadableBlockerBonus = 260;

/// Cap NW tribe declare-war scores while invadable Old World minors remain.
const int kDeclareWarStalledTribeWhenOwMinorCap = 250;

/// Declare-war penalty toward Old World minors with no sea-reachable NW
/// provinces while colonial pressure is active.
const int kDeclareWarColonialPressureOwMinorPenalty = 50;

/// Declare-war bonus for non-adjacent minors with fewer provinces than a stalled GP.
const int kDeclareWarStalledWeakerMinorBonus = 80;

/// Extra declare-war weight toward any minor that still holds Old World provinces
/// while the GP remains at the observer start OW size.
const int kDeclareWarStalledActiveOwMinorBonus = 200;

/// Minimum conquest army-move pass weight when Old World expansion is stalled.
const int kConquestArmyMoveMinWeightWhenStalled = 75;

/// Army-move weight floor when critically weak and not at war with any GP.
const int kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar = 100;

/// Army-move score bonus for invadable provinces owned by the same-turn
/// declare-war target while Old World expansion is stalled.
const double kConquestArmyMoveStalledDeclaredTargetInvadableBonus = 800;

/// Army-move score bonus for any province owned by the same-turn declare-war
/// target while Old World expansion is stalled.
const double kConquestArmyMoveStalledDeclaredTargetBonus = 250;

/// Army-move score bonus when the destination is topologically adjacent to an
/// invadable Old World province (march toward the invasion frontier).
const double kConquestArmyMoveAdjacentInvadableBonus = 450;

/// Army-move score bonus for invadable provinces owned by a Great Power the
/// attacker is already at war with (seed-42 gp3/gp5 blockers; Refs #2509).
const double kConquestArmyMoveStalledGpInvadableBlockerBonus = 1900;

/// Extra army-move score per OW province the invadable-blocker GP leads by.
const double kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince = 300;

/// Penalize offer-peace toward the invadable OW frontier GP while still below
/// the turn-100 observer quota (avoid premature blocker peace; Refs #2509).
const int kOfferPeaceBelowQuotaInvadableBlockerPenalty = 420;

/// Penalize offer-peace toward any Great Power while at default start OW size
/// and below the observer quota (avoid net OW loss; seed-42 gp3; Refs #2509).
const int kOfferPeaceBelowQuotaStartSizeGpWarPenalty = 420;

/// Army-move score bonus for own provinces bordering a faction already at war
/// (march to frontier when invadable tiles are not yet visible).
const double kConquestArmyMoveAdjacentAtWarFrontierBonus = 650;

/// Declare-war bonus when the weakest invadable-border GP blocks expansion.
const int kDeclareWarStalledWeakestInvadableGpBonus = 75;

/// Declare-war bonus toward a weaker adjacent GP that owns invadable OW land
/// while expansion is stalled and far from victory (Refs #2509).
const int kDeclareWarStalledInvadableGpBlockerBonus = 220;

/// Minimum declare-war score toward the GP that owns invadable OW frontier when
/// no minors hold invadable land (seed-42 mid-map blockers; Refs #2509).
const int kDeclareWarStalledGpInvadableBlockerFloor = 500;

/// Declare-war bonus toward a non-adjacent minor while invadable OW land is
/// blocked by Great Powers (seed-42 mid-map geography; Refs #2509).
const int kDeclareWarStalledGpBlockerDistantMinorBonus = 160;

/// Declare-war bonus on any OW minor while still at default observer start size.
const int kDeclareWarDefaultStartOwMinorBonus = 240;

/// Declare-war bonus toward any minor that still holds OW provinces when this
/// GP is stalled, far from victory, and frontier invadable land is GP-owned.
const int kDeclareWarStalledAnyOwMinorBonus = 140;
