part of 'order_suggestion.dart';

void _addExplorerWorkSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required String localId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (provinceHasAtLeastVisibility(
    view,
    regionId,
    provinceId,
    VisibilityLevel.revealed,
  )) {
    final hasPartiallyHiddenTile = view.visibilityByTile.entries.any((e) {
      final parts = e.key.split('|');
      if (parts.length != 4) return false;
      if (parts[0] != regionId || parts[1] != localId) return false;
      return e.value != VisibilityLevel.fullyVisible;
    });

    if (hasPartiallyHiddenTile) {
      final existing = existingTargetsByUnit[unit.id];
      if (existing == null || !existing.contains(kWorkTargetExplore)) {
        final targetTileKey = '$regionId|$localId|0|0';
        final candidate = WorkOrder(
          unitId: unit.id,
          target: kWorkTargetExplore,
          targetTileKey: targetTileKey,
        );
        if (_isWorkOrderAccepted(
          game,
          topology,
          playerId,
          currentOrders,
          candidate,
          tileMapByRegion: tileMapByRegion,
        )) {
          suggestions.add(candidate);
        }
      }
    }
  }

  _addProspectSuggestionIfEligible(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    playerId: playerId,
    unit: unit,
    regionId: regionId,
    provinceId: provinceId,
    tilesInProvince: tilesInProvince,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    tileMapByRegion: tileMapByRegion,
  );
}

void _addProspectSuggestionIfEligible({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (!provinceHasAtLeastVisibility(
        view,
        regionId,
        provinceId,
        VisibilityLevel.fogged,
      ) ||
      tilesInProvince.isEmpty) {
    return;
  }

  final existingProspect = existingTargetsByUnit[unit.id];
  if (existingProspect != null &&
      existingProspect.contains(kWorkTargetProspect)) {
    return;
  }

  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  String? prospectTileKey;
  for (final tk in tilesInProvince) {
    if (prospected.contains(tk)) continue;
    if (!isMineralEligibleTile(game, null, tk)) continue;
    prospectTileKey = tk;
    break;
  }
  if (prospectTileKey == null) {
    return;
  }

  final candidate = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetProspect,
    targetTileKey: prospectTileKey,
  );
  if (_isWorkOrderAccepted(
    game,
    topology,
    playerId,
    currentOrders,
    candidate,
    tileMapByRegion: tileMapByRegion,
  )) {
    suggestions.add(candidate);
  }
}

/// Suggests candidate work orders for explorers and civilian workers owned by
/// [view.playerId]. Worker units (Builder, Engineer, Rail Builder): at least
/// one suggestion per (unit, allowed target) when any **player-controlled** tile
/// (owned or purchased) is valid under visibility and the order engine — same
/// scope as work-order validation, not limited to the unit’s current province.
/// Explorers/Spies/Merchants follow type-specific rules. Visibility per
/// SPEC/program/fog-and-exploration-resolution.md.
List<WorkOrder> suggestWorkOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  _log.d('suggestWorkOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <WorkOrder>[];

  // Index existing work orders per unit to avoid suggesting duplicates (by unit + target).
  final existingTargetsByUnit = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingTargetsByUnit.putIfAbsent(o.unitId, () => <String>{}).add(o.target);
  }

  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;

  // Pre-filter + visibility sort per workTarget; reused across worker units.
  final visibleCandidatesSortedByWorkTarget = <String, List<String>>{};

  final devExclusiveReservedTiles = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
  );

  for (final unit in view.ownUnits) {
    _addWorkSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      tileKeysByRegion: tileKeysByRegion,
      playerId: playerId,
      unit: unit,
      existingTargetsByUnit: existingTargetsByUnit,
      visibleCandidatesSortedByWorkTarget: visibleCandidatesSortedByWorkTarget,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
    );
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    final targetCmp = a.target.compareTo(b.target);
    if (targetCmp != 0) return targetCmp;
    return a.targetTileKey.compareTo(b.targetTileKey);
  });

  _log.d('suggestWorkOrders player=$playerId candidates=${suggestions.length}');
  _log.d(
    'suggestWorkOrders full list ${suggestions.map((o) => "${o.unitId}:${o.target}").toList()}',
  );
  if (suggestions.isEmpty)
    _log.w('suggestWorkOrders no candidates player=$playerId');
  return suggestions;
}

void _addWorkSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required Map<String, Set<String>> existingTargetsByUnit,
  required Map<String, List<String>> visibleCandidatesSortedByWorkTarget,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (unit.currentWork != null) return;

  final type = unit.type;
  final isExplorer = isExplorerUnit(type);
  final isWorker = isCivilianWorkerUnit(type);
  final isSpy = isSpyUnit(type);
  final isMerchant = isMerchantUnit(type);
  if (!isExplorer && !isWorker && !isSpy && !isMerchant) return;

  final regionId = regionIdForUnit(view, unit);
  final provinceId = unit.locationProvinceId;
  final localId = ProvinceId.localIdFrom(provinceId);
  final province = view.provinceByRegionAndId(regionId, provinceId);
  final ownerId = province?.ownerId;
  final tilesInProvince = tileKeysByRegion[regionId]?[provinceId] ?? const [];

  _log.d(
    'suggestWorkOrders unit=${unit.id} provinceId=$provinceId provinceName=${province?.displayName} ownerId=$ownerId regionId=$regionId tilesInProvince=${tilesInProvince.length}',
  );

  if (isExplorer) {
    _addExplorerWorkSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      unit: unit,
      regionId: regionId,
      provinceId: provinceId,
      localId: localId,
      tilesInProvince: tilesInProvince,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
      tileMapByRegion: tileMapByRegion,
    );
    return;
  }

  if (isWorker) {
    _addWorkerSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      unit: unit,
      type: type,
      existingTargetsByUnit: existingTargetsByUnit,
      visibleCandidatesSortedByWorkTarget: visibleCandidatesSortedByWorkTarget,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
      tileMapByRegion: tileMapByRegion,
    );
  }

  if (isSpy && tilesInProvince.isNotEmpty) {
    _addSpySuggestionsForUnit(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      tileKeysByRegion: tileKeysByRegion,
      playerId: playerId,
      unit: unit,
      type: type,
      ownerId: ownerId,
      tilesInProvince: tilesInProvince,
      suggestions: suggestions,
    );
  }

  if (isMerchant) {
    _addMerchantSuggestionsForUnit(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      tileKeysByRegion: tileKeysByRegion,
      playerId: playerId,
      unit: unit,
      type: type,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
    );
  }
}

void _addWorkerSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String type,
  required Map<String, Set<String>> existingTargetsByUnit,
  required Map<String, List<String>> visibleCandidatesSortedByWorkTarget,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  for (final target in allowedTargets) {
    final existing = existingTargetsByUnit[unit.id];
    if (existing != null && existing.contains(target)) continue;

    final sortedVisible = visibleCandidatesSortedByWorkTarget.putIfAbsent(
      target,
      () {
        final raw = _rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: target,
          tileMapByRegion: tileMapByRegion,
        );
        return _sortedVisibleWorkTargetCandidates(view, raw);
      },
    );

    final accepted = _firstAcceptedWorkerCandidate(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      playerId: playerId,
      unitId: unit.id,
      target: target,
      sortedVisibleTileKeys: sortedVisible,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
    );
    if (accepted != null) {
      _log.d('suggestWorkOrders candidate=$accepted');
      suggestions.add(accepted);
      continue;
    }

    _log.d(
      'suggestWorkOrders rejected target=$target unit=${unit.id} (no valid tile)',
    );
  }
}

WorkOrder? _firstAcceptedWorkerCandidate({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required String unitId,
  required String target,
  required List<String> sortedVisibleTileKeys,
  required Set<String> devExclusiveReservedTiles,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  for (final tk in sortedVisibleTileKeys) {
    if (isDevExclusiveWorkTarget(target) &&
        devExclusiveReservedTiles.contains(tk)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: target,
      targetTileKey: tk,
    );
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      return candidate;
    }
  }
  return null;
}

void _addSpySuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required String? ownerId,
  required List<String> tilesInProvince,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  if (allowedTargets.contains(kWorkTargetCounterSpy) && ownerId == playerId) {
    final candidate = WorkOrder(
      unitId: unit.id,
      target: kWorkTargetCounterSpy,
      targetTileKey: tilesInProvince.first,
    );
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      suggestions.add(candidate);
    }
  }

  if (!allowedTargets.contains(kWorkTargetStealTech)) return;
  for (final other in game.players) {
    if (other.id == playerId || other.capitalProvinceId == null) continue;
    final capProvinceId = other.capitalProvinceId!;
    final capRegionId = ProvinceId.regionIdFrom(capProvinceId);
    final capTiles = tileKeysByRegion[capRegionId]?[capProvinceId] ?? const [];
    if (capTiles.isEmpty) continue;
    final candidate = WorkOrder(
      unitId: unit.id,
      target: kWorkTargetStealTech,
      targetTileKey: capTiles.first,
    );
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      suggestions.add(candidate);
      return;
    }
  }
}

void _addMerchantSuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null ||
      !allowedTargets.contains(kWorkTargetPurchaseLand)) {
    return;
  }

  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = game.players.map((p) => p.id).toSet();
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
    final regionId = p.regionId;
    final tiles = tileKeysByRegion[regionId]?[p.id] ?? const [];
    for (final tk in tiles) {
      if (resourceByTile[tk] == null) continue;
      if (devExclusiveReservedTiles.contains(tk)) continue;
      final candidate = WorkOrder(
        unitId: unit.id,
        target: kWorkTargetPurchaseLand,
        targetTileKey: tk,
      );
      if (_isWorkOrderAccepted(
        game,
        topology,
        playerId,
        currentOrders,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )) {
        suggestions.add(candidate);
        break;
      }
    }
  }
}
