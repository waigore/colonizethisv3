part of 'naval_order_validator_expectations.dart';

void _navalmoveRejectsWhenPreviousRejected() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestSeaNode('sea2'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          previousRejected: true,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Previous invalid');
}

void _navalmoveRejectsWhenFleetNotFound() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame();
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Fleet not found');
}

void _navalmoveRejectsWhenFleetNotOwnedByPlayer() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea(ownerId: 'p2')],
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
}

void _navalmoveRejectsWhenHomeFleet() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestSeaNode('sea2'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea(fleetId: 'fleet_p1')],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'fleet_p1', destinationSeaZoneId: 'sea2'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
}

void _navalmoveAcceptAdjacentSeaZoneWhenAtSea() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestSeaNode('sea2'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
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
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea3'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
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
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          NavalMoveOrder(
            fleetId: 'f1',
            destinationPortProvinceId:
                ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
}

void _navalmoveAcceptUndockFromPortToAdjacentSeaZone() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetInPort()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
}

void _navalmoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
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
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetInPort()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final toSea2 = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          previousRejected: false,
        );
        expect(toSea2.status, OrderValidationStatus.accepted);
}

