part of 'work_completion_expectations.dart';

void _buildRailCompletionLeavesRoadWhenTileHasNoRoad() {
  wccExpectRailCompletionLeavesRoadWhenTileHasNoRoad();
}

void _buildRailCompletionSetsRoadLevelTo4WhenValid() {
  wccExpectRailCompletionSetsRoadLevelTo4WhenValid();
}

void _routesKWorkTargetBuildRailThroughHandlerMapEntry() {
  wccExpectRailDispatchSetsRoadLevel(
    roadLevel: 1,
    players: wccSteamPlayers(),
    expectedLevel: 4,
  );
}

void _buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies() {
  wccExpectRailDispatchSetsRoadLevel(
    roadLevel: 0,
    players: [workAppPlayer()],
    expectedLevel: 0,
  );
}

void _upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord() {
  wccExpectUpgradeTownProvinceLevel();
}

void _exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord() {
  wccExpectExploreDispatchCapturesRegion();
}
