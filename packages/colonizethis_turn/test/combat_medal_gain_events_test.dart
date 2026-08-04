import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';


Game _minimalGame({List<General> generals = const []}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'att', displayName: 'Att', isHuman: true)],
    generals: generals,
  );
}

void main() {
  group('winningGeneralIdForBattle', () {
    test('returns defender general when defender wins', () {
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        defenderGeneralId: 'g-def',
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(winningGeneralIdForBattle(ctx, 'def'), 'g-def');
    });

    test('returns attacker general when attacker wins', () {
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1'],
            generalId: 'g-att',
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(winningGeneralIdForBattle(ctx, 'att'), 'g-att');
    });
  });

  group('emitGeneralMedalGainedIfAny', () {
    test('emits when winner general medals increase', () {
      final before = _minimalGame(
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 1)],
      );
      final after = _minimalGame(
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 2)],
      );
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1'],
            generalId: 'g-att',
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final events = <GameEvent>[];
      emitGeneralMedalGainedIfAny(
        gameBefore: before,
        gameAfter: after,
        ctx: ctx,
        winnerId: 'att',
        turn: 3,
        sink: TurnEventSink(onGameEvent: events.add),
      );

      expect(events, hasLength(1));
      expect(events.single, isA<GeneralMedalGainedEvent>());
      final event = events.single as GeneralMedalGainedEvent;
      expect(event.playerId, 'att');
      expect(event.generalId, 'g-att');
      expect(event.provinceId, 'oldWorld|p1');
      expect(event.newMedals, 2);
      expect(event.turnNumber, 3);
    });

    test('omits when medals unchanged at cap', () {
      final before = _minimalGame(
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 4)],
      );
      final after = before;
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1'],
            generalId: 'g-att',
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final events = <GameEvent>[];
      emitGeneralMedalGainedIfAny(
        gameBefore: before,
        gameAfter: after,
        ctx: ctx,
        winnerId: 'att',
        turn: 3,
        sink: TurnEventSink(onGameEvent: events.add),
      );
      expect(events, isEmpty);
    });

    test('omits when winner has no assigned general', () {
      final game = _minimalGame();
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final events = <GameEvent>[];
      emitGeneralMedalGainedIfAny(
        gameBefore: game,
        gameAfter: game,
        ctx: ctx,
        winnerId: 'att',
        turn: 3,
        sink: TurnEventSink(onGameEvent: events.add),
      );
      expect(events, isEmpty);
    });
  });
}
