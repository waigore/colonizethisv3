// Shared pump / fixture helpers for TrainCiviliansDialog widget tests.
// Used by `train_civilians_dialog_test.dart` and
// `train_civilians_dialog_affordance_test.dart` (Refs #4305).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

class TrainCiviliansDialogTestHarness {
  TrainCiviliansDialogTestHarness() : game = buildTrainPanelTestGame() {
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  }

  final Game game;
  late final String humanPlayerId;

  Player player(String pid) => game.players.firstWhere((p) => p.id == pid);

  String humanCapitalId() {
    final p = player(humanPlayerId);
    return (p.capitalProvinceId ?? p.capitalTile?.provinceId)!;
  }

  Game gameWithPlayer(Player Function(Player base) update) {
    final p = player(humanPlayerId);
    return game.copyWith(
      players: [
        update(p),
        ...game.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Game gameWithResources({
    required int treasury,
    required int paper,
    String? techUnlocked,
    Map<String, bool>? techUnlockedMap,
    bool replaceStockpile = false,
  }) {
    return gameWithPlayer((p) {
      final capital = p.capitalProvinceId ?? p.capitalTile?.provinceId;
      final paperStock = Stockpile(quantities: {'paper': paper});
      return p.copyWith(
        treasury: treasury,
        stockpile: replaceStockpile
            ? const Stockpile().merge(paperStock)
            : p.stockpile.merge(paperStock),
        techUnlocked:
            techUnlockedMap ??
            (techUnlocked != null ? {techUnlocked: true} : null),
        capitalProvinceId: capital,
      );
    });
  }

  Orders builderOrders(int count) {
    final capital = humanCapitalId();
    return Orders(
      buildUnitOrdersByPlayerId: {
        humanPlayerId: [
          for (var i = 0; i < count; i++)
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
        ],
      },
    );
  }

  Game gameWithCapital({required int treasury, required int paper}) =>
      gameWithResources(
        treasury: treasury,
        paper: paper,
        replaceStockpile: true,
      );

  Game gameWithNoTech({int? treasury}) => gameWithPlayer(
    (p) => p.copyWith(
      treasury: treasury ?? p.treasury,
      techUnlocked: <String, bool>{},
      capitalProvinceId: p.capitalProvinceId ?? p.capitalTile?.provinceId,
    ),
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Game panelGame,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: TrainCiviliansDialog(
            game: panelGame,
            humanPlayerId: humanPlayerId,
            currentOrders: currentOrders,
            bus: bus ?? AppEventBus.create(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapStepper(
    WidgetTester tester,
    String glyph, {
    int index = 0,
  }) async {
    final finder = find.text(glyph).at(index);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Widget civilianPanelWithAppHandler(Game panelGame) {
    return buildAppShell(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(panelGame)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        availableWorkTargetIdsForUnitProvider.overrideWith(
          (ref, _) => const <String>[],
        ),
      ],
      navigatorKey: appNavigatorKey,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            return CivilianUnitsPanel(
              game: panelGame,
              humanPlayerId: humanPlayerId,
              bus: ref.watch(appEventBusProvider),
            );
          },
        ),
      ),
    );
  }

  Future<void> pumpCivilianPanel(WidgetTester tester, [Game? panelGame]) async {
    await tester.pumpWidget(civilianPanelWithAppHandler(panelGame ?? game));
    await tester.pumpAndSettle();
  }
}
