import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_map_area_event_feed_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area_prospect');
  });

  testWidgets(
    'Player turn event feed Prospect found line and civilian tap (Refs #4746)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final locateEvents = listenEventFeedLocateEvents(harness);
      final panelEvents = listenEventFeedOpenCivilianPanelEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppWorkOrderCompletedEvent(
          playerId: harness.humanId,
          unitId: 'civ_explorer',
          workTarget: kWorkTargetProspect,
          targetTileKey: 'oldWorld|1|0|0',
          provinceId: 'oldWorld|1',
          turnNumber: 1,
          revealedResourceId: 'iron',
        ),
      ], turnNumber: 2);

      final line = find.textContaining('Prospect found Iron');
      expect(line, findsOneWidget);
      expect(find.textContaining('iron'), findsNothing);
      expect(find.textContaining('finished!'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(locateEvents, hasLength(1));
      expect(locateEvents.single.tileKey, 'oldWorld|1|0|0');
      expect(panelEvents, hasLength(1));
      expect(panelEvents.single.initialSelectedUnitId, 'civ_explorer');
    },
  );

  testWidgets('Player turn event feed Prospect none line (Refs #4746)', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness(disposeBus: false);

    await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
    await commitEventFeedTurnEvents(tester, harness, [
      AppWorkOrderCompletedEvent(
        playerId: harness.humanId,
        unitId: 'civ_explorer',
        workTarget: kWorkTargetProspect,
        targetTileKey: 'oldWorld|1|0|0',
        provinceId: 'oldWorld|1',
        turnNumber: 1,
      ),
    ], turnNumber: 2);

    expect(find.textContaining('Prospect found no mineral'), findsOneWidget);
  });

  testWidgets('Player turn event feed omits non-human Prospect (Refs #4746)', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness(disposeBus: false);

    await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
    await commitEventFeedTurnEvents(tester, harness, [
      AppWorkOrderCompletedEvent(
        playerId: harness.opponentId,
        unitId: 'ai_explorer',
        workTarget: kWorkTargetProspect,
        targetTileKey: 'oldWorld|1|0|0',
        provinceId: 'oldWorld|1',
        turnNumber: 1,
        revealedResourceId: 'iron',
      ),
    ], turnNumber: 2);

    expect(find.textContaining('Prospect found'), findsNothing);
  });

  testWidgets('Player turn event feed Explore line unchanged (Refs #4746)', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness(disposeBus: false);

    await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
    await commitEventFeedTurnEvents(tester, harness, [
      AppWorkOrderCompletedEvent(
        playerId: harness.humanId,
        unitId: 'civ_explorer',
        workTarget: kWorkTargetExplore,
        targetTileKey: 'oldWorld|1|0|0',
        provinceId: 'oldWorld|1',
        turnNumber: 1,
      ),
    ], turnNumber: 2);

    expect(find.textContaining('Explore finished!'), findsOneWidget);
    expect(find.textContaining('Prospect found'), findsNothing);
  });
}
