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
}
