import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/foundation.dart';

import 'game_map_area_province_action_states_assignable.dart'
    show GameMapAreaProvinceActionStatesAssignable, ProvinceInlineActionState;

/// Build-railroad inline-action visibility/enablement for province overlay.
/// Refs #4383 — MAP20001 Tile Road / railroad row shortcut.
abstract final class GameMapAreaProvinceActionStatesBuildRail {
  /// Whether [build_rail] could still raise transport on this tile.
  ///
  /// Conceivable on stored transport level **1** or **2** only. Level 0 still
  /// needs a road first; level 4 is already port or railroad.
  @visibleForTesting
  static bool tileCanConceivablyTakeBuildRailStep({required int roadLevel}) {
    return roadLevel == 1 || roadLevel == 2;
  }

  static ProvinceInlineActionState compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final roadLevel = game.worldState.tileState.roadLevel(selectedTileKey);
    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: selectedTileKey,
      playerView: playerView,
      workTarget: kWorkTargetBuildRail,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () =>
          tileCanConceivablyTakeBuildRailStep(roadLevel: roadLevel),
    );
    if (!state.showIcon && !state.enabled && !state.hasMatchingUnits) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    return state;
  }
}
