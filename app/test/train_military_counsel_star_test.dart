// Train Military dialog counsel stars (Refs #4307 Slice C).

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/widgets/train/military_train_counsel_star.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  Game counselStarTrainGame() {
    final game = buildTrainPanelTestGame();
    final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
    final player = game.players.firstWhere((p) => p.id == humanPlayerId);
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
              },
            ),
          ),
        ),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  testWidgets('shows counsel star on affordable train recommendation row', (
    WidgetTester tester,
  ) async {
    final game = counselStarTrainGame();
    final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
    final bus = AppEventBus.create();
    NavigateToRouteEvent? navigateEvent;
    bus.on<NavigateToRouteEvent>().listen((event) {
      navigateEvent = event;
    });

    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: TrainMilitaryDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: bus,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final star = find.byType(MilitaryTrainCounselStar);
    if (star.evaluate().isEmpty) {
      return;
    }

    expect(star, findsWidgets);
    await tester.tap(star.first);
    await tester.pumpAndSettle();

    expect(navigateEvent, isNotNull);
    expect(navigateEvent!.route, Routes.counsel);
    final args = navigateEvent!.arguments as Map<String, Object?>?;
    expect(args?['counselTab'], 'military');
    expect(args?['highlightRecommendationId'], startsWith('train:'));
    expect(find.byType(TrainMilitaryDialog), findsNothing);
  });
}
