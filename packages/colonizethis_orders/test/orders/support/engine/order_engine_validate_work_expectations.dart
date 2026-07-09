// Compact OrderEngine validateWork assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'order_engine_validate_work_expectation_shorthand.dart';

/// Pins for [orderEngineValidateWorkScenarios] rows.
enum OrderEngineValidateWorkTarget {
  rejectsSecondPendingWorkOrderForSameUnitInOneTurn,
  rejectsPurchaseLandWhenNoEmbassyWithMinor,
  rejectsPurchaseLandWhenAtWarWithFaction,
  rejectsPurchaseLandWhenInsufficientTreasury,
  rejectsPurchaseLandWhenTileHasNoResource,
  rejectsPurchaseLandWhenMineralTileNotProspected,
  acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource,
  rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity,
  acceptsPurchaseLandForMineralWhenProspected,
  rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP,
  rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer,
  rejectsBuildImprovementOnMineralTileWhenNotProspected,
  acceptsBuildImprovementOnMineralTileAfterProspected,
  acceptsBuildImprovementOnGrainWhenTileNotProspected,
  rejectsBuildImprovementWhenTileHasNoResource,
  rejectsBuildImprovementWhenImprovementLevelAlready4,
  rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech,
  rejectsBuildImprovementWhenTechCapWouldBeExceeded,
  acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked,
  acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows,
  rejectsBuildImprovementInForeignUnpurchasedProvince,
  rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw,
  acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw,
  acceptsInitialScrubTimberImprovementLevel01,
  acceptsBuildImprovementOnPurchasedTileInForeignProvince,
  rejectsBuildFortToLevel2WithoutMineEngineering,
  rejectsBuildFortToLevel3WithoutModernForts,
  rejectsBuildRailWhenTileTerrainDataIsMissing,
  rejectsBuildRailWhenRoadLevelIs0,
  rejectsBuildRailOnHillsWithOnlyEarlySteam,
  acceptsBuildRailOnPlainsWithEarlySteamAndRoad1,
  rejectsBuildRoadInMinorProvinceWithoutEmbassyPath,
  rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile,
  rejectsUpgradeTownWithoutNationalBureaucracy,
  acceptsUpgradeTownWhenNationalBureaucracyUnlocked,
}

void runOrderEngineValidateWorkExpectation(
  OrderEngineValidateWorkTarget target,
) {
  switch (target) {
    case OrderEngineValidateWorkTarget
        .rejectsSecondPendingWorkOrderForSameUnitInOneTurn:
      vwExpectSecondPendingWorkOrderRejected();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenNoEmbassyWithMinor:
      vwExpectPurchaseLandRejectedNoEmbassy();
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenAtWarWithFaction:
      vwExpectPurchaseLandRejectedAtWar();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenInsufficientTreasury:
      vwExpectPurchaseLandRejectedInsufficientTreasury();
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenTileHasNoResource:
      vwExpectPurchaseLandRejectedNoResource();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenMineralTileNotProspected:
      vwExpectPurchaseLandRejectedMineralNotProspected();
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource:
      vwExpectPurchaseLandAcceptedEmbassy();
    case OrderEngineValidateWorkTarget
        .rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity:
      vwExpectSameTileDevelopmentExclusivityRejected();
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandForMineralWhenProspected:
      vwExpectPurchaseLandAcceptedMineralProspected();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP:
      vwExpectPurchaseLandRejectedAlreadyPurchasedByOther();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer:
      vwExpectPurchaseLandRejectedAlreadyOwnedBySelf();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementOnMineralTileWhenNotProspected:
      vwExpectMineralBuildImprovementRejectedWhenNotProspected();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnMineralTileAfterProspected:
      vwExpectMineralBuildImprovementAcceptedWhenProspected();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnGrainWhenTileNotProspected:
      vwExpectGrainBuildImprovementAcceptedWhenNotProspected();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTileHasNoResource:
      vwExpectBuildImprovementRejectedNoResource();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenImprovementLevelAlready4:
      vwExpectBuildImprovementRejectedAtLevel4();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech:
      vwExpectEmptyTechCapBuildImprovementRejected();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceeded:
      vwExpectTechCapBuildImprovementRejected();
    case OrderEngineValidateWorkTarget
        .acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked:
      vwExpectGrainUpgradeWithLandEnclosure();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows:
      vwExpectBuildImprovementAcceptedAtLevel4TechCap();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementInForeignUnpurchasedProvince:
      vwExpectBuildImprovementRejectedForeignUnpurchased();
    case OrderEngineValidateWorkTarget
        .rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw:
      vwExpectScrubTimberLevel1Rejected();
    case OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw:
      vwExpectHardwoodTimberLevel1Accepted();
    case OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01:
      vwExpectScrubTimberLevel0Accepted();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince:
      vwExpectBuildImprovementAcceptedOnPurchasedForeignTile();
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering:
      vwExpectFortLevel2RejectedWithoutMineEngineering();
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel3WithoutModernForts:
      vwExpectFortLevel3RejectedWithoutModernForts();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailWhenTileTerrainDataIsMissing:
      vwExpectRailMissingTerrainDataRejected();
    case OrderEngineValidateWorkTarget.rejectsBuildRailWhenRoadLevelIs0:
      vwExpectRailRejectedPlainsNoRoad();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailOnHillsWithOnlyEarlySteam:
      vwExpectRailRejectedHillsEarlySteamOnly();
    case OrderEngineValidateWorkTarget
        .acceptsBuildRailOnPlainsWithEarlySteamAndRoad1:
      vwExpectRailTerrainAccepted(terrain: TerrainType.plains);
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceWithoutEmbassyPath:
      vwExpectMinorProvinceRoadRejectedWithoutEmbassy();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile:
      vwExpectMinorProvinceRoadRejectedDespiteEmbassy();
    case OrderEngineValidateWorkTarget
        .rejectsUpgradeTownWithoutNationalBureaucracy:
      vwExpectUpgradeTownRejectedNoBureaucracy();
    case OrderEngineValidateWorkTarget
        .acceptsUpgradeTownWhenNationalBureaucracyUnlocked:
      vwExpectUpgradeTownAcceptedWithBureaucracy();
  }
}
