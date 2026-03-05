import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('defaultSimGameAi', () {
    test('produces move orders only to adjacent provinces', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P3', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
          TopologyEdge(id1: 'P2', id2: 'P3'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2'),
              Province(id: 'oldWorld|P3', regionId: 'oldWorld', ownerId: 'p3'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                provinceId: 'oldWorld|P1',
              ),
              Unit(
                id: 'u2',
                type: 'grenadiers',
                ownerId: 'p1',
                provinceId: 'oldWorld|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
              'oldWorld|P3|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final player = game.players.single;

      final orders = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 42,
      );

      final moveOrders = orders.moveOrdersByPlayerId[player.id] ?? const [];
      expect(moveOrders, isNotEmpty);
      for (final mo in moveOrders) {
        final unit = game.worldState.oldWorld.units
            .firstWhere((u) => u.id == mo.unitId);
        final fromLocal = ProvinceId.localIdFrom(unit.provinceId);
        final toLocal = ProvinceId.localIdFrom(mo.destinationProvinceId);
        final isAdjacent = topology.edges.any(
          (e) =>
              (e.id1 == fromLocal && e.id2 == toLocal) ||
              (e.id1 == toLocal && e.id2 == fromLocal),
        );
        expect(isAdjacent, isTrue,
            reason: 'Move from $fromLocal to $toLocal must follow topology edge');
      }
    });

    test('is deterministic for same game, player, topology, and seed', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: const [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                provinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final player = game.players.single;

      final o1 = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 99,
      );
      final o2 = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 99,
      );

      expect(o1, equals(o2));
    });
  });
}

