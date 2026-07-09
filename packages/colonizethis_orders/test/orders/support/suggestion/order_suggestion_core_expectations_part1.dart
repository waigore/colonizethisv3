part of 'order_suggestion_core_expectations.dart';

void _suggestMoveOrdersOnlyReturnsMovesThatPassValidation() {
  final game = oscFoggedDestinationMoveGame();
  oscExpectFirstMove(
    oscSuggestMoves(game, oscTwoProvincesConnected('p1', 'p2')),
    destinationTileKey: OscIds.tile('p2', 0, 0),
  );
}

void _suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility() {
  oscExpectMoveThrowsOnUnknownSourceVisibility();
}

void _moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians() {
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

void _noExploreSuggestionWhenProvinceUnknown() {
  oscExpectWorkTargetEmpty(
    oscSuggestWork(oscExplorerProvinceGame(), oscProvinceTopology(['p1'])),
    kWorkTargetExplore,
  );
}

void _suggestWorkOrdersExploreTargetUsesKWorkTargetExplore() {
  oscExpectFoggedExploreSuggestion();
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
  oscExpectFoggedProspectTargetsIron();
}

void _playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder() {
  oscExpectProvinceViewForProspectIteration();
}

void
_getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder() {
  oscExpectDualBuilderVisKeysExcludeReserved(OscDualBuilderGrainTiles());
}

void _workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile() {
  oscExpectWorkerSuggestStayInProvince(
    oscBuilderWorkerSuggestGame(),
    oscProvinceTopology(['p1']),
  );
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
