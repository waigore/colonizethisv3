import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
import 'game_map_area_province_action_states_assignable.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';

/// Build-improvement inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesBuildImprovement {
  static ({bool showIcon, bool enabled, bool hasBuilderUnits}) compute({
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
    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: selectedTileKey,
      playerView: playerView,
      workTarget: kWorkTargetBuildImprovement,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () {
        if (player == null) return false;
        final resourceId = game.worldState.resourceByTileKey[selectedTileKey];
        if (resourceId == null || resourceId.isEmpty) return false;
        final currentLevel = game.worldState.tileState.improvementLevel(
          selectedTileKey,
        );
        final techCap = extractionCapForResourceForUnlocked(
          player.techUnlocked,
          resourceId,
        );
        final terrain = terrainTypeForTileKey(tileMapByRegion, selectedTileKey);
        final effectiveCap = terrain == null
            ? techCap
            : clampExtractionCapForTerrain(techCap, resourceId, terrain);
        return currentLevel < effectiveCap;
      },
    );
    if (!state.showIcon && !state.enabled && !state.hasMatchingUnits) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }
    return (
      showIcon: state.showIcon,
      enabled: state.enabled,
      hasBuilderUnits: state.hasMatchingUnits,
    );
  }
}
