import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

/// Tests for [resolveNonGreatPowerConnectivity] (Refs #2991 C3 — part 1).
void main() {
  group('resolveNonGreatPowerConnectivity', () {
    test('empty map when no minors and no tribes', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'Spain', isHuman: true),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );

      expect(result, isEmpty);
    });

    test(
      'minor with capital and no roads: capital + 4-adjacent owned tiles connected',
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ];
        final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 1,
          y: 1,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              displayName: 'Luxembourg',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final result = resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          topology: topology,
        );

        expect(result['minor_lux'], isNotNull);
        final connected = result['minor_lux']!.connected;
        expect(connected.contains('oldWorld|p1|1|1'), isTrue);
        expect(connected.contains('oldWorld|p1|0|1'), isTrue);
        expect(connected.contains('oldWorld|p1|2|1'), isTrue);
        expect(connected.contains('oldWorld|p1|1|0'), isTrue);
        expect(connected.contains('oldWorld|p1|1|2'), isTrue);
        // Diagonals are NOT connected without roads (only Road rule + Town rule
        // 4-adjacency from capital tile).
        expect(connected.contains('oldWorld|p1|0|0'), isFalse);
      },
    );

    test('tribe in NW: road chain extends connectivity beyond adjacency', () {
      const nw = 'newWorld';
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final cap = CapitalTile(regionId: nw, provinceId: '$nw|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('newWorld|p1|0|0', 1)
          .setRoadLevel('newWorld|p1|1|0', 1)
          .setRoadLevel('newWorld|p1|2|0', 1);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
            ],
          ),
          tileState: tileState,
        ),
        players: [],
        tribes: [
          Tribe(
            id: 'tribe_iro',
            displayName: 'Iroquois',
            capitalProvinceId: '$nw|p1',
            capitalTile: cap,
          ),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'newWorld': tileMap},
        topology: topology,
      );

      final connected = result['tribe_iro']!.connected;
      expect(connected.contains('newWorld|p1|0|0'), isTrue);
      expect(connected.contains('newWorld|p1|1|0'), isTrue);
      expect(connected.contains('newWorld|p1|2|0'), isTrue);
      // (2,1) is adjacent to a road tile (2,0) under Road rule "on or next to" so
      // it is also connected.
      expect(connected.contains('newWorld|p1|2|1'), isTrue);
    });

    test('multi-faction: keys map separately by minor id and tribe id', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final owGrid = [
        ['p1', 'p1'],
        ['p2', 'p2'],
      ];
      final nwGrid = [
        ['p3', 'p3'],
      ];
      final owMap = TileMapResult(width: 2, height: 2, grid: owGrid);
      final nwMap = TileMapResult(width: 2, height: 1, grid: nwGrid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final capLux = CapitalTile(
        regionId: ow,
        provinceId: '$ow|p1',
        x: 0,
        y: 0,
      );
      final capDen = CapitalTile(
        regionId: ow,
        provinceId: '$ow|p2',
        x: 0,
        y: 1,
      );
      final capIro = CapitalTile(
        regionId: nw,
        provinceId: '$nw|p3',
        x: 0,
        y: 0,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_den'),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|p3', regionId: nw, ownerId: 'tribe_iro'),
            ],
          ),
        ),
        players: [],
        minorNations: [
          MinorNation(
            id: 'minor_lux',
            capitalProvinceId: '$ow|p1',
            capitalTile: capLux,
          ),
          MinorNation(
            id: 'minor_den',
            capitalProvinceId: '$ow|p2',
            capitalTile: capDen,
          ),
        ],
        tribes: [
          Tribe(
            id: 'tribe_iro',
            capitalProvinceId: '$nw|p3',
            capitalTile: capIro,
          ),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topology: topology,
      );

      expect(result.keys.toSet(), {'minor_lux', 'minor_den', 'tribe_iro'});
      // Each faction sees its own capital tile (same per-tile semantics as the
      // Great Power resolver — see capital-and-connectivity.md § Connectivity
      // (Game Rule)).
      expect(result['minor_lux']!.connected.contains('oldWorld|p1|0|0'), isTrue);
      expect(result['minor_den']!.connected.contains('oldWorld|p2|0|1'), isTrue);
      expect(result['tribe_iro']!.connected.contains('newWorld|p3|0|0'), isTrue);
      // Region isolation: tribe_iro's New World province tiles never appear in
      // minor_lux's or minor_den's Old World result, and vice versa (no
      // cross-region leakage even via single-hop expansion).
      expect(result['minor_lux']!.connected.contains('newWorld|p3|0|0'), isFalse);
      expect(result['minor_den']!.connected.contains('newWorld|p3|0|0'), isFalse);
      expect(result['tribe_iro']!.connected.contains('oldWorld|p1|0|0'), isFalse);
      expect(result['tribe_iro']!.connected.contains('oldWorld|p2|0|1'), isFalse);
    });
  });
}
