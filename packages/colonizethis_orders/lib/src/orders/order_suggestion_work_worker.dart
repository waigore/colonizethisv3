import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'connectivity_dev_snapshot.dart';
import 'connectivity_dev_targets.dart';
import 'development_panel/improve_tile_ordering.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';
import 'order_work_constants.dart';
import 'unit_type_helpers.dart';
import 'work_suggestion_pipeline.dart';

void addWorkerSuggestionsForUnit({
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
  required Set<String> playerOwnedProvinceIds,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required DiplomacyFactionMembership factionMembership,
  required WorkSuggestionProbeBudget workProbeBudget,
  Map<String, TileMapResult>? tileMapByRegion,
  ConnectivityDevSnapshot? connectivityDev,
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
          playerOwnedProvinceIds: playerOwnedProvinceIds,
          factionMembership: factionMembership,
        );
        var visible = sortedVisibleWorkTargetCandidates(view, raw);
        if (target == kWorkTargetBuildImprovement) {
          visible = prioritizeFeedstockBuildImprovementCandidates(
            game: game,
            playerId: playerId,
            sortedVisible: visible,
          );
          if (connectivityDev != null && tileMapByRegion != null) {
            visible = applyBuildImprovementConnectivityPreservingFeedstock(
              game: game,
              playerId: playerId,
              sortedVisible: visible,
              snapshot: connectivityDev,
            );
          }
        } else if (connectivityDev != null && tileMapByRegion != null) {
          visible = applyConnectivityDevTargetOrdering(
            workTarget: target,
            sortedVisible: visible,
            snapshot: connectivityDev,
            game: game,
            topology: topology,
            tileMapByRegion: tileMapByRegion,
          );
        }
        return visible;
      },
    );

    WorkSuggestionPipeline.run(
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
        return isWorkOrderAcceptedWithValidator(candidateValidator, candidate);
      },
      probeBudget: workProbeBudget,
    );
  }
}
