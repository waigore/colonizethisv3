/// Memoized per-scope assign affordance for Development panel region tabs. Refs #4175 Slice E.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'development_panel_assign_row_state.dart';
import 'development_panel_assign_types.dart';

/// Stable cache key for per-scope improvable commodity assign affordance.
String developmentPanelAssignRowStateKey(String scopeKey, String commodityId) =>
    '$scopeKey|$commodityId';

/// Per-scope assign affordance + material-shortage flags for one region tab.
class DevelopmentPanelAssignRowStateCache {
  const DevelopmentPanelAssignRowStateCache({
    required this.byScopeCommodityKey,
    required this.materialShortageCommodityIds,
  });

  static const empty = DevelopmentPanelAssignRowStateCache(
    byScopeCommodityKey: {},
    materialShortageCommodityIds: {},
  );

  final Map<String, DevelopmentAssignRowState> byScopeCommodityKey;
  final Set<String> materialShortageCommodityIds;
}

DevelopmentPanelAssignRowStateCache buildDevelopmentPanelAssignRowStateCache({
  required DevelopmentPanelRegionModel regionModel,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> connectedTileKeys,
}) {
  final byKey = <String, DevelopmentAssignRowState>{};
  final shortages = <String>{};
  for (final scope in [
    ...regionModel.ownedScopes,
    ...regionModel.purchasedScopes,
  ]) {
    for (final row in scope.improvableCommodities) {
      final state = resolveDevelopmentAssignRowState(
        game: game,
        playerId: playerId,
        currentOrders: currentOrders,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        commodityTileKeys: row.tileKeys.toSet(),
        connectedTileKeys: connectedTileKeys,
      );
      byKey[developmentPanelAssignRowStateKey(scope.scopeKey, row.commodityId)] =
          state;
      if (state.disabledReason == 'Insufficient materials') {
        shortages.add(row.commodityId);
      }
    }
  }
  return DevelopmentPanelAssignRowStateCache(
    byScopeCommodityKey: byKey,
    materialShortageCommodityIds: shortages,
  );
}
