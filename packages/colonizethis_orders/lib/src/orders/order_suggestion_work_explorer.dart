import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'bundled_civilian_work_order.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_visibility.dart';
import 'order_work_constants.dart';
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

  _addProspectSuggestionIfEligible(
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

void _addProspectSuggestionIfEligible({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
  required OrderResolutionContext resolution,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  // Early bail mirrors [WorkSuggestionPipeline]'s duplicate-pending check so we
  // skip the per-unit `unitsByIdFromWorld` / province snapshot setup below
  // when this explorer already has a pending `prospect` order this turn.
  // The pipeline would log the same `duplicate_pending` line if reached.
  final existingProspect = existingTargetsByUnit[unit.id];
  if (existingProspect != null &&
      existingProspect.contains(kWorkTargetProspect)) {
    logWorkOrderSuggestion(
      unitId: unit.id,
      unitType: unit.type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      workTarget: kWorkTargetProspect,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }

  final diplomatic =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ?? const [];

  final prospected = game.worldState.prospectedTilesForPlayer(playerId);
  // [buildPlayerView] already aggregates every province row into
  // [PlayerView.provincesById]; reuse that snapshot instead of scanning
  // [allProvinces] again for each explorer prospect probe (Refs #2394,
  // SPEC/program/order-suggestions.md). Probe the explorer's current province
  // first so [kMaxExploreProvinceProbesPerUnit] still reaches co-located
  // mineral tiles on seed-scale maps (Refs #2847).
  final provinces = provincesWithUnitLocationFirst(view, unit);
  final atProvinceFullId = unit.locationProvinceId;

  var lastReason = 'no_valid_tile';
  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: unit.type,
    unitRegionId: regionId,
    atProvinceId: provinceId,
    workTarget: kWorkTargetProspect,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    candidatesProvider: () sync* {
      for (final prov in cappedExploreProvinceProbes(provinces)) {
        if (!provinceHasFoggedVisibilityForExplore(view, prov)) {
          lastReason = 'visibility';
          continue;
        }
        final tilesInP = tileKeysForProvinceInRegion(tileKeysByRegion, prov);
        if (tilesInP.isEmpty) {
          lastReason = 'no_valid_tile';
          continue;
        }
        final scan = acceptedProspectTilesInProvince(
          view: view,
          game: game,
          topology: topology,
          playerId: playerId,
          unit: unit,
          tilesInProvince: tilesInP,
          prospected: prospected,
          resolution: resolution,
          diplomaticOrders: diplomatic,
          candidateValidator: candidateValidator,
          workProbeBudget: workProbeBudget,
          tileMapByRegion: tileMapByRegion,
          // The Explorer's own province carries the highest-value, bounded
          // prospect candidate (a co-located owned mineral tile); exempt it
          // from the shared per-pass budget so earlier units cannot starve it
          // (Refs #2847). Remote provinces still consume the shared budget.
          consumeSharedBudget: prov.id != atProvinceFullId,
        );
        lastReason = scan.lastReason;
        for (final tk in scan.tiles) {
          yield WorkOrder(
            unitId: unit.id,
            target: kWorkTargetProspect,
            targetTileKey: tk,
          );
        }
      }
    },
    candidateAcceptor: (_) => true,
    noCandidateReason: 'no_valid_tile',
    resolveNoCandidateReason: () => lastReason,
    includeAllAccepted: true,
    maxProbeAttempts:
        kMaxExploreProvinceProbesPerUnit *
        kMaxWorkProbeAttemptsPerUnitPerTarget,
  );
}
