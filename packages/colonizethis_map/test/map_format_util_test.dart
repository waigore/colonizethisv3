import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('formatTileKey', () {
    test('returns x,y when tile key has four pipe-separated parts', () {
      expect(formatTileKey('oldWorld|p1|3|5'), '3,5');
      expect(formatTileKey('newWorld|p2|0|0'), '0,0');
    });

    test('returns tileKey unchanged when fewer than four parts', () {
      expect(formatTileKey('a|b'), 'a|b');
      expect(formatTileKey('x'), 'x');
    });

    test('returns tileKey unchanged for empty string', () {
      expect(formatTileKey(''), '');
    });

    test('uses fourth and fifth part when more than four parts', () {
      expect(formatTileKey('r|p|1|2'), '1,2');
      expect(formatTileKey('r|p|1|2|extra'), '1,2');
    });
  });

  group('greatPowerColorOverrideFromGame', () {
    test('returns null when game has no override', () {
      expect(
        greatPowerColorOverrideFromGame(
          minimalGame(
            id: 'g',
            players: const [
              Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            ],
          ),
        ),
        isNull,
      );
      expect(
        greatPowerColorOverrideFromGame(
          minimalGame(
            id: 'g',
            players: const [
              Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            ],
            greatPowerColorOverride: null,
          ),
        ),
        isNull,
      );
    });

    test('returns null when override is empty', () {
      expect(
        greatPowerColorOverrideFromGame(
          minimalGame(
            id: 'g',
            players: const [
              Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            ],
            greatPowerColorOverride: {},
          ),
        ),
        isNull,
      );
    });

    test('converts list form to tuple form', () {
      final game = minimalGame(
        id: 'g',
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        ],
        greatPowerColorOverride: {
          'gp1': [1, 2, 3],
          'gp2': [255, 0, 0],
        },
      );
      final result = greatPowerColorOverrideFromGame(game);
      expect(result, isNotNull);
      expect(result!['gp1'], (1, 2, 3));
      expect(result['gp2'], (255, 0, 0));
    });
  });
}
