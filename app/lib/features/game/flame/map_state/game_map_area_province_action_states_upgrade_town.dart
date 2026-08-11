import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kTownDevelopmentLevelMax, kUnitTypeBuilder;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../caches/per_player_work_target_selection_cache.dart';
import 'game_map_area_province_action_states_assignable.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Upgrade-town political-row action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesUpgradeTown {
  static const kHidden = (
    showControl: false,
    enabled: false,
    hasBuilderUnits: false,
    townTileKey: null as String?,
  );

  static ({
    bool showControl,
    bool enabled,
    bool hasBuilderUnits,
    String? townTileKey,
  })
  compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String provinceId,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final province = game.worldState.tryGetProvince(provinceId);
    if (province == null) return kHidden;
    if (province.ownerId != humanPlayerId) return kHidden;
    if (province.townDevelopmentLevel >= kTownDevelopmentLevelMax) {
      return kHidden;
    }
    final townTileKey = province.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) return kHidden;

    final player = game.playerById(humanPlayerId);
    if (player?.techUnlocked?[kTechIdNationalBureaucracy] != true) {
      final hasBuilders = _hasBuilderUnits(game, humanPlayerId);
      return (
        showControl: true,
        enabled: false,
        hasBuilderUnits: hasBuilders,
        townTileKey: townTileKey,
      );
    }

    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: townTileKey,
      playerView: playerView,
      workTarget: kWorkTargetUpgradeTown,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () => true,
    );
    if (!state.showIcon && !state.enabled && !state.hasMatchingUnits) {
      return (
        showControl: true,
        enabled: false,
        hasBuilderUnits: false,
        townTileKey: townTileKey,
      );
    }
    return (
      showControl: true,
      enabled: state.enabled,
      hasBuilderUnits: state.hasMatchingUnits,
      townTileKey: townTileKey,
    );
  }

  static bool _hasBuilderUnits(ct_models.Game game, String humanPlayerId) {
    return [
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ].any(
      (unit) =>
          unit.ownerId == humanPlayerId &&
          unit.type == kUnitTypeBuilder,
    );
  }
}
