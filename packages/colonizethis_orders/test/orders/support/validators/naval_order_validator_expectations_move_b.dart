part of 'naval_order_validator_expectations.dart';

void _navalmoveInPortRejectsSeaOnlyReachableViaSsFromPortSea() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [
      TopologyEdge(id1: 'P1', id2: 'sea1'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
  final validator = novValidator(
    game: navalOrderValidatorTestGame(
      oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
      fleets: [navalOrderValidatorTestFleetInPort()],
    ),
    topology: topology,
  );
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
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetBrokenInPort()],
      ),
      topology: topology,
    ),
    order: novSeaMove('f1', 'sea1'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveDockAcceptWhenAtSeaAdjacentOwnedProvince() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: novDockMove('f1', 'P1'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveDockRejectWhenFleetInPort() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetInPort()],
      ),
      topology: topology,
    ),
    order: novDockMove('f1', 'P1'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Dock only allowed when fleet is at sea',
  );
}

void _navalmoveDockRejectWhenPortProvinceNotOwned() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        oldWorldProvinces: [
          navalOrderValidatorTestOwnedProvince('P1', ownerId: 'p2'),
        ],
        fleets: [navalOrderValidatorTestFleetAtSea()],
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      ),
      topology: topology,
    ),
    order: novDockMove('f1', 'P1'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Can only dock at own province',
  );
}

void _navalmoveDockRejectWhenPortProvinceNotFound() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: novDockMove('f1', 'Nonexistent'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Port province not found',
  );
}
