part of 'incremental_candidate_validator_equivalence_expectations.dart';

void _armyMoveMissingArmy() {
  iceExpectArmyMoveOnCorpus(
    candidate: const ArmyMoveOrder(
      armyId: 'unknown_army',
      destinationProvinceId: 'oldWorld|P2',
    ),
    label: 'unknown army',
  );
}

void _navalMoveAdjacentSea() {
  iceExpectNavalMoveOnCorpus(
    candidate: const NavalMoveOrder(
      fleetId: 'fleet_atSea',
      destinationSeaZoneId: 'oldWorld|sea2',
    ),
    label: 'sea1->sea2',
  );
}

void _navalMoveNonAdjacentSea() {
  iceExpectNavalMoveOnCorpus(
    candidate: const NavalMoveOrder(
      fleetId: 'fleet_atSea',
      destinationSeaZoneId: 'oldWorld|seaZ',
    ),
    label: 'sea1->unknown',
  );
}

void _navalMoveUndock() {
  iceExpectNavalMoveOnCorpus(
    candidate: const NavalMoveOrder(
      fleetId: 'fleet_inPort',
      destinationSeaZoneId: 'oldWorld|sea1',
    ),
    label: 'inPort->sea1',
  );
}

void _navalMoveMissingFleet() {
  iceExpectNavalMoveOnCorpus(
    candidate: const NavalMoveOrder(
      fleetId: 'unknown_fleet',
      destinationSeaZoneId: 'oldWorld|sea1',
    ),
    label: 'unknown fleet',
  );
}

void _navalMissionPatrol() {
  iceExpectNavalMissionOnCorpus(
    candidate: const NavalMissionOrder(
      fleetId: 'fleet_atSea',
      mission: 'patrol',
    ),
    label: 'patrol owned',
  );
}

void _navalMissionBlockadeNoTarget() {
  iceExpectNavalMissionOnCorpus(
    candidate: const NavalMissionOrder(
      fleetId: 'fleet_atSea',
      mission: 'blockade',
    ),
    label: 'blockade no target',
  );
}

void _navalMissionMissingFleet() {
  iceExpectNavalMissionOnCorpus(
    candidate: const NavalMissionOrder(
      fleetId: 'unknown_fleet',
      mission: 'patrol',
    ),
    label: 'unknown fleet',
  );
}
