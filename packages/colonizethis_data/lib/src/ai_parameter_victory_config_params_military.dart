/// Victory-config GA params: military pace.
///
/// Topic split of `ai_parameter_victory_config_params.dart` (Refs #4072, #4412).
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// Military-pace victory-config parameters (declare-war / stall live in siblings).
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
    'kTradeGoalPenaltyCapWhenFarFromVictory',
    kTradeGoalPenaltyCapWhenFarFromVictory,
    'Cap on trade goal penalty when far from victory.',
  ),
  victoryConfigIntParam(
    'kObserverDefaultStartOldWorldProvincesPerGp',
    kObserverDefaultStartOldWorldProvincesPerGp,
    'Observer default start Old World provinces per GP.',
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
];
