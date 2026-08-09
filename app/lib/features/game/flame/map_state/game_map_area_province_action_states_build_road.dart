import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/foundation.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
import 'game_map_area_province_action_states_assignable.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Build-road inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesBuildRoad {
  /// Whether [build_road] could still raise transport on this tile (visibility gate).
  @visibleForTesting
  static bool tileCanConceivablyTakeBuildRoadStep({
    required int roadLevel,
    required Map<String, bool>? techUnlocked,
  }) {
    if (roadLevel >= 2) return false;
    if (roadLevel == 1) {
      return techUnlocked?[kTechIdRoadConstruction] == true;
    }
    return roadLevel == 0;
  }

  static ({bool showIcon, bool enabled, bool hasEngineerUnits}) compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final player = game.playerById(humanPlayerId);
    final roadLevel = game.worldState.tileState.roadLevel(selectedTileKey);
    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: selectedTileKey,
      playerView: playerView,
      workTarget: kWorkTargetBuildRoad,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () =>
          player != null &&
          tileCanConceivablyTakeBuildRoadStep(
            roadLevel: roadLevel,
            techUnlocked: player.techUnlocked,
          ),
    );
    if (!state.showIcon && !state.enabled && !state.hasMatchingUnits) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }
    return (
      showIcon: state.showIcon,
      enabled: state.enabled,
      hasEngineerUnits: state.hasMatchingUnits,
    );
  }
}
