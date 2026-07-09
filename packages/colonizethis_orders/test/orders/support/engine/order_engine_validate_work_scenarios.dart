// Table-driven OrderEngine validateWork scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_work_expectations.dart';

/// One row in [orderEngineValidateWorkScenarios].
class OrderEngineValidateWorkScenario implements RefsScenario {
  const OrderEngineValidateWorkScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidateWorkTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidateWorkScenario(
  OrderEngineValidateWorkScenario scenario,
) {
  runOrderEngineValidateWorkExpectation(scenario.target);
}

/// Canonical scenarios for order_engine_validate_work family tests.
List<OrderEngineValidateWorkScenario>
orderEngineValidateWorkScenarios() => const [
  // dart format off
  OrderEngineValidateWorkScenario(
    label: 'rejects second pending work order for same unit in one turn',
    target: OrderEngineValidateWorkTarget
        .rejectsSecondPendingWorkOrderForSameUnitInOneTurn,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when no embassy with Minor',
    target:
        OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenNoEmbassyWithMinor,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when at war with faction',
    target:
        OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenAtWarWithFaction,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when insufficient treasury',
    target: OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenInsufficientTreasury,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when tile has no resource',
    target:
        OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenTileHasNoResource,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when mineral tile not prospected',
    target: OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenMineralTileNotProspected,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource',
    target: OrderEngineValidateWorkTarget
        .acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity)',
    target: OrderEngineValidateWorkTarget
        .rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts purchase_land for mineral when prospected',
    target: OrderEngineValidateWorkTarget
        .acceptsPurchaseLandForMineralWhenProspected,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when tile already purchased by another GP',
    target: OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when tile already owned by same player',
    target: OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement on mineral tile when not prospected',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildImprovementOnMineralTileWhenNotProspected,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement on mineral tile after prospected',
    target: OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnMineralTileAfterProspected,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement on grain when tile not prospected',
    target: OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnGrainWhenTileNotProspected,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when tile has no resource',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTileHasNoResource,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when improvement level already 4',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenImprovementLevelAlready4,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when tech cap would be exceeded (empty tech)',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when tech cap would be exceeded',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceeded,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts grain upgrade when exact next-level grain tech is unlocked',
    target: OrderEngineValidateWorkTarget
        .acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement when tile has resource, level < 4, tech cap allows',
    target: OrderEngineValidateWorkTarget
        .acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement in foreign, unpurchased province',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildImprovementInForeignUnpurchasedProvince,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects raising scrub timber from level 1 even with circular_saw',
    target: OrderEngineValidateWorkTarget
        .rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts raising hardwood timber from level 1 with circular_saw',
    target: OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts initial scrub timber improvement (level 0 -> 1)',
    target: OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement on purchased tile in foreign province',
    target: OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_fort to level 2 without Mine Engineering',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_fort to level 3 without Modern Forts',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel3WithoutModernForts,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_rail when tile terrain data is missing',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildRailWhenTileTerrainDataIsMissing,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_rail when road level is 0',
    target: OrderEngineValidateWorkTarget.rejectsBuildRailWhenRoadLevelIs0,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_rail on hills with only Early Steam',
    target:
        OrderEngineValidateWorkTarget.rejectsBuildRailOnHillsWithOnlyEarlySteam,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_rail on plains with Early Steam and road 1',
    target: OrderEngineValidateWorkTarget
        .acceptsBuildRailOnPlainsWithEarlySteamAndRoad1,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_road in minor province without embassy path',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceWithoutEmbassyPath,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_road in minor province even with embassy when occupancy disallows tile',
    target: OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects upgrade_town without National Bureaucracy',
    target: OrderEngineValidateWorkTarget
        .rejectsUpgradeTownWithoutNationalBureaucracy,
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts upgrade_town when National Bureaucracy unlocked',
    target: OrderEngineValidateWorkTarget
        .acceptsUpgradeTownWhenNationalBureaucracyUnlocked,
  ),
];
