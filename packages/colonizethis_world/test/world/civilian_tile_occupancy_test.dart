import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_world/src/world/civilian_tile_occupancy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('isLandTileKeyForGame', () {
    const ow = 'oldWorld';
    const p1 = '$ow|p1';
    const listedTile = '$p1|0|0';
    const fallbackTile = '$p1|9|9';

    test('accepts listed land tile keys from world index', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: p1, regionId: ow, ownerId: 'gp1')],
          units: [],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {p1: [listedTile]},
        },
      );
      expect(isLandTileKeyForGame(game, listedTile), isTrue);
    });

    test('falls back to province existence for sparse worlds', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: p1, regionId: ow, ownerId: 'gp1')],
          units: [],
        ),
      );
      expect(isLandTileKeyForGame(game, fallbackTile), isTrue);
    });

    test('rejects tile when not indexed and province does not exist', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: p1, regionId: ow, ownerId: 'gp1')],
          units: [],
        ),
      );
      expect(isLandTileKeyForGame(game, '$ow|missing|0|0'), isFalse);
    });
  });

  group('civilianMayOccupyLandTileKey', () {
    const ow = 'oldWorld';
    const tileP2 = '$ow|p2|0|0';

    Game gameWithProvinces(List<Province> provinces) => TestFixtures.minimalGame(
          oldWorld: RegionData(provinces: provinces, units: const []),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
        );

    test('Spy may occupy another Great Power province tile', () {
      final game = gameWithProvinces([
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
      ]);
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: kUnitTypeSpy,
          destinationTileKey: tileP2,
        ),
        isTrue,
      );
    });

    test('factionMembership snapshot matches linear classification (Refs #2394)', () {
      final game = gameWithProvinces([
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
      ]);
      final membership = DiplomacyFactionMembership.from(game);
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: kUnitTypeSpy,
          destinationTileKey: tileP2,
          factionMembership: membership,
        ),
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: kUnitTypeSpy,
          destinationTileKey: tileP2,
        ),
      );
    });

    test('Builder may not occupy another Great Power province without purchase', () {
      final game = gameWithProvinces([
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
      ]);
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: kUnitTypeBuilder,
          destinationTileKey: tileP2,
        ),
        isFalse,
      );
    });

    test('purchased tile allows Builder on tile inside other GP province', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
          ],
          units: [],
        ),
        purchasedTilesByTileKey: {tileP2: 'gp1'},
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: kUnitTypeBuilder,
          destinationTileKey: tileP2,
        ),
        isTrue,
      );
    });
  });
}
