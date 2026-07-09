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
      vwExpectPurchaseLandRejectedNoEmbassy();
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenAtWarWithFaction:
      vwExpectPurchaseLandRejectedAtWar();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenInsufficientTreasury:
      vwExpectPurchaseLandRejectedInsufficientTreasury();
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenTileHasNoResource:
      vwExpectPurchaseLandRejected(
        vwPurchaseLandGame(
          treasury: 500,
          overtureStates: purchaseLandEmbassyOverture,
          resourceByTileKey: {},
        ),
        reasonContains: 'no resource',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenMineralTileNotProspected:
      final tk = PurchaseLandTestFixture.tileKey;
        vwExpectPurchaseLandRejected(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
            resourceByTileKey: {tk: 'iron'},
            playerProspectedTiles: {},
          ),
          reasonContains: 'prospected',
        );
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource:
      vwExpectPurchaseLandAccepted(
        vwPurchaseLandGame(
          treasury: 500,
          overtureStates: purchaseLandEmbassyOverture,
        ),
      );
    case OrderEngineValidateWorkTarget
        .rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity:
      const tileKey = ValidateWorkOw.tileKey;
        vwExpectDualWorkOrders(
          game: builderEngineerSameTileExclusivityGame(),
          first: const WorkOrder(
            unitId: 'builder1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileKey,
          ),
          second: const WorkOrder(
            unitId: 'engineer1',
            target: kWorkTargetBuildRoad,
            targetTileKey: tileKey,
          ),
          statuses: const [
            OrderValidationStatus.accepted,
            OrderValidationStatus.rejected,
          ],
          lastReasonContains: 'Tile already has development or purchase work',
        );
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandForMineralWhenProspected:
      final tk = PurchaseLandTestFixture.tileKey;
        vwExpectPurchaseLandAccepted(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
            resourceByTileKey: {tk: 'iron'},
            playerProspectedTiles: {
              'p1': {tk},
            },
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP:
      vwExpectPurchaseLandRejected(
            vwPurchaseLandGame(
              treasury: 500,
              overtureStates: purchaseLandEmbassyOverture,
              purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
            ),
            reasonContains: 'Tile already purchased by another power',
          );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer:
      vwExpectPurchaseLandRejected(
            vwPurchaseLandGame(
              treasury: 500,
              overtureStates: purchaseLandEmbassyOverture,
              purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
            ),
            reasonContains: 'You already own this tile',
          );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementOnMineralTileWhenNotProspected:
      vwExpectMineralBuildImprovementRejectedWhenNotProspected();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnMineralTileAfterProspected:
      const tileKey = ValidateWorkOw.tileKey;
        vwExpectBuildImprovementAccepted(
          game: buildImprovementBaseGame(
            resourceByTileKey: {tileKey: 'iron'},
            playerProspectedTiles: {
              'p1': {tileKey},
            },
          ),
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnGrainWhenTileNotProspected:
      vwExpectBuildImprovementAccepted(
          game: buildImprovementBaseGame(
            resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTileHasNoResource:
      vwExpectBuildImprovementRejected(
          game: buildImprovementBaseGame(resourceByTileKey: {}),
          reasonContains: 'no resource',
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenImprovementLevelAlready4:
      vwExpectBuildImprovementRejected(
          game: buildImprovementBaseGame(
            tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
            stockpile: lumberCastIronStockpile(20),
          ),
          reasonContains: 'maximum',
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech:
      final result = vwValidateBuildImprovement(
          game: buildImprovementBaseGame(
            techUnlocked: const {},
            tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
            stockpile: lumberCastIronStockpile(10),
          ),
        );
        vwExpectRejected(result, reasonContains: 'Insufficient tech');
        expect(result.reason, contains('grain'));
        expect(result.reason, contains('cap 1'));
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceeded:
      vwExpectBuildImprovementRejected(
          game: buildImprovementBaseGame(
            techUnlocked: const {kTechIdSawMill: true},
            tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
            stockpile: lumberCastIronStockpile(10),
          ),
          reasonContains: 'Insufficient tech',
        );
    case OrderEngineValidateWorkTarget
        .acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked:
      vwExpectBuildImprovementAccepted(
          game: buildImprovementBaseGame(
            techUnlocked: const {kTechIdLandEnclosure: true},
            tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
            stockpile: lumberCastIronStockpile(10),
          ),
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows:
      vwExpectBuildImprovementAccepted(
          game: buildImprovementBaseGame(
            resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
            tileState: const TileMapState(),
            techUnlocked: const {kTechIdCircularSaw: true},
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementInForeignUnpurchasedProvince:
      vwExpectBuildImprovementRejected(
          game: buildImprovementForeignProvinceGame(),
          targetTileKey: validateWorkForeignTileKey(),
          reasonContains: 'foreign or uncontrolled province',
        );
    case OrderEngineValidateWorkTarget
        .rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw:
      vwExpectScrubTimberRejected(
          level: 1,
          terrain: TerrainType.scrubForest,
        );
    case OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw:
      vwExpectScrubTimberAccepted(
          level: 1,
          terrain: TerrainType.hardwoodForest,
        );
    case OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01:
      vwExpectScrubTimberAccepted(
          level: 0,
          terrain: TerrainType.scrubForest,
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince:
      final foreignTileKey = validateWorkForeignTileKey();
        vwExpectBuildImprovementAccepted(
          game: buildImprovementForeignProvinceGame(
            purchasedTilesByTileKey: {foreignTileKey: 'p1'},
          ),
          targetTileKey: foreignTileKey,
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering:
      vwExpectFortRejected(
          fortLevel: 1,
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 4)
              .applyDelta(CommodityCatalog.bronze.id, 4),
          techUnlocked: const {},
          reasonContains: 'Mine Engineering',
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel3WithoutModernForts:
      vwExpectFortRejected(
          fortLevel: 2,
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.steel.id, 5)
              .applyDelta(CommodityCatalog.lumber.id, 5),
          techUnlocked: const {kTechIdMineEngineering: true},
          reasonContains: 'Modern Forts',
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailWhenTileTerrainDataIsMissing:
      vwExpectRailRejected(
          game: gameWithRailUnit(
            tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
          ),
          tileMapByRegion: const {},
          reasonContains: 'terrain data required',
        );
    case OrderEngineValidateWorkTarget.rejectsBuildRailWhenRoadLevelIs0:
      vwExpectRailTerrainRejected(
          terrain: TerrainType.plains,
          roadLevel: 0,
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailOnHillsWithOnlyEarlySteam:
      vwExpectRailTerrainRejected(
          terrain: TerrainType.hills,
          techUnlocked: const {kTechIdEarlySteamEngine: true},
          reasonContains: 'Later Steam',
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildRailOnPlainsWithEarlySteamAndRoad1:
      vwExpectRailTerrainAccepted(terrain: TerrainType.plains);
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceWithoutEmbassyPath:
      vwExpectMinorProvinceRoadRejected(
          minorProvinceEngineerRoadGame(),
          reasonContains: 'foreign province',
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile:
      vwExpectMinorProvinceRoadRejected(
          minorProvinceEngineerRoadGame(overtureStates: minorProvinceEmbassyOverture),
          reasonContains: 'cannot occupy',
        );
    case OrderEngineValidateWorkTarget
        .rejectsUpgradeTownWithoutNationalBureaucracy:
      vwExpectUpgradeTownOutcome(
          techUnlocked: const {},
          accepted: false,
          reasonContains: 'National Bureaucracy',
        );
    case OrderEngineValidateWorkTarget
        .acceptsUpgradeTownWhenNationalBureaucracyUnlocked:
      vwExpectUpgradeTownOutcome(
          techUnlocked: const {kTechIdNationalBureaucracy: true},
          accepted: true,
        );
  }
}
