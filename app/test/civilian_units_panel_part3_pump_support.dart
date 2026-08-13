// Part3 pump helpers for CivilianUnitsPanel tests (Refs #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'civilian_units_panel_test_support.dart';

const civilianPanelPart3HumanId = 'h1';
const civilianPanelPart3TileKey = 'oldWorld|p1|0|0';

Finder civilianPanelResourceIcon(String commodityId) => find.byWidgetPredicate(
  (w) => w is ResourceIcon && w.commodityId == commodityId,
);

Future<void> pumpCivilianPanelPendingUnit(
  WidgetTester tester, {
  required String gameId,
  required String unitId,
  required String unitType,
  required String workTarget,
  Map<String, String> resourceByTileKey = const {},
}) async {
  await tester.pumpWidget(
    buildCivilianPanel(
      game: buildCivilianSingleUnitOwGame(
        id: gameId,
        humanId: civilianPanelPart3HumanId,
        unitId: unitId,
        unitType: unitType,
        tileKey: civilianPanelPart3TileKey,
        resourceByTileKey: resourceByTileKey,
      ),
      humanPlayerId: civilianPanelPart3HumanId,
      currentOrders: civilianSinglePendingWorkOrder(
        humanId: civilianPanelPart3HumanId,
        unitId: unitId,
        target: workTarget,
        targetTileKey: civilianPanelPart3TileKey,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpCivilianPanelTileScoped(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  String? tileScopeTileKey,
  String? initialSelectedUnitId,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    buildCivilianPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      tileScopeTileKey: tileScopeTileKey,
      initialSelectedUnitId: initialSelectedUnitId,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}
