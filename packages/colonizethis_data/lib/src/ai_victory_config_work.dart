/// Full AI civilian work scoring constants.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

/// Full AI build-improvement score for an unimproved extractable resource tile.
const int kBuildImprovementExtractableResourceScore = 580;

/// Extra build-improvement score on unimproved extractable tiles in the NW region.
const int kBuildImprovementNewWorldResourceBonus = 120;

/// Additional build-improvement score when the tile is in a GP-owned NW province
/// (observer turn-150 improvement gate; Refs #2509).
const int kBuildImprovementOwnedNewWorldResourceBonus = 120;

/// Merchant purchase_land score for NW tribe/minor tiles (colonial acquisition).
const int kPurchaseLandNewWorldTribeWorkScore = 320;

/// Merchant purchase_land score for other NW tiles.
const int kPurchaseLandNewWorldOtherWorkScore = 160;

/// Full AI civilian-work score boost applied to an unimproved feedstock resource
/// tile when the regiment/supplier/seller feedstock-extraction gate is active
/// (`selectFullAiCivilianWorkOrders`). Sized above
/// [kBuildImprovementExtractableResourceScore] plus the New World resource
/// bonuses so a lock-recovery seller routes its Builder onto the feedstock tile
/// ahead of any other extractable improvement. GA-tunable (Refs #3794);
/// behaviour is normative in SPEC/ai/civilian-work-planner.md.
const int kRegimentBuildInputFeedstockExtractionScoreBoost = 600;

/// Full AI civilian-work score boost applied to an unimproved **fabric**
/// feedstock resource tile (`wool` / `cotton`) under the growth-stage planner
/// (Refs #3371 AC1). Sized above
/// [kRegimentBuildInputFeedstockExtractionScoreBoost] and the New World resource
/// bonuses so a low-labour GP improves a wool/cotton tile ahead of grain, New
/// World, or H8 extraction work. GA-tunable (Refs #3794); behaviour is normative
/// in SPEC/ai/civilian-work-planner.md.
const int kGrowthStageFabricFeedstockScoreBoost = 700;

/// Full AI civilian-work score boost applied to an unimproved
/// **infrastructure** feedstock resource tile (`timber` / `iron` / `coal`) under
/// the growth-stage planner (Refs #3371 AC2). Sized above the New World resource
/// bonuses but below [kGrowthStageFabricFeedstockScoreBoost] so a maturing GP
/// improves castIron/lumber feedstock only after fabric is secured. GA-tunable
/// (Refs #3794); behaviour is normative in SPEC/ai/civilian-work-planner.md.
const int kGrowthStageInfraFeedstockScoreBoost = 520;

/// Full AI civilian-work `prospect` score boost applied to an unprospected
/// mineral feedstock tile under the feedstock-extraction gate, so an Explorer
/// prospects the feedstock mineral ahead of ordinary explore/prospect work and
/// the Builder feedstock-extraction boost then has a valid (prospected) tile to
/// improve. Sized to match [kRegimentBuildInputFeedstockExtractionScoreBoost].
/// GA-tunable (Refs #3794); behaviour is normative in
/// SPEC/ai/civilian-work-planner.md.
const int kFeedstockMineralProspectScoreBoost = 600;

/// Baseline Full AI work score for any valid Rail Builder `build_rail`
/// candidate, ensuring every rail candidate is scored non-zero rather than
/// falling through to the lexicographic default (Refs #3794 § Rail Builder
/// civilian-work scoring, AC6). Sized below the contextual bonuses so context
/// differentiates otherwise-equal candidates.
const int kBuildRailBaseWorkScore = 100;

/// Extra Rail Builder `build_rail` score when the target road tile carries a
/// resource (proxy for province resource output, the cheap per-tile signal the
/// scorer uses instead of per-tile path-finding; Refs #3794 AC6).
const int kBuildRailResourceOutputBonus = 200;

/// Extra Rail Builder `build_rail` score when the target road tile lies in the
/// player's capital province (capital-connector proxy; Refs #3794 AC6).
const int kBuildRailCapitalConnectorBonus = 150;

/// Extra Rail Builder `build_rail` score when the target road tile is in the
/// New World region (colonial rail bias; Refs #3794 AC6).
const int kBuildRailNewWorldBonus = 80;

/// Per-target-type baseline score for an Engineer `build_road` candidate in the
/// unified Engineer scored pool (replaces the lexicographic fallback; Refs #3794
/// § Engineer). Per-target base weights express the relative priority of the
/// three Engineer targets; contextual bonuses then differentiate candidates of
/// the same target. Roads default highest (logistics backbone).
const int kEngineerBuildRoadBaseWorkScore = 120;

/// Per-target-type baseline score for an Engineer `build_port` candidate in the
/// unified Engineer scored pool (Refs #3794 § Engineer).
const int kEngineerBuildPortBaseWorkScore = 110;

/// Per-target-type baseline score for an Engineer `build_fort` candidate in the
/// unified Engineer scored pool (Refs #3794 § Engineer).
const int kEngineerBuildFortBaseWorkScore = 100;

/// Extra Engineer `build_road` score when the target tile carries a resource
/// (resource-connectivity proxy — the cheap per-tile signal the scorer uses
/// instead of per-tile path-finding; Refs #3794 § Engineer).
const int kEngineerRoadResourceConnectivityBonus = 200;

/// Extra Engineer `build_road` score when the target tile lies in the player's
/// capital province (capital-logistics proxy; Refs #3794 § Engineer).
const int kEngineerRoadCapitalLogisticsBonus = 150;

/// Extra Engineer `build_port` score when the target tile carries a resource
/// (high-value extraction proxy; Refs #3794 § Engineer).
const int kEngineerPortResourceExtractionBonus = 180;

/// Extra Engineer `build_port` score when the target tile is in the New World
/// region (colonial coastal bias proxy; Refs #3794 § Engineer).
const int kEngineerPortNewWorldCoastalBonus = 120;

/// Extra Engineer `build_fort` score when the target tile lies in the player's
/// capital province (capital-defense proxy; Refs #3794 § Engineer).
const int kEngineerFortCapitalDefenseBonus = 160;

/// Extra Engineer `build_fort` score when the target tile is in the New World
/// region (colonial-frontier border proxy; Refs #3794 § Engineer).
const int kEngineerFortNewWorldBorderBonus = 100;

/// Per-target-type baseline score for a Builder `upgrade_town` candidate in the
/// unified Builder scored pool (`build_improvement` + `upgrade_town`; Refs #3794
/// § Builder). Sized below [kBuildImprovementExtractableResourceScore] so a
/// genuine unimproved resource extraction still outranks a bare town upgrade,
/// yet above the degenerate `build_improvement` sentinel scores (1 = already
/// improved, 2 = no resource) so a town upgrade competes when no high-value
/// extraction exists. Contextual bonuses then differentiate town upgrades.
const int kUpgradeTownBaseWorkScore = 300;

/// Extra Builder `upgrade_town` score when the target town tile carries a
/// resource (town resource-value proxy — the cheap per-tile signal the scorer
/// uses instead of per-province aggregation; Refs #3794 § Builder).
const int kUpgradeTownResourceValueBonus = 200;

/// Extra Builder `upgrade_town` score when the target town tile is in the New
/// World region (front-line / colonial-frontier proximity proxy; Refs #3794
/// § Builder).
const int kUpgradeTownFrontlineBonus = 150;

/// Extra Builder `upgrade_town` score when the target town tile has the lowest
/// current development level (improvement level `0`), so the AI develops the
/// least-developed towns first (Refs #3794 § Builder).
const int kUpgradeTownLowDevBonus = 120;

/// Baseline Full AI work score for any valid Spy `counter_spy` candidate in the
/// unified Spy scored pool (Refs #3794 § Spy).
const int kSpyCounterSpyBaseWorkScore = 200;

/// Extra Spy `counter_spy` score when a foreign-owned Spy occupies the candidate
/// province (known enemy-spy-presence proxy; Refs #3794 § Spy).
const int kSpyCounterSpyEnemySpyPresenceBonus = 200;

/// Extra Spy `counter_spy` score when the candidate province is the player's
/// capital province (capital-protection proxy; Refs #3794 § Spy).
const int kSpyCounterSpyCapitalBonus = 120;

/// Extra Spy `counter_spy` score when the candidate province is in the New World
/// region (frontier/border proxy; Refs #3794 § Spy).
const int kSpyCounterSpyBorderBonus = 90;

/// Phase bonus added to Spy `counter_spy` scores in the DEVELOP phase
/// (Refs #3794 § Spy, AC24; steal_tech retired Refs #3834).
const int kSpyPhaseCounterSpyBonus = 2000;
