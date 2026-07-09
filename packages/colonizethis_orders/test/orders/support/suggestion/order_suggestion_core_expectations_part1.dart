part of 'order_suggestion_core_expectations.dart';

void _suggestMoveOrdersOnlyReturnsMovesThatPassValidation() {
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
  final topology = oscTwoProvincesConnected('p1', 'p2');
  oscExpectFirstMove(
    oscSuggestMoves(game, topology),
    destinationTileKey: OscIds.tile('p2', 0, 0),
  );
}

void _suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility() {
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

void _moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians() {
  final unit = oscExplorer(provinceLocal: 'p1', tileKey: OscIds.tile('p2', 0, 0));
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
  final suggestions = oscSuggestMoves(game, topology);
  oscExpectFirstMove(
    suggestions,
    destinationTileKey: OscIds.tile('p3', 0, 0),
  );
  expect(
    oscView(game, topology).ownUnitsById['u1']!.locationProvinceId,
    OscIds.prov('p2'),
  );
}

void _noExploreSuggestionWhenProvinceUnknown() {
  final game = oscExplorerProvinceGame();
  final topology = oscProvinceTopology(['p1']);
  oscExpectWorkTargetEmpty(
    oscSuggestWork(game, topology),
    kWorkTargetExplore,
  );
}

void _suggestWorkOrdersExploreTargetUsesKWorkTargetExplore() {
  final t0 = OscIds.tile('p1', 0, 0);
  final t1 = OscIds.tile('p1', 1, 0);
  final game = oscExplorerProvinceGame(
    visibilityByTile: {t0: 'fullyVisible', t1: 'unknown'},
    tilesByLocal: {'p1': [t0, t1]},
  );
  oscExpectWorkTargetNotEmpty(
    oscSuggestWork(game, oscProvinceTopology(['p1'])),
    kWorkTargetExplore,
  );
}

void _suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope() {
  final partialProvince = OscIds.prov('p_partial');
  final fullyKnownProvince = OscIds.prov('p_known');
  final partialKnownTile = OscIds.tile('p_partial', 0, 0);
  final partialUnknownTile = OscIds.tile('p_partial', 1, 0);
  final knownTile = OscIds.tile('p_known', 0, 0);

  final game = oscGame(
    id: 'g-cache-scope',
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p_partial', ownerId: 'tribe1'),
          oscProvince('p_known', ownerId: 'tribe1'),
        ],
        units: [
          oscExplorer(provinceLocal: 'p_partial', tileKey: partialKnownTile),
        ],
      ),
      playerVisibilityByTile: oscVisibility({
        partialKnownTile: 'fogged',
        partialUnknownTile: 'unknown',
        knownTile: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: {
        OscIds.ow: {
          partialProvince: [partialKnownTile, partialUnknownTile],
          fullyKnownProvince: [knownTile],
        },
      },
    ),
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    overtureStates: const [
      OvertureState(
        gpId: OscIds.playerId,
        targetId: 'tribe1',
        stage: OvertureStage.tradeConsulate,
      ),
    ],
  );
  final explore = oscWorkWithTarget(
    oscSuggestWork(game, oscEmptyTopology()),
    kWorkTargetExplore,
  );
  expect(explore, isNotEmpty);
  expect(
    Unit.provinceIdFromTileKey(explore.first.targetTileKey),
    partialProvince,
  );
}

void _noProspectSuggestionWhenProvinceNotAtLeastFogged() {
  final game = oscExplorerProvinceGame(
    ownerId: 'tribe1',
    visibilityByTile: {OscIds.tile('p1', 0, 0): 'unknown'},
  );
  oscExpectWorkTargetEmpty(
    oscSuggestWork(game, oscProvinceTopology(['p1'])),
    kWorkTargetProspect,
  );
}

void _prospectSuggestionWhenProvinceFoggedAndTilesInProvince() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscExplorerProvinceGame(
    visibilityByTile: {tileKey: 'fogged'},
    tilesByLocal: {'p1': [tileKey]},
  );
  final gameWithResource = oscGame(
    worldState: game.worldState.copyWith(
      resourceByTileKey: {tileKey: 'iron'},
    ),
  );
  final suggestions = oscSuggestWork(
    gameWithResource,
    oscProvinceTopology(['p1']),
  );
  oscExpectWorkTargetNotEmpty(suggestions, kWorkTargetProspect);
  expect(
    oscWorkWithTarget(suggestions, kWorkTargetProspect).first.targetTileKey,
    tileKey,
  );
}

void _playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder() {
  final game = oscExplorerProvinceGame(
    extraProvinceLocals: ['p2'],
    extraOwners: ['minor1'],
    visibilityByTile: {OscIds.tile('p1', 0, 0): 'fogged'},
    tilesByLocal: {
      'p1': [OscIds.tile('p1', 0, 0)],
      'p2': [OscIds.tile('p2', 0, 0)],
    },
  );
  final gameWithMinor = oscGame(
    worldState: game.worldState,
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
  final topology = oscProvinceTopology(['p1', 'p2']);
  final fromAll = allProvinces(gameWithMinor.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final fromView = oscView(gameWithMinor, topology).provincesById.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  expect(fromView.length, fromAll.length);
  expect(fromView.map((p) => p.id).toList(), fromAll.map((p) => p.id).toList());
}

void
_getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder() {
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
}

void _workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscGame(
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
  final suggestions = oscSuggestWork(game, oscProvinceTopology(['p1']));
  for (final o in suggestions) {
    expect(o.unitId, 'u1');
    final u = oscView(game, oscProvinceTopology(['p1'])).ownUnitsById[o.unitId];
    expect(u, isNotNull);
    expect(u!.locationProvinceId, OscIds.prov('p1'));
  }
}

void
_suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes() {
  final tileNoResource = OscIds.tile('p1', 0, 0);
  final tileWithResource = OscIds.tile('p1', 1, 0);
  final game = oscBuilderImprovementGame(
    tileNoResource: tileNoResource,
    tileWithResource: tileWithResource,
  );
  final buildImp = oscWorkWithTarget(
    oscSuggestWork(game, oscProvinceTopology(['p1'])),
    kWorkTargetBuildImprovement,
  );
  expect(buildImp, isNotEmpty);
  expect(
    buildImp.first.targetTileKey,
    tileWithResource,
    reason: 'should pick first valid tile, not the empty-resource tile',
  );
}

void
_suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile() {
  final tileP1 = OscIds.tile('p1', 0, 0);
  final tileP2 = OscIds.tile('p2', 0, 0);
  final game = oscBuilderImprovementGame(
    tileNoResource: tileP1,
    tileWithResource: tileP2,
    secondProvinceLocal: 'p2',
    secondTile: tileP2,
  );
  final buildImp = oscWorkWithTarget(
    oscSuggestWork(game, oscProvinceTopology(['p1', 'p2'])),
    kWorkTargetBuildImprovement,
  );
  expect(buildImp, isNotEmpty);
  expect(buildImp.first.targetTileKey, tileP2);
}

void
_suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder() {
  final setup = OscDualBuilderGrainTiles();
  final game = setup.game();
  final topology = setup.topology();
  final b2Build = oscWorkWithTarget(
    oscSuggestWork(game, topology, setup.ordersReservingTileA()),
    kWorkTargetBuildImprovement,
  ).where((o) => o.unitId == 'b2').toList();
  expect(b2Build, isNotEmpty);
  expect(b2Build.first.targetTileKey, setup.tileB);
}

void _suggestNavalMissionOrdersReturnsList() {
  final game = oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]));
  expect(
    oscSuggestNavalMission(game, oscSeaTopology(['sea1'])),
    isA<List<NavalMissionOrder>>(),
  );
}
