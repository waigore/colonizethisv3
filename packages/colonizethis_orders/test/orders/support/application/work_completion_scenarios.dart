// Table-driven applyBuildAndWorkOrders work-completion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_completion_expectation_shorthand.dart';
import 'work_completion_run_rows.dart';

/// One row in [workCompletionScenarios].
class WorkCompletionScenario implements RefsScenario {
  const WorkCompletionScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runWorkCompletionScenario(WorkCompletionScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for work-completion family tests.
/// Labels match former suite descriptions (single-line `label:` for CI).
List<WorkCompletionScenario> workCompletionScenarios() => [
  // dart format off
  WorkCompletionScenario(
    label: 'build_improvement completion increases improvement level and clears currentWork',
    run: wccRunBuildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion sets envy mirror hint for human on extraction tile',
    run: wccRunBuildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion adds envy evidence when AI mirrors human gathering hint',
    run: wccRunBuildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion raises stored level from 3 to 4 (global max)',
    run: wccRunBuildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax,
  ),
  WorkCompletionScenario(
    label: 'build_improvement completion does not re-apply extraction tech cap (#1291)',
    run: wccRunBuildImprovementCompletionDoesNotReApplyExtractionTechCap1291,
    refs: '#1291',
  ),
  WorkCompletionScenario(
    label: 'work cancelled when province containing target tile is conquered (#376)',
    run: wccRunWorkCancelledWhenProvinceContainingTargetTileIsConquered376,
    refs: '#376',
  ),
  WorkCompletionScenario(
    label: 'multi-turn work decrements remainingTurns and completes only when zero',
    run: wccRunMultiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero,
  ),
  WorkCompletionScenario(
    label: 'explore completion sets visibility and clears currentWork',
    run: wccRunExploreCompletionSetsVisibilityAndClearsCurrentWork,
  ),
  WorkCompletionScenario(
    label: 'explore completion reveals every tile in canonical full-id bucket',
    run: wccRunExploreCompletionRevealsEveryTileInCanonicalFullIdBucket,
  ),
  WorkCompletionScenario(
    label: 'build_road completion increases road level',
    run: wccRunBuildRoadCompletionIncreasesRoadLevel,
  ),
  WorkCompletionScenario(
    label: 'build_road completion propagates transport level to adjacent capital tile (no downgrade)',
    run: wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade,
  ),
  WorkCompletionScenario(
    label: 'build_road completion propagates transport level to adjacent port tile and upgrades it',
    run: wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt,
  ),
  WorkCompletionScenario(
    label: 'build_port completion sets port and road level 4 when topology has sea',
    run: wccRunBuildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea,
  ),
  WorkCompletionScenario(
    label: 'build_fort completion increases province fortLevel',
    run: wccRunBuildFortCompletionIncreasesProvinceFortLevel,
  ),
  WorkCompletionScenario(
    label: 'build_rail completion leaves road when tile has no road',
    run: wccRunBuildRailCompletionLeavesRoadWhenTileHasNoRoad,
  ),
  WorkCompletionScenario(
    label: 'build_rail completion sets road level to 4 when valid',
    run: wccRunBuildRailCompletionSetsRoadLevelTo4WhenValid,
  ),
  WorkCompletionScenario(
    label: 'routes kWorkTargetBuildRail through handler map entry',
    run: wccRunRoutesKWorkTargetBuildRailThroughHandlerMapEntry,
  ),
  WorkCompletionScenario(
    label: 'build_rail completion no-ops when rejectionReasonForBuildRailOrder applies',
    run: wccRunBuildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies,
  ),
  WorkCompletionScenario(
    label: 'upgrade_town threads getProvinces/replaceProvinces through the CompletedWorkContext record',
    run: wccRunUpgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord,
  ),
  WorkCompletionScenario(
    label: 'explore invokes the applyExploreCompletion closure with the unit region via the CompletedWorkContext record',
    run: wccRunExploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord,
  ),
  // dart format on
];
