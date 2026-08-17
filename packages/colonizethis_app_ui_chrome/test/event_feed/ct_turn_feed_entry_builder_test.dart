import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_feed_test_context.dart';

void main() {
  group('buildCtTurnFeedEntries dispatcher', () {
    test('AppVictorySetEvent falls back with no tap', () {
      final entry = singleTurnFeedEntry(
        const AppVictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'domination',
          turnNumber: 10,
        ),
        TurnFeedTestContext(),
      );

      expect(entry.text, 'Event resolved!');
      expect(entry.onTap, isNull);
      expect(entry.linkAffordance, isFalse);
    });
  });
}
