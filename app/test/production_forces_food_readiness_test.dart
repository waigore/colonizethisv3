// Forces-food readiness UI tests. SPEC/ui/production-panel.md § Forces food readiness (#4242).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  group('ProductionPanel forces food readiness', () {
    testWidgets('hides strip when no regiments or ships', (
      WidgetTester tester,
    ) async {
      final player = productionPanelTestFullPlayer();
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          forcesFeedingOverride: previewForceFeeding(
            stockpile: player.stockpile,
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.text('Forces food details'), findsNothing);
    });

    testWidgets('shows fully fed armies line without weaker copy', (
      WidgetTester tester,
    ) async {
      final player = productionPanelTestFullPlayer();
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 20),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 2},
        ),
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          forcesFeedingOverride: snapshot,
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.text('Armies fully fed this turn.'), findsOneWidget);
      expect(find.textContaining('somewhat weaker'), findsNothing);
    });

    testWidgets('shows moderate underfed armies line', (
      WidgetTester tester,
    ) async {
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 4),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: productionPanelTestFullPlayer(),
          forcesFeedingOverride: snapshot,
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.text(
          'Armies short on rations — land battles somewhat weaker.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('expands fed/total detail rows on Forces food details tap', (
      WidgetTester tester,
    ) async {
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 4),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: productionPanelTestFullPlayer(),
          forcesFeedingOverride: snapshot,
          height: 900,
        ),
      );
      await pumpSettleCapped(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('production_forces_food_details_toggle')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('production_forces_food_details_toggle')),
      );
      await pumpSettleCapped(tester);

      expect(find.textContaining('regiments fed'), findsOneWidget);
      expect(
        find.text('Armies and fleets eat before workers.'),
        findsOneWidget,
      );
    });
  });
}
