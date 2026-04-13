import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:sim_scenarios/seaboard_port_audit.dart';

void main() {
  group('runSeaboardPortAudit', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
      ],
      edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
    );

    final tileMapPass = TileMapResult(
      width: 3,
      height: 1,
      grid: [
        ['p1', 'p1', 's1'],
      ],
    );

    WorldState emptyWorld({Map<String, String> ports = const {}}) {
      return WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(provinces: [], units: []),
        newWorld: const RegionData(provinces: [], units: []),
        portsByProvinceSeaboard: ports,
      );
    }

    test('passes when port tile has orthogonal sea and capital ports complete', () {
      final game = Game(
        id: 'audit_test',
        worldState: emptyWorld(
          ports: {'oldWorld|p1|s1': 'oldWorld|p1|1|0'},
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final outcome = runSeaboardPortAudit(
        game: game,
        tileMapByRegion: {'oldWorld': tileMapPass},
        topologyByRegion: {'oldWorld': topology},
      );
      expect(outcome.skipped, false);
      expect(outcome.passed, true);
      expect(outcome.failures, isEmpty);
    });

    test('reports drawable_error when port tile has no orthogonal sea cell', () {
      final tileMapFail = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ],
      );
      final game = Game(
        id: 'audit_test',
        worldState: emptyWorld(
          ports: {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
        ),
        players: const [],
      );
      final outcome = runSeaboardPortAudit(
        game: game,
        tileMapByRegion: {'oldWorld': tileMapFail},
        topologyByRegion: {'oldWorld': topology},
      );
      expect(outcome.passed, false);
      expect(outcome.failures, isNotEmpty);
      expect(outcome.failures.first.kind, 'drawable_error');
      expect(outcome.failures.first.seaboardKey, 'oldWorld|p1|s1');
      expect(outcome.failures.first.portTileKey, 'oldWorld|p1|0|0');
    });

    test('reports missing_capital_port for sea-bound capital without registry entry',
        () {
      final game = Game(
        id: 'audit_test',
        worldState: emptyWorld(ports: {}),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final outcome = runSeaboardPortAudit(
        game: game,
        tileMapByRegion: {'oldWorld': tileMapPass},
        topologyByRegion: {'oldWorld': topology},
      );
      expect(outcome.passed, false);
      expect(outcome.failures.single.kind, 'missing_capital_port');
      expect(outcome.failures.single.factionId, 'gp1');
      expect(outcome.failures.single.seaZoneId, 's1');
    });

    test('skips when tileMapByRegion is empty', () {
      final game = Game(
        id: 'audit_test',
        worldState: emptyWorld(),
        players: const [],
      );
      final outcome = runSeaboardPortAudit(
        game: game,
        tileMapByRegion: {},
        topologyByRegion: {'oldWorld': topology},
      );
      expect(outcome.skipped, true);
      expect(outcome.skipReason, isNotNull);
    });
  });
}
