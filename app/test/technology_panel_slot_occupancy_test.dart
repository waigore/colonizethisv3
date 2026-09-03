// Slot occupancy persistence widget/unit tests (deliverable 3, Refs #3512).
// SPEC/ui/technology-panel.md § Slot occupancy + § Slot behaviour > Cancel.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'technology_panel_test_support.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/technology/technology_slot_funding_toggles.dart';

void main() {
  suppressLogsForTests();

  late String techA;
  late String techB;

  setUpAll(() {
    final rootIds =
        techCatalog.entries
            .where((e) => e.value.prerequisiteIds.isEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    techA = rootIds.isNotEmpty ? rootIds.first : techCatalog.keys.first;
    techB = rootIds.length > 1 ? rootIds[1] : techA;
  });

  group('Slot occupancy from persisted assignments (Refs #3512)', () {
    testWidgets(
      'persisted assignment renders in its slot with no fresh order',
      (tester) async {
        final player = technologyPanelOccupancyPlayer(
          assignments: {
            0: ResearchSlotAssignment(
              techId: techA,
              funding: ResearchFundingLevel.high,
            ),
          },
          progress: <String, int>{techA: 600},
        );
        final game = technologyPanelOccupancyGame(player);

        await pumpTechnologyPanel(
          tester,
          game: game,
          player: player,
          currentOrders: const Orders(),
          onOrdersChanged: (_) {},
        );

        expect(find.text(techDisplayName(techA)), findsWidgets);
        // The High funding toggle row renders for the persisted slot.
        expect(
          find.byKey(
            SlotFundingToggleRow.toggleKey(0, ResearchFundingLevel.high),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('fresh non-empty order overrides the persisted assignment', (
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
      final orders = Orders(
        researchOrdersByPlayerId: {
          player.id: [
            ResearchOrder(
              slotIndex: 0,
              techId: techB,
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );

      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        currentOrders: orders,
        onOrdersChanged: (_) {},
      );

      expect(find.text(techDisplayName(techB)), findsWidgets);
      if (techA != techB) {
        expect(find.text(techDisplayName(techA)), findsNothing);
      }
    });

    testWidgets('empty-techId order frees a persisted slot in the UI', (
      tester,
    ) async {
      final player = technologyPanelOccupancyPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 300},
      );
      final game = technologyPanelOccupancyGame(player);
      final orders = Orders(
        researchOrdersByPlayerId: {
          player.id: [
            ResearchOrder(
              slotIndex: 0,
              techId: '',
              funding: ResearchFundingLevel.none,
            ),
          ],
        },
      );

      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        currentOrders: orders,
        onOrdersChanged: (_) {},
      );

      expect(find.text(techDisplayName(techA)), findsNothing);
      // The freed slot 0 shows the empty-state line.
      expect(find.text('No tech assigned'), findsWidgets);
    });

    testWidgets('no standalone In-Progress block when progress is non-empty', (
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

      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        currentOrders: const Orders(),
        onOrdersChanged: (_) {},
      );

      expect(find.text('In progress:'), findsNothing);
    });
  });
}
