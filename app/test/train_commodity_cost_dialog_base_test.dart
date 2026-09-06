// Focused unit test for CommodityCostTrainDialogState (Refs #3686).

import 'package:colonizethis_app/features/game/widgets/train/train_commodity_cost_dialog_base_costs.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'train_commodity_cost_dialog_base_cases.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'canAffordIncrement: true when treasury, peasants, and commodity all cover',
    (tester) async {
      final state = await pumpCommodityCostTestDialog(
        tester,
        game: commodityCostTestGameWith(),
      );
      expect(state.canAffordIncrement('a'), isTrue);
      expect(state.canAffordIncrement('b'), isTrue);
    },
  );

  testWidgets(
    'canAffordIncrement: false when an added unit overruns treasury',
    (tester) async {
      final state = await pumpCommodityCostTestDialog(
        tester,
        game: commodityCostTestGameWith(),
        currentOrders: commodityCostTestOrdersFor(const ['b']),
      );
      expect(state.canAffordIncrement('a'), isFalse);
      expect(state.canAffordIncrement('b'), isFalse);
    },
  );

  testWidgets('canAffordIncrement: false when peasants are exhausted', (
    tester,
  ) async {
    final state = await pumpCommodityCostTestDialog(
      tester,
      game: commodityCostTestGameWith(peasants: 0),
    );
    expect(state.canAffordIncrement('a'), isFalse);
  });

  testWidgets('canAffordIncrement: false when commodity stockpile cannot cover', (
    tester,
  ) async {
    final state = await pumpCommodityCostTestDialog(
      tester,
      game: commodityCostTestGameWith(wood: 1),
    );
    expect(state.canAffordIncrement('b'), isFalse);
    expect(state.canAffordIncrement('a'), isTrue);
  });

  testWidgets('resource bar renders dynamic remaining / total after a queue', (
    tester,
  ) async {
    await pumpCommodityCostTestDialog(
      tester,
      game: commodityCostTestGameWith(),
      currentOrders: commodityCostTestOrdersFor(const ['b']),
    );
    expect(find.textContaining('£1,000 / £5,000'), findsOneWidget);
    expect(find.textContaining('1 / 2'), findsOneWidget);
    expect(find.textContaining('1 / 3'), findsOneWidget);
  });

  testWidgets(
    'other-family worker trains reduce available peasants for + and chip',
    (tester) async {
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          kPanelTestHumanPlayerId: List<RecruitWorkerOrder>.generate(
            3,
            (_) => const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ),
        },
      );
      final state = await pumpCommodityCostTestDialog(
        tester,
        game: commodityCostTestGameWith(peasants: 8, treasury: 50000, wood: 20),
        currentOrders: orders,
      );
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(state.availablePeasants(), 5);
      expect(state.canAffordIncrement('a'), isTrue);
      for (var i = 0; i < 5; i++) {
        state.increment('a');
      }
      await tester.pumpAndSettle();
      expect(state.remainingPeasants(), 0);
      expect(state.canAffordIncrement('a'), isFalse);
    },
  );

  testWidgets(
    'this dialog managed builds are not double-subtracted from available',
    (tester) async {
      final state = await pumpCommodityCostTestDialog(
        tester,
        game: commodityCostTestGameWith(peasants: 8, treasury: 50000, wood: 20),
        currentOrders: commodityCostTestOrdersFor(const ['a', 'a']),
      );
      expect(state.availablePeasants(), 8);
      expect(state.remainingPeasants(), 6);
      expect(find.textContaining('6 / 8'), findsOneWidget);
      expect(find.textContaining('already promised'), findsNothing);
    },
  );

  testWidgets(
    'deficit hint joins multiple insufficient resources with ", "',
    (tester) async {
      await pumpCommodityCostTestDialog(
        tester,
        game: commodityCostTestGameWith(treasury: 0, peasants: 0, wood: 3),
        currentOrders: commodityCostTestOrdersFor(const ['a']),
      );
      expect(find.text('Treasury low, Peasants low'), findsOneWidget);
    },
  );

  testWidgets('increment then reset clears committed counts', (tester) async {
    final state = await pumpCommodityCostTestDialog(
      tester,
      game: commodityCostTestGameWith(),
    );
    state.increment('a');
    await tester.pumpAndSettle();
    expect(state.counts['a'], 1);
    state.reset();
    await tester.pumpAndSettle();
    expect(state.counts['a'], 0);
  });
}
