import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/orders/order_validation_result.dart';
import 'package:colonizethis_logic/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';


void main() {
  group('NavalOrderValidator', () {
    const ow = 'oldWorld';

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

  });
}
