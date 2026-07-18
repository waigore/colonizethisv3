/// Victory-config GA params: military pace and declare-war.
///
/// Topic split of `ai_parameter_victory_config_params.dart` (Refs #4072).
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// Military pace / declare-war victory-config parameters.
final List<AiParameter> victoryConfigParamsMilitary = <AiParameter>[
  victoryConfigIntParam(
    'kMilitaryVictoryOldWorldProvinceThreshold',
    kMilitaryVictoryOldWorldProvinceThreshold,
    'Old World province count required for military victory.',
  ),
  victoryConfigIntParam(
    'kExpandBonusWhenInvadableProvinces',
    kExpandBonusWhenInvadableProvinces,
    'Expand-goal bonus when invadable Old World targets exist.',
  ),
  victoryConfigIntParam(
    'kConquerScoreFloorProvincesToVictoryThreshold',
    kConquerScoreFloorProvincesToVictoryThreshold,
    'Provinces-to-victory threshold above which conquer score is floored.',
  ),
  victoryConfigIntParam(
    'kMinimumConquerScoreWhenFarFromVictory',
    kMinimumConquerScoreWhenFarFromVictory,
    'Minimum conquer goal score when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarMinorMaxRelationWhenFarFromVictory',
    kDeclareWarMinorMaxRelationWhenFarFromVictory,
    'Declare-war relation cap for minor/tribe targets when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarGpWeakNeighborBonus',
    kDeclareWarGpWeakNeighborBonus,
    'Declare-war bonus toward a weak-neighbor Great Power.',
  ),
  victoryConfigIntParam(
    'kDeclareWarGpWeakNeighborMinWarDesire',
    kDeclareWarGpWeakNeighborMinWarDesire,
    'Minimum war-desire for the weak-neighbor GP declare-war bonus.',
  ),
  victoryConfigDoubleParam(
    'kBuildRegimentBonusWhenBehindVictoryPace',
    kBuildRegimentBonusWhenBehindVictoryPace,
    'Extra build weight for regiments when behind military victory pace.',
  ),
  victoryConfigIntParam(
    'kBuildRegimentVictoryPaceThreshold',
    kBuildRegimentVictoryPaceThreshold,
    'Provinces-to-victory threshold for the behind-pace regiment bonus.',
  ),
  victoryConfigIntParam(
    'kDeclareWarGpMaxRelationWhenFarFromVictory',
    kDeclareWarGpMaxRelationWhenFarFromVictory,
    'Declare-war relation cap for adjacent GP targets when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAdjacentOwnerBonus',
    kDeclareWarAdjacentOwnerBonus,
    'Declare-war bonus toward an adjacent Old World province owner.',
  ),
  victoryConfigIntParam(
    'kDeclareWarLowWarLikelihoodAdjacentBonus',
    kDeclareWarLowWarLikelihoodAdjacentBonus,
    'Extra declare-war bonus for low-warLikelihood personalities.',
  ),
  victoryConfigIntParam(
    'kDeclareWarLowWarLikelihoodThreshold',
    kDeclareWarLowWarLikelihoodThreshold,
    'warLikelihood at or below which the low-warLikelihood bonus applies.',
  ),
  victoryConfigIntParam(
    'kTradeGoalPenaltyCapWhenFarFromVictory',
    kTradeGoalPenaltyCapWhenFarFromVictory,
    'Cap on trade goal penalty when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarNonAdjacentSuppressedScore',
    kDeclareWarNonAdjacentSuppressedScore,
    'Declare-war score for suppressed non-adjacent targets.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAdjacentGpBonusWhenFarFromVictory',
    kDeclareWarAdjacentGpBonusWhenFarFromVictory,
    'Declare-war bonus toward an adjacent GP when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAdjacentMinorBonusWhenFarFromVictory',
    kDeclareWarAdjacentMinorBonusWhenFarFromVictory,
    'Declare-war bonus toward an adjacent minor/tribe when far from victory.',
  ),
  victoryConfigIntParam(
    'kSuppressGpDeclareWarMinProvincesToVictory',
    kSuppressGpDeclareWarMinProvincesToVictory,
    'Provinces-to-victory above which GP declare-war is suppressed.',
  ),
  victoryConfigIntParam(
    'kObserverDefaultStartOldWorldProvincesPerGp',
    kObserverDefaultStartOldWorldProvincesPerGp,
    'Observer default start Old World provinces per GP.',
  ),
  victoryConfigIntParam(
    'kStalledOldWorldProvinceThreshold',
    kStalledOldWorldProvinceThreshold,
    'OW holdings at or below this count are treated as stalled expansion.',
  ),
  victoryConfigIntParam(
    'kStalledDiplomacyGoalPenalty',
    kStalledDiplomacyGoalPenalty,
    'Diplomacy goal penalty while OW expansion is stalled.',
  ),
  victoryConfigIntParam(
    'kStalledTradeGoalPenalty',
    kStalledTradeGoalPenalty,
    'Trade goal penalty while OW expansion is stalled.',
  ),
  victoryConfigIntParam(
    'kStalledConquerGoalBonus',
    kStalledConquerGoalBonus,
    'Extra conquer goal weight while OW expansion is stalled.',
  ),
  victoryConfigIntParam(
    'kWeakGpRecoveryConquerBonus',
    kWeakGpRecoveryConquerBonus,
    'Extra conquer weight while critically weak with invadable OW minors.',
  ),
  victoryConfigIntParam(
    'kWeakGpRecoveryDefendPenalty',
    kWeakGpRecoveryDefendPenalty,
    'Reduced defend weight while critically weak with invadable OW minors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledExpansionMinorBonus',
    kDeclareWarStalledExpansionMinorBonus,
    'Extra declare-war weight toward adjacent minors when stalled.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledOwMinorPriorityBonus',
    kDeclareWarStalledOwMinorPriorityBonus,
    'Priority declare-war weight toward OW minors over distant tribes.',
  ),
  victoryConfigIntParam(
    'kDeclareWarWeakGpOwMinorRecoveryBonus',
    kDeclareWarWeakGpOwMinorRecoveryBonus,
    'Extra declare-war weight toward OW minors while critically low.',
  ),
  victoryConfigIntParam(
    'kDeclareWarBelowQuotaOwMinorRecoveryBonus',
    kDeclareWarBelowQuotaOwMinorRecoveryBonus,
    'Extra declare-war weight toward OW minors while below observer quota.',
  ),
  victoryConfigIntParam(
    'kDeclareWarPlateauOwMinorBonus',
    kDeclareWarPlateauOwMinorBonus,
    'Extra declare-war toward invadable OW minors at the 8-9 OW plateau.',
  ),
  victoryConfigIntParam(
    'kDeclareWarNearObserverQuotaMinorBonus',
    kDeclareWarNearObserverQuotaMinorBonus,
    'Extra declare-war toward invadable minors near the observer quota.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledExpansionTribePenalty',
    kDeclareWarStalledExpansionTribePenalty,
    'Penalize tribe declare-war while stalled and OW minors remain.',
  ),
  victoryConfigIntParam(
    'kDeclareWarEarlyExpansionMinorBonus',
    kDeclareWarEarlyExpansionMinorBonus,
    'Extra declare-war weight on adjacent OW minors in the early window.',
  ),
  victoryConfigIntParam(
    'kDeclareWarEarlyExpansionTribePenalty',
    kDeclareWarEarlyExpansionTribePenalty,
    'Penalize tribe declare-war in the early window while OW minors remain.',
  ),
  victoryConfigIntParam(
    'kDeclareWarEarlyExpansionMaxTurn',
    kDeclareWarEarlyExpansionMaxTurn,
    'Last turn for the early-expansion minor bonus.',
  ),
  victoryConfigIntParam(
    'kDeclareWarEarlyAntiDogpileMaxTurn',
    kDeclareWarEarlyAntiDogpileMaxTurn,
    'Last turn quota-meeting GPs avoid opening wars on weaker neighbors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarSatedExpansionMinorPenalty',
    kDeclareWarSatedExpansionMinorPenalty,
    'Penalty on adjacent minor declare-war when holding many OW provinces.',
  ),
  victoryConfigIntParam(
    'kDeclareWarSatedExpansionMinorThreshold',
    kDeclareWarSatedExpansionMinorThreshold,
    'OW holdings at or above which the sated-expansion penalty triggers.',
  ),
  victoryConfigIntParam(
    'kDiplomacyDeclareWarMinWeightWhenStalled',
    kDiplomacyDeclareWarMinWeightWhenStalled,
    'Minimum diplomacy declare-war pass weight when stalled.',
  ),
  victoryConfigDoubleParam(
    'kBuildRegimentBonusWhenStalledExpansion',
    kBuildRegimentBonusWhenStalledExpansion,
    'Extra regiment build weight when OW holdings are stalled.',
  ),
  victoryConfigDoubleParam(
    'kBuildRegimentBonusWhenZeroRegimentsAtWar',
    kBuildRegimentBonusWhenZeroRegimentsAtWar,
    'Extra regiment build weight when at war with zero regiments.',
  ),
  victoryConfigIntParam(
    'kDeclareWarMinorWithInvadableProvinceBonus',
    kDeclareWarMinorWithInvadableProvinceBonus,
    'Declare-war bonus when target owns an adjacent invadable province.',
  ),
  victoryConfigIntParam(
    'kStalledConquestArmyMovePasses',
    kStalledConquestArmyMovePasses,
    'Conquest army-move passes per turn while OW holdings are stalled.',
  ),
  victoryConfigIntParam(
    'kStalledConquestFieldArmySplitCap',
    kStalledConquestFieldArmySplitCap,
    'Max field armies from Home Army splits while OW expansion is stalled.',
  ),
];
