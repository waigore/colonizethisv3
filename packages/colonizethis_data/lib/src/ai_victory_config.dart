/// Victory-pace bonuses for Full AI goal selection. SPEC/game/victory.md, SPEC/ai/ai-architecture.md.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_economy.dart' show unlockingTechByCivilianId;

/// Old World province count required for military victory.
const int kMilitaryVictoryOldWorldProvinceThreshold = 31;

/// Region id for Old World provinces (prefixed `oldWorld|…`).
const String kOldWorldRegionId = 'oldWorld';

/// Region id for New World provinces (prefixed `newWorld|…`).
const String kNewWorldRegionId = 'newWorld';

/// Provinces still needed to reach military victory from [oldWorldOwned].
int provincesToVictoryFromOldWorldOwned(int oldWorldOwned) {
  final gap = kMilitaryVictoryOldWorldProvinceThreshold - oldWorldOwned;
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

/// True when zero-regiment survival peace may engage: below the observer
/// conquest quota and either in the stalled OW band or at terminal attrition
/// collapse (zero OW holdings; Refs #2847 § H8).
bool isZeroRegimentSurvivalOwContext(int oldWorldProvincesOwned) =>
    isBelowObserverConquestQuota(oldWorldProvincesOwned) &&
    (isStalledOldWorldExpansion(oldWorldProvincesOwned) ||
        oldWorldProvincesOwned == 0);

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
/// Includes seed-42 gp3 plateau treasury (~50) so mutual-exhausted peace can
/// fire alongside gp4 (0 treasury) and end the sole GP-blocker war (Refs #2509).
const int kMutualExhaustedGpTreasuryMax = 55;

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

/// Maximum reduction applied to `establishOverture` improve-relations desire
/// when per-turn relation decay (Refs #3753 R9.3/R9.4) will naturally drift a
/// below-equilibrium relation back toward neutral 50 on its own. Scaled by the
/// fraction of the gap-to-equilibrium that one turn of decay closes, so a pair
/// that decay alone restores to neutral next turn is discounted by the full
/// amount, while a deeply hostile pair (decay barely helps) is barely
/// discounted. SPEC/ai/phase-planner-architecture.md § Decay-aware overture.
const int kEstablishOvertureDecayCreditMax = 20;

/// Establish-overture incentive added when the active AI is **not** the
/// current favoured trading partner (highest GP→seller relation) for a
/// Minor/Tribe target. The favoured partner wins the world-market
/// sell-priority tiebreaker among consulate-holding buyers, so a trailing GP
/// is nudged to invest in the relationship (Refs #3758 S10/R11; #3753 R7).
/// SPEC/ai/phase-planner-architecture.md § Favoured-trading-partner
/// competition overture; SPEC/game/world-market.md § Favored Trading Partner.
const int kEstablishOvertureFtpCompetitionBonus = 30;

/// Maximum establish-overture incentive for the overseas-profit **embassy
/// kickback** (Refs #3758 R7/R8 / S6; #3753 R8.3). Every embassy-holding Great
/// Power earns `filledQuantity × pricePerUnit × (relationScore / 100) × 0.10`
/// on each world-market sale from a Minor/Tribe seller — income that requires
/// only an embassy (no purchased tile, no Merchant). When the AI does **not**
/// yet hold an embassy with a Minor/Tribe at peace, this bonus values advancing
/// the overture toward the embassy stage purely for the kickback income, scaled
/// by the relation fraction and the seller's sales-volume proxy, so a
/// high-volume seller is worth an embassy even without a purchase-land intent.
/// SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
const int kEstablishOvertureEmbassyKickbackBonusMax = 24;

/// Seller sales-volume proxy — the count of non-empty resource tiles a
/// Minor/Tribe owns — at or above which [kEstablishOvertureEmbassyKickbackBonusMax]
/// saturates to its maximum. Below this the bonus scales linearly with the
/// seller's resource-tile count; at zero tiles no kickback bonus applies.
/// SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
const int kEstablishOvertureEmbassyKickbackVolumeFull = 4;

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

/// Naval move score for an NW sea zone bordering a **phase-priority** NW
/// invadable province (Refs #2509 S5). Phase-priority provinces are surfaced
/// by `resolvePhaseNavalDirective` from
/// `ColonialNavalPlan.priorityInvasionTransportProvinceIdsSorted` (COLONIAL —
/// declared colonial target's invadable provinces or the at-war owner
/// fallback) or `ColonialLiteNavalPlan.priorityNwProvinceIdsSorted`
/// (COLONIAL-lite — tribe / minor-only invadable provinces). The phase-
/// priority tier ranks above the general priority tier so fleets approach the
/// phase-active acquisition frontier ahead of unrelated invadable NW
/// neighbors when both are reachable on the same turn.
const int kColonialNavalMovePhasePriorityNwSeaZoneScore = 240;

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

/// `trade` goal floor when the GP is broke (`treasury <= 0`) after every
/// other modifier in `evaluateStrategicGoalScores` has been applied. Sized
/// to strictly outrank the worst-case competing goal envelope (stalled-OW
/// `conquer = math.max(conquer, 120)`, victory-pace + endgame conquer
/// bonuses up to `40 + 25 = 65`, max base-trade weight `90`), so a treasury
/// of zero always selects `StrategicGoal.trade` regardless of phase, leader
/// agenda, or stalled / colonial-pressure clamps on `trade`. World Market —
/// AI treasury planner; Refs #2994 F6.
const int kEmergencyTradeGoalDominantFloor = 200;

/// Peak linear bonus added to the `trade` goal score when treasury is
/// strictly between `0` and `cheapestRegimentBuildTreasuryCost()`. Scales
/// as `boost = round((1 - treasury / threshold) * kBoostMax)`: near-zero
/// treasury gets the full `kBoostMax` (lifting a moderate-trade leader near
/// the stalled-OW conquer floor of `120` so trade competes but does not yet
/// hit the emergency floor); at-threshold treasury gets `0`. World Market —
/// AI treasury planner; Refs #2994 F6.
const int kTreasuryAcquisitionTradeBoostMax = 80;

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

/// Full AI civilian-work score boost applied to an unimproved feedstock resource
/// tile when the regiment/supplier/seller feedstock-extraction gate is active
/// (`selectFullAiCivilianWorkOrders`). Sized above
/// [kBuildImprovementExtractableResourceScore] plus the New World resource
/// bonuses so a lock-recovery seller routes its Builder onto the feedstock tile
/// ahead of any other extractable improvement. GA-tunable (Refs #3794);
/// behaviour is normative in SPEC/ai/civilian-work-planner.md.
const int kRegimentBuildInputFeedstockExtractionScoreBoost = 600;

/// Full AI civilian-work score boost applied to an unimproved **fabric**
/// feedstock resource tile (`wool` / `cotton`) under the growth-stage planner
/// (Refs #3371 AC1). Sized above
/// [kRegimentBuildInputFeedstockExtractionScoreBoost] and the New World resource
/// bonuses so a low-labour GP improves a wool/cotton tile ahead of grain, New
/// World, or H8 extraction work. GA-tunable (Refs #3794); behaviour is normative
/// in SPEC/ai/civilian-work-planner.md.
const int kGrowthStageFabricFeedstockScoreBoost = 700;

/// Full AI civilian-work score boost applied to an unimproved
/// **infrastructure** feedstock resource tile (`timber` / `iron` / `coal`) under
/// the growth-stage planner (Refs #3371 AC2). Sized above the New World resource
/// bonuses but below [kGrowthStageFabricFeedstockScoreBoost] so a maturing GP
/// improves castIron/lumber feedstock only after fabric is secured. GA-tunable
/// (Refs #3794); behaviour is normative in SPEC/ai/civilian-work-planner.md.
const int kGrowthStageInfraFeedstockScoreBoost = 520;

/// Full AI civilian-work `prospect` score boost applied to an unprospected
/// mineral feedstock tile under the feedstock-extraction gate, so an Explorer
/// prospects the feedstock mineral ahead of ordinary explore/prospect work and
/// the Builder feedstock-extraction boost then has a valid (prospected) tile to
/// improve. Sized to match [kRegimentBuildInputFeedstockExtractionScoreBoost].
/// GA-tunable (Refs #3794); behaviour is normative in
/// SPEC/ai/civilian-work-planner.md.
const int kFeedstockMineralProspectScoreBoost = 600;

/// Baseline Full AI work score for any valid Rail Builder `build_rail`
/// candidate, ensuring every rail candidate is scored non-zero rather than
/// falling through to the lexicographic default (Refs #3794 § Rail Builder
/// civilian-work scoring, AC6). Sized below the contextual bonuses so context
/// differentiates otherwise-equal candidates.
const int kBuildRailBaseWorkScore = 100;

/// Extra Rail Builder `build_rail` score when the target road tile carries a
/// resource (proxy for province resource output, the cheap per-tile signal the
/// scorer uses instead of per-tile path-finding; Refs #3794 AC6).
const int kBuildRailResourceOutputBonus = 200;

/// Extra Rail Builder `build_rail` score when the target road tile lies in the
/// player's capital province (capital-connector proxy; Refs #3794 AC6).
const int kBuildRailCapitalConnectorBonus = 150;

/// Extra Rail Builder `build_rail` score when the target road tile is in the
/// New World region (colonial rail bias; Refs #3794 AC6).
const int kBuildRailNewWorldBonus = 80;

/// Per-target-type baseline score for an Engineer `build_road` candidate in the
/// unified Engineer scored pool (replaces the lexicographic fallback; Refs #3794
/// § Engineer). Per-target base weights express the relative priority of the
/// three Engineer targets; contextual bonuses then differentiate candidates of
/// the same target. Roads default highest (logistics backbone).
const int kEngineerBuildRoadBaseWorkScore = 120;

/// Per-target-type baseline score for an Engineer `build_port` candidate in the
/// unified Engineer scored pool (Refs #3794 § Engineer).
const int kEngineerBuildPortBaseWorkScore = 110;

/// Per-target-type baseline score for an Engineer `build_fort` candidate in the
/// unified Engineer scored pool (Refs #3794 § Engineer).
const int kEngineerBuildFortBaseWorkScore = 100;

/// Extra Engineer `build_road` score when the target tile carries a resource
/// (resource-connectivity proxy — the cheap per-tile signal the scorer uses
/// instead of per-tile path-finding; Refs #3794 § Engineer).
const int kEngineerRoadResourceConnectivityBonus = 200;

/// Extra Engineer `build_road` score when the target tile lies in the player's
/// capital province (capital-logistics proxy; Refs #3794 § Engineer).
const int kEngineerRoadCapitalLogisticsBonus = 150;

/// Extra Engineer `build_port` score when the target tile carries a resource
/// (high-value extraction proxy; Refs #3794 § Engineer).
const int kEngineerPortResourceExtractionBonus = 180;

/// Extra Engineer `build_port` score when the target tile is in the New World
/// region (colonial coastal bias proxy; Refs #3794 § Engineer).
const int kEngineerPortNewWorldCoastalBonus = 120;

/// Extra Engineer `build_fort` score when the target tile lies in the player's
/// capital province (capital-defense proxy; Refs #3794 § Engineer).
const int kEngineerFortCapitalDefenseBonus = 160;

/// Extra Engineer `build_fort` score when the target tile is in the New World
/// region (colonial-frontier border proxy; Refs #3794 § Engineer).
const int kEngineerFortNewWorldBorderBonus = 100;

/// Per-target-type baseline score for a Builder `upgrade_town` candidate in the
/// unified Builder scored pool (`build_improvement` + `upgrade_town`; Refs #3794
/// § Builder). Sized below [kBuildImprovementExtractableResourceScore] so a
/// genuine unimproved resource extraction still outranks a bare town upgrade,
/// yet above the degenerate `build_improvement` sentinel scores (1 = already
/// improved, 2 = no resource) so a town upgrade competes when no high-value
/// extraction exists. Contextual bonuses then differentiate town upgrades.
const int kUpgradeTownBaseWorkScore = 300;

/// Extra Builder `upgrade_town` score when the target town tile carries a
/// resource (town resource-value proxy — the cheap per-tile signal the scorer
/// uses instead of per-province aggregation; Refs #3794 § Builder).
const int kUpgradeTownResourceValueBonus = 200;

/// Extra Builder `upgrade_town` score when the target town tile is in the New
/// World region (front-line / colonial-frontier proximity proxy; Refs #3794
/// § Builder).
const int kUpgradeTownFrontlineBonus = 150;

/// Extra Builder `upgrade_town` score when the target town tile has the lowest
/// current development level (improvement level `0`), so the AI develops the
/// least-developed towns first (Refs #3794 § Builder).
const int kUpgradeTownLowDevBonus = 120;

/// Baseline Full AI work score for any valid Spy `steal_tech` candidate in the
/// unified Spy scored pool (`steal_tech` + `counter_spy`; Refs #3794 § Spy).
/// Sized so a `steal_tech` candidate is non-zero and the phase bonus, not the
/// alphabetical target order, decides cross-type preference.
const int kSpyStealTechBaseWorkScore = 200;

/// Per-tech Spy `steal_tech` bonus for each tech the rival GP has unlocked that
/// the player lacks (tech-deficit proxy; deficit count capped at 60 for
/// determinism/budget; Refs #3794 § Spy).
const int kSpyStealTechTechDeficitWeight = 10;

/// Extra Spy `steal_tech` score when the player is at war with the rival GP, or
/// the decimal relation score is in the 0-25 Hostile band (worse relations →
/// higher score; scores are `[0, 100]` with 50 neutral; Refs #3794 § Spy).
const int kSpyStealTechHostileRelationsBonus = 150;

/// Extra Spy `steal_tech` score when the rival GP's capital province is in the
/// same region as the Spy (cheap proximity proxy instead of path-finding;
/// Refs #3794 § Spy).
const int kSpyStealTechProximityBonus = 90;

/// Baseline Full AI work score for any valid Spy `counter_spy` candidate in the
/// unified Spy scored pool (Refs #3794 § Spy).
const int kSpyCounterSpyBaseWorkScore = 200;

/// Extra Spy `counter_spy` score when a foreign-owned Spy occupies the candidate
/// province (known enemy-spy-presence proxy; Refs #3794 § Spy).
const int kSpyCounterSpyEnemySpyPresenceBonus = 200;

/// Extra Spy `counter_spy` score when the candidate province is the player's
/// capital province (capital-protection proxy; Refs #3794 § Spy).
const int kSpyCounterSpyCapitalBonus = 120;

/// Extra Spy `counter_spy` score when the candidate province is in the New World
/// region (frontier/border proxy; Refs #3794 § Spy).
const int kSpyCounterSpyBorderBonus = 90;

/// Phase bonus added to Spy `steal_tech` scores outside the DEVELOP phase
/// (EXPAND / COLONIAL / COLONIAL-lite), sized to dominate the contextual bonuses
/// of `counter_spy` so the phase preference is decisive while context still
/// differentiates same-target candidates (Refs #3794 § Spy, AC23).
const int kSpyPhaseStealTechBonus = 2000;

/// Phase bonus added to Spy `counter_spy` scores in the DEVELOP phase, sized to
/// dominate the contextual bonuses of `steal_tech` so the phase preference is
/// decisive while context still differentiates same-target candidates
/// (Refs #3794 § Spy, AC24).
const int kSpyPhaseCounterSpyBonus = 2000;

/// Civilian work economy threshold cap when colonial targets are visible.
const int kColonialCivilianWorkThresholdCap = 12;

/// Build-order economy threshold cap under COLONIAL acquisition pressure when
/// the GP already owns at least one New World province (late-game improvement
/// pacing for observer turn-150 gate; Refs #2509). Applied by
/// `resolvePhaseEconomyColonialBuildOrderThresholdCap` only when the active
/// phase is [ObserverGoalPhase.colonial]; structurally suppressed under
/// EXPAND, COLONIAL-lite, and DEVELOP per
/// `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy build
/// colonial-cap slice.
const int kColonialBuildOrderThresholdWhenOwnedNwUnderPressure = 15;

/// Naval mission score when [NavalMissionOrder.targetPortId] is a New World port.
const int kColonialNavalMissionNwPortScore = 160;

/// Naval mission score when [NavalMissionOrder.targetPortId] points at a New
/// World port whose province id is in the per-phase priority NW province
/// subset surfaced by `resolvePhaseNavalDirective` (Refs #2509 S5 mission-
/// ranking slice). One tier above [kColonialNavalMissionNwPortScore] (160) so
/// missions targeting the COLONIAL declared invasion frontier (or the
/// COLONIAL-lite tribe / minor-only subset) outrank missions toward unrelated
/// NW ports when both arms are scored on the same turn. Empty / null priority
/// list (legacy callers) preserves the prior NW-port tier exactly.
const int kColonialNavalMissionPhasePriorityNwPortScore = 200;

/// Naval mission score when [NavalMissionOrder.targetProvinceId] is in the NW.
const int kColonialNavalMissionNwProvinceScore = 130;

/// Naval mission score when [NavalMissionOrder.targetProvinceId] is in the
/// per-phase priority NW province subset (Refs #2509 S5). Mirrors the
/// [kColonialNavalMissionPhasePriorityNwPortScore] tier for the
/// `targetProvinceId` branch: one step above
/// [kColonialNavalMissionNwProvinceScore] (130) so missions targeting the
/// phase-active NW frontier rank ahead of unrelated NW-province missions.
/// Empty / null priority list preserves the legacy tier exactly.
const int kColonialNavalMissionPhasePriorityNwProvinceScore = 170;

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

// ---------------------------------------------------------------------------
// Civilian build planner — scoring model (Refs #3793).
// GA-tunable parameters for the additive civilian build scoring branch in
// `pickBuildOrder` (SPEC/ai/civilian-build-planner.md § Scoring model). No
// planner magic numbers: the build planner reads only the constants/helpers
// declared here. Phase multipliers, Spy intelligence/war-demand boost, and the
// shared paper ledger are deferred to a later #3793 slice.
// ---------------------------------------------------------------------------

/// Base score for a civilian build candidate before any multiplier
/// (`base × minCapBoost × replacementUrgency`). Sized at `1.0` so a civilian at
/// or above its `targetCount` competes on the same `1.0` footing as the
/// military/naval baseline (`1.0 + bonuses`).
const double kCivilianBuildBaseScore = 1.0;

/// Hard-floor multiplier applied to a civilian build candidate whose current
/// count is strictly below its per-type `minCount` (SPEC § Scoring model — min
/// cap). Sized far above the military/naval bonus envelope (cargo/military
/// bonuses sum to well under `20`) so a below-min civilian dominates the
/// weighted build pool.
const double kCivilianBuildMinCapScoreBoost = 50.0;

/// Replacement-urgency factor: while `minCount <= currentCount < targetCount`,
/// a civilian candidate score is multiplied by
/// `1 + kCivilianBuildReplacementUrgencyFactor × (targetCount − currentCount)`
/// (SPEC § Scoring model — replacement urgency). `0.5` lifts a single-unit
/// deficit by `+50%` without reaching the hard-floor boost.
const double kCivilianBuildReplacementUrgencyFactor = 0.5;

/// Per-type hard minimum count (GA-tunable floor). Below this count the
/// candidate receives [kCivilianBuildMinCapScoreBoost]. Types absent from the
/// map default to `0` (no floor).
const Map<String, int> kCivilianBuildMinCountByType = {
  kUnitTypeBuilder: 2,
  kUnitTypeExplorer: 1,
  kUnitTypeEngineer: 1,
  kUnitTypeSpy: 0,
  kUnitTypeMerchant: 0,
  kUnitTypeRailBuilder: 0,
};

/// Per-type soft target count (GA-tunable). While at or above `minCount` but
/// below `targetCount`, replacement urgency applies. Starting types seed their
/// starting allotment (Explorer 2, Builder 2, Engineer 1); other types default
/// to their `minCount`.
const Map<String, int> kCivilianBuildTargetCountByType = {
  kUnitTypeBuilder: 2,
  kUnitTypeExplorer: 2,
  kUnitTypeEngineer: 1,
  kUnitTypeSpy: 0,
  kUnitTypeMerchant: 0,
  kUnitTypeRailBuilder: 0,
};

/// Per-type hard maximum count (GA-tunable ceiling). A candidate at or above
/// this count is excluded from the build pool (SPEC § Scoring model — max cap)
/// so civilian over-building cannot starve military/naval production. Types
/// absent from the map have no ceiling.
const Map<String, int> kCivilianBuildMaxCountByType = {
  kUnitTypeBuilder: 6,
  kUnitTypeExplorer: 4,
  kUnitTypeEngineer: 4,
  kUnitTypeMerchant: 4,
  kUnitTypeRailBuilder: 4,
};

/// Per-type hard minimum count for [unitType] (defaults to `0`).
int civilianBuildMinCount(String unitType) =>
    kCivilianBuildMinCountByType[unitType] ?? 0;

/// Per-type soft target count for [unitType] (defaults to its `minCount`).
int civilianBuildTargetCount(String unitType) =>
    kCivilianBuildTargetCountByType[unitType] ??
    civilianBuildMinCount(unitType);

/// Per-type hard maximum count for [unitType]; `null` means no ceiling.
int? civilianBuildMaxCount(String unitType) =>
    kCivilianBuildMaxCountByType[unitType];

/// True when [currentCount] of [unitType] is at or above its GA-tunable
/// `maxCount` ceiling, so the candidate is excluded from the build pool
/// (SPEC/ai/civilian-build-planner.md § Scoring model — max cap). Types with no
/// ceiling are never excluded.
bool isCivilianBuildAtOrAboveMaxCount(String unitType, int currentCount) {
  final max = civilianBuildMaxCount(unitType);
  if (max == null) return false;
  return currentCount >= max;
}

// ---------------------------------------------------------------------------
// Civilian build planner — phase priority + Spy demand (Refs #3793 slice 3).
// GA-tunable per-phase, per-type build priority multipliers and the Spy
// intelligence/war-demand boost (SPEC/ai/civilian-build-planner.md § Scoring
// model — phase multiplier / Spy demand). The build planner reads only the
// constants/helpers declared here (no planner magic numbers).
// ---------------------------------------------------------------------------

/// Phase keys for [kCivilianBuildPhaseMultiplierByPhaseType]. These MUST match
/// `ObserverGoalPhase.<value>.name` in `colonizethis_ai`; the AI build planner
/// passes `phase.name`. The contract is locked by an `colonizethis_ai` test
/// (`ObserverGoalPhase.expand.name == kCivilianBuildPhaseExpand`, etc.) so a
/// rename in either package is caught. `colonizethis_data` cannot depend on
/// `colonizethis_ai`, so the key is the stable enum name string.
const String kCivilianBuildPhaseExpand = 'expand';
const String kCivilianBuildPhaseColonialLite = 'colonialLite';
const String kCivilianBuildPhaseColonial = 'colonial';
const String kCivilianBuildPhaseDevelop = 'develop';

/// Neutral per-phase multiplier (no phase preference for the type).
const double kCivilianBuildPhaseMultiplierBase = 1.0;

/// Multiplier for a civilian type favored by the active phase
/// (SPEC § Scoring model — phase multiplier). Sized above
/// [kCivilianBuildPhaseMultiplierBase] so a phase-favored civilian outscores
/// a same-count, non-favored civilian, while remaining well below the min-cap
/// hard floor so phase preference never overrides a below-min replacement.
const double kCivilianBuildPhaseMultiplierFavored = 2.0;

/// Per-phase, per-type civilian build priority multiplier
/// (SPEC § Scoring model — phase multiplier): EXPAND favors Builder; COLONIAL
/// favors Explorer + Merchant; DEVELOP favors Engineer + Rail Builder.
/// COLONIAL-lite mirrors EXPAND (still OW-expansion biased). Spy is intentionally
/// absent — it is phase-flat ([kCivilianBuildSpyPhaseFlatMultiplier], decision
/// #10). Phases/types absent from the map default to
/// [kCivilianBuildPhaseMultiplierBase].
const Map<String, Map<String, double>>
kCivilianBuildPhaseMultiplierByPhaseType = {
  kCivilianBuildPhaseExpand: {
    kUnitTypeBuilder: kCivilianBuildPhaseMultiplierFavored,
  },
  kCivilianBuildPhaseColonialLite: {
    kUnitTypeBuilder: kCivilianBuildPhaseMultiplierFavored,
  },
  kCivilianBuildPhaseColonial: {
    kUnitTypeExplorer: kCivilianBuildPhaseMultiplierFavored,
    kUnitTypeMerchant: kCivilianBuildPhaseMultiplierFavored,
  },
  kCivilianBuildPhaseDevelop: {
    kUnitTypeEngineer: kCivilianBuildPhaseMultiplierFavored,
    kUnitTypeRailBuilder: kCivilianBuildPhaseMultiplierFavored,
  },
};

/// Phase-flat Spy build multiplier (decision #10): identical across every
/// phase. Spy build priority does not follow the economic phase model; it is
/// driven by [kCivilianBuildSpyDemandBoost] instead.
const double kCivilianBuildSpyPhaseFlatMultiplier = 1.0;

/// Spy intelligence/war-demand boost (decision #10): applied on top of the
/// phase-flat baseline when the GP is at war or pursuing a tech-steal posture.
const double kCivilianBuildSpyDemandBoost = 2.0;

/// GA-tunable Spy floor (decision #10, default `0`): mirrors
/// `kCivilianBuildMinCountByType[kUnitTypeSpy]`. Below this count the Spy gets
/// the standard min-cap hard floor; the demand boost applies independently.
const int kCivilianBuildMinSpies = 0;

/// GA-tunable minimum unlocked-tech lead a rival Great Power must hold over the
/// active Great Power for the active GP to be considered "pursuing a tech-steal
/// posture" (decision #10, SPEC/ai/civilian-build-planner.md § Live economy
/// wiring). When the most-advanced rival GP's unlocked-tech count exceeds the
/// active GP's by at least this many techs, a `steal_tech` target exists, so the
/// Spy demand boost ([kCivilianBuildSpyDemandBoost]) applies even at peace.
/// Default `1` (any tech deficit qualifies); a higher value restricts the
/// posture to GPs that are further behind.
const int kCivilianBuildSpyTechStealDeficit = 1;

/// Whether the active Great Power is "pursuing a tech-steal posture"
/// (decision #10) given its own unlocked-tech count [ownUnlockedTechCount] and
/// the maximum unlocked-tech count among rival Great Powers
/// [maxRivalUnlockedTechCount].
///
/// Returns `true` when
/// `maxRivalUnlockedTechCount - ownUnlockedTechCount >= deficit` (default
/// [kCivilianBuildSpyTechStealDeficit]). Pure and deterministic: a fixed pair of
/// counts always yields the same result. The caller computes the counts from
/// `Player.techUnlocked` (the AI planner derives them via
/// `isPursuingTechStealPosture`).
bool isCivilianBuildSpyTechStealPosture({
  required int ownUnlockedTechCount,
  required int maxRivalUnlockedTechCount,
  int deficit = kCivilianBuildSpyTechStealDeficit,
}) => maxRivalUnlockedTechCount - ownUnlockedTechCount >= deficit;

/// Per-phase, per-type civilian build priority multiplier for [unitType] in the
/// phase identified by [phaseName] (an `ObserverGoalPhase.name`). Spy is always
/// phase-flat ([kCivilianBuildSpyPhaseFlatMultiplier]); for other types a null
/// or unknown [phaseName], or a type the phase does not favor, yields
/// [kCivilianBuildPhaseMultiplierBase].
double civilianBuildPhaseMultiplier(String unitType, String? phaseName) {
  if (unitType == kUnitTypeSpy) return kCivilianBuildSpyPhaseFlatMultiplier;
  if (phaseName == null) return kCivilianBuildPhaseMultiplierBase;
  final byType = kCivilianBuildPhaseMultiplierByPhaseType[phaseName];
  if (byType == null) return kCivilianBuildPhaseMultiplierBase;
  return byType[unitType] ?? kCivilianBuildPhaseMultiplierBase;
}

// ---------------------------------------------------------------------------
// Civilian build planner — smooth phase weighting / hysteresis (Refs #3793
// slice 8, design decision #13). SPEC/ai/civilian-build-planner.md § Scoring
// model — phase multiplier. The discrete per-phase multipliers above hard-
// switch a type from favored (2.0) to base (1.0) at a phase boundary, which can
// oscillate when the dispatched phase flips back and forth across a boundary.
// The smooth variant instead ramps continuously between the active phase's
// discrete multiplier and the next phase's discrete multiplier using a runtime
// `phaseProgress` signal in `[0,1]` (the dispatch's
// `PhasePriorityWeights.newWorldCivilian`, itself a continuous ramp across the
// Old World province count). The ramp is opt-in: callers that pass a `null`
// `phaseProgress` keep the discrete multiplier exactly (byte-identical), so a
// caller can pin the discrete-multiplier path even though the live wiring
// (`kCivilianBuildPlannerEnabled`) is enabled by default.
// ---------------------------------------------------------------------------

/// Canonical "next" civilian-build phase for the smooth phase-multiplier ramp
/// (Refs #3793 slice 8). The civilian phase progression toward which each phase
/// ramps is: EXPAND → COLONIAL, COLONIAL-lite → COLONIAL, COLONIAL → DEVELOP,
/// DEVELOP → DEVELOP (terminal). EXPAND and COLONIAL-lite share the same
/// Builder-favored discrete profile, so both ramp toward COLONIAL (the next
/// distinct-favored phase). An unknown phase name is treated as terminal
/// (returns itself), so its ramp is a no-op and the discrete base applies.
String nextCivilianBuildPhaseName(String phaseName) {
  switch (phaseName) {
    case kCivilianBuildPhaseExpand:
    case kCivilianBuildPhaseColonialLite:
      return kCivilianBuildPhaseColonial;
    case kCivilianBuildPhaseColonial:
      return kCivilianBuildPhaseDevelop;
    case kCivilianBuildPhaseDevelop:
      return kCivilianBuildPhaseDevelop;
    default:
      return phaseName;
  }
}

/// Smooth (hysteresis) per-phase, per-type civilian build multiplier for
/// [unitType] in [phaseName], linearly interpolated toward the
/// [nextCivilianBuildPhaseName] profile by [phaseProgress] (clamped to
/// `[0,1]`; Refs #3793 slice 8, SPEC § Scoring model — phase multiplier).
///
/// Returns `current + (next − current) × clamp(phaseProgress, 0, 1)` where
/// `current = civilianBuildPhaseMultiplier(unitType, phaseName)` and
/// `next = civilianBuildPhaseMultiplier(unitType, nextCivilianBuildPhaseName(
/// phaseName))`. At `phaseProgress == 0.0` the result equals the discrete
/// current-phase multiplier (no ramp); as `phaseProgress` rises toward `1.0`
/// the multiplier blends toward the next phase's favored/base profile, so a
/// type favored only in the next phase grows in and a type favored only in the
/// current phase fades out continuously across the boundary.
///
/// Spy is always phase-flat ([kCivilianBuildSpyPhaseFlatMultiplier]) — the ramp
/// never moves it (current == next == flat). A `null` [phaseName] yields the
/// neutral base for every non-Spy type (no phase context to ramp from).
double civilianBuildPhaseMultiplierSmooth(
  String unitType,
  String? phaseName,
  double phaseProgress,
) {
  if (unitType == kUnitTypeSpy) return kCivilianBuildSpyPhaseFlatMultiplier;
  if (phaseName == null) return kCivilianBuildPhaseMultiplierBase;
  final p = phaseProgress.clamp(0.0, 1.0).toDouble();
  final current = civilianBuildPhaseMultiplier(unitType, phaseName);
  final next = civilianBuildPhaseMultiplier(
    unitType,
    nextCivilianBuildPhaseName(phaseName),
  );
  return current + (next - current) * p;
}

/// Additive civilian build candidate score for [unitType] given [currentCount]
/// owned (SPEC/ai/civilian-build-planner.md § Scoring model). Returns
/// `effectiveBase × minCapBoost × replacementUrgency`, where
/// `effectiveBase = base × phaseMultiplier[type] × demandBoost`:
///
/// - **Phase multiplier:** [civilianBuildPhaseMultiplier] for [phaseName]
///   (Spy is phase-flat). When [phaseName] is `null` the multiplier is the
///   neutral base, so legacy callers are unaffected. When [phaseProgress] is
///   non-null the smooth (hysteresis) ramp
///   [civilianBuildPhaseMultiplierSmooth] is used instead (Refs #3793 slice 8):
///   the multiplier blends continuously toward the next phase's profile by
///   `phaseProgress ∈ [0,1]`. A `null` [phaseProgress] keeps the discrete
///   multiplier exactly (byte-identical to the pre-slice-8 path).
/// - **Spy demand boost:** when [unitType] is Spy and [spyDemand] is `true`
///   (GP at war or pursuing a tech-steal posture), multiply by
///   [kCivilianBuildSpyDemandBoost]; otherwise `1.0`.
/// - **Min cap (hard floor):** when `currentCount < minCount`, multiply by
///   [kCivilianBuildMinCapScoreBoost].
/// - **Replacement urgency (soft pull):** while
///   `minCount <= currentCount < targetCount`, multiply by
///   `1 + kCivilianBuildReplacementUrgencyFactor × (targetCount − currentCount)`.
/// - At or above `targetCount`, the multiplier is `1.0` (effective base only).
///
/// The caller is responsible for excluding candidates at or above `maxCount`
/// via [isCivilianBuildAtOrAboveMaxCount].
double civilianBuildCandidateScore(
  String unitType,
  int currentCount, {
  String? phaseName,
  bool spyDemand = false,
  double? phaseProgress,
}) {
  final phaseMultiplier = phaseProgress == null
      ? civilianBuildPhaseMultiplier(unitType, phaseName)
      : civilianBuildPhaseMultiplierSmooth(unitType, phaseName, phaseProgress);
  final demandBoost = (unitType == kUnitTypeSpy && spyDemand)
      ? kCivilianBuildSpyDemandBoost
      : 1.0;
  final effectiveBase = kCivilianBuildBaseScore * phaseMultiplier * demandBoost;
  final minCount = civilianBuildMinCount(unitType);
  if (currentCount < minCount) {
    return effectiveBase * kCivilianBuildMinCapScoreBoost;
  }
  final targetCount = civilianBuildTargetCount(unitType);
  if (currentCount < targetCount) {
    final deficit = targetCount - currentCount;
    return effectiveBase *
        (1.0 + kCivilianBuildReplacementUrgencyFactor * deficit);
  }
  return effectiveBase;
}

/// Civilian-build pool weight (market-share ceiling), GA-tunable in the
/// inclusive range `[0.0, 1.0]` (SPEC/ai/civilian-build-planner.md § Scoring
/// model — pool weight, design decision #8).
///
/// A single shared scalar applied to every civilian candidate's pooled build
/// score. Because the same scalar dampens all civilian types equally it lowers
/// the civilian share of the weighted `pickBuildOrder` pool relative to the
/// untouched military/naval scores — so civilian over-building cannot starve
/// military/naval production — without changing the relative ordering among
/// civilian candidates. Default `1.0` keeps civilian scores byte-identical to
/// the pre-pool-weight path (no live change; the live civilian build pass is
/// itself gated by `kCivilianBuildPlannerEnabled`).
const double kCivilianBuildPoolWeight = 1.0;

/// Civilian build candidate score after the GA-tunable pool-weight market-share
/// ceiling [poolWeight] (defaults to [kCivilianBuildPoolWeight]).
///
/// Returns `civilianBuildCandidateScore(...) × poolWeight`. The pool weight is
/// a single shared scalar across all civilian types, so it dampens the civilian
/// share of the weighted build pool without reordering civilian candidates
/// relative to one another. `pickBuildOrder` applies this only on the civilian
/// branch, so military/naval scores are never multiplied by the pool weight
/// (SPEC § Scoring model — pool weight; AC10 no-regression at `poolWeight = 1.0`).
double civilianBuildPooledScore(
  String unitType,
  int currentCount, {
  String? phaseName,
  bool spyDemand = false,
  double poolWeight = kCivilianBuildPoolWeight,
  double? phaseProgress,
}) =>
    civilianBuildCandidateScore(
      unitType,
      currentCount,
      phaseName: phaseName,
      spyDemand: spyDemand,
      phaseProgress: phaseProgress,
    ) *
    poolWeight;

// ---------------------------------------------------------------------------
// Civilian build planner — shared paper budget ledger (Refs #3793 AC7,
// design decision #11). SPEC/ai/civilian-build-planner.md § Paper budget.
// Paper is shared across research, worker training, and civilian builds. The
// recruitment planner reserves research paper up to
// [kCivilianBuildResearchPaperReserveShare] of the GP's current paper, then
// allocates the remainder via its phase emit order against a running ledger,
// dropping paper-costing candidates that would push the remaining budget below
// 0. No planner magic numbers (the share + reserve math live here).
// ---------------------------------------------------------------------------

/// Fraction of the Great Power's current paper held back for research before
/// the recruitment planner allocates paper to worker-training and civilian
/// build candidates (Refs #3793 AC7, design decision #11). GA-tunable in the
/// inclusive range `[0.0, 1.0]`. Default `0.5` keeps half of the paper
/// available for the tech tree so a full build/training pass cannot starve
/// civilian-gating research (and conversely cannot be fully consumed by it).
const double kCivilianBuildResearchPaperReserveShare = 0.5;

/// Paper reserved for research given [currentPaper], computed as the
/// deterministic integer floor `currentPaper ×
/// kCivilianBuildResearchPaperReserveShare`, clamped to `[0, currentPaper]`.
///
/// Returns `0` when [currentPaper] is `0` or negative. The reserved amount is
/// subtracted from the paper budget the recruitment planner's ledger allocates
/// to worker-training and civilian-build candidates (Refs #3793 AC7).
int researchReservedPaper(int currentPaper) {
  if (currentPaper <= 0) return 0;
  final reserved = (currentPaper * kCivilianBuildResearchPaperReserveShare)
      .floor();
  if (reserved < 0) return 0;
  if (reserved > currentPaper) return currentPaper;
  return reserved;
}

// ---------------------------------------------------------------------------
// Civilian build planner — research prioritization of civilian-gating techs
// (Refs #3793 AC6). SPEC/ai/civilian-build-planner.md § Tech prioritization.
// The research planner front-loads slot selection toward the techs that unlock
// civilian unit types (Merchant ⇐ `merchant_companies`,
// Rail Builder ⇐ `early_steam_engine`) when the owning GP has not unlocked them,
// so the AI researches toward the gates that expand the civilian build pool.
// The bias only reorders selection within the existing per-turn research slot
// target — it never adds a slot or spends extra funding — so it can never
// exceed the `researchPaperReserveShare` paper reservation. No planner magic
// numbers: the gating-tech set is derived from the canonical
// [unlockingTechByCivilianId] map (single source of truth).
// ---------------------------------------------------------------------------

/// Civilian-gating tech ids the research bias prioritizes: the distinct
/// unlocking-tech values of [unlockingTechByCivilianId], in stable insertion
/// order (deterministic). Currently `merchant_companies` (Merchant) and
/// `early_steam_engine` (Rail Builder).
final List<String> kCivilianGatingTechIds = List<String>.unmodifiable(<String>{
  ...unlockingTechByCivilianId.values,
});

/// True when [techId] gates a civilian unit type (i.e. it is in
/// [kCivilianGatingTechIds]). Used by the research planner to prioritize
/// researching toward civilian-build gates (Refs #3793 AC6).
bool isCivilianGatingTech(String techId) =>
    kCivilianGatingTechIds.contains(techId);
