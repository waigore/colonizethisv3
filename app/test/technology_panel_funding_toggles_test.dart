// Slot funding toggle widget tests (Refs #3512).
// SPEC/ui/technology-panel.md § Slot behaviour > Slot funding controls.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology_slot_funding_toggles.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;
  late String rootTechId;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    player = game.players.first;
    final rootIds =
        techCatalog.entries
            .where((e) => e.value.prerequisiteIds.isEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    rootTechId = rootIds.isNotEmpty ? rootIds.first : techCatalog.keys.first;
  });

  Orders seededOrders(ResearchFundingLevel funding) {
    return Orders(
      researchOrdersByPlayerId: {
        player.id: [
          ResearchOrder(
            slotIndex: 0,
            techId: rootTechId,
            funding: funding,
          ),
        ],
      },
    );
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Orders orders,
    required void Function(Orders)? onOrdersChanged,
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

  Color borderColorOf(WidgetTester tester, ResearchFundingLevel level) {
    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(SlotFundingToggleRow.toggleKey(0, level)),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = decorated.decoration as BoxDecoration;
    return decoration.border!.top.color;
  }

  testWidgets(
    'positive: assigned editable slot renders five keyed funding toggles (AC funding toggles present)',
    (WidgetTester tester) async {
      await pumpPanel(
        tester,
        orders: seededOrders(ResearchFundingLevel.medium),
        onOrdersChanged: (_) {},
      );

      expect(find.byType(SlotFundingToggleRow), findsOneWidget);
      for (final level in ResearchFundingLevel.values) {
        expect(
          find.byKey(SlotFundingToggleRow.toggleKey(0, level)),
          findsOneWidget,
          reason: 'funding toggle for ${level.name} should render',
        );
      }
    },
  );

  testWidgets(
    'positive: Medium is selected by default and the others are unselected',
    (WidgetTester tester) async {
      await pumpPanel(
        tester,
        orders: seededOrders(ResearchFundingLevel.medium),
        onOrdersChanged: (_) {},
      );

      expect(
        borderColorOf(tester, ResearchFundingLevel.medium),
        EditorialMonoclePalette.accent,
      );
      for (final level in <ResearchFundingLevel>[
        ResearchFundingLevel.none,
        ResearchFundingLevel.low,
        ResearchFundingLevel.high,
        ResearchFundingLevel.maximum,
      ]) {
        expect(
          borderColorOf(tester, level),
          EditorialMonoclePalette.border,
          reason: '${level.name} toggle should render unselected',
        );
      }
    },
  );

  testWidgets(
    'positive: tapping a funding toggle dispatches updated orders for that slot',
    (WidgetTester tester) async {
      Orders? last;
      await pumpPanel(
        tester,
        orders: seededOrders(ResearchFundingLevel.medium),
        onOrdersChanged: (o) => last = o,
      );

      await tester.tap(
        find.byKey(
          SlotFundingToggleRow.toggleKey(0, ResearchFundingLevel.high),
        ),
      );
      await tester.pumpAndSettle();

      expect(last, isNotNull);
      final orders = last!.researchOrdersByPlayerId[player.id] ?? const [];
      expect(orders, hasLength(1));
      expect(orders.first.slotIndex, 0);
      expect(orders.first.techId, rootTechId);
      expect(orders.first.funding, ResearchFundingLevel.high);
    },
  );

  testWidgets(
    'negative: read-only panel (onOrdersChanged == null) renders no funding toggles',
    (WidgetTester tester) async {
      await pumpPanel(
        tester,
        orders: seededOrders(ResearchFundingLevel.medium),
        onOrdersChanged: null,
      );

      expect(find.byType(SlotFundingToggleRow), findsNothing);
    },
  );

  testWidgets(
    'negative: empty slot (no assigned tech) renders no funding toggles',
    (WidgetTester tester) async {
      await pumpPanel(
        tester,
        orders: const Orders(),
        onOrdersChanged: (_) {},
      );

      expect(find.byType(SlotFundingToggleRow), findsNothing);
    },
  );
}
