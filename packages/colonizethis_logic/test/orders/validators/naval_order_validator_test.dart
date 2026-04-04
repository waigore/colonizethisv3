import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/orders/order_validation_result.dart';
import 'package:colonizethis_logic/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('NavalOrderValidator', () {
    const ow = 'oldWorld';

    test('validateNavalMove rejects when previousRejected', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });

    test('validateNavalMove rejects when fleet not found', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Fleet not found');
    });

    test('validateNavalMove rejects when fleet not owned by player', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p2',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Invalid naval move');
    });

    test('validateNavalMove rejects when home fleet', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet_p1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'fleet_p1', destinationSeaZoneId: 'sea2'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Invalid naval move');
    });

    test('validateNavalMove accept move to adjacent sea zone when at sea', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.accepted);
      expect(result.reason, isNull);
    });

    test('validateNavalMove reject move to non-adjacent sea zone', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea3',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea3'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Invalid naval move');
    });

    test(
      'validateNavalMove dock accept when at sea adjacent owned province',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMove(
          NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: '$ow|P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );

    test(
      'validateNavalMove dock accept when port province id is local (unprefixed)',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMove(
          NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );

    test('validateNavalMove dock reject when fleet in port', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: null,
              inPortAtProvinceId: '$ow|P1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: '$ow|P1'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Dock only allowed when fleet is at sea');
    });

    test('validateNavalMove dock reject when port province not owned', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p2')],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: '$ow|P1'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Can only dock at own province');
    });

    test('validateNavalMove dock reject when port province not found', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        NavalMoveOrder(
          fleetId: 'f1',
          destinationPortProvinceId: '$ow|Nonexistent',
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Port province not found');
    });

    test(
      'validateNavalMove dock reject when sea zone not adjacent to province',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
            TopologyEdge(id1: 'sea2', id2: 'P1'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMove(
          NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: '$ow|P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
      },
    );

    test('validateNavalMove accept undock from port to adjacent sea zone', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: null,
              inPortAtProvinceId: '$ow|P1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMove(
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.accepted);
      expect(result.reason, isNull);
    });

    test(
      'validateNavalMove at sea rejects province id as destinationSeaZoneId',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
      },
    );

    test(
      'validateNavalMove in-port accepts any sea with direct P–S edge to port',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'P1', id2: 'sea1'),
            TopologyEdge(id1: 'P1', id2: 'sea2'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: null,
                inPortAtProvinceId: '$ow|P1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final toSea2 = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          previousRejected: false,
        );
        expect(toSea2.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'validateNavalMove in-port rejects sea only reachable via S–S from port sea',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'P1', id2: 'sea1'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: null,
                inPortAtProvinceId: '$ow|P1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
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
      },
    );

    test(
      'validateNavalMove reject when in port but inPortAtProvinceId null',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: null,
                inPortAtProvinceId: null,
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
      },
    );

    test('validateNavalMission rejects when previousRejected', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final topology = MapTopology(nodes: const [], edges: const []);
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMission(
        const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });

    test('validateNavalMission blockade requires target province', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
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
    });

    test('validateNavalMission blockade reject when target not prefixed', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
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
    });

    test(
      'validateNavalMission blockade reject when blockading own province',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMission(
          NavalMissionOrder(
            fleetId: 'f1',
            mission: FleetMission.blockade.name,
            targetProvinceId: '$ow|P1',
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Cannot blockade own province');
      },
    );

    test(
      'validateNavalMission accept non-blockade mission when fleet at sea',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMission(
          const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );
  });
}
