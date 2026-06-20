import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'test_fixtures.dart';

/// Coverage for the diplomacy deduplication helpers introduced by Refs #3562:
/// the generic [indexByKey] builder (AC2), the relocated
/// [isAiControlledForEvidence] helper now living in the diplomacy shared
/// helpers (AC6), the [logDiplomaticEvent] append+log helper (AC4), and the
/// canonical [clearOverturesBetweenGpAndFaction] overture-clearing helper (AC1).
void main() {
  group('clearOverturesBetweenGpAndFaction (AC1)', () {
    Game gameWithOvertures(List<OvertureState> overtures) =>
        TestFixtures.minimalGame(
          players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
          overtureStates: overtures,
        );

    test('positive: directional clear removes only (gpId -> factionId)', () {
      final game = gameWithOvertures(const [
        OvertureState(gpId: 'gp1', targetId: 'minor1'),
        OvertureState(gpId: 'gp1', targetId: 'minor2'),
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(game, 'gp1', 'minor1');

      expect(result.removed, hasLength(1));
      expect(result.removed.single.targetId, 'minor1');
      expect(result.game.overtureStates.map((o) => '${o.gpId}|${o.targetId}'), [
        'gp1|minor2',
        'gp2|gp1',
      ]);
    });

    test('negative: directional clear ignores the reverse direction', () {
      final game = gameWithOvertures(const [
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(game, 'gp1', 'gp2');

      expect(result.removed, isEmpty);
      // Unchanged game instance is returned when nothing matches.
      expect(identical(result.game, game), isTrue);
    });

    test('positive: bidirectional clear removes both directions', () {
      final game = gameWithOvertures(const [
        OvertureState(gpId: 'gp1', targetId: 'gp2'),
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
        OvertureState(gpId: 'gp1', targetId: 'minor1'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(
        game,
        'gp1',
        'gp2',
        bidirectional: true,
      );

      expect(result.removed, hasLength(2));
      expect(result.game.overtureStates, hasLength(1));
      expect(result.game.overtureStates.single.targetId, 'minor1');
    });

    test('positive: removed list preserves original overtureStates order', () {
      final game = gameWithOvertures(const [
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
        OvertureState(gpId: 'gp1', targetId: 'minor1'),
        OvertureState(gpId: 'gp1', targetId: 'gp2'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(
        game,
        'gp1',
        'gp2',
        bidirectional: true,
      );

      expect(result.removed.map((o) => '${o.gpId}|${o.targetId}'), [
        'gp2|gp1',
        'gp1|gp2',
      ]);
    });

    test('negative: empty overtures yields no removals and same game', () {
      final game = gameWithOvertures(const []);
      final result = clearOverturesBetweenGpAndFaction(game, 'gp1', 'minor1');
      expect(result.removed, isEmpty);
      expect(identical(result.game, game), isTrue);
    });
  });

  group('indexByKey (AC2)', () {
    test('positive: builds key -> position index over a list', () {
      const players = [
        Player(id: 'gp1', displayName: 'A', isHuman: false),
        Player(id: 'gp2', displayName: 'B', isHuman: false),
        Player(id: 'gp3', displayName: 'C', isHuman: false),
      ];
      final index = indexByKey(players, (p) => p.id);
      expect(index, {'gp1': 0, 'gp2': 1, 'gp3': 2});
    });

    test('positive: later entry wins on duplicate key (last-wins)', () {
      const items = ['a', 'b', 'a'];
      final index = indexByKey(items, (s) => s);
      expect(index['a'], 2);
      expect(index['b'], 1);
    });

    test('negative: empty list yields an empty index', () {
      final index = indexByKey<String>(const [], (s) => s);
      expect(index, isEmpty);
    });

    test('negative: lookup of an absent key is null', () {
      const items = ['x'];
      final index = indexByKey(items, (s) => s);
      expect(index['missing'], isNull);
    });
  });

  group('isAiControlledForEvidence relocation (AC6)', () {
    test('positive: non-human player is treated as AI-controlled', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      );
      expect(isAiControlledForEvidence(game, 'gp1'), isTrue);
    });

    test('negative: human player is not AI-controlled', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'h1', displayName: 'H', isHuman: true)],
      );
      expect(isAiControlledForEvidence(game, 'h1'), isFalse);
    });

    test('positive: explicit aiControlByGpId override wins over isHuman', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'h1', displayName: 'H', isHuman: true)],
      ).copyWith(aiControlByGpId: const {'h1': true});
      expect(isAiControlledForEvidence(game, 'h1'), isTrue);
    });

    test('negative: unknown faction id is not AI-controlled', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      );
      expect(isAiControlledForEvidence(game, 'minor1'), isFalse);
    });
  });

  group('logDiplomaticEvent (AC4)', () {
    final captured = <LogEvent>[];
    void listener(LogEvent e) => captured.add(e);

    setUp(() {
      captured.clear();
      Logger.addLogListener(listener);
      Logger.level = Level.info;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      captured.clear();
    });

    test('positive: appends the diplomatic event and emits the log line', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );

      final next = logDiplomaticEvent(
        game,
        1,
        DiplomaticEventType.allianceFormed,
        {'gp1', 'gp2'},
        fromFactionId: 'gp1',
        toFactionId: 'gp2',
        logMessage: 'diplomacy alliance gp1-gp2',
      );

      // Event appended.
      expect(next.diplomaticHistoryEvents, hasLength(1));
      final event = next.diplomaticHistoryEvents.single;
      expect(event.type, DiplomaticEventType.allianceFormed);
      expect(event.fromFactionId, 'gp1');
      expect(event.toFactionId, 'gp2');
      expect(event.participants, {'gp1', 'gp2'});
      // Source game untouched (pure copy).
      expect(game.diplomaticHistoryEvents, isEmpty);

      // Log emitted with the diplomacy prefix and the supplied message.
      final messages = captured.map((e) => e.message).toList();
      expect(
        messages.any((m) => m.contains('diplomacy alliance gp1-gp2')),
        isTrue,
        reason: 'expected logDiplomaticEvent to emit the supplied log message',
      );
    });

    test('positive: forwards optional event fields to the appended event', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      );

      final next = logDiplomaticEvent(
        game,
        2,
        DiplomaticEventType.grantAidApplied,
        {'gp1', 'minor1'},
        fromFactionId: 'gp1',
        toFactionId: 'minor1',
        amount: 500,
        reason: 'aid',
        wasAiInitiator: true,
        logMessage: 'diplomacy GrantAid gp1 -> minor1 amount 500',
      );

      final event = next.diplomaticHistoryEvents.single;
      expect(event.amount, 500);
      expect(event.reason, 'aid');
      expect(event.wasAiInitiator, isTrue);
      expect(event.turn, 2);
    });
  });
}
