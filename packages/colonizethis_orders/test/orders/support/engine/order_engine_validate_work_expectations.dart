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
      const tileA = ValidateWorkOw.tileKey;
      const tileB = '${ValidateWorkOw.provinceId}|1|0';
      vwExpectDualWorkOrders(
        game: dualTilePendingWorkGame(),
        first: const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileA,
        ),
        second: const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileB,
        ),
        statuses: const [
          OrderValidationStatus.accepted,
          OrderValidationStatus.rejected,
        ],
        lastReasonContains: 'Only one work order per unit is allowed each turn',
      );
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
      const exclusivityTileKey = ValidateWorkOw.tileKey;
      vwExpectDualWorkOrders(
        game: builderEngineerSameTileExclusivityGame(),
        first: const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: exclusivityTileKey,
        ),
        second: const WorkOrder(
          unitId: 'engineer1',
          target: kWorkTargetBuildRoad,
          targetTileKey: exclusivityTileKey,
        ),
        statuses: const [
          OrderValidationStatus.accepted,
          OrderValidationStatus.rejected,
        ],
        lastReasonContains: 'Tile already has development or purchase work',
      );
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
      vwExpectBuildImprovementOutcome(
        game: buildImprovementBaseGame(
          techUnlocked: const {},
          tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
          stockpile: lumberCastIronStockpile(10),
        ),
        accepted: false,
        reasonContains: 'Insufficient tech',
        onRejected: (result) {
          expect(result.reason, contains('grain'));
          expect(result.reason, contains('cap 1'));
        },
      );
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
      vwExpectBuildImprovementOutcome(
        game: scrubCapBaseGame(level: 1),
        tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
        accepted: false,
        reasonContains: 'Terrain caps',
        onRejected: (result) => expect(result.reason, contains('level 1')),
      );
    case OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw:
      vwExpectBuildImprovementOutcome(
        game: scrubCapBaseGame(level: 1),
        tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),
        accepted: true,
      );
    case OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01:
      vwExpectBuildImprovementOutcome(
        game: scrubCapBaseGame(level: 0),
        tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
        accepted: true,
      );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince:
      final foreignTileKey = validateWorkForeignTileKey();
      vwExpectBuildImprovementOutcome(
        game: buildImprovementForeignProvinceGame(
          purchasedTilesByTileKey: {foreignTileKey: 'p1'},
        ),
        targetTileKey: foreignTileKey,
        accepted: true,
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering:
      vwExpectFortBuildRejected(
        fortLevel: 1,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 4)
            .applyDelta(CommodityCatalog.bronze.id, 4),
        reasonContains: 'Mine Engineering',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel3WithoutModernForts:
      vwExpectFortBuildRejected(
        fortLevel: 2,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.steel.id, 5)
            .applyDelta(CommodityCatalog.lumber.id, 5),
        techUnlocked: const {kTechIdMineEngineering: true},
        reasonContains: 'Modern Forts',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailWhenTileTerrainDataIsMissing:
      vwExpectRailBuildOutcome(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
        tileMapByRegion: const {},
        accepted: false,
        reasonContains: 'terrain data required',
      );
    case OrderEngineValidateWorkTarget.rejectsBuildRailWhenRoadLevelIs0:
      vwExpectRailBuildOutcome(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 0),
        tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},
        accepted: false,
        reasonContains: 'existing road',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailOnHillsWithOnlyEarlySteam:
      vwExpectRailBuildOutcome(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
        techUnlocked: const {kTechIdEarlySteamEngine: true},
        tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.hills)},
        accepted: false,
        reasonContains: 'Later Steam',
      );
    case OrderEngineValidateWorkTarget
        .acceptsBuildRailOnPlainsWithEarlySteamAndRoad1:
      vwExpectRailBuildOutcome(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
        tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},
        accepted: true,
      );
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
      vwExpectUpgradeTownOutcome(accepted: false, techUnlocked: const {});
    case OrderEngineValidateWorkTarget
        .acceptsUpgradeTownWhenNationalBureaucracyUnlocked:
      vwExpectUpgradeTownOutcome(
        accepted: true,
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      );
}
}
