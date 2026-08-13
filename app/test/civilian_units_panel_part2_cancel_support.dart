// Pending/in-progress cancel helpers for CivilianUnitsPanel part2 (Refs #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore;

import 'app_shell_harness.dart';
import 'civilian_units_panel_test_support.dart';

Unit? firstIdleCivilian(Game game, String humanId) {
  final units = [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  for (final u in units) {
    if (u.ownerId == humanId &&
        u.tileKey != null &&
        isCivilianUnit(u) &&
        u.currentWork == null) {
      return u;
    }
  }
  return null;
}

Orders pendingExploreOrders(String humanId, Unit unit) {
  final pendingOrder = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetExplore,
    targetTileKey: '${unit.tileKey!.split('|').take(2).join('|')}|0|0',
  );
  return Orders(
    workOrdersByPlayerId: {
      humanId: [pendingOrder],
    },
  );
}

Future<void> invokePendingCancel(WidgetTester tester, Unit unit) async {
  final pendingRow = find.byKey(
    ValueKey('civilian-unit-card-${unit.id}'),
    skipOffstage: false,
  );
  expect(pendingRow, findsOneWidget);
  final cancelOnPendingRow = find.descendant(
    of: pendingRow,
    matching: find.byType(CtDangerTextButton, skipOffstage: false),
  );
  expect(cancelOnPendingRow, findsOneWidget);
  final cancelBtn = tester.widget<CtDangerTextButton>(cancelOnPendingRow);
  expect(cancelBtn.onPressed, isNotNull);
  cancelBtn.onPressed!();
  await tester.pumpAndSettle();
}

/// Cross-panel style watcher host: editorial [buildAppShell] + confirm-dialog
/// bus leaf + a counter strip (Refs #4035 — no inline `MaterialApp`).
Widget civilianPanelWatcherHost({
  required AppEventBus bus,
  required GlobalKey<NavigatorState> navigatorKey,
  required ValueNotifier<int> counter,
  required String labelPrefix,
  required Game game,
  required String humanId,
  required Orders orders,
}) {
  return buildAppShell(
    navigatorKey: navigatorKey,
    child: Scaffold(
      body: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: counter,
            builder: (_, count, _) => Text('$labelPrefix:$count'),
          ),
          Expanded(
            child: CivilianPanelBusDialogHost(
              bus: bus,
              navigatorKey: navigatorKey,
              child: CivilianUnitsPanel(
                game: game,
                humanPlayerId: humanId,
                currentOrders: orders,
                bus: bus,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
