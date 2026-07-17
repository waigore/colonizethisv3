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

import 'support/app_shell_harness.dart';

TurnNewsDigest _emptyDigestForTurn(int resolvedTurn) =>
    TurnNewsDigest(resolvedTurnNumber: resolvedTurn, lines: const []);

Game _ordersGame({required String id, int turnNumber = 1}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

Game _advanceTurn(Game game, int turnNumber, {VictoryState? victory}) {
  return game.copyWith(
    worldState: game.worldState.copyWith(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    ),
    victory: victory,
  );
}

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

  AppEventBus createBus() {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    return bus;
  }

  Future<void> pumpListener(
    WidgetTester tester, {
    required Game game,
    required AppEventBus bus,
    Widget child = const SizedBox.shrink(),
  }) async {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    await tester.pumpWidget(
      buildAppShell(
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
        child: GameToUIBusListener(gameId: game.id, child: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpTwice(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
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
      final game = _ordersGame(id: 'g_bus_1');
      final updated = _advanceTurn(game, 2);

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = createBus();
      await pumpListener(
        tester,
        game: game,
        bus: bus,
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
      );

      expect(find.text('turn:1'), findsOneWidget);

      adapter.save(gamesBox, updated);
      bus.emit(
        const TurnResolutionCompleteEvent(gameId: 'g_bus_1', turnNumber: 2),
      );
      await pumpTwice(tester);

      expect(find.text('turn:2'), findsOneWidget);
    },
  );

  testWidgets(
    'Given turn complete with digest When victory null Then emits OpenDialogEvent',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_news_1');
      final updated = _advanceTurn(game, 2);

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = createBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpListener(tester, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: _emptyDigestForTurn(1),
        ),
      );
      await pumpTwice(tester);

      expect(opens, hasLength(1));
      expect(opens.single.dialogId, 'turn_news');
    },
  );

  testWidgets(
    'Given turn complete at turn 0 with digest When processed Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_news_turn0', turnNumber: 0);
      final updated = _advanceTurn(game, 1);

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = createBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpListener(tester, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 0,
          turnNewsDigest: _emptyDigestForTurn(0),
        ),
      );
      await pumpTwice(tester);

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given reloaded game has victory When turn complete with digest Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_news_victory');
      final updated = _advanceTurn(
        game,
        2,
        victory: const VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 2,
        ),
      );

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = createBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpListener(tester, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: _emptyDigestForTurn(1),
        ),
      );
      await pumpTwice(tester);

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given turn complete without digest When victory null Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_news_no_digest');
      final updated = _advanceTurn(game, 2);

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = createBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpListener(tester, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        const TurnResolutionCompleteEvent(
          gameId: 'g_news_no_digest',
          turnNumber: 2,
        ),
      );
      await pumpTwice(tester);

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given negotiation mood input When mood changes Then emits PortraitMoodEvent',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_bus_mood_1');

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);
      final bus = createBus();

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await pumpListener(tester, game: game, bus: bus);

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
      await pumpTwice(tester);

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
      final game = _ordersGame(id: 'g_bus_mood_2');

      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);
      final bus = createBus();

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await pumpListener(tester, game: game, bus: bus);

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
      await pumpTwice(tester);

      expect(moodEvents, isEmpty);
    },
  );
}
