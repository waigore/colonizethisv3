part of 'order_suggestion_work.dart';

void _addSpySuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required String? ownerId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  _addCounterSpySuggestionIfEligible(
    allowedTargets: allowedTargets,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    playerId: playerId,
    unit: unit,
    type: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    ownerId: ownerId,
    tilesInProvince: tilesInProvince,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    tileMapByRegion: tileMapByRegion,
  );

  if (!allowedTargets.contains(kWorkTargetStealTech)) return;
  final existingSteal = existingTargetsByUnit[unit.id];
  if (existingSteal != null && existingSteal.contains(kWorkTargetStealTech)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetStealTech,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }
  var sawStealCandidate = false;
  for (final other in game.players) {
    if (other.id == playerId || other.capitalProvinceId == null) continue;
    final capProvinceId = other.capitalProvinceId!;
    final capRegionId = ProvinceId.regionIdFrom(capProvinceId);
    final capTiles = tileKeysByRegion[capRegionId]?[capProvinceId] ?? const [];
    if (capTiles.isEmpty) continue;
    sawStealCandidate = true;
    final candidate = WorkOrder(
      unitId: unit.id,
      target: kWorkTargetStealTech,
      targetTileKey: capTiles.first,
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
          .add(kWorkTargetStealTech);
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: type,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: kWorkTargetStealTech,
        outcome: 'included',
        tile: candidate.targetTileKey,
      );
      return;
    }
  }
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetStealTech,
    outcome: 'excluded',
    reason: sawStealCandidate ? 'engine_rejected' : 'no_valid_tile',
  );
}

void _addCounterSpySuggestionIfEligible({
  required List<String> allowedTargets,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required String? ownerId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (!allowedTargets.contains(kWorkTargetCounterSpy)) return;
  final existingCounterSpy = existingTargetsByUnit[unit.id];
  if (existingCounterSpy != null &&
      existingCounterSpy.contains(kWorkTargetCounterSpy)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }
  if (ownerId != playerId) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'excluded',
      reason: 'not_applicable',
    );
    return;
  }

  final candidate = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetCounterSpy,
    targetTileKey: tilesInProvince.first,
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
        .add(kWorkTargetCounterSpy);
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'included',
      tile: candidate.targetTileKey,
    );
    return;
  }
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetCounterSpy,
    outcome: 'excluded',
    reason: 'engine_rejected',
  );
}
