import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_map_area_trade_market');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  testWidgets(
    'Player turn event feed overseas profit line opens Deal Book on tap (Refs #4226)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOverseasProfitCreditedEvent(
          playerId: harness.humanId,
          totalTreasuryCredit: 42,
          creditCount: 2,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      const line =
          'Overseas profit credited: £42 from 2 rival purchase(s). '
          'Tap to open Deal Book.';
      expect(find.text(line), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.text(line));
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.trade);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['humanPlayerId'], harness.humanId);
      expect(args['initialTabIndex'], 1);
    },
  );

  testWidgets(
    'Player turn event feed overseas profit line is omitted for other players',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOverseasProfitCreditedEvent(
          playerId: harness.opponentId,
          totalTreasuryCredit: 99,
          creditCount: 1,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.textContaining('Overseas profit credited'), findsNothing);
    },
  );

  testWidgets(
    'Player turn event feed market summary line shows fill totals (Refs #4270)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppMarketTurnSummaryEvent(
          playerId: harness.humanId,
          totalSpent: 240,
          totalReceived: 160,
          carryForwardOrderCount: 0,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(
        find.text('Market: bought £240 · sold £160'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    },
  );

  testWidgets(
    'Player turn event feed market summary carry-forward-only line (Refs #4270)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppMarketTurnSummaryEvent(
          playerId: harness.humanId,
          totalSpent: 0,
          totalReceived: 0,
          carryForwardOrderCount: 2,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(
        find.text('Market: 2 orders carried forward'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Player turn event feed market summary line opens Deal Book on tap (Refs #4270)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppMarketTurnSummaryEvent(
          playerId: harness.humanId,
          totalSpent: 240,
          totalReceived: 0,
          carryForwardOrderCount: 0,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      const line = 'Market: bought £240';
      expect(find.text(line), findsOneWidget);
      await tester.tap(find.text(line));
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.trade);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['humanPlayerId'], harness.humanId);
      expect(args['initialTabIndex'], 1);
    },
  );

  testWidgets(
    'Player turn event feed market summary line is omitted for other players (Refs #4270)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppMarketTurnSummaryEvent(
          playerId: harness.opponentId,
          totalSpent: 500,
          totalReceived: 0,
          carryForwardOrderCount: 0,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.textContaining('Market:'), findsNothing);
    },
  );

  testWidgets(
    'Player turn event feed shows separate overseas profit and market rows (Refs #4270)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOverseasProfitCreditedEvent(
          playerId: harness.humanId,
          totalTreasuryCredit: 42,
          creditCount: 1,
          turnNumber: 1,
        ),
        AppMarketTurnSummaryEvent(
          playerId: harness.humanId,
          totalSpent: 240,
          totalReceived: 160,
          carryForwardOrderCount: 0,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.textContaining('Overseas profit credited'), findsOneWidget);
      expect(find.text('Market: bought £240 · sold £160'), findsOneWidget);
    },
  );

  testWidgets(
    'Player turn event feed omits market summary on overseas-profit-only turn '
    '(Refs #4270)',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOverseasProfitCreditedEvent(
          playerId: harness.humanId,
          totalTreasuryCredit: 42,
          creditCount: 1,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.textContaining('Overseas profit credited'), findsOneWidget);
      expect(find.textContaining('Market:'), findsNothing);
    },
  );

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
