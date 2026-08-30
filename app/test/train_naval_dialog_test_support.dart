// Shared pump / fixture helpers for TrainNavalDialog widget tests.
// Used by `train_naval_dialog_test.dart` and
// `train_naval_dialog_affordance_test.dart` (Refs #4305).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

class TrainNavalDialogTestHarness {
  TrainNavalDialogTestHarness() : game = buildTrainPanelTestGame() {
    humanPlayerId = game.players.isNotEmpty
        ? game.players.firstWhere((p) => p.isHuman).id
        : game.players.first.id;
  }

  final Game game;
  late final String humanPlayerId;

  Player player(String pid) => game.players.firstWhere((p) => p.id == pid);

  Game gameWithPlayer(Player Function(Player base) update) {
    final p = player(humanPlayerId);
    return game.copyWith(
      players: [
        update(p),
        ...game.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Game gameWithNavalResources() {
    return gameWithPlayer((p) {
      final techUnlocked = Map<String, bool>.from(p.techUnlocked ?? {});
      for (final techId in unlockingTechByShipId.values) {
        techUnlocked[techId] = true;
      }
      return p.copyWith(
        treasury: 50000,
        workerPool: p.workerPool.copyWith(peasants: 20),
        techUnlocked: techUnlocked,
        stockpile: p.stockpile.merge(
          const Stockpile(
            quantities: {
              'lumber': 100,
              'fabric': 100,
              'castIron': 100,
              'coal': 100,
            },
          ),
        ),
      );
    });
  }

  String capitalOf(Game g) {
    final p = g.players.firstWhere((x) => x.id == humanPlayerId);
    return (p.capitalProvinceId ?? p.capitalTile?.provinceId)!;
  }

  Widget buildDialog({
    required Game panelGame,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) {
    return buildAppShell(
      child: Scaffold(
        body: TrainNavalDialog(
          game: panelGame,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: bus ?? AppEventBus.create(),
        ),
      ),
    );
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Game panelGame,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) async {
    await tester.pumpWidget(
      buildDialog(
        panelGame: panelGame,
        currentOrders: currentOrders,
        bus: bus,
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget handlerShell({
    required Game panelGame,
    Orders orders = const Orders(),
    required Widget body,
  }) {
    return buildAppShell(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(panelGame)),
        currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(orders)),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      navigatorKey: appNavigatorKey,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(body: body),
    );
  }

  Game richWithHuman(Player Function(Player p) update) {
    final base = gameWithNavalResources();
    final p = base.players.firstWhere((x) => x.id == humanPlayerId);
    return base.copyWith(
      players: [
        update(p),
        ...base.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Orders carrackOrders(Game g, int count) {
    final capital = capitalOf(g);
    return Orders(
      buildUnitOrdersByPlayerId: {
        humanPlayerId: [
          for (var i = 0; i < count; i++)
            BuildUnitOrder(
              unitType: ShipEconomyCatalog.carrack.shipTypeId,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
        ],
      },
    );
  }
}
