part of 'order_suggestion_core_expectations.dart';

void _suggestMoveOrdersOnlyReturnsMovesThatPassValidation() {
  oscExpectFoggedDestinationFirstMove();
}

void _suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility() {
  oscExpectMoveThrowsOnUnknownSourceVisibility();
}

void _moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians() {
  oscExpectMislocatedExplorerMoveUsesTileProvince();
}

void _noExploreSuggestionWhenProvinceUnknown() {
  oscExpectNoExploreWhenProvinceUnknown();
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
  oscExpectNoProspectWhenProvinceNotFogged();
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
  oscExpectBuildImprovementOnSecondTileInProvince();
}

void
_suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile() {
  oscExpectBuildImprovementOnOtherOwnedProvince();
}

void
_suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder() {
  oscExpectDualBuilderSuggestSkipsReserved(OscDualBuilderGrainTiles());
}

void _suggestNavalMissionOrdersReturnsList() {
  oscExpectNavalMissionSuggestList();
}
