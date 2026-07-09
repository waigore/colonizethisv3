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
  oscExpectFirstMove(
    oscSuggestMoves(game, oscTwoProvincesConnected('p1', 'p2')),
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
  oscExpectThrowsSuggestMoveOnUnknownVisibility(game, topology);
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
  oscExpectFirstMove(
    oscSuggestMoves(game, topology),
    destinationTileKey: OscIds.tile('p3', 0, 0),
  );
  expect(
    oscView(game, topology).ownUnitsById['u1']!.locationProvinceId,
    OscIds.prov('p2'),
  );
}

void _noExploreSuggestionWhenProvinceUnknown() {
  oscExpectWorkTargetEmpty(
    oscSuggestWork(oscExplorerProvinceGame(), oscProvinceTopology(['p1'])),
    kWorkTargetExplore,
  );
}

void _suggestWorkOrdersExploreTargetUsesKWorkTargetExplore() {
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

void _suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope() {
  oscExpectExploreTargetsProvince(
    oscPartialRevealExploreCacheGame(),
    oscEmptyTopology(),
    OscIds.prov('p_partial'),
  );
}

void _noProspectSuggestionWhenProvinceNotAtLeastFogged() {
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

void _prospectSuggestionWhenProvinceFoggedAndTilesInProvince() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscGame(
    worldState: oscExplorerProvinceGame(
      visibilityByTile: {tileKey: 'fogged'},
      tilesByLocal: {'p1': [tileKey]},
    ).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),
  );
  final suggestions = oscSuggestWork(game, oscProvinceTopology(['p1']));
  oscExpectWorkTargetNotEmpty(suggestions, kWorkTargetProspect);
  expect(
    oscWorkWithTarget(suggestions, kWorkTargetProspect).first.targetTileKey,
    tileKey,
  );
}

void _playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder() {
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

void
_getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder() {
  oscExpectDualBuilderVisKeysExcludeReserved(OscDualBuilderGrainTiles());
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
  final topology = oscProvinceTopology(['p1']);
  final suggestions = oscSuggestWork(game, topology);
  for (final o in suggestions) {
    expect(o.unitId, 'u1');
    final u = oscView(game, topology).ownUnitsById[o.unitId];
    expect(u, isNotNull);
    expect(u!.locationProvinceId, OscIds.prov('p1'));
  }
}

void
_suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes() {
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

void
_suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile() {
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

void
_suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder() {
  oscExpectDualBuilderSuggestSkipsReserved(OscDualBuilderGrainTiles());
}

void _suggestNavalMissionOrdersReturnsList() {
  oscExpectSuggestListType(
    oscSuggestNavalMission(
      oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])),
      oscSeaTopology(['sea1']),
    ),
  );
}
