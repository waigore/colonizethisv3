part of 'order_suggestion_core_expectation_shorthand.dart';

List<MoveOrder> oscSuggestMoves(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    suggestMoveOrders(oscView(game, topology), game, topology, orders);

List<WorkOrder> oscSuggestWork(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    suggestWorkOrders(oscView(game, topology), game, topology, orders);

void oscExpectMoveSuggestOne(
  Game game,
  MapTopology topology, {
  required String destTileKey,
  String unitId = 'u1',
}) {
  final moves = oscSuggestMoves(game, topology);
  expect(moves.length, 1);
  expect(moves.first.unitId, unitId);
  expect(moves.first.destinationTileKey, destTileKey);
}

void oscExpectWorkTargetSuggestions({
  required Game game,
  required MapTopology topology,
  required String target,
  required bool expectNonEmpty,
  String? expectedTileKey,
  Orders orders = const Orders(),
}) {
  final ordersForTarget = oscWorkWithTarget(
    oscSuggestWork(game, topology, orders),
    target,
  ).toList();
  expect(ordersForTarget, expectNonEmpty ? isNotEmpty : isEmpty);
  if (expectedTileKey != null && expectNonEmpty) {
    expect(ordersForTarget.first.targetTileKey, expectedTileKey);
  }
}

void oscExpectBuildImprovementFirstTile({
  required Game game,
  required MapTopology topology,
  required String expectedTileKey,
  Orders orders = const Orders(),
  String unitId = 'b2',
}) {
  final buildImp = oscWorkWithTarget(
    oscSuggestWork(game, topology, orders),
    kWorkTargetBuildImprovement,
  ).where((o) => o.unitId == unitId).toList();
  expect(buildImp, isNotEmpty);
  expect(buildImp.first.targetTileKey, expectedTileKey);
}

List<BuildUnitOrder> oscSuggestBuild(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    suggestBuildOrders(oscView(game, topology), game, topology, orders);

Iterable<WorkOrder> oscWorkWithTarget(
  List<WorkOrder> suggestions,
  String target,
) =>
    suggestions.where((o) => o.target == target);

Game oscExplorerProvinceGame({
  String provinceLocal = 'p1',
  String? ownerId = OscIds.playerId,
  Map<String, String>? visibilityByTile,
  Map<String, List<String>>? tilesByLocal,
  List<String>? extraProvinceLocals,
  List<String>? extraOwners,
}) {
  final provinces = [
    oscProvince(provinceLocal, ownerId: ownerId),
    for (var i = 0; i < (extraProvinceLocals?.length ?? 0); i++)
      oscProvince(
        extraProvinceLocals![i],
        ownerId: extraOwners != null && i < extraOwners.length
            ? extraOwners[i]
            : ownerId,
      ),
  ];
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: provinces,
        units: [oscExplorer(provinceLocal: provinceLocal)],
      ),
      playerVisibilityByTile:
          visibilityByTile != null ? oscVisibility(visibilityByTile) : null,
      tileKeysByRegionAndProvince:
          tilesByLocal != null ? oscTilesByProvince(tilesByLocal) : null,
    ),
  );
}

Game oscBuilderImprovementGame({
  required String tileNoResource,
  required String tileWithResource,
  String provinceLocal = 'p1',
  String? secondProvinceLocal,
  String? secondTile,
  String resource = 'grain',
}) {
  final provinces = [
    oscProvince(provinceLocal, ownerId: OscIds.playerId),
    if (secondProvinceLocal != null)
      oscProvince(secondProvinceLocal, ownerId: OscIds.playerId),
  ];
  final tilesByLocal = {
    provinceLocal: secondProvinceLocal == null
        ? [tileNoResource, tileWithResource]
        : [tileNoResource],
    if (secondProvinceLocal != null && secondTile != null)
      secondProvinceLocal: [secondTile],
  };
  final visibility = {
    tileNoResource: 'fullyVisible',
    tileWithResource: 'fullyVisible',
    if (secondTile != null) secondTile: 'fullyVisible',
  };
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: provinces,
        units: [
          oscBuilder(provinceLocal: provinceLocal, tileKey: tileNoResource),
        ],
      ),
      playerVisibilityByTile: oscVisibility(visibility),
      tileKeysByRegionAndProvince: oscTilesByProvince(tilesByLocal),
      resourceByTileKey: {
        tileWithResource: resource,
        if (secondTile != null) secondTile: resource,
      },
      tileState: TileMapState(
        improvementByTile: {
          tileWithResource: 0,
          if (secondTile != null) secondTile: 0,
        },
      ),
    ),
    players: [oscBuilderPlayer()],
  );
}

void oscExpectBothRegimentAndShipWhenAffordable() {
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

void oscExpectResearchOrdersReturnsList() {
  final game = oscGame(
    worldState: oscWorld(),
    players: [oscPlayer(treasury: 1000)],
  );
  final topology = oscEmptyTopology();
  expect(
    suggestResearchOrders(
      oscView(game, topology),
      game,
      topology,
      const Orders(),
    ),
    isA<List<ResearchOrder>>(),
  );
}

void oscExpectNavalMoveOrdersReturnsList() {
  final game = oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]));
  final topology = oscSeaTopology(
    ['sea1', 'sea2'],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  expect(
    suggestNavalMoveOrders(
      oscView(game, topology),
      game,
      topology,
      const Orders(),
    ),
    isA<List<NavalMoveOrder>>(),
  );
}

Game oscSpyCounterSuggestGame() {
  final tileKey = OscIds.tile('p1', 0, 0);
  return oscGame(
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
}

Game oscMerchantPurchaseLandSuggestGame() {
  final tileKey = OscIds.tile('minor1', 0, 0);
  return oscGame(
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
}
