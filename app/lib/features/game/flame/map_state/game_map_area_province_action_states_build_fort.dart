import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/foundation.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
import 'game_map_area_province_action_states_assignable.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Build-fort inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesBuildFort {
  /// Whether [build_fort] could still raise fort level on this town tile.
  @visibleForTesting
  static bool tileCanConceivablyTakeBuildFortStep({
    required int fortLevel,
    required Map<String, bool>? techUnlocked,
  }) {
    if (fortLevel >= 3) return false;
    if (fortLevel == 1 &&
        techUnlocked?[kTechIdMineEngineering] != true) {
      return false;
    }
    if (fortLevel == 2 && techUnlocked?[kTechIdModernForts] != true) {
      return false;
    }
    return true;
  }

  static bool selectedTileIsProvinceTownTile({
    required ct_models.Game game,
    required String selectedTileKey,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) return false;
    final province = game.worldState.tryGetProvince(parsed.prefixedProvinceId);
    return province?.townTileKey == selectedTileKey;
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
    if (!selectedTileIsProvinceTownTile(
      game: game,
      selectedTileKey: selectedTileKey,
    )) {
      return GameMapAreaProvinceActionStates.kHiddenEngineerInlineActionState;
    }
    final player = game.playerById(humanPlayerId);
    final parsed = tryParseTileKey(selectedTileKey);
    final province = parsed == null
        ? null
        : game.worldState.tryGetProvince(parsed.prefixedProvinceId);
    final fortLevel = province?.fortLevel ?? 0;
    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: selectedTileKey,
      playerView: playerView,
      workTarget: kWorkTargetBuildFort,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () =>
          player != null &&
          tileCanConceivablyTakeBuildFortStep(
            fortLevel: fortLevel,
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
