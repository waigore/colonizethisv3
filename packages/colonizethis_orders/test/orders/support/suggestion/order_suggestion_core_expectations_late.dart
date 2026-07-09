part of 'order_suggestion_core_expectations.dart';

void oscLateSuggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable() {
  final bothTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
  final bothStockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 5)
      .applyDelta(CommodityCatalog.fabric.id, 5)
      .applyDelta(CommodityCatalog.castIron.id, 5);
  final game = oscCapitalProvinceGame(
    oscPlayer(
      capitalProvinceId: OscIds.prov('p1'),
      workerPool: const WorkerPool(peasants: 2, apprentices: 1),
      treasury: bothTreasury,
      stockpile: bothStockpile,
    ),
  );
  final topology = oscCapitalTopology();
  final suggestions = oscSuggestBuild(game, topology);
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

void oscLateSuggestResearchOrdersReturnsList() {
  final researchGame = oscGame(
    worldState: oscWorld(),
    players: [oscPlayer(treasury: 1000)],
  );
  final researchTopology = oscEmptyTopology();
  expect(
    suggestResearchOrders(
      oscView(researchGame, researchTopology),
      researchGame,
      researchTopology,
      const Orders(),
    ),
    isA<List<ResearchOrder>>(),
  );
}

void oscLateSuggestNavalMoveOrdersReturnsList() {
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
}

void oscLateCounterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
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
  expect(
    oscWorkWithTarget(
      oscSuggestWork(game, oscProvinceTopology(['p1'])),
      kWorkTargetCounterSpy,
    ),
    isNotEmpty,
  );
}

void oscLatePurchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
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
  expect(
    oscWorkWithTarget(
      oscSuggestWork(
        game,
        oscProvinceTopology(['p1', 'minor1']),
      ),
      kWorkTargetPurchaseLand,
    ),
    isNotEmpty,
  );
}
