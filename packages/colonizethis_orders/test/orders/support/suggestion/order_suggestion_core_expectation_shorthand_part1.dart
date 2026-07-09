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

void oscExpectMovePassesValidationToAdjacentProvince() {
  oscExpectMoveSuggestOne(
    oscGame(
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
    ),
    oscTwoProvincesConnected('p1', 'p2'),
    destTileKey: OscIds.tile('p2', 0, 0),
  );
}

void oscExpectMoveThrowsWhenSourceProvinceUnknown() {
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
  expect(
    () => suggestMoveOrders(
      oscView(game, oscTwoProvincesConnected('p1', 'p2')),
      game,
      oscTwoProvincesConnected('p1', 'p2'),
      const Orders(),
    ),
    throwsStateError,
  );
}

void oscExpectCivilianMoveUsesTileKeyDerivedLocation() {
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

void oscExpectExploreTargetUsesExplore() {
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
}

void oscExpectPartialRevealExploreCacheScope() {
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
}

void oscExpectProvinceViewMatchesAllForProspect() {
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
}

void oscExpectReservedTileExcludedFromValidKeys() {
  final setup = OscDualBuilderGrainTiles();
  final validB2 = getValidWorkOrderTileKeysWithVisibility(
    game: setup.game(),
    topology: setup.topology(),
    view: oscView(setup.game(), setup.topology()),
    unitId: 'b2',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: setup.ordersReservingTileA(),
  );
  expect(validB2, isNot(contains(setup.tileA)));
  expect(validB2, contains(setup.tileB));
}

void oscExpectWorkerSuggestionsUseUnitLocation() {
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
  for (final o in oscSuggestWork(workerGame, workerTopology)) {
    expect(o.unitId, 'u1');
    final u = oscView(workerGame, workerTopology).ownUnitsById[o.unitId];
    expect(u, isNotNull);
    expect(u!.locationProvinceId, OscIds.prov('p1'));
  }
}

void oscExpectNavalMissionOrdersReturnsList() {
  final game = oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]));
  final topology = oscSeaTopology(['sea1']);
  expect(
    suggestNavalMissionOrders(
      oscView(game, topology),
      game,
      topology,
      const Orders(),
    ),
    isA<List<NavalMissionOrder>>(),
  );
}

void oscExpectBuildOrdersReturnsList() {
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
}

void oscExpectBuildOrdersReturnsShipWhenAffordable() {
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
}
