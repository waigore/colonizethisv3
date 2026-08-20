import 'package:colonizethis_app/core/utils/human_units_for_work_target.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Unified civilian inline action state for province overlay work-target slots.
typedef ProvinceInlineActionState = ({
  bool showIcon,
  bool enabled,
  bool hasMatchingUnits,
});

/// Shared visibility/enablement for province-overlay inline actions that
/// assign a civilian work target to the selected tile.
abstract final class GameMapAreaProvinceActionStatesAssignable {
  static const ProvinceInlineActionState kHidden = (
    showIcon: false,
    enabled: false,
    hasMatchingUnits: false,
  );

  static ProvinceInlineActionState compute({
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

    final matchingUnits = humanUnitsMatchingWorkTarget(
      game: game,
      playerId: humanPlayerId,
      workTarget: workTarget,
    );
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
