part of 'naval_order_validator_expectations.dart';

void _navalmoveRejectsWhenPreviousRejected() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: novSeaMove('f1', 'sea2'),
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void _navalmoveRejectsWhenFleetNotFound() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(),
      topology: topology,
    ),
    order: novSeaMove('f1', 'sea1'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Fleet not found',
  );
}

void _navalmoveRejectsWhenFleetNotOwnedByPlayer() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [navalOrderValidatorTestSeaNode('sea1')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea(ownerId: 'p2')],
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      ),
      topology: topology,
    ),
    order: novSeaMove('f1', 'sea1'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveRejectsWhenHomeFleet() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea(fleetId: 'fleet_p1')],
      ),
      topology: topology,
    ),
    order: novSeaMove('fleet_p1', 'sea2'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveAcceptAdjacentSeaZoneWhenAtSea() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: novSeaMove('f1', 'sea2'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveRejectNonAdjacentSeaZone() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
      navalOrderValidatorTestSeaNode('sea3'),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  novExpectNavalMove(
    validator: novValidator(
      game: navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: novSeaMove('f1', 'sea3'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveDockRejectWhenSeaZoneNotAdjacentToProvince() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
      TopologyEdge(id1: 'sea2', id2: 'P1'),
    ],
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
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveAcceptUndockFromPortToAdjacentSeaZone() {
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
    order: novSeaMove('f1', 'sea1'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void _navalmoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId() {
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
        fleets: [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: topology,
    ),
    order: novSeaMove('f1', 'P1'),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void _navalmoveInPortAcceptsAnySeaWithDirectPsEdgeToPort() {
  final topology = navalOrderValidatorTestTopology(
    nodes: [
      navalOrderValidatorTestSeaNode('sea1'),
      navalOrderValidatorTestSeaNode('sea2'),
      navalOrderValidatorTestProvinceNode('P1'),
    ],
    edges: const [
      TopologyEdge(id1: 'P1', id2: 'sea1'),
      TopologyEdge(id1: 'P1', id2: 'sea2'),
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
    status: OrderValidationStatus.accepted,
  );
}
