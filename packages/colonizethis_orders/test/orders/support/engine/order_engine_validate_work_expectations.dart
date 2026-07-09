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
      vwExpectRejected(
        vwRunPurchaseLand(vwPurchaseLandGame(treasury: 500)),
        reasonContains: 'embassy',
      );
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenAtWarWithFaction:
      vwExpectRejected(
        vwRunPurchaseLand(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
            diplomacyRelations: const [
              DiplomacyRelation(
                factionId1: 'p1',
                factionId2: 'minor1',
                state: RelationState.atWar,
              ),
            ],
          ),
        ),
        reasonContains: 'war',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenInsufficientTreasury:
        const cost = 15 * 10;
        vwExpectRejected(
          vwRunPurchaseLand(
            vwPurchaseLandGame(
              treasury: cost - 1,
              overtureStates: purchaseLandEmbassyOverture,
            ),
          ),
          reasonContains: 'Insufficient treasury',
        );
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenTileHasNoResource:
      vwExpectRejected(
        vwRunPurchaseLand(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
            resourceByTileKey: {},
          ),
        ),
        reasonContains: 'no resource',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenMineralTileNotProspected:
      final tk = PurchaseLandTestFixture.tileKey;
        vwExpectRejected(
          vwRunPurchaseLand(
            vwPurchaseLandGame(
              treasury: 500,
              overtureStates: purchaseLandEmbassyOverture,
              resourceByTileKey: {tk: 'iron'},
              playerProspectedTiles: {},
            ),
          ),
          reasonContains: 'prospected',
        );
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource:
      vwExpectAccepted(
        vwRunPurchaseLand(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
          ),
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
        vwExpectAccepted(
          vwRunPurchaseLand(
            vwPurchaseLandGame(
              treasury: 500,
              overtureStates: purchaseLandEmbassyOverture,
              resourceByTileKey: {tk: 'iron'},
              playerProspectedTiles: {
                'p1': {tk},
              },
            ),
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP:
      vwExpectRejected(
        vwRunPurchaseLand(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
            purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
          ),
        ),
        reasonContains: 'Tile already purchased by another power',
      );
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer:
      vwExpectRejected(
        vwRunPurchaseLand(
          vwPurchaseLandGame(
            treasury: 500,
            overtureStates: purchaseLandEmbassyOverture,
            purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
          ),
        ),
        reasonContains: 'You already own this tile',
      );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementOnMineralTileWhenNotProspected:
        vwExpectRejected(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              resourceByTileKey: {ValidateWorkOw.tileKey: 'iron'},
            ),
          ),
          reasonContains: 'prospected',
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnMineralTileAfterProspected:
      const tileKey = ValidateWorkOw.tileKey;
        vwExpectAccepted(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              resourceByTileKey: {tileKey: 'iron'},
              playerProspectedTiles: {
                'p1': {tileKey},
              },
            ),
          ),
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnGrainWhenTileNotProspected:
      vwExpectAccepted(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
            ),
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTileHasNoResource:
      vwExpectRejected(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(resourceByTileKey: {}),
          ),
          reasonContains: 'no resource',
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenImprovementLevelAlready4:
      vwExpectRejected(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
              stockpile: lumberCastIronStockpile(20),
            ),
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
      vwExpectRejected(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              techUnlocked: const {kTechIdSawMill: true},
              tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
              stockpile: lumberCastIronStockpile(10),
            ),
          ),
          reasonContains: 'Insufficient tech',
        );
    case OrderEngineValidateWorkTarget
        .acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked:
      vwExpectAccepted(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              techUnlocked: const {kTechIdLandEnclosure: true},
              tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
              stockpile: lumberCastIronStockpile(10),
            ),
          ),
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows:
      vwExpectAccepted(
          vwValidateBuildImprovement(
            game: buildImprovementBaseGame(
              resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
              tileState: const TileMapState(),
              techUnlocked: const {kTechIdCircularSaw: true},
            ),
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementInForeignUnpurchasedProvince:
      vwExpectRejected(
          vwValidateBuildImprovement(
            game: buildImprovementForeignProvinceGame(),
            targetTileKey: validateWorkForeignTileKey(),
          ),
          reasonContains: 'foreign or uncontrolled province',
        );
    case OrderEngineValidateWorkTarget
        .rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw:
      final scrubRejectResult = vwValidateBuildImprovement(
          game: scrubCapBaseGame(level: 1),
          tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
        );
        vwExpectRejected(scrubRejectResult, reasonContains: 'Terrain caps');
        expect(scrubRejectResult.reason, contains('level 1'));
    case OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw:
      vwExpectAccepted(
          vwValidateBuildImprovement(
            game: scrubCapBaseGame(level: 1),
            tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),
          ),
        );
    case OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01:
      vwExpectAccepted(
          vwValidateBuildImprovement(
            game: scrubCapBaseGame(level: 0),
            tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
          ),
        );
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince:
      final foreignTileKey = validateWorkForeignTileKey();
        vwExpectAccepted(
          vwValidateBuildImprovement(
            game: buildImprovementForeignProvinceGame(
              purchasedTilesByTileKey: {foreignTileKey: 'p1'},
            ),
            targetTileKey: foreignTileKey,
          ),
        );
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering:
      vwExpectRejected(
          vwValidateOwWorkTarget(
            game: fortWorkGame(
              fortLevel: 1,
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 4)
                  .applyDelta(CommodityCatalog.bronze.id, 4),
              techUnlocked: const {},
            ),
            unitId: 'eng1',
            target: kWorkTargetBuildFort,
          ),
          reasonContains: 'Mine Engineering',
        );
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
