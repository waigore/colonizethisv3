import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Tests that connectivity hot-path counters are recorded via the threaded
/// `metrics` parameter (Refs #3544 AC3) and that no module-level mutable state
/// captures counts when no instance is passed.
Game _singleProvinceGpGame() {
  const ow = 'oldWorld';
  final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
  return Game(
    id: 'metrics-g1',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$ow|p1',
            regionId: ow,
            ownerId: 'pl1',
            townTileKey: cap.toTileKey(),
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
      ),
    ],
  );
}

MapTopology _singleProvinceTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: [
      TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
}

Map<String, TileMapResult> _threeByThreeTileMap() {
  return {
    'oldWorld': TileMapResult(
      width: 3,
      height: 3,
      grid: [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ],
    ),
  };
}

void main() {
  group('Connectivity metrics parameter threading (Refs #3544 AC3)', () {
    test('records dequeue counters into the supplied metrics instance', () {
      final game = _singleProvinceGpGame();
      final metrics = ConnectivityHotPathMetrics();

      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: _threeByThreeTileMap(),
        topology: _singleProvinceTopology(),
        metrics: metrics,
      );

      // Sanity: connectivity actually ran for the player.
      expect(result['pl1'], isNotNull);
      expect(result['pl1']!.connected.contains('oldWorld|p1|1|1'), isTrue);

      // Road-rule propagation seeded at the capital dequeues at least once.
      expect(metrics.connectivityBottleneckDequeues, greaterThan(0));
      // The capital province carries a town tile, so the town-rule worklist
      // dequeues at least once.
      expect(metrics.townRuleWorklistDequeues, greaterThan(0));
      // Aggregate getter stays consistent with its components.
      expect(
        metrics.connectivityBfsTotalDequeues,
        metrics.connectivityBottleneckDequeues +
            metrics.seaZoneBreadthFirstDequeues,
      );
    });

    test(
      'leaves an unrelated metrics instance untouched when none is passed '
      '(no module-level coupling)',
      () {
        final game = _singleProvinceGpGame();
        // Constructed but deliberately NOT passed to the resolver. With the
        // former module-level test hook this could capture counts via the
        // global setter; with parameter threading it must stay at zero.
        final detached = ConnectivityHotPathMetrics();

        resolveConnectivity(
          game: game,
          tileMapByRegion: _threeByThreeTileMap(),
          topology: _singleProvinceTopology(),
        );

        expect(detached.townRuleWorklistDequeues, 0);
        expect(detached.connectivityBottleneckDequeues, 0);
        expect(detached.seaZoneBreadthFirstDequeues, 0);
        expect(detached.connectivityBfsTotalDequeues, 0);
      },
    );
  });
}
