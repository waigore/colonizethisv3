part of 'work_completion_expectations.dart';

void _buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  wccExpectBasicImprovementCompletion();
}

void _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
  wccExpectImprovementWithEnvyHint();
}

void _buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
  wccExpectAiEnvyEvidenceOnCoalCompletion();
}

void _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax() {
  wccExpectImprovementCapsAtLevel4();
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
  wccExpectBuildRoadLevelIncrease();
}

void _buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  wccExpectBuildRoadCapitalAdjacentPropagation();
}

void _buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  wccExpectBuildRoadPortAdjacentPropagation();
}

void _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  wccExpectBuildPortCompletion();
}

void _buildFortCompletionIncreasesProvinceFortLevel() {
  wccExpectBuildFortCompletion();
}
