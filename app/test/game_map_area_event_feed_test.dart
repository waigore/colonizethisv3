import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/debug_console_overlay_panel.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final bus = AppEventBus.create();
    final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
        ? game.worldState.oldWorld.units.first.id
        : game.worldState.newWorld.units.isNotEmpty
        ? game.worldState.newWorld.units.first.id
        : 'missing-unit-id';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          mapViewDataProvider.overrideWith((ref) => mapViewData),
        ],
        child: MaterialApp(
          home: _MapAreaHost(game: game, mapViewData: mapViewData),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.text('dispose-map-area'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    bus.emit(
      const LocateMapTileEvent(
        tileKey: 'oldWorld|dummy|0|0',
        regionId: 'oldWorld',
      ),
    );
    bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: sampleUnitId,
        workTarget: kWorkTargetExplore,
      ),
    );
    bus.emit(const UnitsPanelClosedEvent('civilian'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    bus.dispose();
  });

  testWidgets('debug console overlay toggles when feature is enabled', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          debugConsoleEnabledProvider.overrideWithValue(true),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          mapViewDataProvider.overrideWith((ref) => mapViewData),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: mapViewData),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(DebugConsoleOverlayPanel), findsNothing);

    bus.emit(const ToggleDebugConsolePanelEvent());
    await tester.pump();
    expect(find.byType(DebugConsoleOverlayPanel), findsOneWidget);

    bus.emit(const CloseDebugConsolePanelEvent());
    await tester.pump();
    expect(find.byType(DebugConsoleOverlayPanel), findsNothing);
  });

  testWidgets('Player turn event feed commits batch on turn complete', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          mapViewDataProvider.overrideWith((ref) => mapViewData),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: mapViewData),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    bus.emit(
      AppResearchCompleteEvent(
        playerId: humanId,
        techId: 'agri_1',
        turnNumber: 1,
      ),
    );
    bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
    await tester.pump();

    expect(
      find.textContaining('Research complete! agri_1 unlocked!'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Player turn event feed naval line emits LocateMapTileEvent on tap',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final opponentId = game.players.firstWhere((p) => p.id != humanId).id;
      final seaKey = game.worldState.portsByProvinceSeaboard.keys.first;
      final seaParts = seaKey.split('|');
      final seaZoneId = '${seaParts.first}|${seaParts.last}';
      final bus = AppEventBus.create();
      final locateEvents = <LocateMapTileEvent>[];
      final sub = bus.on<LocateMapTileEvent>().listen(locateEvents.add);
      addTearDown(() async {
        await sub.cancel();
        bus.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        AppNavalCombatResultEvent(
          seaZoneId: seaZoneId,
          side1OwnerId: humanId,
          side2OwnerId: opponentId,
          outcomeName: 'side1Victory',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();

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
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final opponentId = game.players.firstWhere((p) => p.id != humanId).id;
      final bus = AppEventBus.create();
      final locateEvents = <LocateMapTileEvent>[];
      final sub = bus.on<LocateMapTileEvent>().listen(locateEvents.add);
      addTearDown(() async {
        await sub.cancel();
        bus.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        AppNavalCombatResultEvent(
          seaZoneId: 'missing_zone_anchor',
          side1OwnerId: humanId,
          side2OwnerId: opponentId,
          outcomeName: 'side1Victory',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();

      final navalLine = find.textContaining('naval battle resolved');
      expect(navalLine, findsOneWidget);
      await tester.tap(navalLine);
      await tester.pump();

      expect(locateEvents, isEmpty);
    },
  );

  testWidgets('Player turn event feed uses specific diplomacy war copy', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    final otherId = game.players.firstWhere((p) => p.id != humanId).id;
    final humanName = game.players
        .firstWhere((p) => p.id == humanId)
        .displayName;
    final otherName = game.players
        .firstWhere((p) => p.id == otherId)
        .displayName;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          mapViewDataProvider.overrideWith((ref) => mapViewData),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: mapViewData),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    bus.emit(
      AppDiplomacyChangeEvent(
        actorId: humanId,
        targetId: otherId,
        changeType: 'declare_war',
        turnNumber: 1,
      ),
    );
    bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
    await tester.pump();

    expect(
      find.textContaining('$humanName declared war on $otherName!'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Player turn event feed renders work completion and taps map tile',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final locateEvents = <LocateMapTileEvent>[];
      final sub = bus.on<LocateMapTileEvent>().listen(locateEvents.add);
      addTearDown(() async {
        await sub.cancel();
        bus.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        AppWorkOrderCompletedEvent(
          playerId: humanId,
          unitId: 'u1',
          workTarget: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|1|0|0',
          provinceId: 'oldWorld|1',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();

      final line = find.textContaining('work completed');
      expect(line, findsOneWidget);
      await tester.tap(line);
      await tester.pump();

      expect(locateEvents, hasLength(1));
      expect(locateEvents.single.tileKey, 'oldWorld|1|0|0');
      expect(locateEvents.single.regionId, 'oldWorld');
    },
  );

  testWidgets('Player turn event feed includes discovery and overture lines', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    final otherId = game.players.firstWhere((p) => p.id != humanId).id;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          mapViewDataProvider.overrideWith((ref) => mapViewData),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: mapViewData),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    bus.emit(
      AppPlayerProvinceDiscoveredEvent(
        playerId: humanId,
        provinceId: 'oldWorld|1',
        turnNumber: 1,
      ),
    );
    bus.emit(
      AppOvertureAdvancedEvent(
        offererGpId: humanId,
        targetFactionId: otherId,
        newStage: 'embassy',
        turnNumber: 1,
      ),
    );
    bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
    await tester.pump();

    expect(find.textContaining('discovered!'), findsOneWidget);
    expect(find.textContaining('Overture advanced!'), findsOneWidget);
  });

  testWidgets(
    'Player turn event feed is hidden by default and toggles from news button',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        AppResearchCompleteEvent(
          playerId: humanId,
          techId: 'agri_1',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(kPlayerTurnFeedToggleButtonKey), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsNothing,
      );
      expect(find.text('Events'), findsNothing);

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();

      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsOneWidget,
      );
      expect(find.text('Events'), findsNothing);

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();

      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Player turn event feed replaces previous turn entries on next commit',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        bus.dispose();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(size: Size(500, 900)),
              child: child!,
            ),
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        AppResearchCompleteEvent(
          playerId: humanId,
          techId: 'agri_1',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsNothing,
      );
      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();

      bus.emit(
        AppOrderRejectedEvent(
          playerId: humanId,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsNothing,
      );
      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.textContaining('Order rejected! Reason: insufficient_treasury!'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Player turn event feed shows entries in narrow layout when toggled',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        bus.dispose();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(size: Size(500, 900)),
              child: child!,
            ),
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        AppResearchCompleteEvent(
          playerId: humanId,
          techId: 'agri_1',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final eventsButton = find.byKey(kPlayerTurnFeedToggleButtonKey);
      expect(eventsButton, findsOneWidget);
      final lineFinder = find.textContaining(
        'Research complete! agri_1 unlocked!',
      );
      expect(lineFinder, findsNothing);

      await tester.tap(eventsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(lineFinder, findsOneWidget);
    },
  );
}
