import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_helpers.dart';
import 'order_suggestion_work_tile_prefilter.dart';
import 'partial_province_reveal.dart';
import 'unit_type_helpers.dart';

/// Returns the set of tile keys that are valid targets for a work order
/// (unitId, workTarget) given [currentOrders]. Used by the app to highlight
/// valid tiles when the player is assigning work. SPEC/ui/civilian-units-panel.md.
Set<String> getValidWorkOrderTileKeys(
  Game game,
  MapTopology topology,
  String playerId,
  String unitId,
  String workTarget,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,

  /// When callers evaluate many tile highlights for the same player and
  /// [currentOrders], they may pass a shared [PlayerView] (Refs #2394).
  PlayerView? view,

  /// Optional pass snapshot; must match [game] when supplied.
  OrderResolutionContext? resolution,

  /// Optional faction snapshot; must match [game] when supplied.
  DiplomacyFactionMembership? factionMembership,

  /// When non-null, must match `(game, topology, playerId, currentOrders, …)`.
  IncrementalCandidateValidator? sharedCandidateValidator,

  /// When non-null, must match [view.provincesById] owned by [playerId].
  Set<String>? playerOwnedProvinceIds,
}) {
  assert(
    view == null || view.playerId == playerId,
    'view.playerId must match playerId',
  );
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match playerId',
  );

  final effectiveView = view ?? buildPlayerView(game, topology, playerId);
  final probe = _prepareWorkOrderTileKeyProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    view: effectiveView,
    unitId: unitId,
    workTarget: workTarget,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    playerOwnedProvinceIds: playerOwnedProvinceIds,
    applyExploreProvinceScope: false,
  );
  if (probe == null) return const {};

  final valid = _collectValidWorkOrderTileKeys(
    probe: probe,
    tileKeysToProbe: probe.rawCandidateTileKeys,
  );
  orderSuggestionLog.d(
    'getValidWorkOrderTileKeys unit=$unitId target=$workTarget count=${valid.length}',
  );
  return valid;
}

/// Returns the set of tile keys that are valid targets for a work order,
/// filtering by work-target-specific criteria and visibility BEFORE calling
/// the order engine for efficiency.
///
/// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.
///
/// When [sharedCandidateValidator] is non-null, it must have been built for the
/// same `game`, `topology`, `view.playerId`, `currentOrders`, and
/// `tileMapByRegion` as this call (amortizes [buildPlayerView] / validator setup
/// across multi-unit enumeration; Refs #2394).
Set<String> getValidWorkOrderTileKeysWithVisibility({
  required Game game,
  required MapTopology topology,
  required PlayerView view,
  required String unitId,
  required String workTarget,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,

  /// Optional pass snapshot; must match [game] when supplied.
  OrderResolutionContext? resolution,

  /// When non-null, must match ids from [view.provincesById] owned by the player.
  /// Callers that invoke this many times per pass should supply a shared set to
  /// avoid O(calls × provinces) [allProvinces] rescans (Refs #2394).
  Set<String>? playerOwnedProvinceIds,
}) {
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == view.playerId,
  );

  final probe = _prepareWorkOrderTileKeyProbe(
    game: game,
    topology: topology,
    playerId: view.playerId,
    view: view,
    unitId: unitId,
    workTarget: workTarget,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    sharedCandidateValidator: sharedCandidateValidator,
    playerOwnedProvinceIds: playerOwnedProvinceIds,
    applyExploreProvinceScope: true,
  );
  if (probe == null) return const {};

  return _collectValidWorkOrderTileKeys(
    probe: probe,
    tileKeysToProbe: sortedVisibleWorkTargetCandidates(
      view,
      probe.rawCandidateTileKeys,
    ),
  );
}

class _WorkOrderTileKeyProbe {
  const _WorkOrderTileKeyProbe({
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

_WorkOrderTileKeyProbe? _prepareWorkOrderTileKeyProbe({
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
  final raw = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    exploreProvinceScope: applyExploreProvinceScope &&
            workTarget == kWorkTargetExplore
        ? partiallyRevealedPrefixedProvinceIdsForPlayer(game: game, view: view)
        : null,
    tileMapByRegion: tileMapByRegion,
    playerOwnedProvinceIds: effectiveOwnedProvinceIds,
    factionMembership: effectiveFactionMembership,
  );

  return _WorkOrderTileKeyProbe(
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

Set<String> _collectValidWorkOrderTileKeys({
  required _WorkOrderTileKeyProbe probe,
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

List<String> sortedVisibleWorkTargetCandidates(
  PlayerView view,
  Set<String> rawCandidates,
) {
  final list = <String>[];
  for (final tk in rawCandidates) {
    final visibility = view.visibilityForTile(tk);
    if (visibility == VisibilityLevel.fullyVisible ||
        visibility == VisibilityLevel.fogged) {
      list.add(tk);
    }
  }
  list.sort();
  return list;
}
