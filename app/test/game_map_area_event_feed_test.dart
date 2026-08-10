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
