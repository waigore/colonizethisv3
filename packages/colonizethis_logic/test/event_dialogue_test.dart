// Tests for event dialogue (battle result). SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('dialogueEventsForLandBattleResult', () {
    test('AI victor and AI loser both emit event', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
          Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game, 'gp2', 'gp3', 'ow|prov1', 2, 12345,
      );
      expect(events.length, 2);
      final won = events.where((e) => e.situation == 'battle_won').toList();
      final lost = events.where((e) => e.situation == 'battle_lost').toList();
      expect(won.length, 1);
      expect(lost.length, 1);
      expect(won.first.leaderId, 'gp2');
      expect(won.first.category, 'event');
      expect(won.first.era, 'earlyModern');
      expect(won.first.variables['otherNation'], 'gp3');
      expect(won.first.variables['province'], 'ow|prov1');
      expect(lost.first.leaderId, 'gp3');
      expect(lost.first.variables['otherNation'], 'gp2');
    });

    test('human victor returns no dialogue for victor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game, 'gp1', 'gp2', 'ow|p1', 2, 0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_lost');
      expect(events.first.leaderId, 'gp2');
    });

    test('human loser returns only battle_won for AI victor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game, 'gp2', 'gp1', 'ow|p1', 2, 0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_won');
      expect(events.first.leaderId, 'gp2');
    });
  });

  group('dialogueEventsForNavalBattleResult', () {
    test('AI victor and AI loser both emit event', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
          Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
        ],
      );
      final events = dialogueEventsForNavalBattleResult(
        game, 'gp2', 'gp3', 3, 999,
      );
      expect(events.length, 2);
      expect(events.any((e) => e.situation == 'battle_won' && e.leaderId == 'gp2'), isTrue);
      expect(events.any((e) => e.situation == 'battle_lost' && e.leaderId == 'gp3'), isTrue);
      expect(events.first.variables['otherNation'], isNotNull);
    });

    test('human victor returns only battle_lost for AI loser', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForNavalBattleResult(
        game, 'gp1', 'gp2', 1, 0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_lost');
      expect(events.first.leaderId, 'gp2');
    });
  });
}
