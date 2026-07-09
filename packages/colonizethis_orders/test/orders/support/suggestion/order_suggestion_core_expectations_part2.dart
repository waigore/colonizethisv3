part of 'order_suggestion_core_expectations.dart';


void _suggestBuildOrdersReturnsList() {
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
  );
  final game = oscCapitalProvinceGame(player);
  final topology = oscCapitalTopology();
  final view = oscView(game, topology);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
  expect(suggestions, isA<List<BuildUnitOrder>>());
}

void _suggestBuildOrdersReturnsShipWhenAffordable() {
  final affordableShipTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 2)
      .applyDelta(CommodityCatalog.fabric.id, 2);
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 1),
    treasury: affordableShipTreasury,
    stockpile: stockpile,
  );
  final game = oscCapitalProvinceGame(player);
  final topology = oscCapitalTopology();
  final view = oscView(game, topology);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
  final shipTypes = suggestions
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
  final affordableBothTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 5)
      .applyDelta(CommodityCatalog.fabric.id, 5)
      .applyDelta(CommodityCatalog.castIron.id, 5);
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2, apprentices: 1),
    treasury: affordableBothTreasury,
    stockpile: stockpile,
  );
  final game = oscCapitalProvinceGame(player);
  final topology = oscCapitalTopology();
  final view = oscView(game, topology);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
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
  final topology = oscEmptyTopology();
  final view = oscView(game, topology);
  final suggestions = suggestResearchOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<ResearchOrder>>());
}

void _suggestNavalMoveOrdersReturnsList() {
  final game = oscGame(
    worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]),
  );
  final topology = oscSeaTopology(
    ['sea1', 'sea2'],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  final view = oscView(game, topology);
  final suggestions = suggestNavalMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<NavalMoveOrder>>());
}

void _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscGame(
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
      playerVisibilityByTile: oscVisibility({tileKey: 'fullyVisible'}),
      tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tileKey]}),
    ),
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetCounterSpy),
    isNotEmpty,
  );
}

void _purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
  final tileKey = OscIds.tile('minor1', 0, 0);
  final game = oscGame(
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
        tileKey: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [OscIds.tile('p1', 0, 0)],
        'minor1': [tileKey],
      }),
      resourceByTileKey: {tileKey: 'grain'},
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
  );
  final topology = oscProvinceTopology(['p1', 'minor1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetPurchaseLand),
    isNotEmpty,
  );
}
