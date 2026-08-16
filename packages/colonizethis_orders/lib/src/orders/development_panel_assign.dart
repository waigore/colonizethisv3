/// Development panel one-tap Builder improve assign helpers. Refs #4175 Slice B.
///
/// SPEC: SPEC/ui/development-panel.md, SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_assign_candidate.dart';
import 'development_panel_assign_row_state.dart';
import 'development_panel_assign_types.dart';

export 'development_panel/idle_civilians.dart'
    show idleBuildersForDevelopmentAssign, idleDevelopmentCiviliansForAssign;
export 'development_panel/improve_tile_ordering.dart'
    show
        compareDevelopmentImproveTilePriority,
        orderDevelopmentImproveTiles,
        sortedDevelopmentImproveTileCandidates;
export 'development_panel/material_affordance.dart'
    show effectiveStockpileAfterPendingDevelopmentMaterialWork;
export 'development_panel_assign_candidate.dart'
    show selectDevelopmentImproveAssignCandidate;
export 'development_panel_assign_preview.dart'
    show enrichDevelopmentImproveAssignCandidate;
export 'development_panel_assign_row_state.dart'
    show resolveDevelopmentAssignRowState;
export 'development_panel_assign_row_state_cache.dart'
    show
        DevelopmentPanelAssignRowStateCache,
        buildDevelopmentPanelAssignRowStateCache,
        developmentPanelAssignRowStateKey;
export 'development_panel_assign_types.dart'
    show DevelopmentAssignRowState, DevelopmentImproveAssignCandidate;

/// Commodity ids with at least one improvable row blocked by materials shortage.
Set<String> developmentPanelMaterialShortageCommodityIds({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Iterable<({String commodityId, Set<String> tileKeys})>
  improvableRows,
  required Set<String> connectedTileKeys,
}) {
  final shortages = <String>{};
  for (final row in improvableRows) {
    final state = resolveDevelopmentAssignRowState(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      commodityTileKeys: row.tileKeys,
      connectedTileKeys: connectedTileKeys,
    );
    if (state.disabledReason == 'Insufficient materials') {
      shortages.add(row.commodityId);
    }
  }
  return shortages;
}
