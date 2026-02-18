import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctdev/main.dart';
import 'package:test/test.dart';

void main() {
  group('SimGameController', () {
    test('stepFullTurn advances turn number', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['P1'],
            ['P2'],
          ],
          resourceGrid: const [
            [Resource.grain],
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 123,
      );

      controller.stepFullTurn();

      expect(controller.game.worldState.turnState.turnNumber, 1);
      expect(controller.logLines, isNotEmpty);
    });

    test('stepFullTurn records AI order history', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['P1'],
            ['P2'],
          ],
          resourceGrid: const [
            [Resource.grain],
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 123,
      );

      controller.stepFullTurn();

      expect(controller.orderHistory, isNotEmpty);
      for (final entry in controller.orderHistory) {
        expect(entry.turnNumber, 0);
        expect(entry.playerId, 'p1');
      }
    });
  });
}

