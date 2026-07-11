import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

/// Coverage for town-tile connectivity (Refs #3872).
void main() {
  group('effectiveTownTileKeyForProvince', () {
    test('capital province uses capital tile', () {
      const province = Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        townTileKey: 'oldWorld|p1|9|9',
      );
      final key = effectiveTownTileKeyForProvince(
        province: province,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 2,
        ),
      );
      expect(key, 'oldWorld|p1|1|2');
    });

    test('non-capital province uses townTileKey', () {
      const province = Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        townTileKey: 'oldWorld|p2|3|4',
      );
      final key = effectiveTownTileKeyForProvince(
        province: province,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      expect(key, 'oldWorld|p2|3|4');
    });

    test('returns null when town tile is absent', () {
      const province = Province(id: 'oldWorld|p2', regionId: 'oldWorld');
      expect(
        effectiveTownTileKeyForProvince(
          province: province,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: null,
        ),
        isNull,
      );
    });
  });

  group('resolveTownConnectedTileKeysForProvince', () {
    test(
      '4-adjacent and road-path tiles within province are town-connected',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const townKey = '$ow|p1|1|1';
        const adjacentKey = '$ow|p1|0|1';
        const pathKey = '$ow|p1|2|1';
        final tileState = TileMapState()
            .setRoadLevel(townKey, 1)
            .setRoadLevel(adjacentKey, 1)
            .setRoadLevel('$ow|p1|1|0', 1)
            .setRoadLevel(pathKey, 1);
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          tileState: tileState,
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [adjacentKey, townKey, pathKey, '$ow|p1|2|0'],
            },
          },
        );
        final map = tileMapFromGrid(const [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ]);
        final connected = resolveTownConnectedTileKeysForProvince(
          provinceId: provinceId,
          townTileKey: townKey,
          worldState: world,
          tileMapByRegion: {ow: map},
          portTileToProvinceSeaZone: const {},
        );
        expect(connected, contains(townKey));
        expect(connected, contains(adjacentKey));
        expect(connected, contains(pathKey));
        expect(connected, isNot(contains('$ow|p1|2|0')));
      },
    );

    test('returns empty when town tile key is null or unparseable', () {
      final world = TestFixtures.emptyWorldState();
      expect(
        resolveTownConnectedTileKeysForProvince(
          provinceId: 'oldWorld|p1',
          townTileKey: null,
          worldState: world,
          tileMapByRegion: const {},
          portTileToProvinceSeaZone: const {},
        ),
        isEmpty,
      );
      expect(
        resolveTownConnectedTileKeysForProvince(
          provinceId: 'oldWorld|p1',
          townTileKey: 'bad-key',
          worldState: world,
          tileMapByRegion: const {},
          portTileToProvinceSeaZone: const {},
        ),
        isEmpty,
      );
    });
  });

  group('resolveTownConnectedTileKeysByProvince', () {
    test('indexes town-connected tiles for GP, minor, and tribe provinces', () {
      const ow = 'oldWorld';
      const gpProvince = '$ow|gp';
      const minorProvince = '$ow|m1';
      const tribeProvince = '$ow|t1';
      const gpTown = '$gpProvince|0|0';
      const minorTown = '$minorProvince|0|0';
      const tribeTown = '$tribeProvince|0|0';
      final tileState = TileMapState()
          .setRoadLevel(gpTown, 1)
          .setRoadLevel(minorTown, 1)
          .setRoadLevel(tribeTown, 1);
      final game = TestFixtures.minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: gpProvince,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: gpProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
        minorNations: const [
          MinorNation(
            id: 'm1',
            capitalProvinceId: minorProvince,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: minorProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
        tribes: const [
          Tribe(
            id: 't1',
            capitalProvinceId: tribeProvince,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: tribeProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: gpProvince,
              regionId: ow,
              ownerId: 'gp1',
              townTileKey: gpTown,
            ),
            Province(
              id: minorProvince,
              regionId: ow,
              ownerId: 'm1',
              townTileKey: minorTown,
            ),
            Province(
              id: tribeProvince,
              regionId: ow,
              ownerId: 't1',
              townTileKey: tribeTown,
            ),
            const Province(id: '$ow|empty', regionId: ow),
          ],
        ),
        tileKeysByRegionAndProvince: {
          ow: {
            gpProvince: [gpTown],
            minorProvince: [minorTown],
            tribeProvince: [tribeTown],
          },
        },
        tileState: tileState,
      );
      final tileMap = uniformProvinceTileMap('x', size: 1);
      final byProvince = resolveTownConnectedTileKeysByProvince(
        game: game,
        tileMapByRegion: {ow: tileMap},
      );
      expect(
        byProvince.keys,
        containsAll([gpProvince, minorProvince, tribeProvince]),
      );
      expect(byProvince[gpProvince], contains(gpTown));
      expect(byProvince[minorProvince], contains(minorTown));
      expect(byProvince[tribeProvince], contains(tribeTown));
      expect(byProvince, isNot(contains('$ow|empty')));
    });
  });
}
