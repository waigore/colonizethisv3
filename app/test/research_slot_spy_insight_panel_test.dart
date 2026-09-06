// TechnologyPanel spy-insight widget pins (Refs #4457 / #4734 Slice F).
// Pure preview math: research_slot_spy_insight_preview_test.dart.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show applySpyResearchBoostToPoints, researchPointsMedium;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view_breakdown.dart';

import 'research_slot_spy_insight_preview_support.dart';
import 'technology_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TechnologyPanel spy insight', () {
    testWidgets('positive: funded slot +N RP includes one-rival spy insight', (
      WidgetTester tester,
    ) async {
      final game = spyInsightPreviewGame(rivalCount: 1);
      final player = game.players.first.copyWith(treasury: 8000);
      final expected = applySpyResearchBoostToPoints(
        basePoints: researchPointsMedium,
        qualifyingRivalGpCount: 1,
      );
      await pumpTechnologyPanel(
        tester,
        game: game.copyWith(players: [player, ...game.players.skip(1)]),
        player: player,
        currentOrders: Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: kSpyInsightPreviewTechId,
                funding: ResearchFundingLevel.medium,
              ),
            ],
          },
        ),
        onOrdersChanged: (_) {},
      );

      expect(find.text('+$expected RP'), findsWidgets);
      await tester.tap(find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)));
      await tester.pumpAndSettle();
      expect(find.byType(ResearchFundingBreakdownDialog), findsOneWidget);
      expect(
        find.text('Spy insight — France already knows this (+15%)'),
        findsOneWidget,
      );
    });

    testWidgets('positive: two-rival stack names both courts at +30%', (
      WidgetTester tester,
    ) async {
      final game = spyInsightPreviewGame(rivalCount: 2);
      final player = game.players.first.copyWith(treasury: 8000);
      await pumpTechnologyPanel(
        tester,
        game: game.copyWith(players: [player, ...game.players.skip(1)]),
        player: player,
        currentOrders: Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: kSpyInsightPreviewTechId,
                funding: ResearchFundingLevel.medium,
              ),
            ],
          },
        ),
        onOrdersChanged: (_) {},
      );

      await tester.tap(find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)));
      await tester.pumpAndSettle();
      expect(
        find.text('Spy insight — France and Spain already know this (+30%)'),
        findsOneWidget,
      );
    });

    testWidgets('negative: funding None does not show a spy insight row', (
      WidgetTester tester,
    ) async {
      final game = spyInsightPreviewGame(rivalCount: 1);
      final player = game.players.first.copyWith(treasury: 8000);
      await pumpTechnologyPanel(
        tester,
        game: game.copyWith(players: [player, ...game.players.skip(1)]),
        player: player,
        currentOrders: Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: kSpyInsightPreviewTechId,
                funding: ResearchFundingLevel.none,
              ),
            ],
          },
        ),
        onOrdersChanged: (_) {},
      );

      expect(
        find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
        findsNothing,
      );
      expect(find.textContaining('Spy insight'), findsNothing);
    });
  });
}
