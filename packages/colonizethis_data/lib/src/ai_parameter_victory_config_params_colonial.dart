/// Victory-config GA params: colonial pressure, naval, and conquest weights.
///
/// Sibling topic split of
/// `ai_parameter_victory_config_params_military_stall_colonial.dart`
/// (Refs #4292 wave 5). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// Colonial-pressure, naval, and related victory-config parameters.
final List<AiParameter> victoryConfigParamsColonial = <AiParameter>[
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
