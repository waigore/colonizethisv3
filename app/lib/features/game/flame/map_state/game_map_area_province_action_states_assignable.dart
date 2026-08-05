import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';

/// Shared visibility/enablement for province-overlay inline actions that
/// assign a civilian work target to the selected tile.
abstract final class GameMapAreaProvinceActionStatesAssignable {
  static const kHidden = (
    showIcon: false,
    enabled: false,
    hasMatchingUnits: false,
  );

  static ({bool showIcon, bool enabled, bool hasMatchingUnits}) compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required String workTarget,
    required bool Function() passesTileGate,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) return kHidden;
    if (playerView.visibilityForTile(selectedTileKey) ==
        VisibilityLevel.unknown) {
      return kHidden;
    }
    if (game.worldState.tryGetProvince(parsed.prefixedProvinceId) == null) {
      return kHidden;
    }
    if (game.playerById(humanPlayerId) == null) return kHidden;
    if (!passesTileGate()) return kHidden;

    final matchingUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ]
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ??
              false,
        )
        .toList();
    if (matchingUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasMatchingUnits: false);
    }
    final anyAssignable =
        workTargetSelectionCache?.contains(
          humanPlayerId,
          workTarget,
          selectedTileKey,
        ) ??
        (topology == null
            ? false
            : matchingUnits.any((unit) {
                final valid = getValidWorkOrderTileKeysWithVisibility(
                  game: game,
                  topology: topology,
                  view: playerView,
                  unitId: unit.id,
                  workTarget: workTarget,
                  currentOrders: currentOrders,
                  tileMapByRegion: tileMapByRegion,
                );
                return valid.contains(selectedTileKey);
              }));
    return (showIcon: true, enabled: anyAssignable, hasMatchingUnits: true);
  }
}
