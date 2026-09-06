// Test dialog + fixtures for CommodityCostTrainDialogState (Refs #4734 Slice E, #3686).

import 'package:colonizethis_app/features/game/widgets/train/train_commodity_cost_dialog_base.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_commodity_cost_dialog_base_costs.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_dialog_base.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

const kCommodityCostTestCapital = 'oldWorld|cap';

class CommodityCostTestDialog extends TrainDialogBase {
  const CommodityCostTestDialog({
    required super.game,
    required super.humanPlayerId,
    required super.currentOrders,
    required super.bus,
  });

  @override
  State<CommodityCostTestDialog> createState() => CommodityCostTestDialogState();
}

class CommodityCostTestDialogState
    extends CommodityCostTrainDialogState<CommodityCostTestDialog> {
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

Game commodityCostTestGameWith({
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
        capitalProvinceId: kCommodityCostTestCapital,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: kCommodityCostTestCapital,
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

Orders commodityCostTestOrdersFor(List<String> unitTypeIds) {
  return Orders(
    buildUnitOrdersByPlayerId: {
      kPanelTestHumanPlayerId: [
        for (final id in unitTypeIds)
          BuildUnitOrder(
            unitType: id,
            isMilitary: true,
            spawnProvinceId: kCommodityCostTestCapital,
          ),
      ],
    },
  );
}

Future<CommodityCostTestDialogState> pumpCommodityCostTestDialog(
  WidgetTester tester, {
  required Game game,
  Orders currentOrders = const Orders(),
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: CommodityCostTestDialog(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          currentOrders: currentOrders,
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<CommodityCostTestDialogState>(
    find.byType(CommodityCostTestDialog),
  );
}
