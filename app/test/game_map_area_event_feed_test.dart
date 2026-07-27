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

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_map_area');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
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

      final navalLine = find.textContaining('naval battle resolved');
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

      final navalLine = find.textContaining('naval battle resolved');
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
    'Player turn event feed diplomacy line opens diplomacy detail on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppDiplomacyChangeEvent(
          actorId: harness.humanId,
          targetId: harness.opponentId,
          changeType: 'declare_war',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('declared war on');
      expect(line, findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.diplomacyDetail);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['factionId'], harness.opponentId);
      expect(args['humanPlayerId'], harness.humanId);
    },
  );

  testWidgets(
    'Player turn event feed overture line opens diplomacy detail on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOvertureAdvancedEvent(
          offererGpId: harness.humanId,
          targetFactionId: harness.opponentId,
          newStage: 'embassy',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('Overture advanced!');
      expect(line, findsOneWidget);
      expect(find.textContaining(': Embassy!'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.diplomacyDetail);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['factionId'], harness.opponentId);
      expect(args['humanPlayerId'], harness.humanId);
    },
  );

  testWidgets(
    'Player turn event feed spy caught line opens diplomacy detail on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppSpyCaughtEvent(
          unitId: 'spy_1',
          spyOwnerId: harness.opponentId,
          territoryOwnerId: harness.humanId,
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('enemy spy from');
      expect(line, findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.diplomacyDetail);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['factionId'], harness.opponentId);
    },
  );

  testWidgets(
    'Player turn event feed spy defected line opens diplomacy detail on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppSpyDefectedEvent(
          unitId: 'spy_1',
          previousOwnerId: harness.opponentId,
          newOwnerId: harness.humanId,
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('defected to your side');
      expect(line, findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.diplomacyDetail);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['factionId'], harness.opponentId);
    },
  );

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
          winnerId: harness.humanId,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('battle resolved!');
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

  testWidgets(
    'Player turn event feed rejected research order opens technology on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOrderRejectedEvent(
          playerId: harness.humanId,
          orderKind: OrderKind.research,
          orderSummary: 'Research cotton',
          reasonCode: 'insufficient_treasury',
        ),
      ], turnNumber: 2);

      final line = find.textContaining('Order rejected: insufficient treasury.');
      expect(line, findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.technology);
    },
  );

  testWidgets(
    'Player turn event feed rejected trade order opens trade screen on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppOrderRejectedEvent(
          playerId: harness.humanId,
          orderKind: OrderKind.trade,
          orderSummary: 'Buy grain',
          reasonCode: 'insufficient_treasury',
        ),
      ], turnNumber: 2);

      final line = find.textContaining('Order rejected: insufficient treasury.');
      await tester.tap(line);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.trade);
    },
  );
}
