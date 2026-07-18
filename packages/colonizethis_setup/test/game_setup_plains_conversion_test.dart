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

  group('assignProvinceTowns plains', () {
    test('ownerless province prefers plains and converts if needed', () {
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.hills, TerrainType.desert],
        ],
        resourceGrid: [
          [Resource.grain, Resource.iron],
        ],
      );
      final maps = {'oldWorld': map};
      final p1 = Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        ownerId: null,
      );
      final game = TestFixtures.minimalGame(
        id: 'g',
        turnNumber: 0,
        players: const [],
        oldWorld: RegionData(provinces: [p1]),
        tileKeysByRegionAndProvince: {
          'oldWorld': {
            'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
          },
        },
      );
      final next = assignProvinceTowns(
        game: game,
        topologyByRegion: {
          'oldWorld': const MapTopology(nodes: [], edges: []),
        },
        tileMapByRegion: maps,
      );
      final town = next.worldState.oldWorld.provinces.single.townTileKey;
      expect(town, isNotNull);
      final parsed = parseTileKeyCoordinates(town!);
      expect(parsed, isNotNull);
      expect(maps['oldWorld']!.terrainAt(parsed!.x, parsed.y), TerrainType.plains);
      expect(maps['oldWorld']!.resourceAt(parsed.x, parsed.y), isNull);
    });

    test(
      'overseas port town converts non-plains port and clears resource '
      '(Refs #4065)',
      () {
        // Capital in oldWorld; overseas NW province uses registered port as
        // town (non-sea-bound topology so the overseas-port branch applies).
        const portKey = 'newWorld|nw1|0|0';
        final owMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['cap'],
          ],
          terrainGrid: [
            [TerrainType.plains],
          ],
        );
        final nwMap = TileMapResult(
          width: 2,
          height: 1,
          grid: [
            ['nw1', 'nw1'],
          ],
          terrainGrid: [
            [TerrainType.hills, TerrainType.desert],
          ],
          resourceGrid: [
            [Resource.iron, Resource.grain],
          ],
        );
        final maps = {'oldWorld': owMap, 'newWorld': nwMap};
        final game = TestFixtures.minimalGame(
          id: 'g',
          turnNumber: 0,
          players: [
            const Player(id: 'gp1', displayName: 'G', isHuman: true).copyWith(
              capitalProvinceId: 'oldWorld|cap',
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|cap',
                x: 0,
                y: 0,
              ),
            ),
          ],
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|cap',
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              const Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'gp1',
              ),
            ],
          ),
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|cap': ['oldWorld|cap|0|0'],
            },
            'newWorld': {
              'newWorld|nw1': [portKey, 'newWorld|nw1|1|0'],
            },
          },
          portsByProvinceSeaboard: const {
            'newWorld|nw1|sea1': portKey,
          },
          resourceByTileKey: const {portKey: 'iron'},
          tileState: const TileMapState().setImprovement(portKey, 2),
        );
        final next = assignProvinceTowns(
          game: game,
          topologyByRegion: {
            'oldWorld': const MapTopology(nodes: [], edges: []),
            'newWorld': const MapTopology(nodes: [], edges: []),
          },
          tileMapByRegion: maps,
        );
        final town = next.worldState.newWorld.provinces.single.townTileKey;
        expect(town, portKey);
        final convertedNw = maps['newWorld']!;
        expect(convertedNw.terrainAt(0, 0), TerrainType.plains);
        expect(convertedNw.resourceAt(0, 0), isNull);
        expect(next.worldState.resourceByTileKey.containsKey(portKey), isFalse);
        expect(next.worldState.tileState.improvementLevel(portKey), 0);
        // Non-port tile stays non-plains (conversion is select-then-convert only).
        expect(convertedNw.terrainAt(1, 0), TerrainType.desert);
      },
    );
  });

  group('restoreGpOwTerrainCountsAfterSettlementPlains', () {
    test('relocates destroyed hills onto non-settlement plains', () {
      // (0,0) settlement plains (was hills); (1,0) non-settlement plains donor.
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.plains],
        ],
        resourceGrid: [
          [null, null],
        ],
      );
      final game = TestFixtures.minimalGame(
        id: 'g',
        turnNumber: 0,
        players: const [
          Player(id: 'gp1', displayName: 'G', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        ),
      ).copyWith(
        players: [
          const Player(id: 'gp1', displayName: 'G', isHuman: true).copyWith(
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final targets = <TerrainType, int>{
        for (final t in TerrainType.values) t: 0,
      };
      targets[TerrainType.hills] = 1;
      targets[TerrainType.plains] = 1;
      final out = restoreGpOwTerrainCountsAfterSettlementPlains(
        game: game,
        tileMapOldWorld: map,
        targetCounts: targets,
      );
      expect(out.terrainAt(0, 0), TerrainType.plains);
      expect(out.terrainAt(1, 0), TerrainType.hills);
      final counts = countGpOwTerrainByType(game: game, tileMapOldWorld: out);
      expect(counts[TerrainType.hills], 1);
      expect(counts[TerrainType.plains], 1);
    });

    test('negative: does not mutate settlement plains when no deficit', () {
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.hills],
        ],
        resourceGrid: [
          [null, null],
        ],
      );
      final game = TestFixtures.minimalGame(
        id: 'g',
        turnNumber: 0,
        players: const [
          Player(id: 'gp1', displayName: 'G', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        ),
      ).copyWith(
        players: [
          const Player(id: 'gp1', displayName: 'G', isHuman: true).copyWith(
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final targets = countGpOwTerrainByType(game: game, tileMapOldWorld: map);
      final out = restoreGpOwTerrainCountsAfterSettlementPlains(
        game: game,
        tileMapOldWorld: map,
        targetCounts: targets,
      );
      expect(out.terrainAt(0, 0), TerrainType.plains);
      expect(out.terrainAt(1, 0), TerrainType.hills);
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
