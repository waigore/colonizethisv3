// Cancel-with-forfeiture + applySetSlotFunding (Refs #3512 / #4720 Slice F).
// SPEC/ui/technology-panel.md § Slot occupancy + § Slot behaviour > Cancel.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'technology_panel_test_support.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_orders.dart';

void main() {
  suppressLogsForTests();

  late String techA;

  setUpAll(() {
    final rootIds =
        techCatalog.entries
            .where((e) => e.value.prerequisiteIds.isEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    techA = rootIds.isNotEmpty ? rootIds.first : techCatalog.keys.first;
  });

  group('Cancel with forfeiture warning (Refs #3512)', () {
    testWidgets('cancel with progress warns and only frees slot on confirm', (
      tester,
    ) async {
      final player = technologyPanelOccupancyPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 600},
      );
      final game = technologyPanelOccupancyGame(player);
      Orders? dispatched;

      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        currentOrders: const Orders(),
        onOrdersChanged: (o) => dispatched = o,
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Forfeit research progress?'), findsOneWidget);
      expect(dispatched, isNull);

      await tester.tap(find.text('Forfeit'));
      await tester.pumpAndSettle();

      expect(dispatched, isNotNull);
      final orders =
          dispatched!.researchOrdersByPlayerId[player.id] ?? const [];
      final slot0 = orders.firstWhere((o) => o.slotIndex == 0);
      expect(slot0.techId, isEmpty);
    });

    testWidgets('cancel with progress aborts when player keeps researching', (
      tester,
    ) async {
      final player = technologyPanelOccupancyPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 600},
      );
      final game = technologyPanelOccupancyGame(player);
      Orders? dispatched;

      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        currentOrders: const Orders(),
        onOrdersChanged: (o) => dispatched = o,
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();
      expect(find.text('Forfeit research progress?'), findsOneWidget);

      await tester.tap(find.text('Keep researching'));
      await tester.pumpAndSettle();

      expect(dispatched, isNull);
      expect(find.text(techDisplayName(techA)), findsWidgets);
    });

    testWidgets('cancel with zero progress frees slot without a warning', (
      tester,
    ) async {
      final player = technologyPanelOccupancyPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
      );
      final game = technologyPanelOccupancyGame(player);
      Orders? dispatched;

      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        currentOrders: const Orders(),
        onOrdersChanged: (o) => dispatched = o,
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Forfeit research progress?'), findsNothing);
      expect(dispatched, isNotNull);
      final orders =
          dispatched!.researchOrdersByPlayerId[player.id] ?? const [];
      final slot0 = orders.firstWhere((o) => o.slotIndex == 0);
      expect(slot0.techId, isEmpty);
    });
  });

  group('applySetSlotFunding for persisted-only slots (Refs #3512)', () {
    test('creates a fresh order carrying the persisted tech', () {
      const orders = Orders();
      final updated = applySetSlotFunding(
        currentOrders: orders,
        humanPlayerId: 'p1',
        slotIndex: 0,
        funding: ResearchFundingLevel.high,
        techId: techA,
      );
      final list = updated.researchOrdersByPlayerId['p1'] ?? const [];
      expect(list, hasLength(1));
      expect(list.first.slotIndex, 0);
      expect(list.first.techId, techA);
      expect(list.first.funding, ResearchFundingLevel.high);
    });

    test('returns orders unchanged for an empty slot with no techId', () {
      const orders = Orders();
      final updated = applySetSlotFunding(
        currentOrders: orders,
        humanPlayerId: 'p1',
        slotIndex: 1,
        funding: ResearchFundingLevel.high,
      );
      expect(updated.researchOrdersByPlayerId['p1'] ?? const [], isEmpty);
    });
  });
}
