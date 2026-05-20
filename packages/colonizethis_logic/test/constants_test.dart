import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('kRegion constants', () {
    test('kRegionOldWorld is oldWorld', () {
      expect(kRegionOldWorld, 'oldWorld');
    });

    test('kRegionNewWorld is newWorld', () {
      expect(kRegionNewWorld, 'newWorld');
    });
  });

  group('GamePlayerLookup.playerById', () {
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'France', isHuman: true),
        Player(id: 'gp2', displayName: 'England', isHuman: false),
        Player(id: 'gp3', displayName: 'Spain', isHuman: false),
      ],
    );

    test('returns player when id matches', () {
      final p = game.playerById('gp2');
      expect(p, isNotNull);
      expect(p!.id, 'gp2');
      expect(p.displayName, 'England');
    });

    test('returns null when id not found', () {
      expect(game.playerById('nonexistent'), isNull);
    });

    test('returns first player', () {
      expect(game.playerById('gp1')?.displayName, 'France');
    });

    test('returns last player', () {
      expect(game.playerById('gp3')?.displayName, 'Spain');
    });

    test('handles empty player list', () {
      final emptyGame = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      expect(emptyGame.playerById('gp1'), isNull);
    });

    test('lookup scales across many distinct player ids', () {
      const count = 120;
      final players = List<Player>.generate(
        count,
        (i) => Player(
          id: 'p$i',
          displayName: 'P$i',
          isHuman: i.isEven,
        ),
      );
      final bigGame = Game(
        id: 'g-many',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: players,
      );
      for (var i = 0; i < count; i++) {
        expect(bigGame.playerById('p$i')?.id, 'p$i');
      }
      expect(bigGame.playerById('missing'), isNull);
    });

    test('duplicate player ids keep first list occurrence', () {
      final dupGame = Game(
        id: 'g-dup',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'dup', displayName: 'First', isHuman: true),
          Player(id: 'dup', displayName: 'Second', isHuman: false),
        ],
      );
      expect(dupGame.playerById('dup')?.displayName, 'First');
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
  });

  group('GamePlayerLookup.otherGreatPowerAtCapitalProvince', () {
    const cap = 'oldWorld|paris';

    final capitalGame = Game(
      id: 'g-cap',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(
          id: 'gp1',
          displayName: 'France',
          isHuman: true,
          capitalProvinceId: cap,
        ),
        Player(
          id: 'gp2',
          displayName: 'England',
          isHuman: false,
          capitalProvinceId: 'oldWorld|london',
        ),
      ],
    );

    test('returns owner when capital matches and id is not excluded', () {
      final p = capitalGame.otherGreatPowerAtCapitalProvince(cap, 'gp2');
      expect(p?.id, 'gp1');
    });

    test('returns null when excluded player owns that capital', () {
      expect(capitalGame.otherGreatPowerAtCapitalProvince(cap, 'gp1'), isNull);
    });

    test('returns null when no GP claims that capital province', () {
      expect(
        capitalGame.otherGreatPowerAtCapitalProvince('oldWorld|void', 'gp2'),
        isNull,
      );
    });

    test('duplicate capitals keep first list occurrence for owner map', () {
      final dupCap = Game(
        id: 'g-dup-cap',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
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

  group('GamePlayerLookup.factionDisplayNameById', () {
    // Mixed-faction game with player, minor nation, and tribe rows so the
    // extension's combined index (Refs #2575 Phase 3) can be exercised in one
    // place without relying on app-side scans.
    final mixedGame = Game(
      id: 'g-factions',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'France', isHuman: true),
        Player(id: 'gp2', displayName: 'England', isHuman: false),
      ],
      minorNations: const [
        MinorNation(id: 'mn1', displayName: 'Florence'),
        MinorNation(id: 'mn2'),
      ],
      tribes: const [
        Tribe(id: 'tribe1', displayName: 'Iroquois'),
        Tribe(id: 'tribe2'),
      ],
    );

    test('returns player display name for player id', () {
      expect(mixedGame.factionDisplayNameById('gp1'), 'France');
      expect(mixedGame.factionDisplayNameById('gp2'), 'England');
    });

    test('returns minor nation display name when set', () {
      expect(mixedGame.factionDisplayNameById('mn1'), 'Florence');
    });

    test('falls back to minor nation id when display name is null', () {
      expect(mixedGame.factionDisplayNameById('mn2'), 'mn2');
    });

    test('returns tribe display name when set', () {
      expect(mixedGame.factionDisplayNameById('tribe1'), 'Iroquois');
    });

    test('falls back to tribe id when display name is null', () {
      expect(mixedGame.factionDisplayNameById('tribe2'), 'tribe2');
    });

    test('returns null for unknown faction id', () {
      expect(mixedGame.factionDisplayNameById('missing'), isNull);
    });

    test('copyWith new minorNations invalidates cache for new instance', () {
      final updated = mixedGame.copyWith(
        minorNations: [
          ...mixedGame.minorNations,
          const MinorNation(id: 'mn3', displayName: 'Genoa'),
        ],
      );
      expect(mixedGame.factionDisplayNameById('mn3'), isNull);
      expect(updated.factionDisplayNameById('mn3'), 'Genoa');
    });

    test('player id wins on id collision with minor nation or tribe', () {
      final collisionGame = Game(
        id: 'g-collision',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'dup', displayName: 'PlayerWins', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'dup', displayName: 'MinorLoses')],
        tribes: const [Tribe(id: 'dup', displayName: 'TribeLoses')],
      );
      expect(collisionGame.factionDisplayNameById('dup'), 'PlayerWins');
    });

    test('empty faction lists return null for any id', () {
      final emptyGame = Game(
        id: 'g-empty',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      expect(emptyGame.factionDisplayNameById('anything'), isNull);
    });

    test('repeated lookups reuse cached map (same Game instance)', () {
      // Two consecutive lookups should both succeed; the second uses the
      // Expando-cached map seeded by the first. This exercises the
      // putIfAbsent path without observing internal state directly.
      expect(mixedGame.factionDisplayNameById('gp1'), 'France');
      expect(mixedGame.factionDisplayNameById('mn1'), 'Florence');
      expect(mixedGame.factionDisplayNameById('tribe1'), 'Iroquois');
      expect(mixedGame.factionDisplayNameById('missing'), isNull);
    });
  });
}
