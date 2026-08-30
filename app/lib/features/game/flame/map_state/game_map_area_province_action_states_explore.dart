import 'package:colonizethis_app/core/utils/human_units_for_work_target.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states_assignable.dart'
    show GameMapAreaProvinceActionStatesAssignable, ProvinceInlineActionState;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Explore inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesExplore {
  static Set<String> buildEligibleTileKeyCache({
    required ct_models.Game game,
    required String humanPlayerId,
    required PlayerView playerView,
    required MapTopology topology,
    required Map<String, TileMapResult>? tileMapByRegion,
    required ct_models.Orders currentOrders,
  }) {
    final cache = PerPlayerWorkTargetSelectionCache();
    cache.refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: humanPlayerId,
        playerView: playerView,
        topology: topology,
        currentOrders: currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
    );
    return cache.get(humanPlayerId, kWorkTargetExplore);
  }

  static ProvinceInlineActionState compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required RegionMapViewData selectedRegion,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    Set<String>? cachedExploreEligibleTileKeys,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null || parsed.regionId != selectedRegion.regionId) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final tileProvinceId = parsed.provinceLocalId;
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final province = game.worldState.tryGetProvince(prefixedProvinceId);
    if (province == null) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 ||
        y < 0 ||
        x >= selectedRegion.width ||
        y >= selectedRegion.height) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final selectedCell = selectedRegion.cellAt(x, y);
    if (selectedCell.visibility == TileVisibility.unrevealed) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final provinceCells = selectedRegion.cells
        .where((cell) => !cell.isSea && cell.regionCellId == tileProvinceId)
        .toList();
    if (provinceCells.isEmpty) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final hasUnrevealed = provinceCells.any(
      (cell) => cell.visibility == TileVisibility.unrevealed,
    );
    final hasRevealed = provinceCells.any(
      (cell) => cell.visibility != TileVisibility.unrevealed,
    );
    if (!hasUnrevealed || !hasRevealed) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final hasMatchingUnits = humanUnitsMatchingWorkTarget(
      game: game,
      playerId: humanPlayerId,
      workTarget: kWorkTargetExplore,
    ).isNotEmpty;

    final eligibleTileKeys =
        cachedExploreEligibleTileKeys ??
        workTargetSelectionCache?.get(humanPlayerId, kWorkTargetExplore) ??
        const <String>{};
    final hasEligibleExploreTarget = eligibleTileKeys.any((tileKey) {
      final p = tryParseTileKey(tileKey);
      return p != null &&
          p.regionId == selectedRegion.regionId &&
          p.provinceLocalId == tileProvinceId;
    });
    if (!hasEligibleExploreTarget) {
      // Refs #3753 R4/R4b: when the only blocker is the Consulate gate (a known
      // Minor/Tribe province with no Consulate filters out every eligible
      // explore tile), show the inline action disabled (not hidden) so the
      // overlay can surface the rejection tooltip. Other ineligibility reasons
      // keep the icon hidden as before.
      final ownerId = game.worldState
          .tryGetProvince(prefixedProvinceId)
          ?.ownerId;
      if (explorerConsulateGateBlocksMinorTribeProvince(
        game: game,
        playerId: humanPlayerId,
        provinceOwnerId: ownerId,
      )) {
        return (
          showIcon: true,
          enabled: false,
          hasMatchingUnits: hasMatchingUnits,
        );
      }
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    return (
      showIcon: true,
      enabled: hasMatchingUnits,
      hasMatchingUnits: hasMatchingUnits,
    );
  }
}
