part of 'naval_order_validator_expectations.dart';

void _navalmoveRejectsWhenPreviousRejected() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void _navalmoveRejectsWhenFleetNotFound() {
  novExpectAtSeaMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Fleet not found',
    fleets: const [],
  );
}

void _navalmoveRejectsWhenFleetNotOwnedByPlayer() {
  novExpectAtSeaMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetAtSea(ownerId: 'p2')],
    players: novTwoHumanPlayers,
  );
}

void _navalmoveRejectsWhenHomeFleet() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    fleetId: 'fleet_p1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetAtSea(fleetId: 'fleet_p1')],
  );
}

void _navalmoveAcceptAdjacentSeaZoneWhenAtSea() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveRejectNonAdjacentSeaZone() {
  novExpectAtSeaMove(
    topology: novThreeSeasLinear(),
    destSea: 'sea3',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveDockRejectWhenSeaZoneNotAdjacentToProvince() {
  novExpectDockMove(
    topology: novTwoSeasProvinceDockMismatch(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveAcceptUndockFromPortToAdjacentSeaZone() {
  novExpectInPortMove(
    topology: novSeaProvinceAdjacent(),
    destSea: 'sea1',
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId() {
  novExpectAtSeaMove(
    topology: novSeaProvinceAdjacent(),
    destSea: 'P1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveInPortAcceptsAnySeaWithDirectPsEdgeToPort() {
  final validator = novValidatorInPort(topology: novPortDualSea());
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea2'),
    status: OrderValidationStatus.accepted,
  );
}
