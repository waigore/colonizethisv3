import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

/// Province-overlay action visibility/enablement computations for prospect,
/// explore, and build-improvement shortcuts.
///
/// Extracted from `GameMapAreaStateLogic` (#2575 work item 11) so the
/// province action state logic lives in a single, separately testable
/// module. `GameMapAreaStateLogic.province*ActionState` /
/// `buildExploreEligibleTileKeyCache` remain as thin forwarders for backward
/// compatibility with call sites and existing tests, including the SPEC
/// reference in `SPEC/program/order-suggestions.md` § Authoritative pipeline.
class GameMapAreaProvinceActionStates {
  GameMapAreaProvinceActionStates._();

  static const ({bool showIcon, bool enabled, bool hasExplorerUnits})
  kHiddenExplorerInlineActionState = (
    showIcon: false,
    enabled: false,
    hasExplorerUnits: false,
  );
  static const ({bool showIcon, bool enabled, bool hasBuilderUnits})
  kHiddenBuilderInlineActionState = (
    showIcon: false,
    enabled: false,
    hasBuilderUnits: false,
  );

  /// Returns province-overlay prospect action visibility + enablement.
  ///
  /// The panel must read stable world/player tile state only so map scrolling
  /// and rebuild churn do not trigger expensive order-engine validation.
  static ({bool showIcon, bool enabled, bool hasExplorerUnits}) prospect({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        tryGetProvince(game.worldState, prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final isMineralEligible = isMineralEligibleTile(
      game,
      tileMapByRegion,
      selectedTileKey,
    );
    if (!isMineralEligible) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final playerProspectedTiles =
        game.worldState.playerProspectedTiles[humanPlayerId] ??
        const <String>{};
    if (playerProspectedTiles.contains(selectedTileKey)) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final explorerUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetProspect,
              ) ??
              false,
        )
        .toList();
    if (explorerUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasExplorerUnits: false);
    }
    return (showIcon: true, enabled: true, hasExplorerUnits: true);
  }

  static Set<String> buildExploreEligibleTileKeyCache({
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

  static ({bool showIcon, bool enabled, bool hasExplorerUnits}) explore({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required RegionMapViewData selectedRegion,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    Set<String>? cachedExploreEligibleTileKeys,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null || parsed.regionId != selectedRegion.regionId) {
      return kHiddenExplorerInlineActionState;
    }
    final tileProvinceId = parsed.provinceLocalId;
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final province = tryGetProvince(game.worldState, prefixedProvinceId);
    if (province == null) {
      return kHiddenExplorerInlineActionState;
    }

    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 ||
        y < 0 ||
        x >= selectedRegion.width ||
        y >= selectedRegion.height) {
      return kHiddenExplorerInlineActionState;
    }
    final selectedCell = selectedRegion.cellAt(x, y);
    if (selectedCell.visibility == TileVisibility.unrevealed) {
      return kHiddenExplorerInlineActionState;
    }

    final provinceCells = selectedRegion.cells
        .where((cell) => !cell.isSea && cell.regionCellId == tileProvinceId)
        .toList();
    if (provinceCells.isEmpty) {
      return kHiddenExplorerInlineActionState;
    }
    final hasUnrevealed = provinceCells.any(
      (cell) => cell.visibility == TileVisibility.unrevealed,
    );
    final hasRevealed = provinceCells.any(
      (cell) => cell.visibility != TileVisibility.unrevealed,
    );
    if (!hasUnrevealed || !hasRevealed) {
      return kHiddenExplorerInlineActionState;
    }

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
      return kHiddenExplorerInlineActionState;
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final hasExplorerUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .any(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetExplore,
              ) ??
              false,
        );
    return (
      showIcon: true,
      enabled: hasExplorerUnits,
      hasExplorerUnits: hasExplorerUnits,
    );
  }

  static ({bool showIcon, bool enabled, bool hasBuilderUnits})
  buildImprovement({
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
      return kHiddenBuilderInlineActionState;
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return kHiddenBuilderInlineActionState;
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        tryGetProvince(game.worldState, prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return kHiddenBuilderInlineActionState;
    }
    final player = game.playerById(humanPlayerId);
    if (player == null) {
      return kHiddenBuilderInlineActionState;
    }

    final resourceId = game.worldState.resourceByTileKey[selectedTileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return kHiddenBuilderInlineActionState;
    }
    final currentLevel = game.worldState.tileState.improvementLevel(
      selectedTileKey,
    );
    final techCap = extractionCapForResourceForUnlocked(
      player.techUnlocked,
      resourceId,
    );
    if (currentLevel >= techCap) {
      return kHiddenBuilderInlineActionState;
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
