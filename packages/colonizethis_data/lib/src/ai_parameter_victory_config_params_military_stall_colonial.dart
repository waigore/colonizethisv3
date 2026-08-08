/// Victory-config GA params: stall, quota, peace, colonial pressure.
///
/// Topic split of `ai_parameter_victory_config_params.dart` (Refs #4072).
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// Stall / quota / offer-peace / colonial-pressure victory-config parameters.
final List<AiParameter>
victoryConfigParamsMilitaryStallColonial = <AiParameter>[
  victoryConfigIntParam(
    'kStalledMinRegimentCountWhenAtWar',
    kStalledMinRegimentCountWhenAtWar,
    'Regiment floor while stalled and at war.',
  ),
  victoryConfigIntParam(
    'kStalledMinRegimentCountWhenGpBlockerAtWar',
    kStalledMinRegimentCountWhenGpBlockerAtWar,
    'Higher regiment floor when fighting the sole frontier-blocker GP.',
  ),
  victoryConfigIntParam(
    'kStalledMinRegimentCountWhenCriticallyWeakNoGpWar',
    kStalledMinRegimentCountWhenCriticallyWeakNoGpWar,
    'Regiment floor when critically weak with minor wars only.',
  ),
  victoryConfigIntParam(
    'kStalledMilitaryRebuildCrisisRegimentCap',
    kStalledMilitaryRebuildCrisisRegimentCap,
    'Regiment count cap below which stalled rebuilds are prioritized.',
  ),
  victoryConfigIntParam(
    'kStalledMinRegimentCountPerProvinceDeficitVsBlocker',
    kStalledMinRegimentCountPerProvinceDeficitVsBlocker,
    'Extra regiment floor per OW province the frontier blocker leads by.',
  ),
  victoryConfigIntParam(
    'kBelowQuotaPeaceMinRegimentsBeforeDeclareWar',
    kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
    'Regiment floor below which a below-quota peaceful GP rebuilds first.',
  ),
  victoryConfigIntParam(
    'kBelowQuotaPeaceTreasuryRecoveryCargoBoost',
    kBelowQuotaPeaceTreasuryRecoveryCargoBoost,
    'Cargo economy boost when a below-quota GP cannot afford a regiment.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceFutileMinorWarBonus',
    kOfferPeaceFutileMinorWarBonus,
    'Offer-peace bonus toward a minor/tribe with no invadable land left.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceBelowQuotaActiveMinorWarPenalty',
    kOfferPeaceBelowQuotaActiveMinorWarPenalty,
    'Penalty for offering peace to a minor still holding invadable OW land.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceStalledStrongerGpBlockerBonus',
    kOfferPeaceStalledStrongerGpBlockerBonus,
    'Offer-peace bonus toward a stronger adjacent GP blocking the frontier.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceStalledFutileGpWarBonus',
    kOfferPeaceStalledFutileGpWarBonus,
    'Offer-peace bonus toward a GP owning none of this GP\'s invadable land.',
  ),
  victoryConfigIntParam(
    'kObserverConquestMinOwProvincesPerGp',
    kObserverConquestMinOwProvincesPerGp,
    'Observer per-GP turn-100 conquest quota in OW provinces.',
  ),
  victoryConfigIntParam(
    'kObserverColonialLiteMinTurn',
    kObserverColonialLiteMinTurn,
    'Turn when near-quota EXPAND GPs may enter COLONIAL-lite.',
  ),
  victoryConfigIntParam(
    'kObserverColonialLiteNearQuotaOw',
    kObserverColonialLiteNearQuotaOw,
    'OW holdings at or above which COLONIAL-lite is enabled while below quota.',
  ),
  victoryConfigIntParam(
    'kDevelopCivilianWorkThresholdCap',
    kDevelopCivilianWorkThresholdCap,
    'Civilian work threshold cap in the DEVELOP phase.',
  ),
  victoryConfigIntParam(
    'kConsolidateGainsSoleGpProvinceLead',
    kConsolidateGainsSoleGpProvinceLead,
    'OW province lead over sole GP enemy to consolidate gains via peace.',
  ),
  victoryConfigIntParam(
    'kObserverConquestConsolidateMinOwProvinces',
    kObserverConquestConsolidateMinOwProvinces,
    'Minimum OW holdings before consolidate-gains sole-GP peace may fire.',
  ),
  victoryConfigIntParam(
    'kUnwinnableSoleGpMinProvinceDeficit',
    kUnwinnableSoleGpMinProvinceDeficit,
    'OW province deficit for the unwinnable sole-GP frontier peace.',
  ),
  victoryConfigIntParam(
    'kDeclareWarBelowObserverQuotaMinorBonus',
    kDeclareWarBelowObserverQuotaMinorBonus,
    'Declare-war bonus on adjacent invadable OW minors while below quota.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceStalledZeroRegimentGpWarBonus',
    kOfferPeaceStalledZeroRegimentGpWarBonus,
    'Offer-peace bonus toward any at-war GP when stalled with zero regiments.',
  ),
  victoryConfigIntParam(
    'kMutualExhaustedGpStalemateMinOw',
    kMutualExhaustedGpStalemateMinOw,
    'OW floor for the mutual-exhausted GP stalemate peace check.',
  ),
  victoryConfigIntParam(
    'kMutualExhaustedGpRegimentMax',
    kMutualExhaustedGpRegimentMax,
    'Regiment ceiling under which a GP is treated as militarily exhausted.',
  ),
  victoryConfigIntParam(
    'kMutualExhaustedGpTreasuryMax',
    kMutualExhaustedGpTreasuryMax,
    'Treasury ceiling under which a GP is treated as economically exhausted.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceMutualExhaustedGpStalemateBonus',
    kOfferPeaceMutualExhaustedGpStalemateBonus,
    'Offer-peace bonus for a mutually-exhausted sole-GP stalemate.',
  ),
  victoryConfigIntParam(
    'kStalledMinRegimentCountWhenCriticallyWeakBelowQuota',
    kStalledMinRegimentCountWhenCriticallyWeakBelowQuota,
    'Regiment floor when critically weak, below quota, and at war.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceUnwinnableSoleGpWarBonus',
    kOfferPeaceUnwinnableSoleGpWarBonus,
    'Offer-peace bonus for the unwinnable sole-GP frontier peace target.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceConsolidateGainsSoleGpWarBonus',
    kOfferPeaceConsolidateGainsSoleGpWarBonus,
    'Offer-peace bonus for the consolidate-gains sole-GP peace target.',
  ),
  victoryConfigIntParam(
    'kDefendBonusWhenFewOldWorldProvinces',
    kDefendBonusWhenFewOldWorldProvinces,
    'Defend goal bonus while OW holdings are small and far from victory.',
  ),
  victoryConfigIntParam(
    'kDefendBonusWhenAtWarAndFewHoldings',
    kDefendBonusWhenAtWarAndFewHoldings,
    'Extra defend weight when at war and OW holdings are few.',
  ),
  victoryConfigIntParam(
    'kFewOldWorldProvincesDefendThreshold',
    kFewOldWorldProvincesDefendThreshold,
    'OW province count at or below which the few-holdings defend bonus applies.',
  ),
  victoryConfigIntParam(
    'kColonialExpandBonusWhenInvadableNw',
    kColonialExpandBonusWhenInvadableNw,
    'Expand-goal bonus when invadable New World provinces exist.',
  ),
  victoryConfigIntParam(
    'kColonialConquerBonusWhenInvadableNw',
    kColonialConquerBonusWhenInvadableNw,
    'Conquer-goal bonus for colonial pressure below OW victory floors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialAdjacentTribeBonus',
    kDeclareWarColonialAdjacentTribeBonus,
    'Declare-war bonus toward a tribe/minor owning adjacent NW provinces.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureColonialTribeBonus',
    kEstablishOvertureColonialTribeBonus,
    'Establish-overture bonus toward a preferred colonial tribe target.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureColonialInvadableOwnerBonus',
    kEstablishOvertureColonialInvadableOwnerBonus,
    'Establish-overture bonus toward a sea-reachable NW province owner.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureDecayCreditMax',
    kEstablishOvertureDecayCreditMax,
    'Max improve-relations reduction credited to natural relation decay.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureFtpCompetitionBonus',
    kEstablishOvertureFtpCompetitionBonus,
    'Overture incentive when not the favoured trading partner for a '
        'Minor/Tribe target.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureEmbassyKickbackBonusMax',
    kEstablishOvertureEmbassyKickbackBonusMax,
    'Max improve-relations desire bonus from embassy commodity kickbacks.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureEmbassyKickbackVolumeFull',
    kEstablishOvertureEmbassyKickbackVolumeFull,
    'Seller resource-tile count at which embassy kickback bonus saturates.',
  ),
  victoryConfigIntParam(
    'kConquestArmyMoveNwInvadableBonus',
    kConquestArmyMoveNwInvadableBonus,
    'Conquest army-move bonus for New World invadable destinations.',
  ),
  victoryConfigIntParam(
    'kColonialCargoPreferenceEconomyBoost',
    kColonialCargoPreferenceEconomyBoost,
    'Economy-domain cargo-preference boost when colonial targets exist.',
  ),
  victoryConfigIntParam(
    'kColonialCargoPreferenceNoNwColoniesBoost',
    kColonialCargoPreferenceNoNwColoniesBoost,
    'Extra cargo boost when the GP owns no New World provinces yet.',
  ),
  victoryConfigIntParam(
    'kColonialNavalWeightBonus',
    kColonialNavalWeightBonus,
    'Naval planner weight boost when NW invasion/colonization is viable.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMinWeightWhenPressure',
    kColonialNavalMinWeightWhenPressure,
    'Minimum naval planner weight under active colonial pressure.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMoveDockNewWorldPortScore',
    kColonialNavalMoveDockNewWorldPortScore,
    'Naval move score when docking at a New World port under pressure.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMovePriorityNwSeaZoneScore',
    kColonialNavalMovePriorityNwSeaZoneScore,
    'Naval move score for an NW sea zone bordering an invadable province.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMovePhasePriorityNwSeaZoneScore',
    kColonialNavalMovePhasePriorityNwSeaZoneScore,
    'Naval move score for an NW sea zone bordering a phase-priority province.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMoveNwSeaZoneScore',
    kColonialNavalMoveNwSeaZoneScore,
    'Naval move score for any other New World sea zone destination.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMoveGatewaySeaZoneScore',
    kColonialNavalMoveGatewaySeaZoneScore,
    'Naval move score for an OW sea zone linked to NW seas.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialInvadableOwnerBonus',
    kDeclareWarColonialInvadableOwnerBonus,
    'Declare-war bonus when target owns a sea-reachable invadable NW province.',
  ),
  victoryConfigIntParam(
    'kColonialFewNwProvincesThreshold',
    kColonialFewNwProvincesThreshold,
    'NW holdings below which colonial goal bonuses apply.',
  ),
  victoryConfigIntParam(
    'kColonialConquerBonusWhenFewNwProvinces',
    kColonialConquerBonusWhenFewNwProvinces,
    'Extra conquer weight while below the few-NW-provinces threshold.',
  ),
  victoryConfigIntParam(
    'kColonialDiplomacyGoalPenaltyWhenPressure',
    kColonialDiplomacyGoalPenaltyWhenPressure,
    'Diplomacy goal penalty while sea-reachable NW targets exist.',
  ),
  victoryConfigIntParam(
    'kColonialTradeGoalPenaltyWhenPressure',
    kColonialTradeGoalPenaltyWhenPressure,
    'Trade goal penalty under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kEmergencyTradeGoalDominantFloor',
    kEmergencyTradeGoalDominantFloor,
    'Trade goal floor when the GP treasury is broke.',
  ),
  victoryConfigIntParam(
    'kTreasuryAcquisitionTradeBoostMax',
    kTreasuryAcquisitionTradeBoostMax,
    'Peak trade goal boost when treasury is below a regiment build cost.',
  ),
  victoryConfigIntParam(
    'kMinimumColonialExpandScoreWhenPressure',
    kMinimumColonialExpandScoreWhenPressure,
    'Expand floor under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kMinimumColonialConquerScoreWhenPressure',
    kMinimumColonialConquerScoreWhenPressure,
    'Conquer floor under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kDiplomacyDeclareWarMinWeightWhenColonialPressure',
    kDiplomacyDeclareWarMinWeightWhenColonialPressure,
    'Minimum declare-war diplomacy pass weight under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kConquestArmyMoveMinWeightWhenColonialPressure',
    kConquestArmyMoveMinWeightWhenColonialPressure,
    'Minimum conquest army-move pass weight under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kExploreWorkScoreBonusNewWorld',
    kExploreWorkScoreBonusNewWorld,
    'Explore-work score bonus when the target tile is in the New World.',
  ),
  victoryConfigIntParam(
    'kColonialCivilianWorkThresholdCap',
    kColonialCivilianWorkThresholdCap,
    'Civilian work economy threshold cap when colonial targets are visible.',
  ),
  victoryConfigIntParam(
    'kColonialBuildOrderThresholdWhenOwnedNwUnderPressure',
    kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
    'Build-order economy threshold cap under COLONIAL acquisition pressure.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMissionNwPortScore',
    kColonialNavalMissionNwPortScore,
    'Naval mission score when the target port is a New World port.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMissionPhasePriorityNwPortScore',
    kColonialNavalMissionPhasePriorityNwPortScore,
    'Naval mission score for a phase-priority New World port.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMissionNwProvinceScore',
    kColonialNavalMissionNwProvinceScore,
    'Naval mission score when the target province is in the New World.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMissionPhasePriorityNwProvinceScore',
    kColonialNavalMissionPhasePriorityNwProvinceScore,
    'Naval mission score for a phase-priority New World province.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMissionBeachheadScore',
    kColonialNavalMissionBeachheadScore,
    'Naval mission score for beachhead missions under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceWeakVsInvadableBlockerBonus',
    kOfferPeaceWeakVsInvadableBlockerBonus,
    'Offer-peace bonus toward an invadable frontier GP while critically low.',
  ),
  victoryConfigIntParam(
    'kConquestArmyMoveMinWeightWhenStalled',
    kConquestArmyMoveMinWeightWhenStalled,
    'Minimum conquest army-move pass weight when OW expansion is stalled.',
  ),
  victoryConfigIntParam(
    'kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar',
    kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar,
    'Army-move weight floor when critically weak with no GP war.',
  ),
  victoryConfigDoubleParam(
    'kConquestArmyMoveStalledDeclaredTargetInvadableBonus',
    kConquestArmyMoveStalledDeclaredTargetInvadableBonus,
    'Army-move bonus for invadable provinces of the declared target when stalled.',
  ),
  victoryConfigDoubleParam(
    'kConquestArmyMoveStalledDeclaredTargetBonus',
    kConquestArmyMoveStalledDeclaredTargetBonus,
    'Army-move bonus for any province of the declared target when stalled.',
  ),
  victoryConfigDoubleParam(
    'kConquestArmyMoveAdjacentInvadableBonus',
    kConquestArmyMoveAdjacentInvadableBonus,
    'Army-move bonus when destination is adjacent to an invadable OW province.',
  ),
  victoryConfigDoubleParam(
    'kConquestArmyMoveStalledGpInvadableBlockerBonus',
    kConquestArmyMoveStalledGpInvadableBlockerBonus,
    'Army-move bonus for invadable provinces of an at-war blocker GP.',
  ),
  victoryConfigDoubleParam(
    'kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince',
    kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince,
    'Extra army-move bonus per OW province the invadable blocker GP leads by.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceBelowQuotaInvadableBlockerPenalty',
    kOfferPeaceBelowQuotaInvadableBlockerPenalty,
    'Offer-peace penalty toward the frontier blocker GP while below quota.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceBelowQuotaStartSizeGpWarPenalty',
    kOfferPeaceBelowQuotaStartSizeGpWarPenalty,
    'Offer-peace penalty toward any GP while at start size and below quota.',
  ),
  victoryConfigDoubleParam(
    'kConquestArmyMoveAdjacentAtWarFrontierBonus',
    kConquestArmyMoveAdjacentAtWarFrontierBonus,
    'Army-move bonus for own provinces bordering an at-war faction.',
  ),
];
