import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
void main() {
  final game = TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gp1',
        displayName: 'Great One',
        isHuman: true,
        capitalProvinceId: 'oldWorld|c1',
      ),
      Player(
        id: 'gp2',
        displayName: 'Great Two',
        isHuman: false,
        capitalProvinceId: 'oldWorld|c2',
      ),
    ],
    minorNations: const [MinorNation(id: 'm1')],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
  );

  group('playerById', () {
    test('returns the player for a known id', () {
      expect(game.playerById('gp1')?.displayName, 'Great One');
    });

    test('returns null for an unknown id', () {
      expect(game.playerById('nobody'), isNull);
    });
  });

  group('otherGreatPowerAtCapitalProvince', () {
    test('returns the owner when it is not the excluded player', () {
      expect(
        game.otherGreatPowerAtCapitalProvince('oldWorld|c1', 'gp2')?.id,
        'gp1',
      );
    });

    test('returns null when the owner is the excluded player', () {
      expect(
        game.otherGreatPowerAtCapitalProvince('oldWorld|c1', 'gp1'),
        isNull,
      );
    });

    test('returns null when no player has that capital province', () {
      expect(
        game.otherGreatPowerAtCapitalProvince('oldWorld|none', 'gp1'),
        isNull,
      );
    });
  });

  group('factionDisplayNameById', () {
    test('returns the player display name', () {
      expect(game.factionDisplayNameById('gp1'), 'Great One');
    });

    test('falls back to the id when a minor has no display name', () {
      expect(game.factionDisplayNameById('m1'), 'm1');
    });

    test('returns the tribe display name', () {
      expect(game.factionDisplayNameById('t1'), 'Tribe One');
    });

    test('returns null for an unknown faction id', () {
      expect(game.factionDisplayNameById('zzz'), isNull);
    });
  });

  group('fleetById', () {
    final withFleet = game.copyWith(
      worldState: game.worldState.copyWith(
        fleets: [Fleet(id: 'f1', ownerId: 'gp1', regionId: 'oldWorld')],
      ),
    );

    test('returns the fleet for a known id', () {
      expect(withFleet.fleetById('f1')?.ownerId, 'gp1');
    });

    test('returns null for an unknown fleet id', () {
      expect(withFleet.fleetById('zzz'), isNull);
    });
  });
}
