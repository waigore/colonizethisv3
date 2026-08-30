import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Coverage for `GamePlayerLookup` (Refs #3290; unique cases #4660).
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

    test('handles empty player list', () {
      final empty = TestFixtures.minimalGame(players: const []);
      expect(empty.playerById('gp1'), isNull);
    });

    test('duplicate player ids keep first list occurrence', () {
      final dup = TestFixtures.minimalGame(
        players: const [
          Player(id: 'dup', displayName: 'First', isHuman: true),
          Player(id: 'dup', displayName: 'Second', isHuman: false),
        ],
      );
      expect(dup.playerById('dup')?.displayName, 'First');
    });

    test('copyWith new players list invalidates lookup for new instance', () {
      final updated = game.copyWith(
        players: [
          ...game.players,
          const Player(id: 'gp4', displayName: 'Portugal', isHuman: false),
        ],
      );
      expect(game.playerById('gp4'), isNull);
      expect(updated.playerById('gp4')?.displayName, 'Portugal');
    });

    test('lookup scales across many distinct player ids', () {
      const count = 80;
      final big = TestFixtures.minimalGame(
        players: List<Player>.generate(
          count,
          (i) => Player(id: 'p$i', displayName: 'P$i', isHuman: i.isEven),
        ),
      );
      for (var i = 0; i < count; i++) {
        expect(big.playerById('p$i')?.id, 'p$i');
      }
      expect(big.playerById('missing'), isNull);
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

    test('returns null when no capital matches', () {
      expect(
        game.otherGreatPowerAtCapitalProvince('oldWorld|none', 'gp1'),
        isNull,
      );
    });

    test('duplicate capitals keep first list occurrence for owner map', () {
      const cap = 'oldWorld|paris';
      final dupCap = TestFixtures.minimalGame(
        players: const [
          Player(
            id: 'a',
            displayName: 'A',
            isHuman: true,
            capitalProvinceId: cap,
          ),
          Player(
            id: 'b',
            displayName: 'B',
            isHuman: false,
            capitalProvinceId: cap,
          ),
        ],
      );
      expect(dupCap.otherGreatPowerAtCapitalProvince(cap, 'x')?.id, 'a');
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

    test('copyWith new minorNations invalidates cache for new instance', () {
      final updated = game.copyWith(
        minorNations: [
          ...game.minorNations,
          const MinorNation(id: 'mn3', displayName: 'Genoa'),
        ],
      );
      expect(game.factionDisplayNameById('mn3'), isNull);
      expect(updated.factionDisplayNameById('mn3'), 'Genoa');
    });

    test('player id wins on id collision with minor nation or tribe', () {
      final collision = TestFixtures.minimalGame(
        players: const [
          Player(id: 'dup', displayName: 'PlayerWins', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'dup', displayName: 'MinorLoses')],
        tribes: const [Tribe(id: 'dup', displayName: 'TribeLoses')],
      );
      expect(collision.factionDisplayNameById('dup'), 'PlayerWins');
    });

    test('empty faction lists return null for any id', () {
      final empty = TestFixtures.minimalGame(players: const []);
      expect(empty.factionDisplayNameById('anything'), isNull);
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

    test('handles empty fleet list', () {
      expect(game.fleetById('anything'), isNull);
    });

    test('duplicate fleet ids keep first list occurrence', () {
      final g = game.copyWith(
        worldState: game.worldState.copyWith(
          fleets: [
            Fleet(id: 'dup', ownerId: 'gp1', regionId: 'oldWorld'),
            Fleet(id: 'dup', ownerId: 'gp2', regionId: 'newWorld'),
          ],
        ),
      );
      expect(g.fleetById('dup')?.ownerId, 'gp1');
    });

    test('copyWith new worldState invalidates lookup for new instance', () {
      final updated = withFleet.copyWith(
        worldState: withFleet.worldState.copyWith(
          fleets: [
            Fleet(id: 'f1', ownerId: 'gp1', regionId: 'oldWorld'),
            Fleet(id: 'f2', ownerId: 'gp1', regionId: 'oldWorld'),
          ],
        ),
      );
      expect(withFleet.fleetById('f2'), isNull);
      expect(updated.fleetById('f2')?.id, 'f2');
    });

    test('lookup scales across many distinct fleet ids', () {
      const count = 80;
      final g = game.copyWith(
        worldState: game.worldState.copyWith(
          fleets: List<Fleet>.generate(
            count,
            (i) => Fleet(
              id: 'fleet_$i',
              ownerId: 'gp1',
              regionId: i.isEven ? 'oldWorld' : 'newWorld',
            ),
          ),
        ),
      );
      for (var i = 0; i < count; i++) {
        expect(g.fleetById('fleet_$i')?.id, 'fleet_$i');
      }
      expect(g.fleetById('missing'), isNull);
    });
  });
}
