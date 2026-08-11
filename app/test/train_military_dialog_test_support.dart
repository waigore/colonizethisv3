// Shared pump / fixture helpers for TrainMilitaryDialog widget tests.
// Used by `train_military_dialog_test.dart` and sibling suites (Refs #4305).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

class TrainMilitaryDialogTestHarness {
  TrainMilitaryDialogTestHarness() : game = buildTrainPanelTestGame() {
    humanPlayerId = game.players.isNotEmpty
        ? game.players.firstWhere((p) => p.isHuman).id
        : game.players.first.id;
  }

  final Game game;
  late final String humanPlayerId;

  Player player(String pid) => game.players.firstWhere((p) => p.id == pid);

  Game gameWithMilitaryResources() {
    final p = player(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(p.techUnlocked ?? {});
    for (final techId in unlockingTechByRegimentId.values) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        p.copyWith(
          treasury: 10000,
          workerPool: p.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: p.stockpile.merge(
            const Stockpile(
              quantities: {
                'fabric': 100,
                'castIron': 100,
                'lumber': 100,
                'horses': 100,
                'steel': 100,
                'bronze': 100,
              },
            ),
          ),
        ),
        ...game.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Widget buildDialog({
    required Game panelGame,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) {
    return buildAppShell(
      child: Scaffold(
        body: TrainMilitaryDialog(
          game: panelGame,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: bus ?? AppEventBus.create(),
        ),
      ),
    );
  }
}
