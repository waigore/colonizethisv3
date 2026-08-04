import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../incremental_candidate_validator.dart';
import '../order_resolution_context.dart';
import '../order_suggestion_context.dart';
import '../order_suggestion_helpers.dart';
import '../order_work_constants.dart';
import '../partial_province_reveal.dart';
import '../unit_type_helpers.dart';
import 'work_tile_candidate_index.dart';

/// Internal probe state for work-order tile-key validation (Refs #4246 Slice D).
class WorkOrderTileKeyProbe {
  const WorkOrderTileKeyProbe({
    required this.unitId,
    required this.workTarget,
    required this.reservedForPicker,
    required this.candidateValidator,
    required this.rawCandidateTileKeys,
  });

  final String unitId;
  final String workTarget;
  final Set<String> reservedForPicker;
  final IncrementalCandidateValidator candidateValidator;
  final Set<String> rawCandidateTileKeys;
}

WorkOrderTileKeyProbe? prepareWorkOrderTileKeyProbe({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required PlayerView view,
  required String unitId,
  required String workTarget,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
  IncrementalCandidateValidator? sharedCandidateValidator,
  Set<String>? playerOwnedProvinceIds,
  required bool applyExploreProvinceScope,
}) {
  final unit = game.worldState.tryGetUnitById(unitId);
  if (unit == null || unit.ownerId != playerId) return null;
  if (unit.currentWork != null) return null;
  if (playerHasPendingWorkOrderForUnit(currentOrders, playerId, unitId)) {
    return null;
  }
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) return null;

  final effectiveFactionMembership =
      sharedCandidateValidator?.factionMembershipSnapshot ??
      factionMembership ??
      DiplomacyFactionMembership.from(game);
  final effectiveResolution =
      resolution ??
      (sharedCandidateValidator != null
          ? (
              view: sharedCandidateValidator.view,
              unitsById: sharedCandidateValidator.unitsById,
              provinceById: sharedCandidateValidator.view.provincesById,
            )
          : orderResolutionContextFromView(view, game));
  final effectiveOwnedProvinceIds =
      playerOwnedProvinceIds ??
      <String>{
        for (final e in effectiveResolution.provinceById.entries)
          if (e.value.ownerId == playerId) e.key,
      };
  final candidateValidator =
      sharedCandidateValidator ??
      buildIncrementalCandidateValidator(
        game: game,
        topology: topology,
        playerId: playerId,
        baseOrders: currentOrders,
        tileMapByRegion: tileMapByRegion,
        resolution: effectiveResolution,
        factionMembership: effectiveFactionMembership,
      );
  final world = game.worldState;
  final raw = WorkTileCandidateIndex(
    game: game,
    playerId: playerId,
    tileKeysByRegion: world.tileKeysByRegionAndProvince,
    resourceByTile: world.resourceByTileKey,
    purchasedTiles: world.purchasedTilesByTileKey,
    ownedProvinceIds: effectiveOwnedProvinceIds,
    tileMapByRegion: tileMapByRegion,
    factionMembership: effectiveFactionMembership,
  ).candidateTilesForWorkTarget(
    workTarget,
    exploreProvinceScope: applyExploreProvinceScope &&
            workTarget == kWorkTargetExplore
        ? partiallyRevealedPrefixedProvinceIdsForPlayer(game: game, view: view)
        : null,
  );

  return WorkOrderTileKeyProbe(
    unitId: unitId,
    workTarget: workTarget,
    reservedForPicker: devExclusiveReservedTileKeysForPlayer(
      game,
      currentOrders,
      playerId,
      ignorePendingWorkOrderUnitId: unitId,
    ),
    candidateValidator: candidateValidator,
    rawCandidateTileKeys: raw,
  );
}

Set<String> collectValidWorkOrderTileKeys({
  required WorkOrderTileKeyProbe probe,
  required Iterable<String> tileKeysToProbe,
}) {
  final valid = <String>{};
  for (final tileKey in tileKeysToProbe) {
    if (isDevExclusiveWorkTarget(probe.workTarget) &&
        probe.reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: probe.unitId,
      target: probe.workTarget,
      targetTileKey: tileKey,
    );
    if (isWorkOrderAcceptedWithValidator(probe.candidateValidator, candidate)) {
      valid.add(tileKey);
    }
  }
  return valid;
}
