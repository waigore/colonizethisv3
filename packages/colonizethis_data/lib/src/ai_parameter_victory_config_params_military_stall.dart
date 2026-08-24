/// Victory-config GA params: stalled Old World expansion family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// stalled Old World expansion family.
final List<AiParameter> victoryConfigParamsMilitaryStall = <AiParameter>[
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
    'kStalledConquestArmyMovePasses',
    kStalledConquestArmyMovePasses,
    'Conquest army-move passes per turn while OW holdings are stalled.',
  ),
  victoryConfigIntParam(
    'kStalledConquestFieldArmySplitCap',
    kStalledConquestFieldArmySplitCap,
    'Max field armies from Home Army splits while OW expansion is stalled.',
  ),
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
];
