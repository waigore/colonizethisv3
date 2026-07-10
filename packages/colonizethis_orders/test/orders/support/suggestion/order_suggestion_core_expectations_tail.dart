// Tail expectation dispatch cases (Refs #3949).

import 'order_suggestion_core_expectation_shorthand.dart';
import 'order_suggestion_core_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'order_suggestion_core_expectations.dart' show OrderSuggestionCoreTarget;

void runOrderSuggestionCoreExpectationTail(OrderSuggestionCoreTarget target) {
  switch (target) {
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
      final counterSpyTile = OscIds.tile('p1', 0, 0);
      oscExpectWorkTargetSuggestions(
        game: oscGame(
          worldState: oscWorld(
            oldWorld: RegionData(
              provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeSpy,
                  ownerId: OscIds.playerId,
                  locationProvinceId: OscIds.prov('p1'),
                ),
              ],
            ),
            playerVisibilityByTile: oscVisibility({counterSpyTile: 'fullyVisible'}),
            tileKeysByRegionAndProvince:
                oscTilesByProvince({'p1': [counterSpyTile]}),
          ),
        ),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetCounterSpy,
        expectNonEmpty: true,
      );
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      final purchaseTile = OscIds.tile('minor1', 0, 0);
      oscExpectWorkTargetSuggestions(
        game: oscGame(
          worldState: oscWorld(
            oldWorld: RegionData(
              provinces: [
                oscProvince('p1', ownerId: OscIds.playerId),
                oscProvince('minor1', ownerId: 'minor1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeMerchant,
                  ownerId: OscIds.playerId,
                  locationProvinceId: OscIds.prov('p1'),
                ),
              ],
            ),
            playerVisibilityByTile: oscVisibility({
              OscIds.tile('p1', 0, 0): 'fullyVisible',
              purchaseTile: 'fullyVisible',
            }),
            tileKeysByRegionAndProvince: oscTilesByProvince({
              'p1': [OscIds.tile('p1', 0, 0)],
              'minor1': [purchaseTile],
            }),
            resourceByTileKey: {purchaseTile: 'grain'},
          ),
          players: [oscPlayer(treasury: 500)],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
          overtureStates: const [
            OvertureState(
              gpId: OscIds.playerId,
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        ),
        topology: oscProvinceTopology(['p1', 'minor1']),
        target: kWorkTargetPurchaseLand,
        expectNonEmpty: true,
      );
    default:
      throw StateError('Unexpected OrderSuggestionCoreTarget for tail dispatch: $target');
  }
}
