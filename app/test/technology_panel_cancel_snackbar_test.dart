// Choose-tech + cancel snackbar pins for TechnologyPanel (Refs #3512 / #4734 Slice F).
// Base panel pins: technology_panel_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'technology_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    player = game.players.first;
  });

  testWidgets(
    'TechnologyPanel "Choose tech" shows no-techs modal when none available',
    (WidgetTester tester) async {
      final fullyUnlocked = player.copyWith(
        techUnlocked: {for (final id in techCatalog.keys) id: true},
      );
      final gameWithFullyUnlocked = game.copyWith(
        players: [fullyUnlocked, ...game.players.skip(1)],
      );

      await pumpTechnologyPanel(
        tester,
        game: gameWithFullyUnlocked,
        player: fullyUnlocked,
        onOrdersChanged: (_) {},
        wrapInScrollView: true,
      );

      final chooseTech = find.text('Choose tech').first;
      await tester.ensureVisible(chooseTech);
      await tester.pumpAndSettle();
      await tester.tap(chooseTech);
      await tester.pumpAndSettle();

      expect(find.text('No techs available to research'), findsOneWidget);
    },
  );

  testWidgets(
    'TechnologyPanel slot Cancel (no progress) emits empty-techId cancel order '
    'and shows snackbar (Refs #3512)',
    (WidgetTester tester) async {
      final techId = techCatalog.keys.first;
      final withOrder = player.copyWith(
        techUnlocked: <String, bool>{},
        researchProgressByTechId: <String, int>{},
      );
      final gameWithEmptyUnlocked = game.copyWith(
        players: [withOrder, ...game.players.skip(1)],
      );

      final orders = Orders(
        researchOrdersByPlayerId: {
          withOrder.id: [
            ResearchOrder(
              slotIndex: 0,
              techId: techId,
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );

      Orders? captured;
      await pumpTechnologyPanel(
        tester,
        game: gameWithEmptyUnlocked,
        player: withOrder,
        currentOrders: orders,
        onOrdersChanged: (next) => captured = next,
        wrapInScrollView: true,
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.text('Forfeit research progress?'), findsNothing);
      expect(find.text('Research slot cancelled'), findsOneWidget);
      expect(captured, isNotNull);
      final capturedOrders =
          captured!.researchOrdersByPlayerId[withOrder.id] ?? const [];
      final slot0 = capturedOrders.firstWhere((o) => o.slotIndex == 0);
      expect(slot0.techId, isEmpty);
    },
  );
}
