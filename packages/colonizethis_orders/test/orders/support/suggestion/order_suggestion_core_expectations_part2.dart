part of 'order_suggestion_core_expectations.dart';

void _suggestBuildOrdersReturnsList() {
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
  );
  final game = oscCapitalProvinceGame(player);
  expect(
    oscSuggestBuild(game, oscCapitalTopology()),
    isA<List<BuildUnitOrder>>(),
  );
}

void _suggestBuildOrdersReturnsShipWhenAffordable() {
  final game = oscCapitalProvinceGame(oscAffordableShipPlayer());
  final shipTypes = oscSuggestBuild(game, oscCapitalTopology())
      .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
      .toList();
  expect(
    shipTypes,
    isNotEmpty,
    reason:
        'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
  );
}

void _suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable() {
  final game = oscCapitalProvinceGame(oscAffordableBothPlayer());
  final suggestions = oscSuggestBuild(game, oscCapitalTopology());
  expect(
    suggestions.any((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType)),
    isTrue,
    reason: 'should suggest regiments when affordable',
  );
  expect(
    suggestions.any((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)),
    isTrue,
    reason: 'should suggest ships when affordable',
  );
}

void _suggestResearchOrdersReturnsList() {
  final game = oscGame(
    worldState: oscWorld(),
    players: [oscPlayer(treasury: 1000)],
  );
  expect(
    oscSuggestResearch(game, oscEmptyTopology()),
    isA<List<ResearchOrder>>(),
  );
}

void _suggestNavalMoveOrdersReturnsList() {
  final game = oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]));
  expect(
    oscSuggestNavalMove(
      game,
      oscSeaTopology(
        ['sea1', 'sea2'],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      ),
    ),
    isA<List<NavalMoveOrder>>(),
  );
}

void _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  final game = oscSpyInOwnedProvinceGame();
  oscExpectWorkTargetNotEmpty(
    oscSuggestWork(game, oscProvinceTopology(['p1'])),
    kWorkTargetCounterSpy,
  );
}

void _purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
  oscExpectWorkTargetNotEmpty(
    oscSuggestWork(
      oscMerchantPurchaseLandGame(),
      oscProvinceTopology(['p1', 'minor1']),
    ),
    kWorkTargetPurchaseLand,
  );
}
