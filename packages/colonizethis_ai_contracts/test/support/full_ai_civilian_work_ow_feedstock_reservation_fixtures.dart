/// Old World feedstock unit-reservation fixtures (Refs #2847 / #4368 Slice C).
library;

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

const String supplierReservationIronTile = 'oldWorld|s0|2|0';
const String supplierReservationNewWorldTile = 'newWorld|n0|0|0';

Game ironFeedstockReservationGame({int sellerOw = 5, TileMapState? tileState}) {
  return twoPlayerSupplierFeedstockGame(
    sellerOw: sellerOw,
    resourceByTileKey: const {
      supplierReservationIronTile: 'iron',
      supplierGrainTile: 'grain',
      sellerWoolTile: 'wool',
      supplierReservationNewWorldTile: 'iron',
    },
    tileState: tileState,
  );
}

PlayerView supplierReservationView(Game game, List<Unit> units) {
  return PlayerView(
    playerId: supplierFeedstockId,
    player: game.players.firstWhere((p) => p.id == supplierFeedstockId),
    ownUnitsById: {for (final u in units) u.id: u},
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Unit idleSupplierBuilder(String id) => Unit(
  id: id,
  type: kUnitTypeBuilder,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
);

Unit idleSupplierExplorer(String id) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
);

WorkOrder supplierBuildOrder(String unitId, String tileKey) => WorkOrder(
  unitId: unitId,
  target: kWorkTargetBuildImprovement,
  targetTileKey: tileKey,
);

WorkOrder supplierExploreOrder(String unitId, String tileKey) => WorkOrder(
  unitId: unitId,
  target: kWorkTargetExplore,
  targetTileKey: tileKey,
);

WorkOrder supplierProspectOrder(String unitId, String tileKey) => WorkOrder(
  unitId: unitId,
  target: kWorkTargetProspect,
  targetTileKey: tileKey,
);

FullAiCivilianWorkSelectionResult selectSupplierReservationWork({
  required Game game,
  required List<Unit> units,
  required List<WorkOrder> suggestions,
}) {
  return selectFullAiCivilianWorkOrders(
    workSuggestions: suggestions,
    view: supplierReservationView(game, units),
    game: game,
  );
}
