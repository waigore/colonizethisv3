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
      final game = oscFoggedDestinationMoveGame();
        oscExpectFirstMove(
          oscSuggestMoves(game, oscTwoProvincesConnected('p1', 'p2')),
          destinationTileKey: OscIds.tile('p2', 0, 0),
        );
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      oscExpectThrowsSuggestMoveOnUnknownVisibility(
          oscTwoProvinceExplorerUnknownVisibilityGame(),
          oscTwoProvincesConnected('p1', 'p2'),
        );
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      final game = oscMislocatedExplorerMoveGame();
        final topology = oscMislocatedExplorerTopology();
        oscExpectFirstMove(
          oscSuggestMoves(game, topology),
          destinationTileKey: OscIds.tile('p3', 0, 0),
        );
        expect(
          oscView(game, topology).ownUnitsById['u1']!.locationProvinceId,
          OscIds.prov('p2'),
        );
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
        oscExpectWorkTargetNotEmpty(
          oscSuggestWork(
            oscExplorerProvinceGame(
              visibilityByTile: {t0: 'fullyVisible', t1: 'unknown'},
              tilesByLocal: {'p1': [t0, t1]},
            ),
            oscProvinceTopology(['p1']),
          ),
          kWorkTargetExplore,
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      oscExpectExploreTargetsProvince(
          oscPartialRevealExploreCacheGame(),
          oscEmptyTopology(),
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
        oscExpectProspectTargetsTile(game, oscProvinceTopology(['p1']), tileKey);
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
      oscExpectDualBuilderVisKeysExcludeReserved(OscDualBuilderGrainTiles());
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      final workerGame = oscBuilderWorkerSuggestGame();
        final workerTopology = oscProvinceTopology(['p1']);
        final workerSuggestions = oscSuggestWork(workerGame, workerTopology);
        for (final o in workerSuggestions) {
          expect(o.unitId, 'u1');
          final u = oscView(workerGame, workerTopology).ownUnitsById[o.unitId];
          expect(u, isNotNull);
          expect(u!.locationProvinceId, OscIds.prov('p1'));
        }
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      final tileNoResource = OscIds.tile('p1', 0, 0);
        final tileWithResource = OscIds.tile('p1', 1, 0);
        oscExpectBuildImprovementTargetsTile(
          oscBuilderImprovementGame(
            tileNoResource: tileNoResource,
            tileWithResource: tileWithResource,
          ),
          oscProvinceTopology(['p1']),
          tileWithResource,
          reason: 'should pick first valid tile, not the empty-resource tile',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      final tileP1 = OscIds.tile('p1', 0, 0);
        final tileP2 = OscIds.tile('p2', 0, 0);
        oscExpectBuildImprovementTargetsTile(
          oscBuilderImprovementGame(
            tileNoResource: tileP1,
            tileWithResource: tileP2,
            secondProvinceLocal: 'p2',
            secondTile: tileP2,
          ),
          oscProvinceTopology(['p1', 'p2']),
          tileP2,
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      oscExpectDualBuilderSuggestSkipsReserved(OscDualBuilderGrainTiles());
    case OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList:
      oscExpectSuggestListType(
          oscSuggestNavalMission(
            oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])),
            oscSeaTopology(['sea1']),
          ),
        );
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList:
      oscExpectSuggestListType(
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
      );
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable:
      oscExpectBuildIncludesShipTypes(
          oscCapitalProvinceGame(oscAffordableShipPlayer()),
          oscCapitalTopology(),
        );
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
      oscExpectBuildIncludesRegimentAndShip(
          oscCapitalProvinceGame(oscAffordableBothPlayer()),
          oscCapitalTopology(),
        );
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
      oscExpectSuggestListType(
          oscSuggestResearch(
            oscGame(
              worldState: oscWorld(),
              players: [oscPlayer(treasury: 1000)],
            ),
            oscEmptyTopology(),
          ),
        );
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
      oscExpectSuggestListType(
          oscSuggestNavalMove(
            oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])),
            oscSeaTopology(
              ['sea1', 'sea2'],
              edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
            ),
          ),
        );
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
      oscExpectWorkTargetNotEmpty(
          oscSuggestWork(oscSpyInOwnedProvinceGame(), oscProvinceTopology(['p1'])),
          kWorkTargetCounterSpy,
        );
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      oscExpectWorkTargetNotEmpty(
          oscSuggestWork(
            oscMerchantPurchaseLandGame(),
            oscProvinceTopology(['p1', 'minor1']),
          ),
          kWorkTargetPurchaseLand,
        );
  }
}
