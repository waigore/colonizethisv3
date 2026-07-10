// Table-driven IncrementalCandidateValidator equivalence scenarios (Refs #3949).

import '../scenario_runner.dart';
import 'incremental_candidate_validator_equivalence_runs.dart';

class IncrementalEquivalenceScenario implements RefsScenario {
  const IncrementalEquivalenceScenario({
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

void runIncrementalEquivalenceScenario(
  IncrementalEquivalenceScenario scenario,
) {
  scenario.run();
}

List<IncrementalEquivalenceScenario>
incrementalCandidateValidatorEquivalenceScenarios() => [
  // dart format off
  IncrementalEquivalenceScenario(
    label: 'move: builder onto own province (accepted)',
    run: iceRunMoveBuilderOwnProvince,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: builder onto other GP province (rejected)',
    run: iceRunMoveBuilderOtherGp,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: explorer onto Minor province (accepted)',
    run: iceRunMoveExplorerMinor,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: spy onto other GP province (accepted)',
    run: iceRunMoveSpyOtherGp,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: military regiment via MoveOrder (rejected)',
    run: iceRunMoveMilitaryRegiment,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: missing unit (rejected)',
    run: iceRunMoveMissingUnit,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: empty destination tile (rejected)',
    run: iceRunMoveEmptyDestination,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: rejected because basePrefix has work order for same unit (move XOR work cascade)',
    run: iceRunMoveXorWorkCascade,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: with non-empty accepted basePrefix (accepted)',
    run: iceRunMoveNonEmptyBasePrefix,
  ),
  IncrementalEquivalenceScenario(
    label: 'build: candidate remains equivalent to full-pass path',
    run: iceRunBuildSingleCandidate,
  ),
  IncrementalEquivalenceScenario(
    label: 'build: successive candidate probes stay full-pass equivalent (#2394)',
    run: iceRunBuildSuccessiveProbes,
  ),
  IncrementalEquivalenceScenario(
    label: 'work: non-empty basePrefix replay remains equivalent',
    run: iceRunWorkNonEmptyBasePrefix,
  ),
  IncrementalEquivalenceScenario(
    label: 'diplomatic: non-empty basePrefix replay remains equivalent',
    run: iceRunDiplomaticNonEmptyBasePrefix,
  ),
  IncrementalEquivalenceScenario(
    label: 'diplomatic: sequential probes on one validator stay equivalent (#2394)',
    run: iceRunDiplomaticSequentialProbes,
  ),
  IncrementalEquivalenceScenario(
    label: 'prefetched DiplomacyFactionMembership matches lazy membership (#2394)',
    run: iceRunPrefetchedFactionMembership,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into own adjacent province (accepted)',
    run: iceRunArmyMoveOwnAdjacent,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into other GP without war (rejected)',
    run: iceRunArmyMoveGpNoWar,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into other GP with same-turn declare war (accepted)',
    run: iceRunArmyMoveGpDeclareWar,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into Minor without war (rejected)',
    run: iceRunArmyMoveMinorNoWar,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: missing army (rejected)',
    run: iceRunArmyMoveMissingArmy,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: at-sea fleet to adjacent sea zone (accepted)',
    run: iceRunNavalMoveAdjacentSea,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: at-sea fleet to non-adjacent sea zone (rejected)',
    run: iceRunNavalMoveNonAdjacentSea,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: in-port fleet undock to adjacent sea zone (accepted)',
    run: iceRunNavalMoveUndock,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: missing fleet (rejected)',
    run: iceRunNavalMoveMissingFleet,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval mission: patrol owned fleet (accepted)',
    run: iceRunNavalMissionPatrol,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval mission: blockade without target province (rejected)',
    run: iceRunNavalMissionBlockadeNoTarget,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval mission: missing fleet (rejected)',
    run: iceRunNavalMissionMissingFleet,
  ),
  // dart format on
];
