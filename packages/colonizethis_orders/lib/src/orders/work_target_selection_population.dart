import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'work_target_selection_snapshot.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';

export 'work_target_selection_snapshot.dart';

final Map<String, WorkTargetSelectionPopulationStrategy>
workTargetSelectionDefaultStrategies = {
  for (final target in _mergedValidWorkTargets)
    target: (WorkTargetSelectionSnapshot s) =>
        _populateMergedValidForTarget(s, target),
  for (final target in _idleNoPendingWorkTargets)
    target: (WorkTargetSelectionSnapshot s) =>
        _populateIdleNoPendingTargets(s, target),
};

const _mergedValidWorkTargets = <String>{
  kWorkTargetExplore,
  kWorkTargetCounterSpy,
  kWorkTargetPurchaseLand,
};

const _idleNoPendingWorkTargets = <String>{
  kWorkTargetProspect,
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};

IncrementalCandidateValidator sharedOrBuildWorkTargetValidator(
  WorkTargetSelectionSnapshot s,
) {
  final existing = s.sharedCandidateValidator;
  if (existing != null) {
    return existing;
  }
  return buildIncrementalCandidateValidator(
    game: s.game,
    topology: s.topology,
    playerId: s.playerId,
    baseOrders: s.currentOrders,
    tileMapByRegion: s.tileMapByRegion,
    resolution: orderResolutionContextFromView(s.playerView, s.game),
    factionMembership: DiplomacyFactionMembership.from(s.game),
  );
}

Set<String> _populateMergedValidForTarget(
  WorkTargetSelectionSnapshot s,
  String workTarget,
) {
  final sharedValidator = sharedOrBuildWorkTargetValidator(s);
  final merged = <String>{};
  for (final unit in humanCivilianUnitsForWorkTargets(s.game, s.playerId)) {
    final supportsTarget =
        workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ?? false;
    if (!supportsTarget) {
      continue;
    }
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: s.game,
      topology: s.topology,
      view: s.playerView,
      unitId: unit.id,
      workTarget: workTarget,
      currentOrders: s.currentOrders,
      tileMapByRegion: s.tileMapByRegion,
      sharedCandidateValidator: sharedValidator,
      playerOwnedProvinceIds: s.playerOwnedProvinceIds,
    );
    merged.addAll(valid);
  }
  return merged;
}

Set<String> _populateIdleNoPendingTargets(
  WorkTargetSelectionSnapshot s,
  String workTarget,
) {
  final sharedValidator = sharedOrBuildWorkTargetValidator(s);
  final pendingWorkUnitIds = <String>{
    for (final w
        in s.currentOrders.workOrdersByPlayerId[s.playerId] ??
            const <WorkOrder>[])
      w.unitId,
  };
  final merged = <String>{};
  for (final unit in humanCivilianUnitsForWorkTargets(s.game, s.playerId)) {
    final supportsTarget =
        workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ?? false;
    if (!supportsTarget) {
      continue;
    }
    final isIdleNow = unit.status == UnitStatus.idle;
    if (!isIdleNow || unit.currentWork != null) {
      continue;
    }
    if (pendingWorkUnitIds.contains(unit.id)) {
      continue;
    }
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: s.game,
      topology: s.topology,
      view: s.playerView,
      unitId: unit.id,
      workTarget: workTarget,
      currentOrders: s.currentOrders,
      tileMapByRegion: s.tileMapByRegion,
      sharedCandidateValidator: sharedValidator,
      playerOwnedProvinceIds: s.playerOwnedProvinceIds,
    );
    merged.addAll(valid);
  }
  return merged;
}

Iterable<Unit> humanCivilianUnitsForWorkTargets(Game game, String playerId) =>
    game.worldState.allUnitsById.values.where(
      (unit) => unit.ownerId == playerId,
    );
