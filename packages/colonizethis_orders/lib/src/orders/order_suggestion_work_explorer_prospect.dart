import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_work_constants.dart';
import 'work_suggestion_pipeline.dart';
import 'work_tile_candidacy/explorer_province_probe.dart';

/// Prospect half of Explorer work suggestions (Refs #4508). Explore assembly
/// stays in `order_suggestion_work_explorer.dart`.
void addExplorerProspectWorkSuggestionsForUnit({
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
