// Compact applyBuildAndWorkOrders work-completion assertions (Refs #3949 wave 3).

import 'work_completion_expectation_shorthand.dart';

/// Pins for [workCompletionScenarios] rows.
enum WorkCompletionTarget {
  buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork,
  buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile,
  buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint,
  buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax,
  buildImprovementCompletionDoesNotReApplyExtractionTechCap1291,
  workCancelledWhenProvinceContainingTargetTileIsConquered376,
  multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero,
  exploreCompletionSetsVisibilityAndClearsCurrentWork,
  exploreCompletionRevealsEveryTileInCanonicalFullIdBucket,
  buildRoadCompletionIncreasesRoadLevel,
  buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade,
  buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt,
  buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea,
  buildFortCompletionIncreasesProvinceFortLevel,
  buildRailCompletionLeavesRoadWhenTileHasNoRoad,
  buildRailCompletionSetsRoadLevelTo4WhenValid,
  routesKWorkTargetBuildRailThroughHandlerMapEntry,
  buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies,
  upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord,
  exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord,
}

void runWorkCompletionExpectation(WorkCompletionTarget target) {
  switch (target) {
    case WorkCompletionTarget
        .buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork:
      wccExpectBasicImprovementCompletion();
    case WorkCompletionTarget
        .buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile:
      wccExpectImprovementWithEnvyHint();
    case WorkCompletionTarget
        .buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint:
      wccExpectAiEnvyEvidenceOnCoalCompletion();
    case WorkCompletionTarget
        .buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax:
      wccExpectImprovementCapsAtLevel4();
    case WorkCompletionTarget
        .buildImprovementCompletionDoesNotReApplyExtractionTechCap1291:
      wccExpectSawMillCapStillAllowsLevel4();
    case WorkCompletionTarget
        .workCancelledWhenProvinceContainingTargetTileIsConquered376:
      wccExpectConqueredProvinceCancelsWork();
    case WorkCompletionTarget
        .multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero:
      wccExpectTwoTurnImprovementCompletesOnSecondApply();
    case WorkCompletionTarget
        .exploreCompletionSetsVisibilityAndClearsCurrentWork:
      wccExpectExploreSetsVisibility();
    case WorkCompletionTarget
        .exploreCompletionRevealsEveryTileInCanonicalFullIdBucket:
      wccExpectExploreRevealsBucketOnly();
    case WorkCompletionTarget.buildRoadCompletionIncreasesRoadLevel:
      wccExpectBuildRoadLevelIncrease();
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade:
      wccExpectBuildRoadCapitalAdjacentPropagation();
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt:
      wccExpectBuildRoadPortAdjacentPropagation();
    case WorkCompletionTarget
        .buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea:
      wccExpectBuildPortCompletion();
    case WorkCompletionTarget.buildFortCompletionIncreasesProvinceFortLevel:
      wccExpectBuildFortCompletion();
    case WorkCompletionTarget.buildRailCompletionLeavesRoadWhenTileHasNoRoad:
      wccExpectRailCompletionLeavesRoadWhenTileHasNoRoad();
    case WorkCompletionTarget.buildRailCompletionSetsRoadLevelTo4WhenValid:
      wccExpectRailCompletionSetsRoadLevelTo4WhenValid();
    case WorkCompletionTarget.routesKWorkTargetBuildRailThroughHandlerMapEntry:
      wccExpectRailDispatchSteamAccepted();
    case WorkCompletionTarget
        .buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies:
      wccExpectRailDispatchRejectedWithoutRoad();
    case WorkCompletionTarget
        .upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord:
      wccExpectUpgradeTownProvinceLevel();
    case WorkCompletionTarget
        .exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord:
      wccExpectExploreDispatchCapturesRegion();
  }
}
