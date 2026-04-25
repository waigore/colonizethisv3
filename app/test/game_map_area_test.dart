import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
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
        workTarget: 'explore',
      ),
    );
    bus.emit(const UnitsPanelClosedEvent('civilian'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    bus.dispose();
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

    await tester.tap(find.byTooltip('Events'));
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

      await tester.tap(find.byTooltip('Events'));
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

      await tester.tap(find.byTooltip('Events'));
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

    await tester.tap(find.byTooltip('Events'));
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
          workTarget: 'build_road',
          targetTileKey: 'oldWorld|1|0|0',
          provinceId: 'oldWorld|1',
          turnNumber: 1,
        ),
      );
      bus.emit(TurnResolutionCompleteEvent(gameId: game.id, turnNumber: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byTooltip('Events'));
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

    await tester.tap(find.byTooltip('Events'));
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

      expect(find.byTooltip('Events'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsNothing,
      );
      expect(find.text('Events'), findsNothing);

      await tester.tap(find.byTooltip('Events'));
      await tester.pump();

      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsOneWidget,
      );
      expect(find.text('Events'), findsNothing);

      await tester.tap(find.byTooltip('Events'));
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
      await tester.tap(find.byTooltip('Events'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.textContaining('Research complete! agri_1 unlocked!'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Events'));
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
      await tester.tap(find.byTooltip('Events'));
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

      final eventsButton = find.byTooltip('Events');
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

  testWidgets(
    'explore selection mode prompt appears under one second',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
          ? game.worldState.oldWorld.units.first.id
          : game.worldState.newWorld.units.first.id;

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

      final sw = Stopwatch()..start();
      bus.emit(
        StartCivilianWorkTargetSelectionEvent(
          unitId: sampleUnitId,
          workTarget: kWorkTargetExplore,
        ),
      );
      await tester.pump();

      var selectionReady = false;
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 5));
        if (find.text('Select a tile, or click cancel').evaluate().isNotEmpty) {
          selectionReady = true;
          break;
        }
      }
      sw.stop();

      expect(selectionReady, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    },
  );

  testWidgets(
    'work target selection caches global valid tile keys across region switches',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final workTargets = <String>[
        'explore',
        'prospect',
        'build_improvement',
        'upgrade_town',
        'build_road',
        'build_port',
        'build_fort',
        'build_rail',
        'steal_tech',
        'counter_spy',
        'purchase_land',
      ];
      final topology = init.combinedTopology;
      final playerView = buildPlayerView(game, topology, humanPlayerId);
      final unitById = <String, Unit>{
        for (final unit in [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ])
          unit.id: unit,
      };

      ({String unitId, String workTarget})? offTabSelection;
      for (final unit in unitById.values) {
        for (final workTarget in workTargets) {
          final valid = getValidWorkOrderTileKeysWithVisibility(
            game: game,
            topology: topology,
            view: playerView,
            unitId: unit.id,
            workTarget: workTarget,
            currentOrders: const Orders(),
            tileMapByRegion: init.tileMapByRegion,
          );
          final hasOldWorld = valid.any((k) => k.startsWith('oldWorld|'));
          final hasOnlyOldWorld = hasOldWorld &&
              !valid.any((k) => k.startsWith('newWorld|'));
          if (hasOnlyOldWorld) {
            offTabSelection = (unitId: unit.id, workTarget: workTarget);
            break;
          }
        }
        if (offTabSelection != null) {
          break;
        }
      }

      expect(
        offTabSelection,
        isNotNull,
        reason:
            'debug init fixture must include one selection with valid tiles only in Old World',
      );

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

      await tester.tap(find.text('New World'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        StartCivilianWorkTargetSelectionEvent(
          unitId: offTabSelection!.unitId,
          workTarget: offTabSelection.workTarget,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final beforeSwitchRegionMap = tester
          .widgetList<CtRegionMap>(find.byType(CtRegionMap))
          .first;
      final beforeSwitchValidKeys = beforeSwitchRegionMap.validTileKeys;
      expect(beforeSwitchValidKeys, isNotNull);
      expect(
        beforeSwitchValidKeys!.every((k) => k.startsWith('oldWorld|')),
        isTrue,
      );
      await tester.tap(find.text('Old World'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final afterSwitchRegionMap = tester
          .widgetList<CtRegionMap>(find.byType(CtRegionMap))
          .first;
      final afterSwitchValidKeys = afterSwitchRegionMap.validTileKeys;
      expect(afterSwitchValidKeys, isNotNull);
      expect(
        afterSwitchValidKeys!.every((k) => k.startsWith('oldWorld|')),
        isTrue,
      );
    },
  );

  testWidgets(
    'work target selection shows prompt overlay and cancel button exits mode',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
          ? game.worldState.oldWorld.units.first.id
          : game.worldState.newWorld.units.first.id;

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
        StartCivilianWorkTargetSelectionEvent(
          unitId: sampleUnitId,
          workTarget: 'explore',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Select a tile, or click cancel'), findsOneWidget);
      expect(find.text('cancel'), findsOneWidget);

      await tester.tap(find.text('cancel'));
      await tester.pump();

      expect(find.text('Select a tile, or click cancel'), findsNothing);
    },
  );

  testWidgets('left rail icon cancels selection mode before opening panel', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    final openedPanels = <OpenCivilianUnitsPanelEvent>[];
    final panelSub = bus.on<OpenCivilianUnitsPanelEvent>().listen(
      openedPanels.add,
    );
    addTearDown(panelSub.cancel);

    final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
        ? game.worldState.oldWorld.units.first.id
        : game.worldState.newWorld.units.first.id;

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
      StartCivilianWorkTargetSelectionEvent(
        unitId: sampleUnitId,
        workTarget: 'explore',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Select a tile, or click cancel'), findsOneWidget);

    await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
    await tester.pump();

    expect(find.text('Select a tile, or click cancel'), findsNothing);
    expect(openedPanels, hasLength(1));
  });

  testWidgets('escape key cancels work target selection mode', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
        ? game.worldState.oldWorld.units.first.id
        : game.worldState.newWorld.units.first.id;

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
      StartCivilianWorkTargetSelectionEvent(
        unitId: sampleUnitId,
        workTarget: 'explore',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Select a tile, or click cancel'), findsOneWidget);
    var regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
    expect(regionMap.validTileKeys, isNotNull);

    final keyHandlerFocuses = tester
        .widgetList<Focus>(find.byType(Focus))
        .where((focus) => focus.onKeyEvent != null);
    var keyHandled = false;
    for (final focus in keyHandlerFocuses) {
      final keyResult = focus.onKeyEvent!(
        FocusNode(),
        const KeyDownEvent(
          timeStamp: Duration.zero,
          logicalKey: LogicalKeyboardKey.escape,
          physicalKey: PhysicalKeyboardKey.escape,
        ),
      );
      if (keyResult == KeyEventResult.handled) {
        keyHandled = true;
        break;
      }
    }
    expect(keyHandled, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Select a tile, or click cancel'), findsNothing);
    regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
    expect(regionMap.validTileKeys, isNull);
  });

  testWidgets(
    'selection mode blocks non-selection map interaction callbacks',
    (WidgetTester tester) async {
      final init = getDebugInitGameResult();
      final game = init.game;
      final mapViewData = init.mapViewData;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
          ? game.worldState.oldWorld.units.first.id
          : game.worldState.newWorld.units.first.id;

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

      var regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
      expect(regionMap.onMapTileTappedForDetail, isNotNull);
      expect(regionMap.onCivilianTileTapped, isNotNull);
      expect(regionMap.onFleetMarkerTapped, isNotNull);

      bus.emit(
        StartCivilianWorkTargetSelectionEvent(
          unitId: sampleUnitId,
          workTarget: 'explore',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Select a tile, or click cancel'), findsOneWidget);
      regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
      expect(regionMap.onMapTileTappedForDetail, isNull);
      expect(regionMap.onCivilianTileTapped, isNull);
      expect(regionMap.onFleetMarkerTapped, isNull);
    },
  );
}
