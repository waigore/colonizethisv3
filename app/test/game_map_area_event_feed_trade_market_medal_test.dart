import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area_trade_market');
  });

  testWidgets(
    'Player turn event feed general medal line shows for human (Refs #4234)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppGeneralMedalGainedEvent(
          playerId: harness.humanId,
          generalId: 'g1',
          provinceId: 'oldWorld|cap',
          newMedals: 2,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(
        find.textContaining('a general earned a medal (now 2)'),
        findsOneWidget,
      );
      expect(find.textContaining('commander'), findsNothing);
    },
  );

  testWidgets(
    'Player turn event feed general medal line is omitted for other players (Refs #4234)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppGeneralMedalGainedEvent(
          playerId: harness.opponentId,
          generalId: 'g-ai',
          provinceId: 'oldWorld|cap',
          newMedals: 3,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.textContaining('earned a medal'), findsNothing);
    },
  );
}
