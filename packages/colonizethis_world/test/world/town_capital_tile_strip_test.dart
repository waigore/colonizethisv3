import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/town_capital_tile_strip.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
void main() {
  group('collectTownAndCapitalTileKeys', () {
    test('collects player, minor, tribe capitals and province town tiles', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 1,
              y: 2,
            ),
          ),
          Player(id: 'gp2', displayName: 'No capital', isHuman: false),
        ],
        minorNations: const [
          MinorNation(
            id: 'm1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|m',
              x: 3,
              y: 4,
            ),
          ),
        ],
        tribes: const [
          Tribe(
            id: 't1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|t',
              x: 5,
              y: 6,
            ),
          ),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p2|7|8',
            ),
            Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
          ],
        ),
      );

      final keys = collectTownAndCapitalTileKeys(game);
      expect(keys, {
        'oldWorld|p1|1|2',
        'oldWorld|m|3|4',
        'oldWorld|t|5|6',
        'oldWorld|p2|7|8',
      });
    });

    test('returns empty set when nothing has capital or town tiles', () {
      final game = TestFixtures.minimalGame();
      expect(collectTownAndCapitalTileKeys(game), isEmpty);
    });
  });

  group('stripResourcesAndExtractionImprovementsOnTileKeys', () {
    test('removes resource entries for valid keys and skips invalid keys', () {
      final game = TestFixtures.minimalGame(
        resourceByTileKey: const {
          'oldWorld|p1|0|0': 'food',
          'oldWorld|p1|1|1': 'silver',
        },
      );

      final (nextGame, maps) =
          stripResourcesAndExtractionImprovementsOnTileKeys(
        game,
        null,
        const ['oldWorld|p1|0|0', 'not-a-tile-key'],
      );

      expect(nextGame.worldState.resourceByTileKey.containsKey('oldWorld|p1|0|0'),
          isFalse);
      expect(nextGame.worldState.resourceByTileKey['oldWorld|p1|1|1'], 'silver');
      expect(maps, isNull);
    });

    test('returns the provided tile-map collection when one is supplied', () {
      final game = TestFixtures.minimalGame(
        resourceByTileKey: const {'oldWorld|p1|0|0': 'food'},
      );

      final (nextGame, maps) =
          stripResourcesAndExtractionImprovementsOnTileKeys(
        game,
        const {},
        const ['oldWorld|p1|0|0'],
      );

      expect(nextGame.worldState.resourceByTileKey, isEmpty);
      expect(maps, isNotNull);
    });
  });
}
