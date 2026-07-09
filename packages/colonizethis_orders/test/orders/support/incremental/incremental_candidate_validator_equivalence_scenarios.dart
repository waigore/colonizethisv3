// Table-driven IncrementalCandidateValidator equivalence scenarios (Refs #3949).

import '../scenario_runner.dart';
import 'incremental_candidate_validator_equivalence_expectations.dart';

class IncrementalEquivalenceScenario implements RefsScenario {
  const IncrementalEquivalenceScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final IncrementalEquivalenceTarget target;
  @override
  final String? refs;
}

void runIncrementalEquivalenceScenario(
  IncrementalEquivalenceScenario scenario,
) {
  runIncrementalEquivalenceExpectation(scenario.target);
}

List<IncrementalEquivalenceScenario>
incrementalCandidateValidatorEquivalenceScenarios() => const [
  // dart format off
  IncrementalEquivalenceScenario(
    label: 'move: builder onto own province (accepted)',
    target: IncrementalEquivalenceTarget.moveBuilderOwnProvince,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: builder onto other GP province (rejected)',
    target: IncrementalEquivalenceTarget.moveBuilderOtherGp,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: explorer onto Minor province (accepted)',
    target: IncrementalEquivalenceTarget.moveExplorerMinor,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: spy onto other GP province (accepted)',
    target: IncrementalEquivalenceTarget.moveSpyOtherGp,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: military regiment via MoveOrder (rejected)',
    target: IncrementalEquivalenceTarget.moveMilitaryRegiment,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: missing unit (rejected)',
    target: IncrementalEquivalenceTarget.moveMissingUnit,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: empty destination tile (rejected)',
    target: IncrementalEquivalenceTarget.moveEmptyDestination,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: rejected because basePrefix has work order for same unit (move XOR work cascade)',
    target: IncrementalEquivalenceTarget.moveXorWorkCascade,
  ),
  IncrementalEquivalenceScenario(
    label: 'move: with non-empty accepted basePrefix (accepted)',
    target: IncrementalEquivalenceTarget.moveNonEmptyBasePrefix,
  ),
  IncrementalEquivalenceScenario(
    label: 'build: candidate remains equivalent to full-pass path',
    target: IncrementalEquivalenceTarget.buildSingleCandidate,
  ),
  IncrementalEquivalenceScenario(
    label: 'build: successive candidate probes stay full-pass equivalent (#2394)',
    target: IncrementalEquivalenceTarget.buildSuccessiveProbes,
  ),
  IncrementalEquivalenceScenario(
    label: 'work: non-empty basePrefix replay remains equivalent',
    target: IncrementalEquivalenceTarget.workNonEmptyBasePrefix,
  ),
  IncrementalEquivalenceScenario(
    label: 'diplomatic: non-empty basePrefix replay remains equivalent',
    target: IncrementalEquivalenceTarget.diplomaticNonEmptyBasePrefix,
  ),
  IncrementalEquivalenceScenario(
    label: 'diplomatic: sequential probes on one validator stay equivalent (#2394)',
    target: IncrementalEquivalenceTarget.diplomaticSequentialProbes,
  ),
  IncrementalEquivalenceScenario(
    label: 'prefetched DiplomacyFactionMembership matches lazy membership (#2394)',
    target: IncrementalEquivalenceTarget.prefetchedFactionMembership,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into own adjacent province (accepted)',
    target: IncrementalEquivalenceTarget.armyMoveOwnAdjacent,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into other GP without war (rejected)',
    target: IncrementalEquivalenceTarget.armyMoveGpNoWar,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into other GP with same-turn declare war (accepted)',
    target: IncrementalEquivalenceTarget.armyMoveGpDeclareWar,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: into Minor without war (rejected)',
    target: IncrementalEquivalenceTarget.armyMoveMinorNoWar,
  ),
  IncrementalEquivalenceScenario(
    label: 'army move: missing army (rejected)',
    target: IncrementalEquivalenceTarget.armyMoveMissingArmy,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: at-sea fleet to adjacent sea zone (accepted)',
    target: IncrementalEquivalenceTarget.navalMoveAdjacentSea,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: at-sea fleet to non-adjacent sea zone (rejected)',
    target: IncrementalEquivalenceTarget.navalMoveNonAdjacentSea,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: in-port fleet undock to adjacent sea zone (accepted)',
    target: IncrementalEquivalenceTarget.navalMoveUndock,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval move: missing fleet (rejected)',
    target: IncrementalEquivalenceTarget.navalMoveMissingFleet,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval mission: patrol owned fleet (accepted)',
    target: IncrementalEquivalenceTarget.navalMissionPatrol,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval mission: blockade without target province (rejected)',
    target: IncrementalEquivalenceTarget.navalMissionBlockadeNoTarget,
  ),
  IncrementalEquivalenceScenario(
    label: 'naval mission: missing fleet (rejected)',
    target: IncrementalEquivalenceTarget.navalMissionMissingFleet,
  ),
  // dart format on
];
