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
        expect(toSea2.status, OrderValidationStatus.rejected);
        final toSea1 = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(toSea1.status, OrderValidationStatus.accepted);
}

void _navalmoveRejectWhenInPortButInPortAtProvinceIdNull() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetBrokenInPort()],
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

void _navalmoveDockAcceptWhenAtSeaAdjacentOwnedProvince() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
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
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
}

void _navalmoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
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
          NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
}

void _navalmoveDockRejectWhenFleetInPort() {
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
          NavalMoveOrder(
            fleetId: 'f1',
            destinationPortProvinceId:
                ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Dock only allowed when fleet is at sea');
}

void _navalmoveDockRejectWhenPortProvinceNotOwned() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [
            navalOrderValidatorTestOwnedProvince('P1', ownerId: 'p2'),
          ],
          fleets: [navalOrderValidatorTestFleetAtSea()],
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
          NavalMoveOrder(
            fleetId: 'f1',
            destinationPortProvinceId:
                ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Can only dock at own province');
}

void _navalmoveDockRejectWhenPortProvinceNotFound() {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame(
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
                ProvinceId.full(kNavalOrderValidatorTestRegionId, 'Nonexistent'),
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Port province not found');
}

