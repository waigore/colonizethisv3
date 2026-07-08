// Compact NavalOrderValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_order_validator_test_support.dart';

/// Pins for [navalOrderValidatorScenarios] rows.
enum NavalOrderValidatorTarget {
  moveRejectsWhenPreviousRejected,
  moveRejectsWhenFleetNotFound,
  moveRejectsWhenFleetNotOwnedByPlayer,
  moveRejectsWhenHomeFleet,
  moveAcceptAdjacentSeaZoneWhenAtSea,
  moveRejectNonAdjacentSeaZone,
  moveDockRejectWhenSeaZoneNotAdjacentToProvince,
  moveAcceptUndockFromPortToAdjacentSeaZone,
  moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId,
  moveInPortAcceptsAnySeaWithDirectPsEdgeToPort,
  moveInPortRejectsSeaOnlyReachableViaSsFromPortSea,
  moveRejectWhenInPortButInPortAtProvinceIdNull,
  moveDockAcceptWhenAtSeaAdjacentOwnedProvince,
  moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed,
  moveDockRejectWhenFleetInPort,
  moveDockRejectWhenPortProvinceNotOwned,
  moveDockRejectWhenPortProvinceNotFound,
  missionRejectsWhenPreviousRejected,
  missionBlockadeRequiresTargetProvince,
  missionBlockadeRejectWhenTargetNotPrefixed,
  missionBlockadeRejectWhenBlockadingOwnProvince,
  missionAcceptNonBlockadeMissionWhenFleetAtSea,
}

void runNavalOrderValidatorExpectation(NavalOrderValidatorTarget target) {
  switch (target) {
    case NavalOrderValidatorTarget.moveRejectsWhenPreviousRejected:
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
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotFound:
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
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotOwnedByPlayer:
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
    case NavalOrderValidatorTarget.moveRejectsWhenHomeFleet:
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
    case NavalOrderValidatorTarget.moveAcceptAdjacentSeaZoneWhenAtSea:
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
    case NavalOrderValidatorTarget.moveRejectNonAdjacentSeaZone:
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
    case NavalOrderValidatorTarget.moveDockRejectWhenSeaZoneNotAdjacentToProvince:
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
    case NavalOrderValidatorTarget.moveAcceptUndockFromPortToAdjacentSeaZone:
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
    case NavalOrderValidatorTarget.moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId:
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
    case NavalOrderValidatorTarget.moveInPortAcceptsAnySeaWithDirectPsEdgeToPort:
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
    case NavalOrderValidatorTarget.moveInPortRejectsSeaOnlyReachableViaSsFromPortSea:
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
    case NavalOrderValidatorTarget.moveRejectWhenInPortButInPortAtProvinceIdNull:
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
    case NavalOrderValidatorTarget.moveDockAcceptWhenAtSeaAdjacentOwnedProvince:
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
    case NavalOrderValidatorTarget.moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed:
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
    case NavalOrderValidatorTarget.moveDockRejectWhenFleetInPort:
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
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotOwned:
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
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotFound:
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
    case NavalOrderValidatorTarget.missionRejectsWhenPreviousRejected:
      final game = navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      );
      final topology = navalOrderValidatorTestTopology(nodes: const []);
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMission(
        const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    case NavalOrderValidatorTarget.missionBlockadeRequiresTargetProvince:
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
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: null,
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Blockade requires a target province');
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenTargetNotPrefixed:
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
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: 'P2',
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Blockade requires a target province');
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenBlockadingOwnProvince:
      final topology = navalOrderValidatorTestTopology(
        nodes: [navalOrderValidatorTestSeaNode('sea1')],
      );
      final game = navalOrderValidatorTestGame(
        oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetAtSea()],
      );
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId:
              ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Cannot blockade own province');
    case NavalOrderValidatorTarget.missionAcceptNonBlockadeMissionWhenFleetAtSea:
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
      final result = validator.validateNavalMission(
        const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.accepted);
      expect(result.reason, isNull);
  }
}
