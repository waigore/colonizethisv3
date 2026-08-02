// Labour readiness UI tests. SPEC/ui/production-panel.md § Labour readiness (#4237).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  group('ProductionPanel labour readiness', () {
    testWidgets('shows labour total without reason at full capacity', (
      WidgetTester tester,
    ) async {
      final player = productionPanelTestFullPlayer();
      final readiness = computeLabourReadiness(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          labourReadinessOverride: readiness,
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.textContaining('Labour this turn:'), findsOneWidget);
      expect(
        find.text('Some workers are not working — food is short.'),
        findsNothing,
      );
    });

    testWidgets('shows food shortfall reason when labour is reduced', (
      WidgetTester tester,
    ) async {
      final player = Player(
        id: 'gp1',
        displayName: 'Test',
        isHuman: true,
        workerPool: const WorkerPool(peasants: 4),
        stockpile: const Stockpile().applyDelta('grain', 2),
      );
      final readiness = computeLabourReadiness(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          gameOverride: productionPanelTestGameFor(player),
          labourReadinessOverride: readiness,
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.text('Some workers are not working — food is short.'),
        findsOneWidget,
      );
      expect(find.text('Labour details'), findsOneWidget);
    });

    testWidgets('shows luxury shortfall reason when masters lack fur hats', (
      WidgetTester tester,
    ) async {
      final player = Player(
        id: 'gp1',
        displayName: 'Test',
        isHuman: true,
        workerPool: const WorkerPool(masters: 2),
        stockpile: const Stockpile()
            .applyDelta('grain', 10)
            .applyDelta('meat', 10),
      );
      final readiness = computeLabourReadiness(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          gameOverride: productionPanelTestGameFor(player),
          labourReadinessOverride: readiness,
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.text('Some workers are not working — short of Fur hats.'),
        findsOneWidget,
      );
      expect(find.textContaining('Labour this turn: 0'), findsOneWidget);
    });

    testWidgets('shows primary reason when labour is zero', (
      WidgetTester tester,
    ) async {
      final player = Player(
        id: 'gp1',
        displayName: 'Test',
        isHuman: true,
        workerPool: const WorkerPool(peasants: 4, masters: 1),
        stockpile: const Stockpile(),
      );
      final readiness = computeLabourReadiness(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          gameOverride: productionPanelTestGameFor(player),
          labourReadinessOverride: readiness,
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.textContaining('Labour this turn: 0'), findsOneWidget);
      expect(
        find.text('Some workers are not working — food is short.'),
        findsOneWidget,
      );
    });

    testWidgets('expands tier detail rows on Labour details tap', (
      WidgetTester tester,
    ) async {
      final player = Player(
        id: 'gp1',
        displayName: 'Test',
        isHuman: true,
        workerPool: const WorkerPool(peasants: 4),
        stockpile: const Stockpile().applyDelta('grain', 2),
      );
      final readiness = computeLabourReadiness(
        workers: player.workerPool,
        stockpile: player.stockpile,
      );
      await tester.pumpWidget(
        buildProductionPanel(
          player: player,
          gameOverride: productionPanelTestGameFor(player),
          labourReadinessOverride: readiness,
        ),
      );
      await pumpSettleCapped(tester);

      await tester.tap(find.text('Labour details'));
      await pumpSettleCapped(tester);

      expect(find.textContaining('not working'), findsWidgets);
    });
  });
}
