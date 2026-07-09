part of 'work_completion_expectations.dart';

void _buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  final next = wccApply(wccBuilderImprovementAtLevel(0));
  wccExpectImprovement(next, 1);
  wccExpectUnitIdleCleared(next);
}

void _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
  wccExpectImprovementWithEnvyHint();
}

void _buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
  wccExpectAiEnvyEvidenceOnCoalCompletion();
}

void _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax() {
  final next = wccApply(
    wccGame(
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
  );
  wccExpectImprovement(next, 4);
}

void _buildImprovementCompletionDoesNotReApplyExtractionTechCap1291() {
  wccExpectSawMillCapStillAllowsLevel4();
}

void _workCancelledWhenProvinceContainingTargetTileIsConquered376() {
  wccExpectConqueredProvinceCancelsWork();
}

void _multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero() {
  wccExpectTwoTurnImprovementCompletesOnSecondApply();
}

void _exploreCompletionSetsVisibilityAndClearsCurrentWork() {
  wccExpectExploreSetsVisibility();
}

void _exploreCompletionRevealsEveryTileInCanonicalFullIdBucket() {
  wccExpectExploreRevealsBucketOnly();
}

void _buildRoadCompletionIncreasesRoadLevel() {
  final next = wccApply(
    wccEngineerCompletionGame(
      workTarget: kWorkTargetBuildRoad,
      tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, 0),
    ),
    tileMapByRegion: const {},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
}

void _buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  const capitalTileKey = WorkAppIds.originTileKey;
  final next = wccApply(
    wccBuildRoadCapitalAdjacentGame(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
  wccExpectRoadLevel(next, capitalTileKey, 2);
}

void _buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  const portTileKey = WorkAppIds.originTileKey;
  final next = wccApply(
    wccBuildRoadPortAdjacentGame(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 2);
  wccExpectRoadLevel(next, portTileKey, 2);
}

void _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  final next = wccApply(
    wccEngineerCompletionGame(workTarget: kWorkTargetBuildPort),
    topology: wccPortSeaTopology(),
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
  wccExpectPortRegisteredForProvince(next);
}

void _buildFortCompletionIncreasesProvinceFortLevel() {
  final next = wccApply(
    wccEngineerCompletionGame(
      workTarget: kWorkTargetBuildFort,
      provinces: [workAppOwnedProvince(fortLevel: 0)],
    ),
  );
  wccExpectFortLevel(next, 1);
}
