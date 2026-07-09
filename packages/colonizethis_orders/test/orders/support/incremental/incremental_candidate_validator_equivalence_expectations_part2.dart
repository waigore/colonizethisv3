part of 'incremental_candidate_validator_equivalence_expectations.dart';

void _armyMoveMissingArmy() {
  iceExpectArmyMoveTo('unknown_army', 'P2', label: 'unknown army');
}

void _navalMoveAdjacentSea() {
  iceExpectNavalMoveTo(
    'fleet_atSea',
    'oldWorld|sea2',
    label: 'sea1->sea2',
  );
}

void _navalMoveNonAdjacentSea() {
  iceExpectNavalMoveTo(
    'fleet_atSea',
    'oldWorld|seaZ',
    label: 'sea1->unknown',
  );
}

void _navalMoveUndock() {
  iceExpectNavalMoveTo(
    'fleet_inPort',
    'oldWorld|sea1',
    label: 'inPort->sea1',
  );
}

void _navalMoveMissingFleet() {
  iceExpectNavalMoveTo(
    'unknown_fleet',
    'oldWorld|sea1',
    label: 'unknown fleet',
  );
}

void _navalMissionPatrol() {
  iceExpectNavalMissionFor('fleet_atSea', 'patrol', label: 'patrol owned');
}

void _navalMissionBlockadeNoTarget() {
  iceExpectNavalMissionFor('fleet_atSea', 'blockade', label: 'blockade no target');
}

void _navalMissionMissingFleet() {
  iceExpectNavalMissionFor('unknown_fleet', 'patrol', label: 'unknown fleet');
}
