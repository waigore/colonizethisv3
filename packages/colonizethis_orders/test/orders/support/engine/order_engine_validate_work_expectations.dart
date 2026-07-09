// Compact OrderEngine validateWork assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'order_engine_validate_work_fixtures.dart';
import 'order_engine_purchase_land_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

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
      vwExpectDualPendingWorkRejected();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenNoEmbassyWithMinor:
      vwExpectPurchaseLandRejected(
        overtureStates: null,
        reasonContains: 'embassy',
      );
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenAtWarWithFaction:
      vwExpectPurchaseLandRejected(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'minor1',
            state: RelationState.atWar,
          ),
        ],
        reasonContains: 'war',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenInsufficientTreasury:
      vwExpectPurchaseLandRejected(
        treasury: 15 * 10 - 1,
        reasonContains: 'Insufficient treasury',
      );
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenTileHasNoResource:
      vwExpectPurchaseLandRejected(
        resourceByTileKey: {},
        reasonContains: 'no resource',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenMineralTileNotProspected:
      vwExpectPurchaseLandMineral(prospected: false);
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource:
      vwExpectPurchaseLandAccepted();
    case OrderEngineValidateWorkTarget
        .rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity:
      vwExpectBuilderEngineerSameTileExclusivityRejected();
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandForMineralWhenProspected:
      vwExpectPurchaseLandMineral(prospected: true);
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP:
      vwExpectPurchaseLandRejected(
        purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
        reasonContains: 'Tile already purchased by another power',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer:
      vwExpectPurchaseLandRejected(
        purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
        reasonContains: 'You already own this tile',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementOnMineralTileWhenNotProspected:
      vwExpectBuildImprovementMineral(prospected: false);
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnMineralTileAfterProspected:
      vwExpectBuildImprovementMineral(prospected: true);
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnGrainWhenTileNotProspected:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(
          resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
        ),
        accepted: true,
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTileHasNoResource:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(resourceByTileKey: {}),
        accepted: false,
        reasonContains: 'no resource',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenImprovementLevelAlready4:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(
          tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
          stockpile: lumberCastIronStockpile(20),
        ),
        accepted: false,
        reasonContains: 'maximum',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech:
      vwExpectBuildImprovementTechCapEmptyTechRejected();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceeded:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(
          techUnlocked: const {kTechIdSawMill: true},
          tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
          stockpile: lumberCastIronStockpile(10),
        ),
        accepted: false,
        reasonContains: 'Insufficient tech',
      );
    case OrderEngineValidateWorkTarget
        .acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(
          techUnlocked: const {kTechIdLandEnclosure: true},
          tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
          stockpile: lumberCastIronStockpile(10),
        ),
        accepted: true,
      );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(
          resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
          tileState: const TileMapState(),
          techUnlocked: const {kTechIdCircularSaw: true},
        ),
        accepted: true,
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementInForeignUnpurchasedProvince:
      vwExpectBuildImprovementOutcome(
        game: buildImprovementForeignProvinceGame(),
        targetTileKey: validateWorkForeignTileKey(),
        accepted: false,
        reasonContains: 'foreign or uncontrolled province',
      );
    case OrderEngineValidateWorkTarget
        .rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw:
      vwExpectScrubTimberRejectAtLevel1();
    case OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw:
      vwExpectHardwoodTimberAcceptAtLevel1();
    case OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01:
      vwExpectInitialScrubTimberAcceptAtLevel0();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince:
      vwExpectBuildImprovementOnPurchasedForeignTile();
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering:
      vwExpectRejectFortLevel2WithoutMineEngineering();
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel3WithoutModernForts:
      vwExpectRejectFortLevel3WithoutModernForts();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailWhenTileTerrainDataIsMissing:
      vwExpectRejectRailMissingTerrain();
    case OrderEngineValidateWorkTarget.rejectsBuildRailWhenRoadLevelIs0:
      vwExpectRejectRailWhenRoadLevelZero();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailOnHillsWithOnlyEarlySteam:
      vwExpectRejectRailOnHillsWithEarlySteamOnly();
    case OrderEngineValidateWorkTarget
        .acceptsBuildRailOnPlainsWithEarlySteamAndRoad1:
      vwExpectAcceptRailOnPlainsWithEarlySteam();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceWithoutEmbassyPath:
      vwExpectRejectMinorProvinceRoad(
        game: minorProvinceEngineerRoadGame(),
        reasonContains: 'foreign province',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile:
      vwExpectRejectMinorProvinceRoad(
        game: minorProvinceEngineerRoadGame(
          overtureStates: minorProvinceEmbassyOverture,
        ),
        reasonContains: 'cannot occupy',
      );
    case OrderEngineValidateWorkTarget
        .rejectsUpgradeTownWithoutNationalBureaucracy:
      vwExpectRejectUpgradeTownWithoutNationalBureaucracy();
    case OrderEngineValidateWorkTarget
        .acceptsUpgradeTownWhenNationalBureaucracyUnlocked:
      vwExpectAcceptUpgradeTownWithNationalBureaucracy();
}
}
