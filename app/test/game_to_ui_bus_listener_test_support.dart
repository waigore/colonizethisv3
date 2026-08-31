// Pump/harness helpers for GameToUIBusListener widget tests (Refs #4305).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart'
    show gameSaveAdapterProvider, gameServiceProvider;
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/game_to_ui_bus_listener.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/providers/games_box_provider.dart';

import 'app_shell_harness.dart';

TurnNewsDigest gameToUiEmptyDigestForTurn(int resolvedTurn) =>
    TurnNewsDigest(resolvedTurnNumber: resolvedTurn, lines: const []);

Game gameToUiOrdersGame({required String id, int turnNumber = 1}) {
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

Game gameToUiAdvanceTurn(Game game, int turnNumber, {VictoryState? victory}) {
  return game.copyWith(
    worldState: game.worldState.copyWith(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    ),
    victory: victory,
  );
}

void gameToUiSaveRequiredMapData(
  GameSaveAdapter adapter,
  Box<dynamic> gamesBox,
  String gameId,
) {
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

AppEventBus gameToUiCreateBus() {
  final bus = AppEventBus.create();
  addTearDown(bus.dispose);
  return bus;
}

Future<void> pumpGameToUiListener(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required GameSaveAdapter adapter,
  required Game game,
  required AppEventBus bus,
  Widget child = const SizedBox.shrink(),
}) async {
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

Future<void> pumpGameToUiTwice(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}
