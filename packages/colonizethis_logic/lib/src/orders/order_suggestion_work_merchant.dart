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
  required IncrementalCandidateValidator candidateValidator,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null ||
      !allowedTargets.contains(kWorkTargetPurchaseLand)) {
    return;
  }

  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = game.players.map((p) => p.id).toSet();
  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetPurchaseLand,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    noCandidateReason: 'no_valid_tile',
    candidatesProvider: () sync* {
      for (final p in allProvinces(game.worldState)) {
        if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
        final regionId = p.regionId;
        final tiles = tileKeysByRegion[regionId]?[p.id] ?? const <String>[];
        for (final tk in tiles) {
          if (resourceByTile[tk] == null) continue;
          if (devExclusiveReservedTiles.contains(tk)) continue;
          yield WorkOrder(
            unitId: unit.id,
            target: kWorkTargetPurchaseLand,
            targetTileKey: tk,
          );
        }
      }
    },
    candidateAcceptor: (candidate) =>
        isWorkOrderAcceptedWithValidator(candidateValidator, candidate),
  );
}
