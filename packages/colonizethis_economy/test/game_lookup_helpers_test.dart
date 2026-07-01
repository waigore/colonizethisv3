import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_economy/src/economy/game_lookup_helpers.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Dedicated unit tests for the package-local `Game` lookup helpers.
/// SPEC/game/world-model.md (prefixed province ids).
void main() {
  group('buildProvinceIndex', () {
    test('indexes provinces across both regions by prefixed id', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
          ],
        ),
        newWorld: const RegionData(
          provinces: [Province(id: 'newWorld|n1', regionId: 'newWorld')],
        ),
      );

      final index = buildProvinceIndex(game);

      expect(index.keys.toSet(), {'oldWorld|p1', 'oldWorld|p2', 'newWorld|n1'});
      expect(index['oldWorld|p1']!.regionId, 'oldWorld');
      expect(index['newWorld|n1']!.regionId, 'newWorld');
    });

    test('empty world produces an empty index', () {
      final game = TestFixtures.minimalGame();

      expect(buildProvinceIndex(game), isEmpty);
    });
  });

  group('collectPortTileKeys', () {
    test('collects the seaboard port tile keys as a set', () {
      final game = TestFixtures.minimalGame(
        portsByProvinceSeaboard: const {
          'oldWorld|harbor|north': 'oldWorld|harbor|0|0',
          'newWorld|harbor|south': 'newWorld|harbor|1|1',
        },
      );

      expect(collectPortTileKeys(game), {
        'oldWorld|harbor|0|0',
        'newWorld|harbor|1|1',
      });
    });

    test('deduplicates seaboards that map to the same tile key', () {
      final game = TestFixtures.minimalGame(
        portsByProvinceSeaboard: const {
          'oldWorld|harbor|north': 'oldWorld|harbor|0|0',
          'oldWorld|harbor|east': 'oldWorld|harbor|0|0',
        },
      );

      expect(collectPortTileKeys(game), {'oldWorld|harbor|0|0'});
    });

    test('no ports produces an empty set', () {
      final game = TestFixtures.minimalGame();

      expect(collectPortTileKeys(game), isEmpty);
    });
  });
}
