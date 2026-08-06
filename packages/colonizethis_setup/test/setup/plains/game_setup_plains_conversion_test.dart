import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('preferPlainsTownCandidates', () {
    test('returns only plains when any plains exist', () {
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.hills, TerrainType.plains],
        ],
      );
      final out = preferPlainsTownCandidates(
        candidates: const ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
        tileMap: map,
      );
      expect(out, ['oldWorld|p1|1|0']);
    });

    test('keeps full set when no plains among candidates', () {
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.hills, TerrainType.desert],
        ],
      );
      final candidates = ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'];
      expect(
        preferPlainsTownCandidates(candidates: candidates, tileMap: map),
        candidates,
      );
    });
  });

  group('ensureTileIsPlains', () {
    test('no-ops when tile is already plains', () {
      final map = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final maps = {'oldWorld': map};
      final game = _minimalOwnedProvinceGame(
        provinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
        resourceByTileKey: {'oldWorld|p1|0|0': 'grain'},
        improvement: 2,
      );
      final out = ensureTileIsPlains(
        game: game,
        tileMapByRegion: maps,
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(out.converted, isFalse);
      expect(maps['oldWorld']!.terrainAt(0, 0), TerrainType.plains);
      expect(maps['oldWorld']!.resourceAt(0, 0), Resource.grain);
      expect(out.game.worldState.tileState.improvementLevel('oldWorld|p1|0|0'), 2);
    });

    test('converts non-plains and clears resource/extraction', () {
      final map = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
        terrainGrid: [
          [TerrainType.hills],
        ],
        resourceGrid: [
          [Resource.iron],
        ],
      );
      final maps = {'oldWorld': map};
      final game = _minimalOwnedProvinceGame(
        provinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
        resourceByTileKey: {'oldWorld|p1|0|0': 'iron'},
        improvement: 3,
      );
      final out = ensureTileIsPlains(
        game: game,
        tileMapByRegion: maps,
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(out.converted, isTrue);
      expect(maps['oldWorld']!.terrainAt(0, 0), TerrainType.plains);
      expect(maps['oldWorld']!.resourceAt(0, 0), isNull);
      expect(out.game.worldState.resourceByTileKey.containsKey('oldWorld|p1|0|0'), isFalse);
      expect(out.game.worldState.tileState.improvementLevel('oldWorld|p1|0|0'), 0);
    });
  });

  group('pickCapitalForFaction plains preference', () {
    test('prefers plains Class A over earlier non-plains Class A', () {
      // Row-major: (0,0) hills Class A coastal, (1,0) plains Class A coastal.
      final grid = [
        ['p1', 'p1', 'sea1'],
        ['p1', 'p1', 'sea1'],
      ];
      final terrain = [
        [TerrainType.hills, TerrainType.plains, null],
        [TerrainType.hills, TerrainType.hills, null],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final tileMap = TileMapResult(
        width: 3,
        height: 2,
        grid: grid,
        terrainGrid: terrain,
      );
      final (_, tile) = pickCapitalForFaction(
        ['oldWorld|p1'],
        'oldWorld',
        topology,
        tileMap,
      );
      expect(tile.x, 1);
      expect(tile.y, 0);
      expect(tileMap.terrainAt(tile.x, tile.y), TerrainType.plains);
    });

    test('Class A non-plains beats Class B plains', () {
      // Class A coastal at (1,0) hills; Class B interior plains at (0,0).
      final grid = [
        ['p1', 'p1'],
        ['p1', 'sea1'],
      ];
      final terrain = [
        [TerrainType.plains, TerrainType.hills],
        [TerrainType.hills, null],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        terrainGrid: terrain,
      );
      final (_, tile) = pickCapitalForFaction(
        ['oldWorld|p1'],
        'oldWorld',
        topology,
        tileMap,
      );
      expect(tile.x, 1);
      expect(tile.y, 0);
      expect(tileMap.terrainAt(1, 0), TerrainType.hills);
    });
  });
}

Game _minimalOwnedProvinceGame({
  required String provinceId,
  required String tileKey,
  Map<String, String> resourceByTileKey = const {},
  int improvement = 0,
}) {
  var tileState = const TileMapState();
  if (improvement != 0) {
    tileState = tileState.setImprovement(tileKey, improvement);
  }
  return TestFixtures.minimalGame(
    id: 'g',
    turnNumber: 0,
    players: const [
      Player(id: 'gp1', displayName: 'G', isHuman: true),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(id: provinceId, regionId: 'oldWorld', ownerId: 'gp1'),
      ],
    ),
    resourceByTileKey: resourceByTileKey,
    tileState: tileState,
  );
}
