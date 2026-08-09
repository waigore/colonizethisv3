import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
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
}
