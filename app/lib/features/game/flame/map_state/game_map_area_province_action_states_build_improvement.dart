import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
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
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        game.worldState.tryGetProvince(prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }
    final player = game.playerById(humanPlayerId);
    if (player == null) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }

    final resourceId = game.worldState.resourceByTileKey[selectedTileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }
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
    if (currentLevel >= effectiveCap) {
      return GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final builderUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetBuildImprovement,
              ) ??
              false,
        )
        .toList();
    if (builderUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasBuilderUnits: false);
    }
    final anyAssignable =
        workTargetSelectionCache?.contains(
          humanPlayerId,
          kWorkTargetBuildImprovement,
          selectedTileKey,
        ) ??
        (topology == null
            ? false
            : builderUnits.any((builder) {
                final valid = getValidWorkOrderTileKeysWithVisibility(
                  game: game,
                  topology: topology,
                  view: playerView,
                  unitId: builder.id,
                  workTarget: kWorkTargetBuildImprovement,
                  currentOrders: currentOrders,
                  tileMapByRegion: tileMapByRegion,
                );
                return valid.contains(selectedTileKey);
              }));
    return (showIcon: true, enabled: anyAssignable, hasBuilderUnits: true);
  }
}
