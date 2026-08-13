// Pending-turns + dual-shortfall helpers for CivilianUnitsPanel part3 (Refs #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildFort,
        kWorkTargetBuildImprovement,
        kWorkTargetBuildPort,
        kWorkTargetBuildRail,
        kWorkTargetBuildRoad,
        kWorkTargetCounterSpy,
        kWorkTargetExplore,
        kWorkTargetProspect,
        kWorkTargetPurchaseLand,
        kWorkTargetUpgradeTown;

import 'civilian_units_panel_part3_pump_support.dart';
import 'civilian_units_panel_test_support.dart';

const List<({String unitType, String target, int turns})>
civilianPanelPendingTurnCases = [
  (unitType: kUnitTypeExplorer, target: kWorkTargetExplore, turns: 3),
  (unitType: kUnitTypeExplorer, target: kWorkTargetProspect, turns: 1),
  (unitType: kUnitTypeBuilder, target: kWorkTargetBuildImprovement, turns: 1),
  (unitType: kUnitTypeBuilder, target: kWorkTargetUpgradeTown, turns: 1),
  (unitType: kUnitTypeEngineer, target: kWorkTargetBuildRoad, turns: 1),
  (unitType: kUnitTypeEngineer, target: kWorkTargetBuildPort, turns: 1),
  (unitType: kUnitTypeEngineer, target: kWorkTargetBuildFort, turns: 3),
  (unitType: kUnitTypeRailBuilder, target: kWorkTargetBuildRail, turns: 1),
  (unitType: kUnitTypeSpy, target: kWorkTargetCounterSpy, turns: 1),
  (unitType: kUnitTypeMerchant, target: kWorkTargetPurchaseLand, turns: 1),
];

Future<void> pumpCivilianDualBuilderShortfall(WidgetTester tester) async {
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  await tester.pumpWidget(
    buildCivilianPanel(
      game: buildCivilianDualBuilderLowStockGame(id: 'g_civ_dual_shortfall'),
      humanPlayerId: civilianPanelPart3HumanId,
      currentOrders: civilianPendingWorkOrders(
        humanId: civilianPanelPart3HumanId,
        workOrders: [
          WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileA,
          ),
          WorkOrder(
            unitId: 'b2',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileB,
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> expectCivilianPendingTurnLine(
  WidgetTester tester, {
  required int index,
  required String unitType,
  required String target,
  required int turns,
}) async {
  const targetTileKey = 'oldWorld|p1|1|0';
  final unitId = 'u_$index';
  await tester.pumpWidget(
    buildCivilianPanel(
      game: buildCivilianOwUnitsGame(
        id: 'g_civ_pending_turns_${target}_$index',
        humanId: civilianPanelPart3HumanId,
        fortLevel: 2,
        resourceByTileKey: const {targetTileKey: 'grain'},
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p1': [civilianPanelPart3TileKey, targetTileKey],
          },
        },
        units: [
          civilianIdleUnit(
            id: unitId,
            type: unitType,
            ownerId: civilianPanelPart3HumanId,
            provinceId: 'oldWorld|p1',
            tileKey: civilianPanelPart3TileKey,
          ),
        ],
      ),
      humanPlayerId: civilianPanelPart3HumanId,
      currentOrders: civilianSinglePendingWorkOrder(
        humanId: civilianPanelPart3HumanId,
        unitId: unitId,
        target: target,
        targetTileKey: targetTileKey,
      ),
    ),
  );
  await tester.pumpAndSettle();

  final lineFinder = find.textContaining('Assigned to:');
  expect(
    lineFinder,
    findsOneWidget,
    reason: 'Expected one Assigned to line for target $target',
  );
  final line = tester.widget<Text>(lineFinder).data ?? '';
  final singular = '$turns turn';
  final plural = '$turns turns';
  expect(
    line.contains(singular) || line.contains(plural),
    isTrue,
    reason: 'Expected target $target to show $singular/$plural, got: $line',
  );
  expect(
    line.contains('# turn'),
    isFalse,
    reason: 'Target $target should not render placeholder text',
  );
}
