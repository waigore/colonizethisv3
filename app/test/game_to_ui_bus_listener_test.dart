// SPEC/program/app-event-bus.md — GameToUI per-screen subscription (architecture).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/game_to_ui_bus_listener.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';

TurnNewsDigest _emptyDigestForTurn(int resolvedTurn) =>
    TurnNewsDigest(resolvedTurnNumber: resolvedTurn, lines: const []);

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late GameSaveAdapter adapter;

  void saveRequiredMapDataForGame(String gameId) {
    final tileMap = TileMapResult(
      width: 1,
      height: 1,
      grid: [
        ['oldWorld|M1'],
      ],
    );
    const topo = MapTopology(nodes: [], edges: []);
    adapter.saveMapData(
      gamesBox,
      gameId,
      tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
      topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
      combinedTopology: topo,
    );
  }

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_to_ui');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
    adapter = GameSaveAdapter();
  });

  testWidgets(
    'Given GameToUIBusListener for current game When TurnResolutionCompleteEvent '
    'Then currentGameProvider reloads from GameService',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_bus_1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        ),
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: MaterialApp(
            home: GameToUIBusListener(
              gameId: game.id,
              child: Consumer(
                builder: (context, ref, _) {
                  final g = ref.watch(currentGameProvider);
                  return Scaffold(
                    body: Text(
                      'turn:${g?.worldState.turnState.turnNumber ?? -1}',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('turn:1'), findsOneWidget);

      adapter.save(gamesBox, updated);
      bus.emit(
        const TurnResolutionCompleteEvent(gameId: 'g_bus_1', turnNumber: 2),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('turn:2'), findsOneWidget);
    },
  );

  testWidgets(
    'Given turn complete with digest When victory null Then emits OpenDialogEvent',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_news_1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        ),
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: MaterialApp(
            home: GameToUIBusListener(
              gameId: game.id,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: _emptyDigestForTurn(1),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(opens, hasLength(1));
      expect(opens.single.dialogId, 'turn_news');
    },
  );

  testWidgets(
    'Given turn complete at turn 0 with digest When processed Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_news_turn0',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        ),
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: MaterialApp(
            home: GameToUIBusListener(
              gameId: game.id,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 0,
          turnNewsDigest: _emptyDigestForTurn(0),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given reloaded game has victory When turn complete with digest Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_news_victory',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        ),
        victory: const VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 2,
        ),
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: MaterialApp(
            home: GameToUIBusListener(
              gameId: game.id,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: _emptyDigestForTurn(1),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given turn complete without digest When victory null Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_news_no_digest',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        ),
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: MaterialApp(
            home: GameToUIBusListener(
              gameId: game.id,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      adapter.save(gamesBox, updated);
      bus.emit(
        const TurnResolutionCompleteEvent(
          gameId: 'g_news_no_digest',
          turnNumber: 2,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given negotiation mood input When mood changes Then emits PortraitMoodEvent',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_bus_mood_1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: const MaterialApp(
            home: GameToUIBusListener(
              gameId: 'g_bus_mood_1',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      bus.emit(
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'considering',
          offerQualityDelta: -0.8,
          stallCounter: 0,
          seed: 0,
          durationMs: 900,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(moodEvents, hasLength(1));
      expect(moodEvents.single.leaderId, 'ai1');
      expect(moodEvents.single.fromMood, 'considering');
      expect(moodEvents.single.toMood, anyOf('irritated', 'dismissive'));
      expect(moodEvents.single.durationMs, 900);
    },
  );

  testWidgets(
    'Given negotiation mood input When mood does not change Then emits no PortraitMoodEvent',
    (WidgetTester tester) async {
      final game = Game(
        id: 'g_bus_mood_2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith((ref) {
              final svc = GameService(gamesBox, adapter);
              svc.eventBus = bus;
              return svc;
            }),
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: const MaterialApp(
            home: GameToUIBusListener(
              gameId: 'g_bus_mood_2',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      bus.emit(
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'calculating',
          offerQualityDelta: 0.0,
          stallCounter: 2,
          seed: 1,
          durationMs: 900,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(moodEvents, isEmpty);
    },
  );
}
