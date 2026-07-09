part of 'order_suggestion_core_expectations.dart';

void _suggestBuildOrdersReturnsList() {
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
  );
  oscExpectSuggestListType(
    oscSuggestBuild(oscCapitalProvinceGame(player), oscCapitalTopology()),
  );
}

void _suggestBuildOrdersReturnsShipWhenAffordable() {
  oscExpectBuildIncludesShipTypes(
    oscCapitalProvinceGame(oscAffordableShipPlayer()),
    oscCapitalTopology(),
  );
}

void _suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable() {
  oscExpectBuildIncludesRegimentAndShip(
    oscCapitalProvinceGame(oscAffordableBothPlayer()),
    oscCapitalTopology(),
  );
}

void _suggestResearchOrdersReturnsList() {
  oscExpectSuggestListType(
    oscSuggestResearch(
      oscGame(
        worldState: oscWorld(),
        players: [oscPlayer(treasury: 1000)],
      ),
      oscEmptyTopology(),
    ),
  );
}

void _suggestNavalMoveOrdersReturnsList() {
  oscExpectSuggestListType(
    oscSuggestNavalMove(
      oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])),
      oscSeaTopology(
        ['sea1', 'sea2'],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      ),
    ),
  );
}

void _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  oscExpectWorkTargetNotEmpty(
    oscSuggestWork(oscSpyInOwnedProvinceGame(), oscProvinceTopology(['p1'])),
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
