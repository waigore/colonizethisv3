import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/flame/overlays/debug_console_overlay_panel.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/app_shell_harness.dart';
import 'support/map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

class _MapAreaHost extends StatefulWidget {
  const _MapAreaHost({required this.game, required this.mapViewData});

  final Game game;
  final InitGameMapViewData mapViewData;

  @override
  State<_MapAreaHost> createState() => _MapAreaHostState();
}

class _MapAreaHostState extends State<_MapAreaHost> {
  bool _showMapArea = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => setState(() => _showMapArea = false),
            child: const Text('dispose-map-area'),
          ),
          Expanded(
            child: _showMapArea
                ? GameMapArea(
                    game: widget.game,
                    mapViewData: widget.mapViewData,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EventFeedHarness {
  _EventFeedHarness(this.game, this.mapViewData, this.bus)
    : humanId = game.players.firstWhere((p) => p.isHuman).id {
    opponentId = game.players.firstWhere((p) => p.id != humanId).id;
  }

  final Game game;
  final InitGameMapViewData mapViewData;
  final AppEventBus bus;
  final String humanId;
  late final String opponentId;

  String get playerDisplayName =>
      game.players.firstWhere((p) => p.id == humanId).displayName;

  String get opponentDisplayName =>
      game.players.firstWhere((p) => p.id == opponentId).displayName;
}

_EventFeedHarness _newHarness({bool disposeBus = true}) {
  final harness = _EventFeedHarness(
    buildMapAreaEventFeedTestGame(),
    buildLightweightMapViewData(),
    AppEventBus.create(),
  );
  if (disposeBus) {
    addTearDown(harness.bus.dispose);
  }
  return harness;
}

Future<void> _pumpMapArea(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required _EventFeedHarness harness,
  Widget? home,
  bool debugConsoleEnabled = false,
  Size? mediaQuerySize,
}) async {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  await tester.pumpWidget(
    buildAppShell(
      overrides: [
        appEventBusProvider.overrideWith((ref) => harness.bus),
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(harness.game),
        ),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        mapViewDataProvider.overrideWith((ref) => harness.mapViewData),
        if (debugConsoleEnabled)
          debugConsoleEnabledProvider.overrideWithValue(true),
      ],
      viewport: mediaQuerySize,
      child:
          home ??
          Scaffold(
            body: GameMapArea(
              game: harness.game,
              mapViewData: harness.mapViewData,
            ),
          ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _commitTurnEvents(
  WidgetTester tester,
  _EventFeedHarness harness,
  List<AppEvent> events, {
  required int turnNumber,
  bool openFeed = true,
}) async {
  for (final event in events) {
    harness.bus.emit(event);
  }
  harness.bus.emit(
    TurnResolutionCompleteEvent(
      gameId: harness.game.id,
      turnNumber: turnNumber,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  if (openFeed) {
    await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
    await tester.pump();
  }
}

List<LocateMapTileEvent> _listenLocateEvents(_EventFeedHarness harness) {
  final locateEvents = <LocateMapTileEvent>[];
  final sub = harness.bus.on<LocateMapTileEvent>().listen(locateEvents.add);
  addTearDown(() async {
    await sub.cancel();
    harness.bus.dispose();
  });
  return locateEvents;
}

Future<void> _openFeedToggle(WidgetTester tester) async {
  await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

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
    final harness = _newHarness(disposeBus: false);
    final sampleUnitId = harness.game.worldState.oldWorld.units.isNotEmpty
        ? harness.game.worldState.oldWorld.units.first.id
        : harness.game.worldState.newWorld.units.isNotEmpty
        ? harness.game.worldState.newWorld.units.first.id
        : 'missing-unit-id';

    await _pumpMapArea(
      tester,
      gamesBox: gamesBox,
      harness: harness,
      home: _MapAreaHost(game: harness.game, mapViewData: harness.mapViewData),
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
    final harness = _newHarness();
    await _pumpMapArea(
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
    final harness = _newHarness();
    await _pumpMapArea(tester, gamesBox: gamesBox, harness: harness);
    await _commitTurnEvents(tester, harness, [
      AppResearchCompleteEvent(
        playerId: harness.humanId,
        techId: 'agri_1',
        turnNumber: 1,
      ),
    ], turnNumber: 2);

    expect(
      find.textContaining('Research complete! agri_1 unlocked!'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Player turn event feed naval line emits LocateMapTileEvent on tap',
    (WidgetTester tester) async {
      final harness = _newHarness(disposeBus: false);
      final seaKey = harness.game.worldState.portsByProvinceSeaboard.keys.first;
      final seaParts = seaKey.split('|');
      final seaZoneId = '${seaParts.first}|${seaParts.last}';
      final locateEvents = _listenLocateEvents(harness);

      await _pumpMapArea(tester, gamesBox: gamesBox, harness: harness);
      await _commitTurnEvents(tester, harness, [
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
      expect(locateEvents.single.tileKey, isNotEmpty);
      expect(locateEvents.single.regionId, isNotEmpty);
    },
  );

  testWidgets(
    'Player turn event feed unresolved naval anchor is non-tappable',
    (WidgetTester tester) async {
      final harness = _newHarness(disposeBus: false);
      final locateEvents = _listenLocateEvents(harness);

      await _pumpMapArea(tester, gamesBox: gamesBox, harness: harness);
      await _commitTurnEvents(tester, harness, [
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
    'Player turn event feed renders work completion and taps map tile',
    (WidgetTester tester) async {
      final harness = _newHarness(disposeBus: false);
      final locateEvents = _listenLocateEvents(harness);

      await _pumpMapArea(tester, gamesBox: gamesBox, harness: harness);
      await _commitTurnEvents(tester, harness, [
        AppWorkOrderCompletedEvent(
          playerId: harness.humanId,
          unitId: 'u1',
          workTarget: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|1|0|0',
          provinceId: 'oldWorld|1',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final line = find.textContaining('work completed');
      expect(line, findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(locateEvents, hasLength(1));
      expect(locateEvents.single.tileKey, 'oldWorld|1|0|0');
      expect(locateEvents.single.regionId, 'oldWorld');
    },
  );

  testWidgets('Player turn event feed renders diplomacy/discovery/overture copy', (
    WidgetTester tester,
  ) async {
    final harness = _newHarness();
    await _pumpMapArea(tester, gamesBox: gamesBox, harness: harness);
    await _commitTurnEvents(tester, harness, [
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
  });

  testWidgets(
    'Player turn event feed toggles visibility and replaces prior turn batch',
    (WidgetTester tester) async {
      final harness = _newHarness(disposeBus: false);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        harness.bus.dispose();
      });
      await _pumpMapArea(
        tester,
        gamesBox: gamesBox,
        harness: harness,
        mediaQuerySize: const Size(500, 900),
      );
      const researchLine = 'Research complete! agri_1 unlocked!';
      final researchFinder = find.textContaining(researchLine);

      await _commitTurnEvents(
        tester,
        harness,
        [
          AppResearchCompleteEvent(
            playerId: harness.humanId,
            techId: 'agri_1',
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

      await _openFeedToggle(tester);
      expect(researchFinder, findsOneWidget);
      expect(find.text('Events'), findsNothing);

      await _openFeedToggle(tester);
      expect(researchFinder, findsNothing);

      await _commitTurnEvents(
        tester,
        harness,
        [
          AppOrderRejectedEvent(
            playerId: harness.humanId,
            orderSummary: 'Build road',
            reasonCode: 'insufficient_treasury',
          ),
        ],
        turnNumber: 3,
        openFeed: false,
      );
      expect(researchFinder, findsNothing);
      await _openFeedToggle(tester);
      expect(
        find.textContaining('Order rejected! Reason: insufficient_treasury!'),
        findsOneWidget,
      );
    },
  );
}
