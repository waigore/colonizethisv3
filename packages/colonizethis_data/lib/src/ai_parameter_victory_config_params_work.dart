/// Victory-config GA params: civilian work scores, feedstock, Spy counter-spy.
///
/// Topic split of `ai_parameter_victory_config_params.dart` (Refs #4072).
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// Work-order / feedstock / Spy-counter victory-config parameters.
final List<AiParameter> victoryConfigParamsWork = <AiParameter>[
  victoryConfigIntParam(
    'kBuildImprovementExtractableResourceScore',
    kBuildImprovementExtractableResourceScore,
    'Build-improvement score for an unimproved extractable resource tile.',
  ),
  victoryConfigIntParam(
    'kBuildImprovementNewWorldResourceBonus',
    kBuildImprovementNewWorldResourceBonus,
    'Extra build-improvement score on unimproved NW extractable tiles.',
  ),
  victoryConfigIntParam(
    'kBuildImprovementOwnedNewWorldResourceBonus',
    kBuildImprovementOwnedNewWorldResourceBonus,
    'Extra build-improvement score on owned NW extractable tiles.',
  ),
  victoryConfigIntParam(
    'kPurchaseLandNewWorldTribeWorkScore',
    kPurchaseLandNewWorldTribeWorkScore,
    'Merchant purchase_land score for NW tribe/minor tiles.',
  ),
  victoryConfigIntParam(
    'kPurchaseLandNewWorldOtherWorkScore',
    kPurchaseLandNewWorldOtherWorkScore,
    'Merchant purchase_land score for other NW tiles.',
  ),
  victoryConfigIntParam(
    'kBuildRailBaseWorkScore',
    kBuildRailBaseWorkScore,
    'Baseline Rail Builder build_rail work score for any valid candidate.',
  ),
  victoryConfigIntParam(
    'kBuildRailResourceOutputBonus',
    kBuildRailResourceOutputBonus,
    'Extra Rail Builder build_rail score when the road tile carries a resource.',
  ),
  victoryConfigIntParam(
    'kBuildRailCapitalConnectorBonus',
    kBuildRailCapitalConnectorBonus,
    'Extra Rail Builder build_rail score when the road tile is in the capital province.',
  ),
  victoryConfigIntParam(
    'kBuildRailNewWorldBonus',
    kBuildRailNewWorldBonus,
    'Extra Rail Builder build_rail score when the road tile is in the New World.',
  ),
  victoryConfigIntParam(
    'kEngineerBuildRoadBaseWorkScore',
    kEngineerBuildRoadBaseWorkScore,
    'Baseline Engineer build_road work score for any valid candidate.',
  ),
  victoryConfigIntParam(
    'kEngineerBuildPortBaseWorkScore',
    kEngineerBuildPortBaseWorkScore,
    'Baseline Engineer build_port work score for any valid candidate.',
  ),
  victoryConfigIntParam(
    'kEngineerBuildFortBaseWorkScore',
    kEngineerBuildFortBaseWorkScore,
    'Baseline Engineer build_fort work score for any valid candidate.',
  ),
  victoryConfigIntParam(
    'kEngineerRoadResourceConnectivityBonus',
    kEngineerRoadResourceConnectivityBonus,
    'Extra Engineer build_road score when the tile carries a resource.',
  ),
  victoryConfigIntParam(
    'kEngineerRoadCapitalLogisticsBonus',
    kEngineerRoadCapitalLogisticsBonus,
    'Extra Engineer build_road score when the tile is in the capital province.',
  ),
  victoryConfigIntParam(
    'kEngineerPortResourceExtractionBonus',
    kEngineerPortResourceExtractionBonus,
    'Extra Engineer build_port score when the tile carries a resource.',
  ),
  victoryConfigIntParam(
    'kEngineerPortNewWorldCoastalBonus',
    kEngineerPortNewWorldCoastalBonus,
    'Extra Engineer build_port score when the tile is in the New World.',
  ),
  victoryConfigIntParam(
    'kEngineerFortCapitalDefenseBonus',
    kEngineerFortCapitalDefenseBonus,
    'Extra Engineer build_fort score when the tile is in the capital province.',
  ),
  victoryConfigIntParam(
    'kEngineerFortNewWorldBorderBonus',
    kEngineerFortNewWorldBorderBonus,
    'Extra Engineer build_fort score when the tile is in the New World.',
  ),
  victoryConfigIntParam(
    'kUpgradeTownBaseWorkScore',
    kUpgradeTownBaseWorkScore,
    'Baseline Builder upgrade_town work score for any valid candidate.',
  ),
  victoryConfigIntParam(
    'kUpgradeTownResourceValueBonus',
    kUpgradeTownResourceValueBonus,
    'Extra Builder upgrade_town score when the town tile carries a resource.',
  ),
  victoryConfigIntParam(
    'kUpgradeTownFrontlineBonus',
    kUpgradeTownFrontlineBonus,
    'Extra Builder upgrade_town score when the town tile is in the New World.',
  ),
  victoryConfigIntParam(
    'kUpgradeTownLowDevBonus',
    kUpgradeTownLowDevBonus,
    'Extra Builder upgrade_town score when the town tile is undeveloped (level 0).',
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
    'kOfferPeaceWeakVsInvadableBlockerBonus',
    kOfferPeaceWeakVsInvadableBlockerBonus,
    'Offer-peace bonus toward an invadable frontier GP while critically low.',
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
  victoryConfigIntParam(
    'kRegimentBuildInputFeedstockExtractionScoreBoost',
    kRegimentBuildInputFeedstockExtractionScoreBoost,
    'Civilian-work score boost on an unimproved feedstock tile under the '
        'feedstock-extraction gate.',
  ),
  victoryConfigIntParam(
    'kGrowthStageFabricFeedstockScoreBoost',
    kGrowthStageFabricFeedstockScoreBoost,
    'Civilian-work score boost on an unimproved fabric feedstock tile under '
        'the growth-stage planner.',
  ),
  victoryConfigIntParam(
    'kGrowthStageInfraFeedstockScoreBoost',
    kGrowthStageInfraFeedstockScoreBoost,
    'Civilian-work score boost on an unimproved infrastructure feedstock tile '
        'under the growth-stage planner.',
  ),
  victoryConfigIntParam(
    'kFeedstockMineralProspectScoreBoost',
    kFeedstockMineralProspectScoreBoost,
    'Civilian-work prospect score boost on an unprospected mineral feedstock '
        'tile under the feedstock-extraction gate.',
  ),
  victoryConfigIntParam(
    'kSpyCounterSpyBaseWorkScore',
    kSpyCounterSpyBaseWorkScore,
    'Baseline Spy counter_spy work score for any valid candidate.',
  ),
  victoryConfigIntParam(
    'kSpyCounterSpyEnemySpyPresenceBonus',
    kSpyCounterSpyEnemySpyPresenceBonus,
    'Extra Spy counter_spy score when a foreign-owned Spy occupies the province.',
  ),
  victoryConfigIntParam(
    'kSpyCounterSpyCapitalBonus',
    kSpyCounterSpyCapitalBonus,
    'Extra Spy counter_spy score in the player\'s capital province.',
  ),
  victoryConfigIntParam(
    'kSpyCounterSpyBorderBonus',
    kSpyCounterSpyBorderBonus,
    'Extra Spy counter_spy score in a New World region province.',
  ),
  victoryConfigIntParam(
    'kSpyPhaseCounterSpyBonus',
    kSpyPhaseCounterSpyBonus,
    'Phase bonus added to Spy counter_spy scores in the DEVELOP phase.',
  ),
];
