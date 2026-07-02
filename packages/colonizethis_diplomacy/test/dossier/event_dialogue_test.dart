// Tests for event dialogue (battle result, era change, negotiation).
// Reactive and additional event-dialogue rules live in
// event_dialogue_reactive_test.dart.
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('dialogueEventsForLandBattleResult', () {
    test(
      'AI victor and AI loser both emit event with era from turn-time mapping',
      () {
        const mapping = TurnTimeMapping.gdd01;
        final game = dialogueGame(
          turnNumber: 2,
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true),
            Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
            Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
          ],
        );
        final expectedEra = eraFromYear(mapping.yearAtTurn(2));
        final events = dialogueEventsForLandBattleResult(
          game,
          'gp2',
          'gp3',
          'ow|prov1',
          2,
          12345,
        );
        expect(events.length, 2);
        final won = events.where((e) => e.situation == 'battle_won').toList();
        final lost = events.where((e) => e.situation == 'battle_lost').toList();
        expect(won.length, 1);
        expect(lost.length, 1);
        expect(won.first.leaderId, 'gp2');
        expect(won.first.category, 'event');
        expect(won.first.era, expectedEra);
        expect(won.first.variables['otherNation'], 'gp3');
        expect(won.first.variables['province'], 'ow|prov1');
        expect(lost.first.leaderId, 'gp3');
        expect(lost.first.variables['otherNation'], 'gp2');
      },
    );

    test('human victor returns no dialogue for victor', () {
      final game = dialogueGame(
        turnNumber: 2,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game,
        'gp1',
        'gp2',
        'ow|p1',
        2,
        0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_lost');
      expect(events.first.leaderId, 'gp2');
    });

    test('human loser returns only battle_won for AI victor', () {
      final game = dialogueGame(
        turnNumber: 2,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game,
        'gp2',
        'gp1',
        'ow|p1',
        2,
        0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_won');
      expect(events.first.leaderId, 'gp2');
    });
  });

  group('dialogueEventsForNavalBattleResult', () {
    test('AI victor and AI loser both emit event', () {
      final game = dialogueGame(
        turnNumber: 3,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
          Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
        ],
      );
      final events = dialogueEventsForNavalBattleResult(
        game,
        'gp2',
        'gp3',
        3,
        999,
      );
      expect(events.length, 2);
      expect(
        events.any((e) => e.situation == 'battle_won' && e.leaderId == 'gp2'),
        isTrue,
      );
      expect(
        events.any((e) => e.situation == 'battle_lost' && e.leaderId == 'gp3'),
        isTrue,
      );
      expect(events.first.variables['otherNation'], isNotNull);
    });

    test('human victor returns only battle_lost for AI loser', () {
      final game = dialogueGame(
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForNavalBattleResult(
        game,
        'gp1',
        'gp2',
        1,
        0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_lost');
      expect(events.first.leaderId, 'gp2');
    });
  });

  group('eraFromYear', () {
    test('maps year to dialogue era bands', () {
      expect(eraFromYear(1599), 'discovery');
      expect(eraFromYear(1600), 'earlyModern');
      expect(eraFromYear(1699), 'earlyModern');
      expect(eraFromYear(1700), 'imperial');
      expect(eraFromYear(1799), 'imperial');
      expect(eraFromYear(1800), 'industrial');
    });
  });

  group('dialogueEventsForEraChange', () {
    test('emits one event per AI leader with era_change situation', () {
      final game = dialogueGame(
        turnNumber: 100,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForEraChange(
        game,
        'earlyModern',
        'imperial',
        42,
      );
      expect(events.length, 2);
      for (final e in events) {
        expect(e.category, 'event');
        expect(e.situation, 'era_change');
        expect(e.era, 'imperial');
        expect(e.variables['previousEra'], 'earlyModern');
        expect(['gp2', 'gp3'], contains(e.leaderId));
      }
    });

    test('emits no events when all players are human', () {
      final game = dialogueGame(
        turnNumber: 100,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Human', isHuman: true),
        ],
      );
      final events = dialogueEventsForEraChange(
        game,
        'earlyModern',
        'imperial',
        0,
      );
      expect(events, isEmpty);
    });
  });

  group('dialogueEventForNegotiation', () {
    test('builds event with category negotiation and optional mood', () {
      final e = dialogueEventForNegotiation(
        leaderId: 'gp1',
        situation: 'counter_offer',
        era: 'earlyModern',
        mood: 'skeptical',
        variables: {'offer': 'gold'},
      );
      expect(e.leaderId, 'gp1');
      expect(e.category, 'negotiation');
      expect(e.situation, 'counter_offer');
      expect(e.era, 'earlyModern');
      expect(e.mood, 'skeptical');
      expect(e.variables['offer'], 'gold');
    });

    test('builds event without mood', () {
      final e = dialogueEventForNegotiation(
        leaderId: 'gp2',
        situation: 'opening',
        era: 'imperial',
      );
      expect(e.category, 'negotiation');
      expect(e.situation, 'opening');
      expect(e.mood, isNull);
    });
  });
}
