import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:sim_scenarios/seaboard_port_audit.dart';

void main() {
  group('runSeaboardPortAudit', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 's1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
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

    test(
      'passes when port tile has orthogonal sea and capital ports complete',
      () {
        final game = Game(
          id: 'audit_test',
          worldState: emptyWorld(ports: {'oldWorld|p1|s1': 'oldWorld|p1|1|0'}),
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
      },
    );

    test(
      'reports drawable_error when port tile has no orthogonal sea cell',
      () {
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
          worldState: emptyWorld(ports: {'oldWorld|p1|s1': 'oldWorld|p1|0|0'}),
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
      },
    );

    test(
      'reports missing_capital_port for sea-bound capital without registry entry',
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
      },
    );

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

    test('passes when overseas owned province town matches a port tile '
        '(SPEC capital-and-connectivity § Town per province)', () {
      final topologyNw = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'snw',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'nw1', id2: 'snw')],
      );
      final tileMapNw = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['nw1', 'nw1'],
          ['snw', 'snw'],
        ],
      );
      final game = Game(
        id: 'audit_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'england',
                townTileKey: 'oldWorld|p1|0|0',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: [
              Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'england',
                townTileKey: 'newWorld|nw1|0|0',
              ),
            ],
            units: const [],
          ),
          portsByProvinceSeaboard: {
            'oldWorld|p1|s1': 'oldWorld|p1|1|0',
            'newWorld|nw1|snw': 'newWorld|nw1|0|0',
          },
        ),
        players: const [
          Player(
            id: 'england',
            displayName: 'England',
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
        tileMapByRegion: {'oldWorld': tileMapPass, 'newWorld': tileMapNw},
        topologyByRegion: {'oldWorld': topology, 'newWorld': topologyNw},
      );
      expect(outcome.skipped, false);
      expect(outcome.passed, true);
    });

    test('reports overseas_town_not_port_tile when overseas province has ports '
        'but town is not on a port tile', () {
      final topologyNw = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'snw',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'nw1', id2: 'snw')],
      );
      final tileMapNw = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['nw1', 'nw1'],
          ['snw', 'snw'],
        ],
      );
      final game = Game(
        id: 'audit_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'england',
                townTileKey: 'oldWorld|p1|0|0',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: [
              Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'england',
                townTileKey: 'newWorld|nw1|1|0',
              ),
            ],
            units: const [],
          ),
          portsByProvinceSeaboard: {
            'oldWorld|p1|s1': 'oldWorld|p1|1|0',
            'newWorld|nw1|snw': 'newWorld|nw1|0|0',
          },
        ),
        players: const [
          Player(
            id: 'england',
            displayName: 'England',
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
        tileMapByRegion: {'oldWorld': tileMapPass, 'newWorld': tileMapNw},
        topologyByRegion: {'oldWorld': topology, 'newWorld': topologyNw},
      );
      expect(outcome.passed, false);
      final overseas = outcome.failures
          .where((f) => f.kind == 'overseas_town_not_port_tile')
          .toList();
      expect(overseas, isNotEmpty);
      expect(overseas.single.provinceId, 'newWorld|nw1');
      expect(overseas.single.townTileKey, 'newWorld|nw1|1|0');
    });

    test('does not require ports for unowned seaboard province', () {
      final game = Game(
        id: 'audit_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: null,
                townTileKey: 'oldWorld|p1|0|0',
              ),
            ],
            units: const [],
          ),
          newWorld: const RegionData(provinces: [], units: []),
          portsByProvinceSeaboard: {},
        ),
        players: const [],
      );
      final outcome = runSeaboardPortAudit(
        game: game,
        tileMapByRegion: {'oldWorld': tileMapPass},
        topologyByRegion: {'oldWorld': topology},
      );
      expect(outcome.skipped, false);
      expect(outcome.passed, true);
    });
  });
}
