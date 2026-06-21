// Slot occupancy persistence + Cancel-with-forfeiture-warning widget/unit
// tests (deliverable 3, Refs #3512).
// SPEC/ui/technology-panel.md § Slot occupancy + § Slot behaviour > Cancel.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel_orders.dart';
import 'package:colonizethis_app/features/game/widgets/technology_slot_funding_toggles.dart';

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

  Player buildPlayer({
    required Map<int, ResearchSlotAssignment> assignments,
    Map<String, int> progress = const <String, int>{},
  }) {
    return Player(
      id: 'p1',
      displayName: 'P1',
      isHuman: true,
      treasury: 8000,
      researchSlots: 3,
      techUnlocked: const <String, bool>{},
      researchProgressByTechId: progress,
      researchSlotAssignments: assignments,
    );
  }

  Game buildGame(Player player) {
    return Game(
      id: 'occupancy-test',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: [player],
    );
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Game game,
    required Player player,
    required Orders orders,
    void Function(Orders)? onOrdersChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnologyPanel(
            game: game,
            player: player,
            currentOrders: orders,
            onOrdersChanged: onOrdersChanged,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Slot occupancy from persisted assignments (Refs #3512)', () {
    testWidgets(
      'persisted assignment renders in its slot with no fresh order',
      (tester) async {
        final player = buildPlayer(
          assignments: {
            0: ResearchSlotAssignment(
              techId: techA,
              funding: ResearchFundingLevel.high,
            ),
          },
          progress: <String, int>{techA: 600},
        );
        final game = buildGame(player);

        await pumpPanel(
          tester,
          game: game,
          player: player,
          orders: const Orders(),
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

    testWidgets('fresh non-empty order overrides the persisted assignment',
        (tester) async {
      final player = buildPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
      );
      final game = buildGame(player);
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

      await pumpPanel(
        tester,
        game: game,
        player: player,
        orders: orders,
        onOrdersChanged: (_) {},
      );

      expect(find.text(techDisplayName(techB)), findsWidgets);
      if (techA != techB) {
        expect(find.text(techDisplayName(techA)), findsNothing);
      }
    });

    testWidgets('empty-techId order frees a persisted slot in the UI',
        (tester) async {
      final player = buildPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 300},
      );
      final game = buildGame(player);
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

      await pumpPanel(
        tester,
        game: game,
        player: player,
        orders: orders,
        onOrdersChanged: (_) {},
      );

      expect(find.text(techDisplayName(techA)), findsNothing);
      // The freed slot 0 shows the empty-state line.
      expect(find.text('No tech assigned'), findsWidgets);
    });

    testWidgets('no standalone In-Progress block when progress is non-empty',
        (tester) async {
      final player = buildPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 600},
      );
      final game = buildGame(player);

      await pumpPanel(
        tester,
        game: game,
        player: player,
        orders: const Orders(),
        onOrdersChanged: (_) {},
      );

      expect(find.text('In progress:'), findsNothing);
    });
  });

  group('Cancel with forfeiture warning (Refs #3512)', () {
    testWidgets('cancel with progress warns and only frees slot on confirm',
        (tester) async {
      final player = buildPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 600},
      );
      final game = buildGame(player);
      Orders? dispatched;

      await pumpPanel(
        tester,
        game: game,
        player: player,
        orders: const Orders(),
        onOrdersChanged: (o) => dispatched = o,
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Forfeit research progress?'), findsOneWidget);
      expect(dispatched, isNull);

      await tester.tap(find.text('Forfeit'));
      await tester.pumpAndSettle();

      expect(dispatched, isNotNull);
      final orders = dispatched!.researchOrdersByPlayerId[player.id] ?? const [];
      final slot0 = orders.firstWhere((o) => o.slotIndex == 0);
      expect(slot0.techId, isEmpty);
    });

    testWidgets('cancel with progress aborts when player keeps researching',
        (tester) async {
      final player = buildPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
        progress: <String, int>{techA: 600},
      );
      final game = buildGame(player);
      Orders? dispatched;

      await pumpPanel(
        tester,
        game: game,
        player: player,
        orders: const Orders(),
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

    testWidgets('cancel with zero progress frees slot without a warning',
        (tester) async {
      final player = buildPlayer(
        assignments: {
          0: ResearchSlotAssignment(
            techId: techA,
            funding: ResearchFundingLevel.medium,
          ),
        },
      );
      final game = buildGame(player);
      Orders? dispatched;

      await pumpPanel(
        tester,
        game: game,
        player: player,
        orders: const Orders(),
        onOrdersChanged: (o) => dispatched = o,
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Forfeit research progress?'), findsNothing);
      expect(dispatched, isNotNull);
      final orders = dispatched!.researchOrdersByPlayerId[player.id] ?? const [];
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
