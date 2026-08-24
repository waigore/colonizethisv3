/// Victory-config GA params: declare-war minor, tribe, and stalled-target family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// declare-war minor, tribe, and stalled-target family.
final List<AiParameter> victoryConfigParamsDeclareWarMinor = <AiParameter>[
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
  victoryConfigIntParam(
    'kDeclareWarMinorWithInvadableProvinceBonus',
    kDeclareWarMinorWithInvadableProvinceBonus,
    'Declare-war bonus when target owns an adjacent invadable province.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialNwTribeDominanceBonus',
    kDeclareWarColonialNwTribeDominanceBonus,
    'Extra declare-war weight for tribes owning sea-reachable NW provinces.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialNwTribePriorityOverOwMinorBonus',
    kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
    'Tribe declare-war weight to beat OW minor bonuses under colonial pressure.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledLowWarLikelihoodMinorBonus',
    kDeclareWarStalledLowWarLikelihoodMinorBonus,
    'Declare-war bonus for low-warLikelihood leaders toward stalled minors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledLowWarLikelihoodMinorFloor',
    kDeclareWarStalledLowWarLikelihoodMinorFloor,
    'Declare-war floor for low-warLikelihood leaders toward stalled minors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledLowWarLikelihoodTribeCap',
    kDeclareWarStalledLowWarLikelihoodTribeCap,
    'Cap NW tribe declare-war for low-warLikelihood leaders while OW minors remain.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledAdjacentInvadableMinorFloor',
    kDeclareWarStalledAdjacentInvadableMinorFloor,
    'Declare-war floor toward adjacent invadable minors while stalled.',
  ),
  victoryConfigIntParam(
    'kDeclareWarWeakGpAdjacentInvadableMinorFloor',
    kDeclareWarWeakGpAdjacentInvadableMinorFloor,
    'Higher declare-war floor for critically weak GPs toward OW minors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarCriticalWeakNoGpWarMinorBonus',
    kDeclareWarCriticalWeakNoGpWarMinorBonus,
    'Declare-war bonus toward OW minors when critically weak with no GP war.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledGpWhenMinorsRemainPenalty',
    kDeclareWarStalledGpWhenMinorsRemainPenalty,
    'Declare-war penalty toward adjacent GPs while invadable minors remain.',
  ),
  victoryConfigIntParam(
    'kDeclareWarOnStalledWeakerNeighborPenalty',
    kDeclareWarOnStalledWeakerNeighborPenalty,
    'Declare-war penalty toward a stalled weaker neighbor GP.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAggressorSuppressWeakGpLeadThreshold',
    kDeclareWarAggressorSuppressWeakGpLeadThreshold,
    'OW lead over a weak GP above which declare-war is suppressed.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledTribeWhenOwMinorCap',
    kDeclareWarStalledTribeWhenOwMinorCap,
    'Cap NW tribe declare-war scores while invadable OW minors remain.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialPressureOwMinorPenalty',
    kDeclareWarColonialPressureOwMinorPenalty,
    'Declare-war penalty toward OW minors with no NW provinces under pressure.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledWeakerMinorBonus',
    kDeclareWarStalledWeakerMinorBonus,
    'Declare-war bonus for non-adjacent minors weaker than a stalled GP.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledActiveOwMinorBonus',
    kDeclareWarStalledActiveOwMinorBonus,
    'Declare-war weight toward any OW-holding minor while at start size.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledWeakestInvadableGpBonus',
    kDeclareWarStalledWeakestInvadableGpBonus,
    'Declare-war bonus when the weakest invadable-border GP blocks expansion.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledInvadableGpBlockerBonus',
    kDeclareWarStalledInvadableGpBlockerBonus,
    'Declare-war bonus toward a weaker adjacent GP owning invadable OW land.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledGpInvadableBlockerFloor',
    kDeclareWarStalledGpInvadableBlockerFloor,
    'Declare-war floor toward the GP owning invadable OW frontier.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledGpBlockerDistantMinorBonus',
    kDeclareWarStalledGpBlockerDistantMinorBonus,
    'Declare-war bonus toward a distant minor while OW land is GP-blocked.',
  ),
  victoryConfigIntParam(
    'kDeclareWarDefaultStartOwMinorBonus',
    kDeclareWarDefaultStartOwMinorBonus,
    'Declare-war bonus on any OW minor while at default observer start size.',
  ),
  victoryConfigIntParam(
    'kDeclareWarStalledAnyOwMinorBonus',
    kDeclareWarStalledAnyOwMinorBonus,
    'Declare-war bonus toward any OW-holding minor while stalled.',
  ),
];
