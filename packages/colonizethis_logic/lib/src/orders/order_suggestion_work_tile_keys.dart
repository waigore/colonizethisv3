import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'incremental_candidate_validator.dart';
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
  /// Optional units index; must match [game.worldState] when supplied.
  Map<String, Unit>? unitsById,
  /// Optional faction snapshot; must match [game] when supplied.
  DiplomacyFactionMembership? factionMembership,
  /// When non-null, must match `(game, topology, playerId, currentOrders, …)`.
  IncrementalCandidateValidator? sharedCandidateValidator,
  /// When non-null, must match [view.provincesById] owned by [playerId].
  Set<String>? playerOwnedProvinceIds,
}) {
  final unit = game.worldState.tryGetUnitById(unitId);
  if (unit == null || unit.ownerId != playerId) return {};
  if (unit.currentWork != null) return {};
  if (playerHasPendingWorkOrderForUnit(currentOrders, playerId, unitId)) {
    return {};
  }
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) return {};

  assert(
    view == null || view.playerId == playerId,
    'view.playerId must match playerId',
  );
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match playerId',
  );

  final reservedForPicker = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
    ignorePendingWorkOrderUnitId: unitId,
  );

  // One PlayerView + validator per call unless the caller supplies shared
  // snapshots for multi-unit panel enumeration (Refs #2394).
  final effectiveView = view ?? buildPlayerView(game, topology, playerId);
  final effectiveFactionMembership =
      sharedCandidateValidator?.factionMembershipSnapshot ??
      factionMembership ??
      DiplomacyFactionMembership.from(game);
  final effectiveUnitsById = unitsById ?? unitsByIdFromWorld(game.worldState);
  final effectiveOwnedProvinceIds =
      playerOwnedProvinceIds ??
      <String>{
        for (final e in effectiveView.provincesById.entries)
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
        view: effectiveView,
        unitsById: effectiveUnitsById,
        factionMembership: effectiveFactionMembership,
      );
  final raw = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    tileMapByRegion: tileMapByRegion,
    playerOwnedProvinceIds: effectiveOwnedProvinceIds,
    factionMembership: effectiveFactionMembership,
  );
  final valid = <String>{};
  for (final tileKey in raw) {
    if (isDevExclusiveWorkTarget(workTarget) &&
        reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: workTarget,
      targetTileKey: tileKey,
    );
    if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
      valid.add(tileKey);
    }
  }
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

  /// When non-null, must match ids from [view.provincesById] owned by the player.
  /// Callers that invoke this many times per pass should supply a shared set to
  /// avoid O(calls × provinces) [allProvinces] rescans (Refs #2394).
  Set<String>? playerOwnedProvinceIds,
}) {
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == view.playerId,
  );
  final unit = game.worldState.tryGetUnitById(unitId);
  if (unit == null || unit.ownerId != view.playerId) {
    return {};
  }
  if (unit.currentWork != null) {
    return {};
  }
  if (playerHasPendingWorkOrderForUnit(currentOrders, view.playerId, unitId)) {
    return {};
  }
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) {
    return {};
  }

  final playerId = view.playerId;

  final reservedForPicker = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
    ignorePendingWorkOrderUnitId: unitId,
  );

  final factionMembership = sharedCandidateValidator?.factionMembershipSnapshot ??
      DiplomacyFactionMembership.from(game);
  final ownedProvinceIds = playerOwnedProvinceIds ??
      <String>{
        for (final e in view.provincesById.entries)
          if (e.value.ownerId == playerId) e.key,
      };
  final raw = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    exploreProvinceScope: workTarget == kWorkTargetExplore
        ? partiallyRevealedPrefixedProvinceIdsForPlayer(game: game, view: view)
        : null,
    tileMapByRegion: tileMapByRegion,
    playerOwnedProvinceIds: ownedProvinceIds,
    factionMembership: factionMembership,
  );
  final sortedVisible = sortedVisibleWorkTargetCandidates(view, raw);
  final candidateValidator =
      sharedCandidateValidator ??
      buildIncrementalCandidateValidator(
        game: game,
        topology: topology,
        playerId: playerId,
        baseOrders: currentOrders,
        tileMapByRegion: tileMapByRegion,
        factionMembership: factionMembership,
      );

  final valid = <String>{};
  for (final tileKey in sortedVisible) {
    if (isDevExclusiveWorkTarget(workTarget) &&
        reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: workTarget,
      targetTileKey: tileKey,
    );
    if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
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
