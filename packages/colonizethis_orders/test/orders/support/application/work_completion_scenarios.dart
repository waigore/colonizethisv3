// Table-driven applyBuildAndWorkOrders work-completion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_completion_expectations.dart';

/// One row in [workCompletionScenarios].
class WorkCompletionScenario implements RefsScenario {
  const WorkCompletionScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final WorkCompletionTarget target;
  @override
  final String? refs;
}

void runWorkCompletionScenario(WorkCompletionScenario scenario) {
  runWorkCompletionExpectation(scenario.target);
}

/// Canonical scenarios for work-completion family tests.
/// Labels match former suite descriptions (single-line `label:` for CI).
List<WorkCompletionScenario> workCompletionScenarios() => const [
  // dart format off
  WorkCompletionScenario(
    label: 'build_improvement completion increases improvement level and clears currentWork',
    target: WorkCompletionTarget.buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion sets envy mirror hint for human on extraction tile',
    target: WorkCompletionTarget.buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion adds envy evidence when AI mirrors human gathering hint',
    target: WorkCompletionTarget.buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion raises stored level from 3 to 4 (global max)',
    target: WorkCompletionTarget.buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion does not re-apply extraction tech cap (#1291)',
    target: WorkCompletionTarget.buildImprovementCompletionDoesNotReApplyExtractionTechCap1291,
    refs: '#1291',
  ),
  WorkCompletionScenario(
    label: 'work cancelled when province containing target tile is conquered (#376)',
    target: WorkCompletionTarget.workCancelledWhenProvinceContainingTargetTileIsConquered376,
    refs: '#376',
  ),
  WorkCompletionScenario(
    label: 'multi-turn work decrements remainingTurns and completes only when zero',
    target: WorkCompletionTarget.multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero,
  ),
  WorkCompletionScenario(
    label: 'explore completion sets visibility and clears currentWork',
    target: WorkCompletionTarget.exploreCompletionSetsVisibilityAndClearsCurrentWork,
  ),
  WorkCompletionScenario(
    label: 'explore completion reveals every tile in canonical full-id bucket',
    target: WorkCompletionTarget.exploreCompletionRevealsEveryTileInCanonicalFullIdBucket,
  ),
  WorkCompletionScenario(
    label: 'build_road completion increases road level',
    target: WorkCompletionTarget.buildRoadCompletionIncreasesRoadLevel,
  ),
  WorkCompletionScenario(
    label: 'build_road completion propagates transport level to adjacent capital tile (no downgrade)',
    target: WorkCompletionTarget.buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade,
  ),
  WorkCompletionScenario(
    label: 'build_road completion propagates transport level to adjacent port tile and upgrades it',
    target: WorkCompletionTarget.buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt,
  ),
  WorkCompletionScenario(
    label: 'build_port completion sets port and road level 4 when topology has sea',
    target: WorkCompletionTarget.buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea,
  ),
  WorkCompletionScenario(
    label: 'build_fort completion increases province fortLevel',
    target: WorkCompletionTarget.buildFortCompletionIncreasesProvinceFortLevel,
  ),
  WorkCompletionScenario(
    label: 'build_rail completion leaves road when tile has no road',
    target: WorkCompletionTarget.buildRailCompletionLeavesRoadWhenTileHasNoRoad,
  ),
  WorkCompletionScenario(
    label: 'build_rail completion sets road level to 4 when valid',
    target: WorkCompletionTarget.buildRailCompletionSetsRoadLevelTo4WhenValid,
  ),
  WorkCompletionScenario(
    label: 'routes kWorkTargetBuildRail through handler map entry',
    target: WorkCompletionTarget.routesKWorkTargetBuildRailThroughHandlerMapEntry,
  ),
  WorkCompletionScenario(
    label: 'build_rail completion no-ops when rejectionReasonForBuildRailOrder applies',
    target: WorkCompletionTarget.buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies,
  ),
  WorkCompletionScenario(
    label: 'upgrade_town threads getProvinces/replaceProvinces through the CompletedWorkContext record',
    target: WorkCompletionTarget.upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord,
  ),
  WorkCompletionScenario(
    label: 'explore invokes the applyExploreCompletion closure with the unit region via the CompletedWorkContext record',
    target: WorkCompletionTarget.exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord,
  ),
  // dart format on
];
