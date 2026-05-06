import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';
import 'build_rail_work_rules.dart';
import 'draft_orders_mutations.dart';
import 'order_engine.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_helpers.dart';
import 'orders_application_helpers.dart';
import 'unit_type_helpers.dart';

/// Suggests build-unit orders that are affordable and valid for [view.playerId].
List<BuildUnitOrder> suggestBuildOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  orderSuggestionLog.d('suggestBuildOrders player=${view.playerId}');
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <BuildUnitOrder>[];

  final capitalId = player.capitalProvinceId;
  if (capitalId == null) {
    orderSuggestionLog.w('suggestBuildOrders no capital player=$playerId');
    return suggestions;
  }

  // Military (regiment) builds.
  for (final entry in RegimentEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary:
          buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: capitalId,
    );

    if (isBuildOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }

  // Naval (ship) builds. SPEC/program/order-suggestions.md.
  for (final entry in ShipEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary: false,
      spawnProvinceId: capitalId,
    );

    if (isBuildOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.unitType.compareTo(b.unitType));

  orderSuggestionLog.d(
    'suggestBuildOrders player=$playerId candidates=${suggestions.length}',
  );
  orderSuggestionLog.d(
    'suggestBuildOrders full list ${suggestions.map((o) => o.unitType).join(", ")}',
  );
  if (suggestions.isEmpty) {
    orderSuggestionLog.w('suggestBuildOrders no candidates player=$playerId');
  }
  return suggestions;
}

/// Suggests research orders for [view.playerId] based on unlocked tech and
/// the public tech catalog. At most one order per slot is suggested; it is up
/// to the AI to select which slot to fund.
List<ResearchOrder> suggestResearchOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  orderSuggestionLog.d('suggestResearchOrders player=${view.playerId}');
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <ResearchOrder>[];

  final unlocked = player.techUnlocked ?? const {};
  final existingBySlot = <int, ResearchOrder>{};
  final existingForPlayer =
      currentOrders.researchOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingBySlot[o.slotIndex] = o;
  }

  // Include discovery gate: only techs researchable with current visibility/prospection. SPEC/game/tech-tree.md.
  final researchableIds = researchableTechIds(
    unlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, playerId, r),
  );
  final candidates = <TechDefinition>[];
  for (final id in researchableIds) {
    final tech = techCatalog[id];
    if (tech != null) candidates.add(tech);
  }

  if (candidates.isEmpty) return suggestions;

  candidates.sort((a, b) {
    final eraCmp = a.era.compareTo(b.era);
    if (eraCmp != 0) return eraCmp;
    final costCmp = a.cost.compareTo(b.cost);
    if (costCmp != 0) return costCmp;
    return a.id.compareTo(b.id);
  });

  // For simplicity, suggest the cheapest valid tech for slot 0 if that slot
  // does not already have a research assignment.
  const slotIndex = 0;
  if (!existingBySlot.containsKey(slotIndex)) {
    final tech = candidates.first;
    suggestions.add(
      ResearchOrder(
        slotIndex: slotIndex,
        techId: tech.id,
        funding: ResearchFundingLevel.medium,
      ),
    );
  }

  orderSuggestionLog.d(
    'suggestResearchOrders player=$playerId candidates=${suggestions.length}',
  );
  orderSuggestionLog.d(
    'suggestResearchOrders full list ${suggestions.map((o) => "slot${o.slotIndex}:${o.techId}").join(", ")}',
  );
  return suggestions;
}

bool _isMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  MoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addMoveOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool _isArmyMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  ArmyMoveOrder candidate,
) {
  final merged = applyArmyMoveOrderForPlayer(baseOrders, playerId, candidate);
  final engine = OrderEngine(initialOrders: merged);
  final results = engine.validatePlayerOrdersWithContext(
    game,
    topology,
    playerId,
  );
  if (results.isEmpty) return false;
  return results.every((r) => r.isAccepted);
}

bool _isWorkOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  bumpOrderSuggestionWorkOrderAcceptanceProbeIfTracking();
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addWorkOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

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
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
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
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
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
  for (final regionEntry in game.worldState.tileKeysByRegionAndProvince.entries) {
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

bool _hasMixedKnownAndUnknownVisibility(PlayerView view, List<String> tileKeys) {
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

/// Pre-filters tiles based on work-target-specific criteria per SPEC/program/order-suggestions.md.
/// Returns a set of candidate tile keys that pass work-target requirements.
Set<String> _preFilterWorkTargetTiles({
  required Game game,
  required String workTarget,
  required String playerId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> resourceByTile,
  required Map<String, String> purchasedTiles,
  required Set<String> ownedProvinceIds,
  Set<String>? exploreProvinceScope,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final result = <String>{};
  final ctx = _WorkTilePrefilterCtx(
    game: game,
    playerId: playerId,
    tileKeysByRegion: tileKeysByRegion,
    resourceByTile: resourceByTile,
    purchasedTiles: purchasedTiles,
    ownedProvinceIds: ownedProvinceIds,
    exploreProvinceScope: exploreProvinceScope,
    tileMapByRegion: tileMapByRegion,
    result: result,
  );
  final op = _workTargetPrefilters[workTarget];
  if (op != null) {
    op(ctx);
  } else {
    _prefilterWorkTargetDefault(ctx);
  }
  return result;
}

Set<String> rawCandidateTilesForWorkTarget({
  required Game game,
  required String playerId,
  required String workTarget,
  Set<String>? exploreProvinceScope,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final world = game.worldState;
  final ownedProvinceIds = <String>{};
  for (final p in allProvinces(world)) {
    if (p.ownerId == playerId) {
      ownedProvinceIds.add(p.id);
    }
  }
  return _preFilterWorkTargetTiles(
    game: game,
    workTarget: workTarget,
    playerId: playerId,
    tileKeysByRegion: world.tileKeysByRegionAndProvince,
    resourceByTile: world.resourceByTileKey,
    purchasedTiles: world.purchasedTilesByTileKey,
    ownedProvinceIds: ownedProvinceIds,
    exploreProvinceScope: exploreProvinceScope,
    tileMapByRegion: tileMapByRegion,
  );
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

/// Iterates every tile in land provinces (prefixed province ids), skipping sea zones.
/// Used by work-target pre-filtering; per-tile logic lives in [onTile].
void _forEachPrefixedProvinceTile({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required void Function(String provinceId, String tileKey) onTile,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      for (final tileKey in provinceEntry.value) {
        onTile(provinceId, tileKey);
      }
    }
  }
}

/// All land tiles in owned provinces with prefixed ids (build_port, counter_spy pre-filter).
void _addAllTilesInOwnedPrefixedProvinces({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> ownedProvinceIds,
  required Set<String> result,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (!ownedProvinceIds.contains(provinceId)) continue;
      result.addAll(provinceEntry.value);
    }
  }
}

/// Adds candidate tiles for upgrade_town/build_fort: town tiles in owned provinces.
void _addCandidateTilesForTownWork({
  required Game game,
  required Set<String> ownedProvinceIds,
  required Set<String> result,
}) {
  for (final province in allProvinces(game.worldState)) {
    if (!ownedProvinceIds.contains(province.id)) continue;
    final townTileKey = province.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) continue;
    result.add(townTileKey);
  }
}

/// Adds candidate tiles for steal_tech: other GP capital provinces.
void _addCandidateTilesForStealTech({
  required Game game,
  required String playerId,
  required Set<String> result,
}) {
  for (final other in game.players) {
    if (other.id == playerId) continue;
    final capitalProvinceId = other.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    // Find a tile in the capital province
    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final byProvince = game.worldState.tileKeysByRegionAndProvince[regionId];
    final tiles = byProvince?[capitalProvinceId];
    if (tiles != null && tiles.isNotEmpty) {
      result.add(tiles.first);
    }
  }
}

bool _isBuildOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  BuildUnitOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addBuildOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

/// Context for [_workTargetPrefilters] map dispatch (work-target tile pre-filter).
class _WorkTilePrefilterCtx {
  _WorkTilePrefilterCtx({
    required this.game,
    required this.playerId,
    required this.tileKeysByRegion,
    required this.resourceByTile,
    required this.purchasedTiles,
    required this.ownedProvinceIds,
    required this.exploreProvinceScope,
    required this.tileMapByRegion,
    required this.result,
  });

  final Game game;
  final String playerId;
  final Map<String, Map<String, List<String>>> tileKeysByRegion;
  final Map<String, String> resourceByTile;
  final Map<String, String> purchasedTiles;
  final Set<String> ownedProvinceIds;
  final Set<String>? exploreProvinceScope;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Set<String> result;
}

typedef _WorkTilePrefilterOp = void Function(_WorkTilePrefilterCtx c);

void _prefilterWtBuildImprovement(_WorkTilePrefilterCtx c) {
  _forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      final resourceId = c.resourceByTile[tileKey];
      if (resourceId == null || resourceId.isEmpty) return;
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtBuildRoad(_WorkTilePrefilterCtx c) {
  _forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtBuildRail(_WorkTilePrefilterCtx c) {
  final player = c.game.playerById(c.playerId);
  if (player == null) return;
  final tech = player.techUnlocked;
  final tileState = c.game.worldState.tileState;
  _forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      final roadLevel = tileState.roadLevel(tileKey);
      if (roadLevel != 1 && roadLevel != 2) return;
      final terrain = terrainTypeForTileKey(c.tileMapByRegion, tileKey);
      if (rejectionReasonForBuildRailOrder(
            techUnlocked: tech,
            roadLevel: roadLevel,
            terrain: terrain,
          ) !=
          null) {
        return;
      }
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtTownWork(_WorkTilePrefilterCtx c) {
  _addCandidateTilesForTownWork(
    game: c.game,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void _prefilterWtOwnedProvinceTiles(_WorkTilePrefilterCtx c) {
  _addAllTilesInOwnedPrefixedProvinces(
    tileKeysByRegion: c.tileKeysByRegion,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void _prefilterWtStealTech(_WorkTilePrefilterCtx c) {
  _addCandidateTilesForStealTech(
    game: c.game,
    playerId: c.playerId,
    result: c.result,
  );
}

void _prefilterWtPurchaseLand(_WorkTilePrefilterCtx c) {
  final gpIds = c.game.players.map((p) => p.id).toSet();
  final minorIds = c.game.minorNations.map((m) => m.id).toSet();
  final tribeIds = c.game.tribes.map((t) => t.id).toSet();
  _forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final province = c.game.worldState.tryGetProvince(provinceId);
      if (province == null) return;
      final ownerId = province.ownerId;
      if (ownerId == null) return;
      if (gpIds.contains(ownerId)) return;
      if (!minorIds.contains(ownerId) && !tribeIds.contains(ownerId)) {
        return;
      }
      final resourceId = c.resourceByTile[tileKey];
      if (resourceId == null || resourceId.isEmpty) return;
      final existingBuyer = c.game.worldState.purchasedTilesByTileKey[tileKey];
      if (existingBuyer != null) return;
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtExplore(_WorkTilePrefilterCtx c) {
  final scoped = c.exploreProvinceScope;
  if (scoped != null) {
    for (final regionEntry in c.tileKeysByRegion.entries) {
      for (final provinceEntry in regionEntry.value.entries) {
        if (!scoped.contains(provinceEntry.key)) continue;
        c.result.addAll(provinceEntry.value);
      }
    }
    return;
  }
  for (final regionEntry in c.tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      c.result.addAll(provinceEntry.value);
    }
  }
}

void _prefilterWtProspect(_WorkTilePrefilterCtx c) {
  final prospected =
      c.game.worldState.playerProspectedTiles[c.playerId] ?? const <String>{};
  _forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      if (prospected.contains(tileKey)) return;
      if (!isMineralEligibleTile(c.game, c.tileMapByRegion, tileKey)) {
        return;
      }
      c.result.add(tileKey);
    },
  );
}

void _prefilterWorkTargetDefault(_WorkTilePrefilterCtx c) {
  for (final regionEntry in c.tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      c.result.addAll(provinceEntry.value);
    }
  }
}

final Map<String, _WorkTilePrefilterOp> _workTargetPrefilters =
    <String, _WorkTilePrefilterOp>{
      kWorkTargetBuildImprovement: _prefilterWtBuildImprovement,
      kWorkTargetBuildRoad: _prefilterWtBuildRoad,
      'build_rail': _prefilterWtBuildRail,
      kWorkTargetUpgradeTown: _prefilterWtTownWork,
      kWorkTargetBuildFort: _prefilterWtTownWork,
      kWorkTargetBuildPort: _prefilterWtOwnedProvinceTiles,
      kWorkTargetCounterSpy: _prefilterWtOwnedProvinceTiles,
      kWorkTargetStealTech: _prefilterWtStealTech,
      kWorkTargetPurchaseLand: _prefilterWtPurchaseLand,
      kWorkTargetExplore: _prefilterWtExplore,
      kWorkTargetProspect: _prefilterWtProspect,
    };
