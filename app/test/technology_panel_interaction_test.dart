import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  group('TechnologyPanel interactions', () {
    late Game game;
    late Player player;

    setUpAll(() {
      final result = getDebugInitGameResult();
      game = result.game;
      player = game.players.first;
    });

    testWidgets('Choose tech assigns an order and closes sheet',
        (WidgetTester tester) async {
      Orders last = const Orders();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechnologyPanel(
              game: game,
              player: player,
              currentOrders: const Orders(),
              onOrdersChanged: (o) => last = o,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open choose dialog for slot 1.
      await tester.tap(find.text('Choose tech').first);
      await tester.pumpAndSettle();

      // Either we see a list of available techs, or the empty-state message.
      if (find.text('No techs available to research').evaluate().isNotEmpty) {
        expect(find.text('No techs available to research'), findsOneWidget);
        return;
      }

      // Tap the first tech row in the bottom sheet. The sheet tiles have a
      // subtitle that includes "Era ...".
      final firstTechTile = find.ancestor(
        of: find.textContaining('Era ').first,
        matching: find.byType(ListTile),
      );
      expect(firstTechTile, findsOneWidget);
      await tester.ensureVisible(firstTechTile);
      await tester.tap(firstTechTile);
      await tester.pumpAndSettle();

      // Orders should now contain at least one research order for the player.
      final orders = last.researchOrdersByPlayerId[player.id] ?? const [];
      expect(orders, isNotEmpty);
      expect(orders.first.slotIndex, 0);
      expect(orders.first.techId, isNotEmpty);
    });

    testWidgets('Cancel removes a research order and shows snack bar',
        (WidgetTester tester) async {
      Orders last = const Orders();
      final techId = techCatalog.keys.first;
      final seeded = Orders(
        researchOrdersByPlayerId: {
          player.id: [
            ResearchOrder(
              slotIndex: 0,
              techId: techId,
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechnologyPanel(
              game: game,
              player: player,
              currentOrders: seeded,
              onOrdersChanged: (o) => last = o,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pump(); // snack bar enqueued

      expect(find.text('Research slot cancelled'), findsOneWidget);

      final orders = last.researchOrdersByPlayerId[player.id] ?? const [];
      expect(orders.where((o) => o.slotIndex == 0), isEmpty);
    });
  });
}

