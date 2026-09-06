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
}
