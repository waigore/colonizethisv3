/// Victory-config GA params: stalled conquest army-move and related offer-peace family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// stalled conquest army-move and related offer-peace family.
final List<AiParameter> victoryConfigParamsColonialConquest = <AiParameter>[
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
