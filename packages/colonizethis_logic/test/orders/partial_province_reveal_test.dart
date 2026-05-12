import 'package:colonizethis_logic/src/orders/partial_province_reveal.dart';
import 'package:colonizethis_logic/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('partiallyRevealedPrefixedProvinceIdsForPlayer', () {
    test(
      'includes prefixed province id when land tiles mix unknown and known',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final game = TestFixtures.minimalGame(
          id: 'g1',
          players: [Player(id: playerId, displayName: 'GP', isHuman: true)],
          oldWorld: const RegionData(provinces: [], units: []),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['$ow|p1|0|0', '$ow|p1|0|1'],
            },
          },
        );
        final view = PlayerView(
          playerId: playerId,
          player: Player(id: playerId, displayName: 'GP', isHuman: true),
          ownUnitsById: const {},
          provincesById: const {},
          visibilityByTile: {
            '$ow|p1|0|0': VisibilityLevel.unknown,
            '$ow|p1|0|1': VisibilityLevel.fogged,
          },
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final ids = partiallyRevealedPrefixedProvinceIdsForPlayer(
          game: game,
          view: view,
        );
        expect(ids, {'$ow|p1'});
      },
    );

    test('excludes unprefixed province keys and uniform visibility', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [Player(id: playerId, displayName: 'GP', isHuman: true)],
        oldWorld: const RegionData(provinces: [], units: []),
        tileKeysByRegionAndProvince: {
          ow: {
            'p1': ['$ow|p1|0|0'],
            '$ow|p2': ['$ow|p2|0|0', '$ow|p2|0|1'],
          },
        },
      );
      final view = PlayerView(
        playerId: playerId,
        player: Player(id: playerId, displayName: 'GP', isHuman: true),
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: {
          '$ow|p2|0|0': VisibilityLevel.fogged,
          '$ow|p2|0|1': VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final ids = partiallyRevealedPrefixedProvinceIdsForPlayer(
        game: game,
        view: view,
      );
      expect(ids, isEmpty);
    });
  });

  group('sortedProvincesForPartialRevealPrefixedIds', () {
    test('returns empty list without scanning when id set is empty', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: const [Player(id: 'p1', displayName: 'P', isHuman: true)],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|a',
              regionId: 'oldWorld',
              displayName: 'A',
              ownerId: 'p1',
            ),
          ],
          units: const [],
        ),
      );
      expect(
        sortedProvincesForPartialRevealPrefixedIds(
          world: game.worldState,
          partiallyRevealedPrefixedProvinceIds: const {},
        ),
        isEmpty,
      );
    });

    test('returns matching provinces sorted by id', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: const [Player(id: 'p1', displayName: 'P', isHuman: true)],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$ow|z',
              regionId: ow,
              displayName: 'Z',
              ownerId: 'p1',
            ),
            Province(
              id: '$ow|m',
              regionId: ow,
              displayName: 'M',
              ownerId: 'p1',
            ),
            Province(
              id: '$ow|skip',
              regionId: ow,
              displayName: 'S',
              ownerId: 'p1',
            ),
          ],
          units: const [],
        ),
      );
      final sorted = sortedProvincesForPartialRevealPrefixedIds(
        world: game.worldState,
        partiallyRevealedPrefixedProvinceIds: {'$ow|z', '$ow|m'},
      );
      expect(sorted.map((p) => p.id).toList(), ['$ow|m', '$ow|z']);
    });
  });
}
