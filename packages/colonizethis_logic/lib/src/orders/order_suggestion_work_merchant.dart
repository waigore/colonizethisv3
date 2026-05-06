part of 'order_suggestion_work.dart';

void _addMerchantSuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required Map<String, Set<String>> existingTargetsByUnit,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null ||
      !allowedTargets.contains(kWorkTargetPurchaseLand)) {
    return;
  }

  final existing = existingTargetsByUnit[unit.id];
  if (existing != null && existing.contains(kWorkTargetPurchaseLand)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetPurchaseLand,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }

  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = game.players.map((p) => p.id).toSet();
  var sawCandidate = false;
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
    final regionId = p.regionId;
    final tiles = tileKeysByRegion[regionId]?[p.id] ?? const [];
    for (final tk in tiles) {
      if (resourceByTile[tk] == null) continue;
      sawCandidate = true;
      if (devExclusiveReservedTiles.contains(tk)) continue;
      final candidate = WorkOrder(
        unitId: unit.id,
        target: kWorkTargetPurchaseLand,
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
        suggestions.add(candidate);
        existingTargetsByUnit
            .putIfAbsent(unit.id, () => <String>{})
            .add(kWorkTargetPurchaseLand);
        _suggestionWorkLog(
          unitId: unit.id,
          unitType: type,
          unitRegionId: unitRegionId,
          atProvinceId: atProvinceId,
          workTarget: kWorkTargetPurchaseLand,
          outcome: 'included',
          tile: candidate.targetTileKey,
        );
        return;
      }
    }
  }
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetPurchaseLand,
    outcome: 'excluded',
    reason: sawCandidate ? 'engine_rejected' : 'no_valid_tile',
  );
}
