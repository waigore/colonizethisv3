import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('civilian work draft commit validation (Refs #2133)', () {
    test(
      'one validatePlayerOrdersWithContext pass accepts merged draft for '
      'valid explorer explore work order',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const explorerId = 'E1';
        final player = const Player(
          id: playerId,
          displayName: 'Human',
          isHuman: true,
          treasury: 5000,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final explorer = Unit(
          id: explorerId,
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: p1.id,
          tileKey: '$ow|p1|0|0',
          status: UnitStatus.idle,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [explorer]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {
              '$ow|p1|0|0': 'fullyVisible',
              '$ow|p1|0|1': 'unknown',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              p1.id: ['$ow|p1|0|0', '$ow|p1|0|1'],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [],
          tribes: const [],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        );
        const orders = Orders();
        final pending = WorkOrder(
          unitId: explorerId,
          target: kWorkTargetExplore,
          targetTileKey: '$ow|p1|0|0',
        );
        final merged = orders.copyWith(
          workOrdersByPlayerId: {
            playerId: [pending],
          },
        );

        final engine = OrderEngine(initialOrders: merged);
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          playerId,
        );
        expect(results, isNotEmpty);
        expect(results.every((r) => r.isAccepted), isTrue);
      },
    );
  });
}
