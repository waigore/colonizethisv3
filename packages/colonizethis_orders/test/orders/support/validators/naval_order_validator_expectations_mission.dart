part of 'naval_order_validator_expectations.dart';

void _navalmissionRejectsWhenPreviousRejected() {
  novExpectNavalMission(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: navalOrderValidatorTestTopology(nodes: const []),
    ),
    order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void _navalmissionBlockadeRequiresTargetProvince() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMission(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: null,
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Blockade requires a target province',
  );
}

void _navalmissionBlockadeRejectWhenTargetNotPrefixed() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMission(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: 'P2',
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Blockade requires a target province',
  );
}

void _navalmissionBlockadeRejectWhenBlockadingOwnProvince() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMission(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Cannot blockade own province',
  );
}

void _navalmissionAcceptNonBlockadeMissionWhenFleetAtSea() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMission(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}
