part of 'order_suggestion_core_expectation_shorthand.dart';

void oscExpectFoggedExploreSuggestion() {
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
}

void oscExpectFoggedProspectTargetsIron() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscGame(
    worldState: oscExplorerProvinceGame(
      visibilityByTile: {tileKey: 'fogged'},
      tilesByLocal: {'p1': [tileKey]},
    ).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),
  );
  oscExpectProspectTargetsTile(game, oscProvinceTopology(['p1']), tileKey);
}

void oscExpectProvinceViewForProspectIteration() {
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
  oscExpectProvinceViewMatchesAll(game, oscProvinceTopology(['p1', 'p2']));
}

Game oscBuilderWorkerSuggestGame() {
  final tileKey = OscIds.tile('p1', 0, 0);
  return oscGame(
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
}

void oscExpectProspectTargetsTile(
  Game game,
  MapTopology topology,
  String tileKey,
) {
  final suggestions = oscSuggestWork(game, topology);
  oscExpectWorkTargetNotEmpty(suggestions, kWorkTargetProspect);
  expect(
    oscWorkWithTarget(suggestions, kWorkTargetProspect).first.targetTileKey,
    tileKey,
  );
}

void oscExpectWorkerSuggestStayInProvince(Game game, MapTopology topology) {
  final suggestions = oscSuggestWork(game, topology);
  for (final o in suggestions) {
    expect(o.unitId, 'u1');
    final u = oscView(game, topology).ownUnitsById[o.unitId];
    expect(u, isNotNull);
    expect(u!.locationProvinceId, OscIds.prov('p1'));
  }
}

void oscExpectMerchantPurchaseLandWorkSuggested() {
  oscExpectWorkTargetNotEmpty(
    oscSuggestWork(
      oscMerchantPurchaseLandGame(),
      oscProvinceTopology(['p1', 'minor1']),
    ),
    kWorkTargetPurchaseLand,
  );
}

void oscExpectCapitalBuildSuggestList(Player player) {
  oscExpectSuggestListType(
    oscSuggestBuild(oscCapitalProvinceGame(player), oscCapitalTopology()),
  );
}

void oscExpectAffordableShipBuildSuggestions() {
  oscExpectBuildIncludesShipTypes(
    oscCapitalProvinceGame(oscAffordableShipPlayer()),
    oscCapitalTopology(),
  );
}

void oscExpectAffordableRegimentAndShipBuildSuggestions() {
  oscExpectBuildIncludesRegimentAndShip(
    oscCapitalProvinceGame(oscAffordableBothPlayer()),
    oscCapitalTopology(),
  );
}

void oscExpectResearchSuggestList() {
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

void oscExpectNavalMoveSuggestList() {
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

void oscExpectNavalMissionSuggestList() {
  oscExpectSuggestListType(
    oscSuggestNavalMission(
      oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])),
      oscSeaTopology(['sea1']),
    ),
  );
}

Game oscMerchantPurchaseLandGame() {
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

void oscExpectFoggedDestinationFirstMove() {
  final game = oscFoggedDestinationMoveGame();
  oscExpectFirstMove(
    oscSuggestMoves(game, oscTwoProvincesConnected('p1', 'p2')),
    destinationTileKey: OscIds.tile('p2', 0, 0),
  );
}

void oscExpectMislocatedExplorerMoveUsesTileProvince() {
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
}

void oscExpectNoExploreWhenProvinceUnknown() {
  oscExpectWorkTargetEmpty(
    oscSuggestWork(oscExplorerProvinceGame(), oscProvinceTopology(['p1'])),
    kWorkTargetExplore,
  );
}

void oscExpectNoProspectWhenProvinceNotFogged() {
  oscExpectWorkTargetEmpty(
    oscSuggestWork(
      oscExplorerProvinceGame(
        ownerId: 'tribe1',
        visibilityByTile: {OscIds.tile('p1', 0, 0): 'unknown'},
      ),
      oscProvinceTopology(['p1']),
    ),
    kWorkTargetProspect,
  );
}

void oscExpectBuildImprovementOnSecondTileInProvince() {
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
}

void oscExpectBuildImprovementOnOtherOwnedProvince() {
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
}
