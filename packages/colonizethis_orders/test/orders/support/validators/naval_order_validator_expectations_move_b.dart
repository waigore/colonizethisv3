part of 'naval_order_validator_expectations.dart';

void _navalmoveInPortRejectsSeaOnlyReachableViaSsFromPortSea() {
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

void _navalmoveRejectWhenInPortButInPortAtProvinceIdNull() {
  novExpectInPortMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetBrokenInPort()],
  );
}

void _navalmoveDockAcceptWhenAtSeaAdjacentOwnedProvince() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
    order: NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
  );
}

void _navalmoveDockRejectWhenFleetInPort() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Dock only allowed when fleet is at sea',
    fleets: [navalOrderValidatorTestFleetInPort()],
  );
}

void _navalmoveDockRejectWhenPortProvinceNotOwned() {
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

void _navalmoveDockRejectWhenPortProvinceNotFound() {
  novExpectDockMove(
    topology: novSingleSea(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Port province not found',
    order: novDockMove('f1', 'Nonexistent'),
  );
}
