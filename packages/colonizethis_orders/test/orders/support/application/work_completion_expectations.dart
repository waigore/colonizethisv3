// Compact applyBuildAndWorkOrders work-completion assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'work_application_fixtures.dart';
import 'work_completion_expectation_shorthand.dart';

/// Pins for [workCompletionScenarios] rows.
part 'work_completion_expectations_part1.dart';
part 'work_completion_expectations_part2.dart';

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
      _buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork();
    case WorkCompletionTarget
        .buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile:
      _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile();
    case WorkCompletionTarget
        .buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint:
      _buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint();
    case WorkCompletionTarget
        .buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax:
      _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax();
    case WorkCompletionTarget
        .buildImprovementCompletionDoesNotReApplyExtractionTechCap1291:
      _buildImprovementCompletionDoesNotReApplyExtractionTechCap1291();
    case WorkCompletionTarget
        .workCancelledWhenProvinceContainingTargetTileIsConquered376:
      _workCancelledWhenProvinceContainingTargetTileIsConquered376();
    case WorkCompletionTarget
        .multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero:
      _multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero();
    case WorkCompletionTarget
        .exploreCompletionSetsVisibilityAndClearsCurrentWork:
      _exploreCompletionSetsVisibilityAndClearsCurrentWork();
    case WorkCompletionTarget
        .exploreCompletionRevealsEveryTileInCanonicalFullIdBucket:
      _exploreCompletionRevealsEveryTileInCanonicalFullIdBucket();
    case WorkCompletionTarget.buildRoadCompletionIncreasesRoadLevel:
      _buildRoadCompletionIncreasesRoadLevel();
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade:
      _buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade();
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt:
      _buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt();
    case WorkCompletionTarget
        .buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea:
      _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea();
    case WorkCompletionTarget.buildFortCompletionIncreasesProvinceFortLevel:
      _buildFortCompletionIncreasesProvinceFortLevel();
    case WorkCompletionTarget.buildRailCompletionLeavesRoadWhenTileHasNoRoad:
      _buildRailCompletionLeavesRoadWhenTileHasNoRoad();
    case WorkCompletionTarget.buildRailCompletionSetsRoadLevelTo4WhenValid:
      _buildRailCompletionSetsRoadLevelTo4WhenValid();
    case WorkCompletionTarget.routesKWorkTargetBuildRailThroughHandlerMapEntry:
      _routesKWorkTargetBuildRailThroughHandlerMapEntry();
    case WorkCompletionTarget
        .buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies:
      _buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies();
    case WorkCompletionTarget
        .upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord:
      _upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord();
    case WorkCompletionTarget
        .exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord:
      _exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord();
  }
}


