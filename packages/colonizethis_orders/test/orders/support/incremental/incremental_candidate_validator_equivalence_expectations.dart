// Compact IncrementalCandidateValidator equivalence assertions (Refs #3949).

import 'incremental_candidate_validator_equivalence_expectation_shorthand.dart';

/// Pins for [incrementalCandidateValidatorEquivalenceScenarios] rows.
enum IncrementalEquivalenceTarget {
  moveBuilderOwnProvince,
  moveBuilderOtherGp,
  moveExplorerMinor,
  moveSpyOtherGp,
  moveMilitaryRegiment,
  moveMissingUnit,
  moveEmptyDestination,
  moveXorWorkCascade,
  moveNonEmptyBasePrefix,
  buildSingleCandidate,
  buildSuccessiveProbes,
  workNonEmptyBasePrefix,
  diplomaticNonEmptyBasePrefix,
  diplomaticSequentialProbes,
  prefetchedFactionMembership,
  armyMoveOwnAdjacent,
  armyMoveGpNoWar,
  armyMoveGpDeclareWar,
  armyMoveMinorNoWar,
  armyMoveMissingArmy,
  navalMoveAdjacentSea,
  navalMoveNonAdjacentSea,
  navalMoveUndock,
  navalMoveMissingFleet,
  navalMissionPatrol,
  navalMissionBlockadeNoTarget,
  navalMissionMissingFleet,
}

void runIncrementalEquivalenceExpectation(IncrementalEquivalenceTarget target) {
  switch (target) {
    case IncrementalEquivalenceTarget.moveBuilderOwnProvince:
      iceExpectMoveBuilderOwnProvince();
    case IncrementalEquivalenceTarget.moveBuilderOtherGp:
      iceExpectMoveBuilderOtherGp();
    case IncrementalEquivalenceTarget.moveExplorerMinor:
      iceExpectMoveExplorerMinor();
    case IncrementalEquivalenceTarget.moveSpyOtherGp:
      iceExpectMoveSpyOtherGp();
    case IncrementalEquivalenceTarget.moveMilitaryRegiment:
      iceExpectMoveMilitaryRegiment();
    case IncrementalEquivalenceTarget.moveMissingUnit:
      iceExpectMoveMissingUnit();
    case IncrementalEquivalenceTarget.moveEmptyDestination:
      iceExpectMoveEmptyDestination();
    case IncrementalEquivalenceTarget.moveXorWorkCascade:
      iceExpectMoveXorWorkCascade();
    case IncrementalEquivalenceTarget.moveNonEmptyBasePrefix:
      iceExpectMoveNonEmptyBasePrefix();
    case IncrementalEquivalenceTarget.buildSingleCandidate:
      iceExpectBuildSingleCandidate();
    case IncrementalEquivalenceTarget.buildSuccessiveProbes:
      iceExpectBuildSuccessiveProbes();
    case IncrementalEquivalenceTarget.workNonEmptyBasePrefix:
      iceExpectWorkNonEmptyBasePrefix();
    case IncrementalEquivalenceTarget.diplomaticNonEmptyBasePrefix:
      iceExpectDiplomaticNonEmptyBasePrefix();
    case IncrementalEquivalenceTarget.diplomaticSequentialProbes:
      iceExpectDiplomaticSequentialProbes();
    case IncrementalEquivalenceTarget.prefetchedFactionMembership:
      iceExpectPrefetchedFactionMembershipProbe();
    case IncrementalEquivalenceTarget.armyMoveOwnAdjacent:
      iceExpectArmyMoveOwnAdjacent();
    case IncrementalEquivalenceTarget.armyMoveGpNoWar:
      iceExpectArmyMoveGpNoWar();
    case IncrementalEquivalenceTarget.armyMoveGpDeclareWar:
      iceExpectArmyMoveGpDeclareWar();
    case IncrementalEquivalenceTarget.armyMoveMinorNoWar:
      iceExpectArmyMoveMinorNoWar();
    case IncrementalEquivalenceTarget.armyMoveMissingArmy:
      iceExpectArmyMoveMissingArmy();
    case IncrementalEquivalenceTarget.navalMoveAdjacentSea:
      iceExpectNavalMoveAdjacentSea();
    case IncrementalEquivalenceTarget.navalMoveNonAdjacentSea:
      iceExpectNavalMoveNonAdjacentSea();
    case IncrementalEquivalenceTarget.navalMoveUndock:
      iceExpectNavalMoveUndock();
    case IncrementalEquivalenceTarget.navalMoveMissingFleet:
      iceExpectNavalMoveMissingFleet();
    case IncrementalEquivalenceTarget.navalMissionPatrol:
      iceExpectNavalMissionPatrol();
    case IncrementalEquivalenceTarget.navalMissionBlockadeNoTarget:
      iceExpectNavalMissionBlockadeNoTarget();
    case IncrementalEquivalenceTarget.navalMissionMissingFleet:
      iceExpectNavalMissionMissingFleet();
  }
}
