import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/flame/overlays/debug_console_overlay_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdCropRotation, techDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_map_area_event_feed_test_fixtures.dart';
import 'game_map_area_event_feed_toggle_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area');
  });

  testWidgets('GameMapArea dispose cancels AppEventBus subscriptions', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness(disposeBus: false);
    final sampleUnitId = sampleUnitIdFromEventFeedHarness(harness);

    await pumpEventFeedMapArea(
      tester,
      gamesBox: gamesBox,
      harness: harness,
      home: MapAreaHost(game: harness.game, mapViewData: harness.mapViewData),
    );

    await tester.tap(find.text('dispose-map-area'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    harness.bus.emit(
      const LocateMapTileEvent(
        tileKey: 'oldWorld|dummy|0|0',
        regionId: 'oldWorld',
      ),
    );
    harness.bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: sampleUnitId,
        workTarget: kWorkTargetExplore,
      ),
    );
    harness.bus.emit(const UnitsPanelClosedEvent('civilian'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    harness.bus.dispose();
  });

  testWidgets('debug console overlay toggles when feature is enabled', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness();
    await pumpEventFeedMapArea(
      tester,
      gamesBox: gamesBox,
      harness: harness,
      debugConsoleEnabled: true,
    );

    expect(find.byType(DebugConsoleOverlayPanel), findsNothing);

    harness.bus.emit(const ToggleDebugConsolePanelEvent());
    await tester.pump();
    await tester.pump();
    expect(find.byType(DebugConsoleOverlayPanel), findsOneWidget);

    harness.bus.emit(const CloseDebugConsolePanelEvent());
    await tester.pump();
    await tester.pump();
    expect(find.byType(DebugConsoleOverlayPanel), findsNothing);
  });

  testWidgets('Player turn event feed commits batch on turn complete', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness();
    await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
    await commitEventFeedTurnEvents(tester, harness, [
      AppResearchCompleteEvent(
        playerId: harness.humanId,
        techId: kTechIdCropRotation,
        turnNumber: 1,
      ),
    ], turnNumber: 2);

    expect(
      find.text(
        'Research complete: ${techDisplayName(kTechIdCropRotation)} unlocked',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(kTechIdCropRotation), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets(
    'Player turn event feed research line emits NavigateToRouteEvent on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppResearchCompleteEvent(
          playerId: harness.humanId,
          techId: kTechIdCropRotation,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final researchLine = find.text(
        'Research complete: ${techDisplayName(kTechIdCropRotation)} unlocked',
      );
      expect(researchLine, findsOneWidget);
      await tester.tap(researchLine);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.technology);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['humanPlayerId'], harness.humanId);
    },
  );

  testWidgets(
    'Player turn event feed unknown research tech is non-tappable',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppResearchCompleteEvent(
          playerId: harness.humanId,
          techId: 'agri_1',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      const fallbackLine = 'Research complete — technology unlocked!';
      expect(find.text(fallbackLine), findsOneWidget);
      expect(find.textContaining('agri_1'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.text(fallbackLine));
      await tester.pump();
      expect(navigateEvents, isEmpty);
    },
  );

  testWidgets(
    'Player turn event feed naval line emits locate and overlay on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final seaKey = harness.game.worldState.portsByProvinceSeaboard.keys.first;
      final seaParts = seaKey.split('|');
      final seaZoneId = '${seaParts.first}|${seaParts.last}';
      final locateEvents = listenEventFeedLocateEvents(harness);
      final overlayEvents = listenEventFeedOpenMapTileDetailEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppNavalCombatResultEvent(
          seaZoneId: seaZoneId,
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

      expect(locateEvents, hasLength(1));
      expect(overlayEvents, hasLength(1));
      expect(overlayEvents.single.tileKey, locateEvents.single.tileKey);
    },
  );

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
      await expectEventFeedToggleReplacesBatch(
        tester,
        gamesBox: gamesBox,
        harness: harness,
        civilianEvents: civilianEvents,
      );
    },
  );
}
