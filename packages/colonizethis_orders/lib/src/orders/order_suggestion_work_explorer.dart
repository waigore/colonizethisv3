import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'bundled_civilian_work_order.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_visibility.dart';
import 'order_work_constants.dart';
import 'order_suggestion_work_explorer_prospect.dart';
import 'work_suggestion_pipeline.dart';
import 'work_tile_candidacy/explorer_province_probe.dart';

// Explore-only logic retained in this library (Refs #4109 wave-5 slice D):
// - `exploreProvinceStillUsefulFromAuthoritativeTiles` gate in
//   `_tryExploreWorkOrderForProvince`.
// - Explore candidate assembly + ranking in `addExplorerWorkSuggestionsForUnit`
//   (fogged-province usefulness + bundled move leg for explore targets).
// Shared province/tile probe scaffolding lives in
// `work_tile_candidacy/explorer_province_probe.dart`.

({WorkOrder? chosen, String lastReason}) _tryExploreWorkOrderForProvince({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required Province prov,
  required OrderResolutionContext resolution,
  required List<DiplomaticOrder> diplomatic,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required IncrementalCandidateValidator candidateValidator,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final tilesInP = tileKeysForProvinceInRegion(tileKeysByRegion, prov);
  if (tilesInP.isEmpty) {
    return (chosen: null, lastReason: 'no_valid_tile');
  }
  final targetTileKey = pickFirstKnownOrFirstSortedTile(view, tilesInP);

  if (!workOrderVisibilityOk(
    view,
    unit,
    kWorkTargetExplore,
    targetTileKey: targetTileKey,
    worldState: game.worldState,
  )) {
    return (chosen: null, lastReason: 'visibility');
  }
  if (!provinceHasFoggedVisibilityForExplore(view, prov)) {
    return (chosen: null, lastReason: 'visibility');
  }
  if (!exploreProvinceStillUsefulFromAuthoritativeTiles(view, tilesInP)) {
    return (chosen: null, lastReason: 'not_applicable');
  }
  final probe = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetExplore,
    targetTileKey: targetTileKey,
  );
  final moveLegReason = bundledWorkMoveLegRejectionReason(
    game: game,
    topology: topology,
    playerId: playerId,
    unit: unit,
    probe: probe,
    resolution: resolution,
    diplomatic: diplomatic,
  );
  if (moveLegReason != null) {
    return (chosen: null, lastReason: moveLegReason);
  }
  final candidate = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetExplore,
    targetTileKey: targetTileKey,
  );
  if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
    return (chosen: candidate, lastReason: '');
  }
  return (chosen: null, lastReason: 'engine_rejected');
}

void addExplorerWorkSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required List<Province> partiallyRevealedProvincesSorted,
  required Set<String> colonialIntelExploreProvinceIds,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final resolution = orderResolutionContextFromView(view, game);
  final diplomatic =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ?? const [];

  final pendingOrClaimed = existingTargetsByUnit[unit.id];
  if (pendingOrClaimed != null && pendingOrClaimed.isNotEmpty) {
    for (final target in [kWorkTargetExplore, kWorkTargetProspect]) {
      logWorkOrderSuggestion(
        unitId: unit.id,
        unitType: unit.type,
        unitRegionId: regionId,
        atProvinceId: provinceId,
        workTarget: target,
        outcome: 'excluded',
        reason: 'duplicate_pending',
      );
    }
    return;
  }

  final provinces = partiallyRevealedProvincesSorted;
  var lastReason = 'no_valid_tile';
  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: unit.type,
    unitRegionId: regionId,
    atProvinceId: provinceId,
    workTarget: kWorkTargetExplore,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    candidatesProvider: () sync* {
      for (final prov in cappedExploreProvinceProbes(provinces)) {
        final attempt = _tryExploreWorkOrderForProvince(
          view: view,
          game: game,
          topology: topology,
          currentOrders: currentOrders,
          playerId: playerId,
          unit: unit,
          prov: prov,
          resolution: resolution,
          diplomatic: diplomatic,
          tileKeysByRegion: tileKeysByRegion,
          candidateValidator: candidateValidator,
          tileMapByRegion: tileMapByRegion,
        );
        if (attempt.chosen != null) {
          yield attempt.chosen!;
        } else {
          lastReason = attempt.lastReason;
        }
      }
    },
    candidateAcceptor: (_) => true,
    noCandidateReason: 'no_valid_tile',
    resolveNoCandidateReason: () => lastReason,
    includeAllAccepted: true,
    probeBudget: workProbeBudget,
  );

  addExplorerProspectWorkSuggestionsForUnit(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    playerId: playerId,
    unit: unit,
    regionId: regionId,
    provinceId: provinceId,
    tileKeysByRegion: tileKeysByRegion,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    candidateValidator: candidateValidator,
    workProbeBudget: workProbeBudget,
    resolution: resolution,
    tileMapByRegion: tileMapByRegion,
  );
}
