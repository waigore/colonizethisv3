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
      final moveGame = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [
              oscProvince('p1', ownerId: OscIds.playerId),
              oscProvince('p2'),
            ],
            units: [oscExplorer()],
          ),
          tileKeysByRegionAndProvince: oscTilesByProvince({
            'p2': [OscIds.tile('p2', 0, 0)],
          }),
          playerVisibilityByTile: oscVisibility({
            OscIds.tile('p1', 0, 0): 'fullyVisible',
            OscIds.tile('p2', 0, 0): 'fogged',
          }),
        ),
      );
      final moveTopology = oscTwoProvincesConnected('p1', 'p2');
      final moves = oscSuggestMoves(moveGame, moveTopology);
      expect(moves.length, 1);
      expect(moves.first.unitId, 'u1');
      expect(moves.first.destinationTileKey, OscIds.tile('p2', 0, 0));
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      final throwsGame = oscGame(
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
      expect(
        () => suggestMoveOrders(
          oscView(throwsGame, oscTwoProvincesConnected('p1', 'p2')),
          throwsGame,
          oscTwoProvincesConnected('p1', 'p2'),
          const Orders(),
        ),
        throwsStateError,
      );
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      final unit = oscExplorer(
        provinceLocal: 'p1',
        tileKey: OscIds.tile('p2', 0, 0),
      );
      final civilianGame = oscGame(
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
      final civilianTopology = oscProvinceTopology(
        ['p1', 'p2', 'p3'],
        edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
      );
      final civilianMoves = oscSuggestMoves(civilianGame, civilianTopology);
      expect(civilianMoves.length, 1);
      expect(civilianMoves.first.unitId, 'u1');
      expect(civilianMoves.first.destinationTileKey, OscIds.tile('p3', 0, 0));
      expect(
        oscView(civilianGame, civilianTopology).ownUnitsById['u1']!.locationProvinceId,
        OscIds.prov('p2'),
      );
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
      oscExpectWorkTargetSuggestions(
        game: oscExplorerProvinceGame(),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetExplore,
        expectNonEmpty: false,
      );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
      final t0 = OscIds.tile('p1', 0, 0);
      final t1 = OscIds.tile('p1', 1, 0);
      final exploreSuggestions = oscSuggestWork(
        oscExplorerProvinceGame(
          visibilityByTile: {t0: 'fullyVisible', t1: 'unknown'},
          tilesByLocal: {'p1': [t0, t1]},
        ),
        oscProvinceTopology(['p1']),
      );
      expect(
        oscWorkWithTarget(exploreSuggestions, kWorkTargetExplore),
        isNotEmpty,
      );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      final cacheGame = oscPartialRevealExploreCacheGame();
      final cacheTopology = oscEmptyTopology();
      final explore = oscWorkWithTarget(
        oscSuggestWork(cacheGame, cacheTopology),
        kWorkTargetExplore,
      );
      expect(explore, isNotEmpty);
      expect(
        Unit.provinceIdFromTileKey(explore.first.targetTileKey),
        OscIds.prov('p_partial'),
      );
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
      oscExpectWorkTargetSuggestions(
        game: oscExplorerProvinceGame(
          ownerId: 'tribe1',
          visibilityByTile: {OscIds.tile('p1', 0, 0): 'unknown'},
        ),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetProspect,
        expectNonEmpty: false,
      );
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
      final tileKey = OscIds.tile('p1', 0, 0);
        oscExpectWorkTargetSuggestions(
          game: oscGame(
            worldState: oscExplorerProvinceGame(
              visibilityByTile: {tileKey: 'fogged'},
              tilesByLocal: {'p1': [tileKey]},
            ).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),
          ),
          topology: oscProvinceTopology(['p1']),
          target: kWorkTargetProspect,
          expectNonEmpty: true,
          expectedTileKey: tileKey,
        );
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
      final prospectGame = oscGame(
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
      final fromAll = allProvinces(prospectGame.worldState).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final fromView = oscView(prospectGame, oscProvinceTopology(['p1', 'p2']))
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
      final reservedSetup = OscDualBuilderGrainTiles();
      final validB2 = getValidWorkOrderTileKeysWithVisibility(
        game: reservedSetup.game(),
        topology: reservedSetup.topology(),
        view: oscView(reservedSetup.game(), reservedSetup.topology()),
        unitId: 'b2',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: reservedSetup.ordersReservingTileA(),
      );
      expect(validB2, isNot(contains(reservedSetup.tileA)));
      expect(validB2, contains(reservedSetup.tileB));
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      final workerTileKey = OscIds.tile('p1', 0, 0);
      final workerGame = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
            units: [oscBuilder()],
          ),
          playerVisibilityByTile: oscVisibility({workerTileKey: 'fullyVisible'}),
          tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [workerTileKey]}),
        ),
        players: [oscBuilderPlayer()],
      );
      final workerTopology = oscProvinceTopology(['p1']);
      for (final o in oscSuggestWork(workerGame, workerTopology)) {
        expect(o.unitId, 'u1');
        final u = oscView(workerGame, workerTopology).ownUnitsById[o.unitId];
        expect(u, isNotNull);
        expect(u!.locationProvinceId, OscIds.prov('p1'));
      }
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      final tileNoResource = OscIds.tile('p1', 0, 0);
        final tileWithResource = OscIds.tile('p1', 1, 0);
        oscExpectBuildImprovementFirstTile(
          game: oscBuilderImprovementGame(
            tileNoResource: tileNoResource,
            tileWithResource: tileWithResource,
          ),
          topology: oscProvinceTopology(['p1']),
          expectedTileKey: tileWithResource,
          unitId: 'u1',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      final tileP1 = OscIds.tile('p1', 0, 0);
        final tileP2 = OscIds.tile('p2', 0, 0);
        oscExpectBuildImprovementFirstTile(
          game: oscBuilderImprovementGame(
            tileNoResource: tileP1,
            tileWithResource: tileP2,
            secondProvinceLocal: 'p2',
            secondTile: tileP2,
          ),
          topology: oscProvinceTopology(['p1', 'p2']),
          expectedTileKey: tileP2,
          unitId: 'u1',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      final setup = OscDualBuilderGrainTiles();
        oscExpectBuildImprovementFirstTile(
          game: setup.game(),
          topology: setup.topology(),
          expectedTileKey: setup.tileB,
          orders: setup.ordersReservingTileA(),
        );
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
      final shipTypes = oscSuggestBuild(
        oscCapitalProvinceGame(
          oscPlayer(
            capitalProvinceId: OscIds.prov('p1'),
            workerPool: const WorkerPool(peasants: 1),
            treasury: shipTreasury,
            stockpile: shipStockpile,
          ),
        ),
        oscCapitalTopology(),
      ).where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)).toList();
      expect(
        shipTypes,
        isNotEmpty,
        reason:
            'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
      );
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
      final bothTreasury =
          ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
      final bothStockpile = const Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 5)
          .applyDelta(CommodityCatalog.fabric.id, 5)
          .applyDelta(CommodityCatalog.castIron.id, 5);
      final bothGame = oscCapitalProvinceGame(
        oscPlayer(
          capitalProvinceId: OscIds.prov('p1'),
          workerPool: const WorkerPool(peasants: 2, apprentices: 1),
          treasury: bothTreasury,
          stockpile: bothStockpile,
        ),
      );
      final bothTopology = oscCapitalTopology();
      final bothSuggestions = oscSuggestBuild(bothGame, bothTopology);
      expect(
        bothSuggestions.any((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType)),
        isTrue,
        reason: 'should suggest regiments when affordable',
      );
      expect(
        bothSuggestions.any((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)),
        isTrue,
        reason: 'should suggest ships when affordable',
      );
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
      final researchGame = oscGame(
        worldState: oscWorld(),
        players: [oscPlayer(treasury: 1000)],
      );
      expect(
        suggestResearchOrders(
          oscView(researchGame, oscEmptyTopology()),
          researchGame,
          oscEmptyTopology(),
          const Orders(),
        ),
        isA<List<ResearchOrder>>(),
      );
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
      final navalMoveGame =
          oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]));
      final navalMoveTopology = oscSeaTopology(
        ['sea1', 'sea2'],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      expect(
        suggestNavalMoveOrders(
          oscView(navalMoveGame, navalMoveTopology),
          navalMoveGame,
          navalMoveTopology,
          const Orders(),
        ),
        isA<List<NavalMoveOrder>>(),
      );
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
      oscExpectWorkTargetSuggestions(
        game: oscSpyCounterSuggestGame(),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetCounterSpy,
        expectNonEmpty: true,
      );
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      oscExpectWorkTargetSuggestions(
        game: oscMerchantPurchaseLandSuggestGame(),
        topology: oscProvinceTopology(['p1', 'minor1']),
        target: kWorkTargetPurchaseLand,
        expectNonEmpty: true,
      );
}
}
