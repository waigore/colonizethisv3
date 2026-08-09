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
  victoryConfigIntParam(
    'kEngineerFrontierRoadExtensionBonus',
    kEngineerFrontierRoadExtensionBonus,
    'Extra Engineer build_road score for frontier network extension.',
  ),
  victoryConfigIntParam(
    'kBuildImprovementConnectedBonus',
    kBuildImprovementConnectedBonus,
    'Extra build_improvement score on capital-connected tiles.',
  ),
  victoryConfigIntParam(
    'kBuildImprovementAdjacentToConnectedBonus',
    kBuildImprovementAdjacentToConnectedBonus,
    'Extra build_improvement score on tiles adjacent to the connected set.',
  ),
  victoryConfigIntParam(
    'kBuildRailBottleneckYieldBonus',
    kBuildRailBottleneckYieldBonus,
    'Extra build_rail score on connected bottleneck path tiles.',
  ),
  victoryConfigIntParam(
    'kEngineerPortOverseasLinkageBonus',
    kEngineerPortOverseasLinkageBonus,
    'Extra build_port score for overseas dev-target linkage.',
  ),
];
