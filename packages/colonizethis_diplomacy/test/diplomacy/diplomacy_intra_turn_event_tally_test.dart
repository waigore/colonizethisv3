import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_event_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/diplomacy_game_fixtures.dart';

DiplomaticEvent _event(int turn, int intraTurnIndex) => DiplomaticEvent(
  turn: turn,
  intraTurnIndex: intraTurnIndex,
  type: DiplomaticEventType.declareWar,
  participants: {'gp1', 'gp2'},
  fromFactionId: 'gp1',
  toFactionId: 'gp2',
);

void main() {
  group('IntraTurnEventTally', () {
    test('positive: fromEvents seeds per-turn counts from history', () {
      final tally = IntraTurnEventTally.fromEvents([
        _event(3, 0),
        _event(3, 1),
        _event(5, 0),
      ]);
      expect(tally.nextIndex(3), 2);
      expect(tally.nextIndex(3), 3);
      expect(tally.nextIndex(5), 1);
      expect(tally.nextIndex(7), 0);
    });

    test('positive: append with tally matches sequential scan fallback', () {
      var withTally = diplomacyHistoryGame();
      var withoutTally = diplomacyHistoryGame();
      final tally = IntraTurnEventTally.fromGame(withTally);

      for (var i = 0; i < 4; i++) {
        withTally = appendDiplomaticEvent(
          withTally,
          1,
          DiplomaticEventType.declareWar,
          {'gp1', 'gp2'},
          fromFactionId: 'gp1',
          toFactionId: 'gp2',
          eventTally: tally,
        );
        withoutTally = appendDiplomaticEvent(
          withoutTally,
          1,
          DiplomaticEventType.declareWar,
          {'gp1', 'gp2'},
          fromFactionId: 'gp1',
          toFactionId: 'gp2',
        );
      }

      expect(
        withTally.diplomaticHistoryEvents.map((e) => e.intraTurnIndex).toList(),
        withoutTally.diplomaticHistoryEvents
            .map((e) => e.intraTurnIndex)
            .toList(),
      );
      expect(
        withTally.diplomaticHistoryEvents.map((e) => e.intraTurnIndex).toList(),
        [0, 1, 2, 3],
      );
    });

    test('positive: tally continues after pre-existing same-turn events', () {
      final game = diplomacyHistoryGame(
        history: [_event(2, 0), _event(2, 1)],
      );
      final tally = IntraTurnEventTally.fromGame(game);
      final after = appendDiplomaticEvent(
        game,
        2,
        DiplomaticEventType.peace,
        {'gp1', 'gp2'},
        fromFactionId: 'gp1',
        toFactionId: 'gp2',
        eventTally: tally,
      );
      expect(after.diplomaticHistoryEvents.last.intraTurnIndex, 2);
    });

    test('negative: without tally still assigns indices via scan', () {
      final game = diplomacyHistoryGame(history: [_event(1, 0)]);
      final after = appendDiplomaticEvent(
        game,
        1,
        DiplomaticEventType.peace,
        {'gp1', 'gp2'},
        fromFactionId: 'gp1',
        toFactionId: 'gp2',
      );
      expect(after.diplomaticHistoryEvents.last.intraTurnIndex, 1);
    });
  });
}
