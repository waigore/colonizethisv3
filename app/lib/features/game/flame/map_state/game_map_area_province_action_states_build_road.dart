import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/foundation.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';

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
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        game.worldState.tryGetProvince(prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }
    final player = game.playerById(humanPlayerId);
    if (player == null) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }

    final roadLevel = game.worldState.tileState.roadLevel(selectedTileKey);
    if (!tileCanConceivablyTakeBuildRoadStep(
      roadLevel: roadLevel,
      techUnlocked: player.techUnlocked,
    )) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final engineerUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetBuildRoad,
              ) ??
              false,
        )
        .toList();
    if (engineerUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasEngineerUnits: false);
    }
    final anyAssignable =
        workTargetSelectionCache?.contains(
          humanPlayerId,
          kWorkTargetBuildRoad,
          selectedTileKey,
        ) ??
        (topology == null
            ? false
            : engineerUnits.any((engineer) {
                final valid = getValidWorkOrderTileKeysWithVisibility(
                  game: game,
                  topology: topology,
                  view: playerView,
                  unitId: engineer.id,
                  workTarget: kWorkTargetBuildRoad,
                  currentOrders: currentOrders,
                  tileMapByRegion: tileMapByRegion,
                );
                return valid.contains(selectedTileKey);
              }));
    return (showIcon: true, enabled: anyAssignable, hasEngineerUnits: true);
  }
}
