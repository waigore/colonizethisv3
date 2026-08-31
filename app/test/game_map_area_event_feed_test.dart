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
    final sampleUnitId = harness.game.worldState.oldWorld.units.isNotEmpty
        ? harness.game.worldState.oldWorld.units.first.id
        : harness.game.worldState.newWorld.units.isNotEmpty
        ? harness.game.worldState.newWorld.units.first.id
        : 'missing-unit-id';

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
    expect(find.byType(DebugConsoleOverlayPanel), findsOneWidget);

    harness.bus.emit(const CloseDebugConsolePanelEvent());
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
}
