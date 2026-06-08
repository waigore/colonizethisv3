import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('NavalOrderValidator', () {
    const ow = 'oldWorld';

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

  });
}
