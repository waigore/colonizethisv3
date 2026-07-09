part of 'naval_order_validator_expectation_shorthand.dart';

void novExpectMissionPreviousRejected() {
  novExpectNavalMission(
    validator: _novAtSeaMissionValidator(),
    order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void novExpectBlockadeNoTarget() {
  novExpectNavalMission(
    validator: _novAtSeaMissionValidator(),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: null,
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Blockade requires a target province',
  );
}

void novExpectBlockadeUnprefixedTarget() {
  novExpectNavalMission(
    validator: _novAtSeaMissionValidator(),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: 'P2',
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Blockade requires a target province',
  );
}

void novExpectBlockadeOwnProvince() {
  novExpectNavalMission(
    validator: _novAtSeaMissionValidator(
      oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
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

void novExpectPatrolAcceptedAtSea() {
  novExpectNavalMission(
    validator: _novAtSeaMissionValidator(),
    order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novExpectMovePreviousRejected() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void novExpectFleetNotFound() {
  novExpectAtSeaMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Fleet not found',
    fleets: const [],
  );
}

void novExpectFleetNotOwned() {
  novExpectAtSeaMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetAtSea(ownerId: 'p2')],
    players: novTwoHumanPlayers,
  );
}

void novExpectHomeFleetRejected() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    fleetId: 'fleet_p1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetAtSea(fleetId: 'fleet_p1')],
  );
}

void novExpectAdjacentSeaAccepted() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novExpectNonAdjacentSeaRejected() {
  novExpectAtSeaMove(
    topology: novThreeSeasLinear(),
    destSea: 'sea3',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void novExpectDockSeaNotAdjacent() {
  novExpectDockMove(
    topology: novTwoSeasProvinceDockMismatch(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void novExpectUndockAccepted() {
  novExpectInPortMove(
    topology: novSeaProvinceAdjacent(),
    destSea: 'sea1',
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novExpectProvinceAsSeaRejected() {
  novExpectAtSeaMove(
    topology: novSeaProvinceAdjacent(),
    destSea: 'P1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void novExpectInPortDirectPsEdgeAccepted() {
  final validator = novValidatorInPort(topology: novPortDualSea());
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea2'),
    status: OrderValidationStatus.accepted,
  );
}

void novExpectInPortSsOnlyReachability() {
  final validator = novValidatorInPort(topology: novPortSeaChain());
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea2'),
    status: OrderValidationStatus.rejected,
  );
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea1'),
    status: OrderValidationStatus.accepted,
  );
}

void novExpectBrokenInPortRejected() {
  novExpectInPortMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetBrokenInPort()],
  );
}

void novExpectDockAdjacentOwnedAccepted() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novExpectDockLocalPortIdAccepted() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
    order: NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
  );
}

void novExpectDockFleetInPortRejected() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Dock only allowed when fleet is at sea',
    fleets: [navalOrderValidatorTestFleetInPort()],
  );
}

void novExpectDockNotOwnedRejected() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Can only dock at own province',
    oldWorldProvinces: [
      navalOrderValidatorTestOwnedProvince('P1', ownerId: 'p2'),
    ],
    players: novTwoHumanPlayers,
  );
}

void novExpectDockPortNotFoundRejected() {
  novExpectDockMove(
    topology: novSingleSea(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Port province not found',
    order: novDockMove('f1', 'Nonexistent'),
  );
}
