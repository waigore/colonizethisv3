/// Victory-config GA params: colonial pressure, floors, and NW civilian family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// colonial pressure, floors, and NW civilian family.
final List<AiParameter> victoryConfigParamsColonialPressure = <AiParameter>[
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
];
