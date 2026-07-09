// Compact order_suggestion_core assertions (Refs #3949 wave 3).

import 'order_suggestion_core_expectation_shorthand.dart';
import 'order_suggestion_core_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Pins for [orderSuggestionCoreScenarios] rows.
enum OrderSuggestionCoreTarget {
  suggestMoveOrdersOnlyReturnsMovesThatPassValidation,
  suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility,
  moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians,
  noExploreSuggestionWhenProvinceUnknown,
  suggestWorkOrdersExploreTargetUsesKWorkTargetExplore,
  suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope,
  noProspectSuggestionWhenProvinceNotAtLeastFogged,
  prospectSuggestionWhenProvinceFoggedAndTilesInProvince,
  playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder,
  getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder,
  workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile,
  suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes,
  suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile,
  suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder,
  suggestNavalMissionOrdersReturnsList,
  suggestBuildOrdersReturnsList,
  suggestBuildOrdersReturnsShipWhenAffordable,
  suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable,
  suggestResearchOrdersReturnsList,
  suggestNavalMoveOrdersReturnsList,
  counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles,
  purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile,
}

void runOrderSuggestionCoreExpectation(OrderSuggestionCoreTarget target) {
  switch (target) {
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersOnlyReturnsMovesThatPassValidation:
      {
        final p1 = oscProvince('p1', ownerId: OscIds.playerId);
        final p2 = oscProvince('p2');
        final game = oscGame(
          worldState: oscWorld(
            oldWorld: RegionData(provinces: [p1, p2], units: [oscExplorer()]),
            tileKeysByRegionAndProvince: oscTilesByProvince({
              'p2': [OscIds.tile('p2', 0, 0)],
            }),
            playerVisibilityByTile: oscVisibility({
              OscIds.tile('p1', 0, 0): 'fullyVisible',
              OscIds.tile('p2', 0, 0): 'fogged',
            }),
          ),
        );
        final moves = oscSuggestMoves(
          game,
          oscTwoProvincesConnected('p1', 'p2'),
        );
        expect(moves.length, 1);
        expect(moves.first.unitId, 'u1');
        expect(moves.first.destinationTileKey, OscIds.tile('p2', 0, 0));
      }
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      {
        final game = oscGame(
          worldState: oscWorld(
            oldWorld: RegionData(
              provinces: [
                oscProvince('p1', ownerId: OscIds.playerId),
                oscProvince('p2', ownerId: OscIds.playerId),
              ],
              units: [oscExplorer()],
            ),
          ),
        );
        final topology = oscTwoProvincesConnected('p1', 'p2');
        final view = oscView(game, topology);
        expect(
          () => suggestMoveOrders(view, game, topology, const Orders()),
          throwsStateError,
        );
      }
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      {
        final unit = oscExplorer(
          provinceLocal: 'p1',
          tileKey: OscIds.tile('p2', 0, 0),
        );
        final game = oscGame(
          worldState: oscWorld(
            oldWorld: RegionData(
              provinces: [
                oscProvince('p1', ownerId: OscIds.playerId),
                oscProvince('p2', ownerId: OscIds.playerId),
                oscProvince('p3', ownerId: OscIds.playerId),
              ],
              units: [unit],
            ),
            tileKeysByRegionAndProvince: oscTilesByProvince({
              'p3': [OscIds.tile('p3', 0, 0)],
            }),
            playerVisibilityByTile: oscVisibility({
              OscIds.tile('p2', 0, 0): 'fullyVisible',
              OscIds.tile('p3', 0, 0): 'fogged',
            }),
          ),
        );
        final topology = oscProvinceTopology(
          ['p1', 'p2', 'p3'],
          edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
        );
        final moves = oscSuggestMoves(game, topology);
        expect(moves.length, 1);
        expect(moves.first.unitId, 'u1');
        expect(moves.first.destinationTileKey, OscIds.tile('p3', 0, 0));
        expect(
          oscView(game, topology).ownUnitsById['u1']!.locationProvinceId,
          OscIds.prov('p2'),
        );
      }
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
      final exploreSuggestions = oscSuggestWork(
        oscExplorerProvinceGame(),
        oscProvinceTopology(['p1']),
      );
      expect(
        oscWorkWithTarget(exploreSuggestions, kWorkTargetExplore),
        isEmpty,
      );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
      final t0 = OscIds.tile('p1', 0, 0);
        final t1 = OscIds.tile('p1', 1, 0);
        final suggestions = oscSuggestWork(
          oscExplorerProvinceGame(
            visibilityByTile: {t0: 'fullyVisible', t1: 'unknown'},
            tilesByLocal: {'p1': [t0, t1]},
          ),
          oscProvinceTopology(['p1']),
        );
        expect(
          oscWorkWithTarget(suggestions, kWorkTargetExplore),
          isNotEmpty,
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      final game = oscPartialRevealExploreCacheGame();
        final topology = oscEmptyTopology();
        final explore = oscWorkWithTarget(
          oscSuggestWork(game, topology),
          kWorkTargetExplore,
        );
        expect(explore, isNotEmpty);
        expect(
          Unit.provinceIdFromTileKey(explore.first.targetTileKey),
          OscIds.prov('p_partial'),
        );
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
      final prospectSuggestions = oscSuggestWork(
        oscExplorerProvinceGame(
          ownerId: 'tribe1',
          visibilityByTile: {OscIds.tile('p1', 0, 0): 'unknown'},
        ),
        oscProvinceTopology(['p1']),
      );
      expect(
        oscWorkWithTarget(prospectSuggestions, kWorkTargetProspect),
        isEmpty,
      );
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
      final tileKey = OscIds.tile('p1', 0, 0);
        final game = oscGame(
          worldState: oscExplorerProvinceGame(
            visibilityByTile: {tileKey: 'fogged'},
            tilesByLocal: {'p1': [tileKey]},
          ).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),
        );
        final topology = oscProvinceTopology(['p1']);
        final suggestions = oscSuggestWork(game, topology);
        expect(
          oscWorkWithTarget(suggestions, kWorkTargetProspect),
          isNotEmpty,
        );
        expect(
          oscWorkWithTarget(suggestions, kWorkTargetProspect).first.targetTileKey,
          tileKey,
        );
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
      final game = oscGame(
          worldState: oscExplorerProvinceGame(
            extraProvinceLocals: ['p2'],
            extraOwners: ['minor1'],
            visibilityByTile: {OscIds.tile('p1', 0, 0): 'fogged'},
            tilesByLocal: {
              'p1': [OscIds.tile('p1', 0, 0)],
              'p2': [OscIds.tile('p2', 0, 0)],
            },
          ).worldState,
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        );
        final fromAll = allProvinces(game.worldState).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        final fromView = oscView(game, oscProvinceTopology(['p1', 'p2']))
            .provincesById
            .values
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        expect(fromView.length, fromAll.length);
        expect(
          fromView.map((p) => p.id).toList(),
          fromAll.map((p) => p.id).toList(),
        );
    case OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder:
      final setup = OscDualBuilderGrainTiles();
        final game = setup.game();
        final topology = setup.topology();
        final validB2 = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: oscView(game, topology),
          unitId: 'b2',
          workTarget: kWorkTargetBuildImprovement,
          currentOrders: setup.ordersReservingTileA(),
        );
        expect(validB2, isNot(contains(setup.tileA)));
        expect(validB2, contains(setup.tileB));
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      {
        final tileKey = OscIds.tile('p1', 0, 0);
        final workerGame = oscGame(
          worldState: oscWorld(
            oldWorld: RegionData(
              provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
              units: [oscBuilder()],
            ),
            playerVisibilityByTile: oscVisibility({tileKey: 'fullyVisible'}),
            tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tileKey]}),
          ),
          players: [oscBuilderPlayer()],
        );
        final workerTopology = oscProvinceTopology(['p1']);
        final workerSuggestions = oscSuggestWork(workerGame, workerTopology);
        for (final o in workerSuggestions) {
          expect(o.unitId, 'u1');
          final u = oscView(workerGame, workerTopology).ownUnitsById[o.unitId];
          expect(u, isNotNull);
          expect(u!.locationProvinceId, OscIds.prov('p1'));
        }
      }
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      final tileNoResource = OscIds.tile('p1', 0, 0);
        final tileWithResource = OscIds.tile('p1', 1, 0);
        final game = oscBuilderImprovementGame(
          tileNoResource: tileNoResource,
          tileWithResource: tileWithResource,
        );
        final topology = oscProvinceTopology(['p1']);
        final buildImp = oscWorkWithTarget(
          oscSuggestWork(game, topology),
          kWorkTargetBuildImprovement,
        );
        expect(buildImp, isNotEmpty);
        expect(
          buildImp.first.targetTileKey,
          tileWithResource,
          reason: 'should pick first valid tile, not the empty-resource tile',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      final tileP1 = OscIds.tile('p1', 0, 0);
        final tileP2 = OscIds.tile('p2', 0, 0);
        final game = oscBuilderImprovementGame(
          tileNoResource: tileP1,
          tileWithResource: tileP2,
          secondProvinceLocal: 'p2',
          secondTile: tileP2,
        );
        final topology = oscProvinceTopology(['p1', 'p2']);
        final buildImp = oscWorkWithTarget(
          oscSuggestWork(game, topology),
          kWorkTargetBuildImprovement,
        );
        expect(buildImp, isNotEmpty);
        expect(buildImp.first.targetTileKey, tileP2);
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      final setup = OscDualBuilderGrainTiles();
        final game = setup.game();
        final topology = setup.topology();
        final b2Build = oscWorkWithTarget(
          oscSuggestWork(game, topology, setup.ordersReservingTileA()),
          kWorkTargetBuildImprovement,
        ).where((o) => o.unitId == 'b2').toList();
        expect(b2Build, isNotEmpty);
        expect(b2Build.first.targetTileKey, setup.tileB);
    case OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList:
      final navalMissionGame =
          oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]));
      final navalMissionTopology = oscSeaTopology(['sea1']);
      expect(
        suggestNavalMissionOrders(
          oscView(navalMissionGame, navalMissionTopology),
          navalMissionGame,
          navalMissionTopology,
          const Orders(),
        ),
        isA<List<NavalMissionOrder>>(),
      );
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList:
      expect(
        oscSuggestBuild(
          oscCapitalProvinceGame(
            oscPlayer(
              capitalProvinceId: OscIds.prov('p1'),
              workerPool: const WorkerPool(peasants: 2),
              treasury: 500,
            ),
          ),
          oscCapitalTopology(),
        ),
        isA<List<BuildUnitOrder>>(),
      );
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable:
      final shipTreasury = ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
        final shipStockpile = const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 2)
            .applyDelta(CommodityCatalog.fabric.id, 2);
        final game = oscCapitalProvinceGame(
          oscPlayer(
            capitalProvinceId: OscIds.prov('p1'),
            workerPool: const WorkerPool(peasants: 1),
            treasury: shipTreasury,
            stockpile: shipStockpile,
          ),
        );
        final topology = oscCapitalTopology();
        final shipTypes = oscSuggestBuild(game, topology)
            .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
            .toList();
        expect(
          shipTypes,
          isNotEmpty,
          reason:
              'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
        );
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
      oscExpectBothRegimentAndShipWhenAffordable();
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
      oscExpectResearchOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
      oscExpectNavalMoveOrdersReturnsList();
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
      expect(
        oscWorkWithTarget(
          oscSuggestWork(
            oscSpyCounterSuggestGame(),
            oscProvinceTopology(['p1']),
          ),
          kWorkTargetCounterSpy,
        ),
        isNotEmpty,
      );
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      expect(
        oscWorkWithTarget(
          oscSuggestWork(
            oscMerchantPurchaseLandSuggestGame(),
            oscProvinceTopology(['p1', 'minor1']),
          ),
          kWorkTargetPurchaseLand,
        ),
        isNotEmpty,
      );
}
}
