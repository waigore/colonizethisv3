// Smoke coverage for civilian units-panel shared scenario factories (Refs #4021).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';
import 'units_panel_test_shared.dart';

void main() {
  test('buildCivilianExplorerBuilderShortcutGame places explorer+builder', () {
    final game = buildCivilianExplorerBuilderShortcutGame(
      id: 't',
      humanId: 'h1',
    );
    expect(game.worldState.oldWorld.units, hasLength(2));
    expect(
      game.worldState.oldWorld.units.map((u) => u.type).toSet(),
      {kUnitTypeExplorer, kUnitTypeBuilder},
    );
  });

  test('buildUnitsPanelAdjacentOwProvincesTopology has one edge', () {
    final topo = buildUnitsPanelAdjacentOwProvincesTopology();
    expect(topo.nodes, hasLength(2));
    expect(topo.edges, hasLength(1));
  });

  test('civilianSinglePendingWorkOrder wraps one WorkOrder', () {
    final orders = civilianSinglePendingWorkOrder(
      humanId: 'h1',
      unitId: 'u1',
      target: 'explore',
      targetTileKey: 'oldWorld|p1|0|0',
    );
    expect(orders.workOrdersByPlayerId['h1'], hasLength(1));
  });
}
