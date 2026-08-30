import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area_realm');
  });

  testWidgets(
    'Player turn event feed realm economy summary line (Refs #4308)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppEconomyTurnSummaryEvent(
          playerId: harness.humanId,
          treasuryDelta: 200,
          stockpileDeltas: const {'grain': -10},
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(
        find.text('Realm: treasury +£200 · Grain -10'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    },
  );

  testWidgets(
    'Player turn event feed realm economy line opens Production on tap (Refs #4308)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppEconomyTurnSummaryEvent(
          playerId: harness.humanId,
          treasuryDelta: 50,
          stockpileDeltas: const {},
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      const line = 'Realm: treasury +£50';
      expect(find.text(line), findsOneWidget);
      await tester.tap(find.text(line));
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.production);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['humanPlayerId'], harness.humanId);
    },
  );

  testWidgets(
    'Player turn event feed realm economy line omitted for other players (Refs #4308)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppEconomyTurnSummaryEvent(
          playerId: harness.opponentId,
          treasuryDelta: 999,
          stockpileDeltas: const {'grain': 5},
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.textContaining('Realm:'), findsNothing);
    },
  );
}
