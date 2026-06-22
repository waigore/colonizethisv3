// Pins the shared TrainDialogBase / TrainDialogBaseState abstraction extracted
// for issue #3594 (AC: train_military_dialog.dart, train_civilians_dialog.dart,
// and train_naval_dialog.dart share a TrainDialogBase abstract State class).
//
// These structural assertions guard against regression where a train dialog is
// re-implemented as a bare StatefulWidget/State and silently re-duplicates the
// PopScope/CtDialogShell wrapper, capital-check state, count scaffolding, and
// order materialization that now live in the shared base.

import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_base.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_naval_dialog.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  });

  Player getPlayer(String pid) => game.players.firstWhere((p) => p.id == pid);

  Game richGame() {
    final player = getPlayer(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(player.techUnlocked ?? {});
    for (final techId in unlockingTechByRegimentId.values) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        player.copyWith(
          treasury: 10000,
          workerPool: player.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: player.stockpile.merge(
            const Stockpile(
              quantities: {
                'fabric': 100,
                'castIron': 100,
                'lumber': 100,
                'horses': 100,
                'steel': 100,
                'bronze': 100,
                'coal': 100,
                'paper': 100,
              },
            ),
          ),
          capitalProvinceId:
              player.capitalProvinceId ?? player.capitalTile?.provinceId,
        ),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('TrainDialogBase shared abstraction (#3594)', () {
    testWidgets('TrainCiviliansDialog extends the shared base', (tester) async {
      await tester.pumpWidget(
        host(
          TrainCiviliansDialog(
            game: richGame(),
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget(find.byType(TrainCiviliansDialog)),
        isA<TrainDialogBase>(),
      );
      expect(
        tester.state(find.byType(TrainCiviliansDialog)),
        isA<TrainDialogBaseState>(),
      );
    });

    testWidgets('TrainMilitaryDialog extends the shared base', (tester) async {
      await tester.pumpWidget(
        host(
          TrainMilitaryDialog(
            game: richGame(),
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget(find.byType(TrainMilitaryDialog)),
        isA<TrainDialogBase>(),
      );
      expect(
        tester.state(find.byType(TrainMilitaryDialog)),
        isA<TrainDialogBaseState>(),
      );
    });

    testWidgets('TrainNavalDialog extends the shared base', (tester) async {
      await tester.pumpWidget(
        host(
          TrainNavalDialog(
            game: richGame(),
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget(find.byType(TrainNavalDialog)),
        isA<TrainDialogBase>(),
      );
      expect(
        tester.state(find.byType(TrainNavalDialog)),
        isA<TrainDialogBaseState>(),
      );
    });

    testWidgets(
      'shared base renders the no-capital message when the player has no '
      'capital (negative path is centralized, not re-duplicated)',
      (tester) async {
        // An unknown player id resolves to a null Player, exercising the
        // shared base's hasCapital == false branch without mutating fixtures.
        await tester.pumpWidget(
          host(
            TrainCiviliansDialog(
              game: game,
              humanPlayerId: 'no_such_player',
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state =
            tester.state(find.byType(TrainCiviliansDialog))
                as TrainDialogBaseState;
        expect(state.hasCapital, isFalse);
        // No stepper steppers render in the no-capital branch.
        expect(find.text('+'), findsNothing);
      },
    );
  });
}
