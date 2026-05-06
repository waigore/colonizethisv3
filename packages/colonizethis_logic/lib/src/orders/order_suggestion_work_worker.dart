part of 'order_suggestion_work.dart';

void _addWorkerSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
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
    if (existing != null && existing.contains(target)) {
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: type,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: target,
        outcome: 'excluded',
        reason: 'duplicate_pending',
      );
      continue;
    }

    final sortedVisible = visibleCandidatesSortedByWorkTarget.putIfAbsent(
      target,
      () {
        final raw = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: target,
          tileMapByRegion: tileMapByRegion,
        );
        return sortedVisibleWorkTargetCandidates(view, raw);
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
      orderSuggestionLog.d('suggestWorkOrders candidate=$accepted');
      suggestions.add(accepted);
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: type,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: target,
        outcome: 'included',
        tile: accepted.targetTileKey,
      );
      continue;
    }

    final reason = sortedVisible.isEmpty ? 'no_valid_tile' : 'engine_rejected';
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: target,
      outcome: 'excluded',
      reason: reason,
    );
    orderSuggestionLog.d(
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
    if (isWorkOrderAccepted(
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
