// Compact IncrementalCandidateValidator equivalence assertions (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'incremental_candidate_validator_equivalence_naval_helpers.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

/// Pins for [incrementalCandidateValidatorEquivalenceScenarios] rows.
part 'incremental_candidate_validator_equivalence_expectations_part1.dart';
part 'incremental_candidate_validator_equivalence_expectations_part2.dart';

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
      _moveBuilderOwnProvince();
    case IncrementalEquivalenceTarget.moveBuilderOtherGp:
      _moveBuilderOtherGp();
    case IncrementalEquivalenceTarget.moveExplorerMinor:
      _moveExplorerMinor();
    case IncrementalEquivalenceTarget.moveSpyOtherGp:
      _moveSpyOtherGp();
    case IncrementalEquivalenceTarget.moveMilitaryRegiment:
      _moveMilitaryRegiment();
    case IncrementalEquivalenceTarget.moveMissingUnit:
      _moveMissingUnit();
    case IncrementalEquivalenceTarget.moveEmptyDestination:
      _moveEmptyDestination();
    case IncrementalEquivalenceTarget.moveXorWorkCascade:
      _moveXorWorkCascade();
    case IncrementalEquivalenceTarget.moveNonEmptyBasePrefix:
      _moveNonEmptyBasePrefix();
    case IncrementalEquivalenceTarget.buildSingleCandidate:
      _buildSingleCandidate();
    case IncrementalEquivalenceTarget.buildSuccessiveProbes:
      _buildSuccessiveProbes();
    case IncrementalEquivalenceTarget.workNonEmptyBasePrefix:
      _workNonEmptyBasePrefix();
    case IncrementalEquivalenceTarget.diplomaticNonEmptyBasePrefix:
      _diplomaticNonEmptyBasePrefix();
    case IncrementalEquivalenceTarget.diplomaticSequentialProbes:
      _diplomaticSequentialProbes();
    case IncrementalEquivalenceTarget.prefetchedFactionMembership:
      _prefetchedFactionMembership();
    case IncrementalEquivalenceTarget.armyMoveOwnAdjacent:
      _armyMoveOwnAdjacent();
    case IncrementalEquivalenceTarget.armyMoveGpNoWar:
      _armyMoveGpNoWar();
    case IncrementalEquivalenceTarget.armyMoveGpDeclareWar:
      _armyMoveGpDeclareWar();
    case IncrementalEquivalenceTarget.armyMoveMinorNoWar:
      _armyMoveMinorNoWar();
    case IncrementalEquivalenceTarget.armyMoveMissingArmy:
      _armyMoveMissingArmy();
    case IncrementalEquivalenceTarget.navalMoveAdjacentSea:
      _navalMoveAdjacentSea();
    case IncrementalEquivalenceTarget.navalMoveNonAdjacentSea:
      _navalMoveNonAdjacentSea();
    case IncrementalEquivalenceTarget.navalMoveUndock:
      _navalMoveUndock();
    case IncrementalEquivalenceTarget.navalMoveMissingFleet:
      _navalMoveMissingFleet();
    case IncrementalEquivalenceTarget.navalMissionPatrol:
      _navalMissionPatrol();
    case IncrementalEquivalenceTarget.navalMissionBlockadeNoTarget:
      _navalMissionBlockadeNoTarget();
    case IncrementalEquivalenceTarget.navalMissionMissingFleet:
      _navalMissionMissingFleet();
  }
}


