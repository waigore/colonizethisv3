// SPEC/program/app-event-bus.md — GameToUI per-screen subscription (architecture).

import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_to_ui_bus_listener_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late GameSaveAdapter adapter;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_to_ui');
    adapter = GameSaveAdapter();
  });

  testWidgets(
    'Given GameToUIBusListener for current game When TurnResolutionCompleteEvent '
    'Then currentGameProvider reloads from GameService',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_bus_1');
      final updated = gameToUiAdvanceTurn(game, 2);

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);

      final bus = gameToUiCreateBus();
      await pumpGameToUiListener(
        tester,
        gamesBox: gamesBox,
        adapter: adapter,
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
      await pumpGameToUiTwice(tester);

      expect(find.text('turn:2'), findsOneWidget);
    },
  );

  testWidgets(
    'Given turn complete with digest When victory null Then emits OpenDialogEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_news_1');
      final updated = gameToUiAdvanceTurn(game, 2);

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);

      final bus = gameToUiCreateBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpGameToUiListener(tester, gamesBox: gamesBox, adapter: adapter, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: gameToUiEmptyDigestForTurn(1),
        ),
      );
      await pumpGameToUiTwice(tester);

      expect(opens, hasLength(1));
      expect(opens.single.dialogId, 'turn_news');
    },
  );

  testWidgets(
    'Given turn complete at turn 0 with digest When processed Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_news_turn0', turnNumber: 0);
      final updated = gameToUiAdvanceTurn(game, 1);

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);

      final bus = gameToUiCreateBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpGameToUiListener(tester, gamesBox: gamesBox, adapter: adapter, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 0,
          turnNewsDigest: gameToUiEmptyDigestForTurn(0),
        ),
      );
      await pumpGameToUiTwice(tester);

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given reloaded game has victory When turn complete with digest Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_news_victory');
      final updated = gameToUiAdvanceTurn(
        game,
        2,
        victory: const VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 2,
        ),
      );

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);

      final bus = gameToUiCreateBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpGameToUiListener(tester, gamesBox: gamesBox, adapter: adapter, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: gameToUiEmptyDigestForTurn(1),
        ),
      );
      await pumpGameToUiTwice(tester);

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given turn complete without digest When victory null Then does not emit OpenDialogEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_news_no_digest');
      final updated = gameToUiAdvanceTurn(game, 2);

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);

      final bus = gameToUiCreateBus();
      final opens = <OpenDialogEvent>[];
      final openSub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(openSub.cancel);

      await pumpGameToUiListener(tester, gamesBox: gamesBox, adapter: adapter, game: game, bus: bus);

      adapter.save(gamesBox, updated);
      bus.emit(
        const TurnResolutionCompleteEvent(
          gameId: 'g_news_no_digest',
          turnNumber: 2,
        ),
      );
      await pumpGameToUiTwice(tester);

      expect(opens, isEmpty);
    },
  );

  testWidgets(
    'Given negotiation mood input When mood changes Then emits PortraitMoodEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_bus_mood_1');

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);
      final bus = gameToUiCreateBus();

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await pumpGameToUiListener(tester, gamesBox: gamesBox, adapter: adapter, game: game, bus: bus);

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
      await pumpGameToUiTwice(tester);

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
      final game = gameToUiOrdersGame(id: 'g_bus_mood_2');

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);
      final bus = gameToUiCreateBus();

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await pumpGameToUiListener(tester, gamesBox: gamesBox, adapter: adapter, game: game, bus: bus);

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
      await pumpGameToUiTwice(tester);

      expect(moodEvents, isEmpty);
    },
  );
}
