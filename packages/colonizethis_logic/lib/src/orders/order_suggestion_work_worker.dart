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

    _runWorkSuggestionPipeline(
      unit: unit,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: target,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
      noCandidateReason: 'no_valid_tile',
      candidatesProvider: () sync* {
        for (final tk in sortedVisible) {
          if (isDevExclusiveWorkTarget(target) &&
              devExclusiveReservedTiles.contains(tk)) {
            continue;
          }
          yield WorkOrder(unitId: unit.id, target: target, targetTileKey: tk);
        }
      },
      candidateAcceptor: (candidate) {
        final accepted = isWorkOrderAccepted(
          game,
          topology,
          playerId,
          currentOrders,
          candidate,
          tileMapByRegion: tileMapByRegion,
        );
        if (accepted) {
          orderSuggestionLog.d('suggestWorkOrders candidate=$candidate');
        }
        return accepted;
      },
    );
  }
}
