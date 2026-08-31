import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/flame/overlays/debug_console_overlay_panel.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdCropRotation, kWorkTargetExplore, techDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_test_fixtures.dart';
import 'app_test_hive_harness.dart';
  testWidgets(
    'Player turn event feed unresolved naval anchor is non-tappable',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final locateEvents = listenEventFeedLocateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppNavalCombatResultEvent(
          seaZoneId: 'missing_zone_anchor',
          side1OwnerId: harness.humanId,
          side2OwnerId: harness.opponentId,
          outcomeName: 'side1Victory',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final navalLine = find.textContaining('Attacker victory');
      expect(navalLine, findsOneWidget);
      await tester.tap(navalLine);
      await tester.pump();

      expect(locateEvents, isEmpty);
    },
  );

  testWidgets(
    'Player turn event feed renders work completion and opens civilian panel',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final locateEvents = listenEventFeedLocateEvents(harness);
      final panelEvents = listenEventFeedOpenCivilianPanelEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppWorkOrderCompletedEvent(
          playerId: harness.humanId,
          unitId: 'civ_explorer',
          workTarget: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|1|0|0',
          provinceId: 'oldWorld|1',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('Build road finished!');
      expect(line, findsOneWidget);
      expect(find.textContaining('BUILD_ROAD'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(locateEvents, hasLength(1));
      expect(locateEvents.single.tileKey, 'oldWorld|1|0|0');
      expect(panelEvents, hasLength(1));
      expect(panelEvents.single.initialSelectedUnitId, 'civ_explorer');
    },
  );

  testWidgets(
    'Player turn event feed toggles visibility and replaces prior turn batch',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final civilianEvents = listenEventFeedOpenCivilianPanelEvents(harness);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        harness.bus.dispose();
      });
      await pumpEventFeedMapArea(
        tester,
        gamesBox: gamesBox,
        harness: harness,
        mediaQuerySize: const Size(500, 900),
      );
      final researchLine =
          'Research complete: ${techDisplayName(kTechIdCropRotation)} unlocked';
      final researchFinder = find.textContaining(researchLine);

      await commitEventFeedTurnEvents(
        tester,
        harness,
        [
          AppResearchCompleteEvent(
            playerId: harness.humanId,
            techId: kTechIdCropRotation,
            turnNumber: 1,
          ),
        ],
        turnNumber: 2,
        openFeed: false,
      );

      expect(find.byKey(kPlayerTurnFeedToggleButtonKey), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(researchFinder, findsNothing);
      expect(find.text('Events'), findsNothing);

      await openEventFeedToggle(tester);
      expect(researchFinder, findsOneWidget);
      expect(find.text('Events'), findsNothing);

      await openEventFeedToggle(tester);
      expect(researchFinder, findsNothing);

      await commitEventFeedTurnEvents(
        tester,
        harness,
        [
          AppOrderRejectedEvent(
            playerId: harness.humanId,
            orderKind: OrderKind.work,
            orderSummary: 'Build road',
            reasonCode: 'insufficient_treasury',
          ),
        ],
        turnNumber: 3,
        openFeed: false,
      );
      expect(researchFinder, findsNothing);
      await openEventFeedToggle(tester);
      expect(
        find.textContaining('Order rejected: insufficient treasury.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(
        find.textContaining('Order rejected: insufficient treasury.'),
      );
      await tester.pump();
      expect(civilianEvents, hasLength(1));
    },
  );
}
