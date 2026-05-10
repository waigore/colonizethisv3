import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_helpers.dart';
import 'order_suggestion_work_tile_prefilter.dart';
import 'unit_type_helpers.dart';

/// Returns the set of tile keys that are valid targets for a work order
/// (unitId, workTarget) given [currentOrders]. Used by the app to highlight
/// valid tiles when the player is assigning work. SPEC/ui/civilian-units-panel.md.
Set<String> getValidWorkOrderTileKeys(
  Game game,
  MapTopology topology,
  String playerId,
  String unitId,
  String workTarget,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final unit = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.id == unitId).firstOrNull;
  if (unit == null || unit.ownerId != playerId) return {};
  if (unit.currentWork != null) return {};
  if (playerHasPendingWorkOrderForUnit(currentOrders, playerId, unitId)) {
    return {};
  }
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) return {};

  final reservedForPicker = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
    ignorePendingWorkOrderUnitId: unitId,
  );

  final raw = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    tileMapByRegion: tileMapByRegion,
  );
  final candidateValidator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );
  final valid = <String>{};
  for (final tileKey in raw) {
    if (isDevExclusiveWorkTarget(workTarget) &&
        reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: workTarget,
      targetTileKey: tileKey,
    );
    if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
      valid.add(tileKey);
    }
  }
  orderSuggestionLog.d(
    'getValidWorkOrderTileKeys unit=$unitId target=$workTarget count=${valid.length}',
  );
  return valid;
}

/// Returns the set of tile keys that are valid targets for a work order,
/// filtering by work-target-specific criteria and visibility BEFORE calling
/// the order engine for efficiency.
///
/// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.
Set<String> getValidWorkOrderTileKeysWithVisibility({
  required Game game,
  required MapTopology topology,
  required PlayerView view,
  required String unitId,
  required String workTarget,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final unit = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.id == unitId).firstOrNull;
  if (unit == null || unit.ownerId != view.playerId) {
    orderSuggestionLog.d(
      'getValidWorkOrderTileKeysWithVisibility unit not found or not owned by player',
    );
    return {};
  }
  if (unit.currentWork != null) {
    orderSuggestionLog.d(
      'getValidWorkOrderTileKeysWithVisibility unit has current work',
    );
    return {};
  }
  if (playerHasPendingWorkOrderForUnit(currentOrders, view.playerId, unitId)) {
    orderSuggestionLog.d(
      'getValidWorkOrderTileKeysWithVisibility skipped pending draft work '
      'unit=$unitId',
    );
    return {};
  }
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) {
    orderSuggestionLog.d(
      'getValidWorkOrderTileKeysWithVisibility target $workTarget not allowed for unit type ${unit.type}',
    );
    return {};
  }

  orderSuggestionLog.d(
    'getValidWorkOrderTileKeysWithVisibility unit=${unit.id} type=${unit.type} workTarget=$workTarget',
  );

  final playerId = view.playerId;

  final reservedForPicker = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
    ignorePendingWorkOrderUnitId: unitId,
  );

  final raw = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    exploreProvinceScope: workTarget == kWorkTargetExplore
        ? _partiallyRevealedProvinceCacheForPlayer(game: game, view: view)
        : null,
    tileMapByRegion: tileMapByRegion,
  );
  final sortedVisible = sortedVisibleWorkTargetCandidates(view, raw);
  final candidateValidator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  orderSuggestionLog.d(
    'getValidWorkOrderTileKeysWithVisibility visible sorted count=${sortedVisible.length}',
  );

  final valid = <String>{};
  for (final tileKey in sortedVisible) {
    if (isDevExclusiveWorkTarget(workTarget) &&
        reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: workTarget,
      targetTileKey: tileKey,
    );
    if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
      valid.add(tileKey);
    }
  }

  orderSuggestionLog.d(
    'getValidWorkOrderTileKeysWithVisibility unit=$unitId target=$workTarget count=${valid.length} (filtered from ${sortedVisible.length} visible candidates)',
  );
  return valid;
}

Set<String> _partiallyRevealedProvinceCacheForPlayer({
  required Game game,
  required PlayerView view,
}) {
  final cached = <String>{};
  for (final regionEntry
      in game.worldState.tileKeysByRegionAndProvince.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (_hasMixedKnownAndUnknownVisibility(view, provinceEntry.value)) {
        cached.add(provinceId);
      }
    }
  }
  return cached;
}

bool _hasMixedKnownAndUnknownVisibility(
  PlayerView view,
  List<String> tileKeys,
) {
  var hasKnown = false;
  var hasUnknown = false;
  for (final tileKey in tileKeys) {
    if (view.visibilityForTile(tileKey) == VisibilityLevel.unknown) {
      hasUnknown = true;
    } else {
      hasKnown = true;
    }
    if (hasKnown && hasUnknown) return true;
  }
  return false;
}

List<String> sortedVisibleWorkTargetCandidates(
  PlayerView view,
  Set<String> rawCandidates,
) {
  final list = <String>[];
  for (final tk in rawCandidates) {
    final visibility = view.visibilityForTile(tk);
    if (visibility == VisibilityLevel.fullyVisible ||
        visibility == VisibilityLevel.fogged) {
      list.add(tk);
    }
  }
  list.sort();
  return list;
}
