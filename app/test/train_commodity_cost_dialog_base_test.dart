// Focused unit test for the shared commodity-cost train-dialog base
// (`CommodityCostTrainDialogState`) cost math in isolation (Refs #3686).
//
// A tiny two-entry test dialog exercises the treasury + peasant + commodity
// affordability rules (`canAffordIncrement`), the dynamic `remaining / total`
// resource bar, and the comma-joined deficit hint without depending on the real
// regiment/ship catalogs.

import 'package:colonizethis_app/features/game/widgets/train_commodity_cost_dialog_base.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_base.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

const _capital = 'oldWorld|cap';

class _TestCommodityCostDialog extends TrainDialogBase {
  const _TestCommodityCostDialog({
    required super.game,
    required super.humanPlayerId,
    required super.currentOrders,
    required super.bus,
  });

  @override
  State<_TestCommodityCostDialog> createState() =>
      _TestCommodityCostDialogState();
}

class _TestCommodityCostDialogState
    extends CommodityCostTrainDialogState<_TestCommodityCostDialog> {
  @override
  bool get ordersAreMilitary => true;

  @override
  Map<String, String> get unlockingTechByUnitType => const {};

  @override
  String dialogTitle(AppLocalizations l10n) => 'Test';

  @override
  List<String> get resourceBarCommodityIds => const ['wood'];

  @override
  List<CommodityCostUnitEntry> get commodityCostEntries => const [
    CommodityCostUnitEntry(
      unitTypeId: 'a',
      displayName: 'Alpha',
      buildTreasuryCost: 2000,
      buildInputs: {'wood': 1},
    ),
    CommodityCostUnitEntry(
      unitTypeId: 'b',
      displayName: 'Beta',
      buildTreasuryCost: 4000,
      buildInputs: {'wood': 2},
    ),
  ];

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {}
}

Game _gameWith({
  int treasury = 5000,
  int peasants = 2,
  int wood = 3,
}) {
  return buildPanelTestGame(
    id: 'commodity-cost-base-test',
    players: [
      Player(
        id: kPanelTestHumanPlayerId,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: _capital,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: _capital,
          x: 0,
          y: 0,
        ),
        treasury: treasury,
        workerPool: WorkerPool(peasants: peasants),
        stockpile: Stockpile(quantities: {'wood': wood}),
      ),
    ],
  );
}

Orders _ordersFor(List<String> unitTypeIds) {
  return Orders(
    buildUnitOrdersByPlayerId: {
      kPanelTestHumanPlayerId: [
        for (final id in unitTypeIds)
          BuildUnitOrder(
            unitType: id,
            isMilitary: true,
            spawnProvinceId: _capital,
          ),
      ],
    },
  );
}

Future<_TestCommodityCostDialogState> _pump(
  WidgetTester tester, {
  required Game game,
  Orders currentOrders = const Orders(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _TestCommodityCostDialog(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          currentOrders: currentOrders,
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_TestCommodityCostDialogState>(
    find.byType(_TestCommodityCostDialog),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'canAffordIncrement: true when treasury, peasants, and commodity all cover',
    (tester) async {
      final state = await _pump(tester, game: _gameWith());
      expect(state.canAffordIncrement('a'), isTrue);
      expect(state.canAffordIncrement('b'), isTrue);
    },
  );

  testWidgets(
    'canAffordIncrement: false when an added unit overruns treasury',
    (tester) async {
      // Treasury 5000; one queued Beta (£4,000) leaves £1,000 — too little for
      // Alpha (£2,000) or another Beta (£4,000).
      final state = await _pump(
        tester,
        game: _gameWith(),
        currentOrders: _ordersFor(const ['b']),
      );
      expect(state.canAffordIncrement('a'), isFalse);
      expect(state.canAffordIncrement('b'), isFalse);
    },
  );

  testWidgets('canAffordIncrement: false when peasants are exhausted', (
    tester,
  ) async {
    final state = await _pump(tester, game: _gameWith(peasants: 0));
    expect(state.canAffordIncrement('a'), isFalse);
  });

  testWidgets('canAffordIncrement: false when commodity stockpile cannot cover', (
    tester,
  ) async {
    // Beta needs 2 wood; only 1 in stockpile.
    final state = await _pump(tester, game: _gameWith(wood: 1));
    expect(state.canAffordIncrement('b'), isFalse);
    // Alpha needs only 1 wood, so it remains affordable.
    expect(state.canAffordIncrement('a'), isTrue);
  });

  testWidgets('resource bar renders dynamic remaining / total after a queue', (
    tester,
  ) async {
    // One queued Beta: treasury 5000-4000, peasants 2-1, wood 3-2.
    await _pump(
      tester,
      game: _gameWith(),
      currentOrders: _ordersFor(const ['b']),
    );
    expect(find.textContaining('£1,000 / £5,000'), findsOneWidget);
    expect(find.textContaining('1 / 2'), findsOneWidget);
    expect(find.textContaining('1 / 3'), findsOneWidget);
  });

  testWidgets(
    'deficit hint joins multiple insufficient resources with ", "',
    (tester) async {
      // Zero treasury and peasants, one queued Alpha (£2,000 + 1 peasant + 1
      // wood) → both treasury and peasants are deficient; wood is sufficient.
      await _pump(
        tester,
        game: _gameWith(treasury: 0, peasants: 0, wood: 3),
        currentOrders: _ordersFor(const ['a']),
      );
      expect(find.text('Treasury low, Peasants low'), findsOneWidget);
    },
  );

  testWidgets('increment then reset clears committed counts', (tester) async {
    final state = await _pump(tester, game: _gameWith());
    state.increment('a');
    await tester.pumpAndSettle();
    expect(state.counts['a'], 1);
    state.reset();
    await tester.pumpAndSettle();
    expect(state.counts['a'], 0);
  });
}
