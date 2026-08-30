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
    Hive.init('./.dart_tool/test_hive_game_map_area_diplomacy_combat');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  for (final case_ in eventFeedDiplomacyDetailNavigateCases()) {
    testWidgets(case_.name, (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(
        tester,
        harness,
        case_.buildEvents(harness),
        turnNumber: 2,
      );

      final line = find.textContaining(case_.lineMatch);
      expect(line, findsOneWidget);
      if (case_.lineMatch == 'Overture advanced!') {
        expect(find.textContaining(': Embassy!'), findsOneWidget);
      }
      if (case_.expectChevron) {
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      }
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, case_.expectedRoute);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['factionId'], harness.opponentId);
      if (case_.lineMatch.contains('declared war')) {
        expect(args['humanPlayerId'], harness.humanId);
      }
    });
  }

  testWidgets(
    'Player turn event feed unresolved spy counterpart is non-tappable',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppSpyCaughtEvent(
          unitId: 'spy_1',
          spyOwnerId: 'unknown_spy_owner',
          territoryOwnerId: harness.humanId,
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('enemy spy from');
      expect(line, findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      await tester.tap(line);
      await tester.pump();
      expect(navigateEvents, isEmpty);
    },
  );

  testWidgets(
    'Player turn event feed land combat line emits locate and overlay on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final locateEvents = listenEventFeedLocateEvents(harness);
      final overlayEvents = listenEventFeedOpenMapTileDetailEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppCombatResultEvent(
          provinceId: 'oldWorld|cap',
          attackerId: harness.humanId,
          defenderId: harness.opponentId,
          outcomeName: 'attackerVictory',
          winnerId: harness.humanId,
          turnNumber: 1,
          attackerCasualtyCount: 1,
          defenderCasualtyCount: 2,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('Attacker victory');
      expect(line, findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      await tester.tap(line);
      await tester.pump();

      expect(locateEvents, hasLength(1));
      expect(overlayEvents, hasLength(1));
      expect(overlayEvents.single.tileKey, locateEvents.single.tileKey);
    },
  );

  testWidgets(
    'Player turn event feed province captured line emits locate and overlay on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final locateEvents = listenEventFeedLocateEvents(harness);
      final overlayEvents = listenEventFeedOpenMapTileDetailEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppProvinceCapturedEvent(
          provinceId: 'oldWorld|cap',
          previousOwnerId: harness.opponentId,
          newOwnerId: harness.humanId,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('captured!');
      expect(line, findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(locateEvents, hasLength(1));
      expect(overlayEvents, hasLength(1));
      expect(overlayEvents.single.tileKey, locateEvents.single.tileKey);
    },
  );

  testWidgets('Player turn event feed renders diplomacy/discovery/overture copy', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness();
    await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
    await commitEventFeedTurnEvents(tester, harness, [
      AppDiplomacyChangeEvent(
        actorId: harness.humanId,
        targetId: harness.opponentId,
        changeType: 'declare_war',
        turnNumber: 1,
      ),
      AppPlayerProvinceDiscoveredEvent(
        playerId: harness.humanId,
        provinceId: 'oldWorld|1',
        turnNumber: 1,
      ),
      AppOvertureAdvancedEvent(
        offererGpId: harness.humanId,
        targetFactionId: harness.opponentId,
        newStage: 'embassy',
        turnNumber: 1,
      ),
    ], turnNumber: 2);

    expect(
      find.textContaining(
        '${harness.playerDisplayName} declared war on '
        '${harness.opponentDisplayName}!',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('discovered!'), findsOneWidget);
    expect(find.textContaining('Overture advanced!'), findsOneWidget);
    expect(find.textContaining(': Embassy!'), findsOneWidget);
    expect(find.textContaining('EMBASSY'), findsNothing);
  });

  for (final case_ in eventFeedRejectedOrderNavigateCases()) {
    testWidgets(case_.name, (WidgetTester tester) async {
      await pumpEventFeedRejectedOrderNavigateCase(
        tester,
        gamesBox: gamesBox,
        case_: case_,
      );
    });
  }
}
