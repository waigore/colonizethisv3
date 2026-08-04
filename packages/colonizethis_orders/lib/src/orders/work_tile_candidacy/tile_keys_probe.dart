import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../incremental_candidate_validator.dart';
import '../order_resolution_context.dart';
import '../order_suggestion_context.dart';
import '../order_suggestion_helpers.dart';
import '../order_work_constants.dart';
import '../unit_type_helpers.dart';
import 'work_tile_candidate_index.dart';
import 'work_order_tile_key_probe.dart';

// Work-tile candidate index and tile-keys probe API.
// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.

Set<String> rawCandidateTilesForWorkTarget({
  required Game game,
  required String playerId,
  required String workTarget,
  Set<String>? exploreProvinceScope,
  Map<String, TileMapResult>? tileMapByRegion,

  /// When non-null, must match the ids of provinces owned by [playerId] (same
  /// as the default path, which reads them from [ProvinceOwnerCache]). Callers
  /// that invoke this repeatedly in one suggestion pass should supply a shared
  /// set to avoid O(targets × provinces) rescans (Refs #2394).
  Set<String>? playerOwnedProvinceIds,

  /// When non-null, [kWorkTargetPurchaseLand] prefilter reuses this snapshot
  /// instead of calling [DiplomacyFactionMembership.from] again (Refs #2394 —
  /// same pass often already built membership for incremental validation).
  DiplomacyFactionMembership? factionMembership,
}) {
  final world = game.worldState;
  final ownedProvinceIds =
      playerOwnedProvinceIds ??
      <String>{
        for (final p in ProvinceOwnerCache.of(world).provincesOwnedBy(playerId))
          p.id,
      };
  return WorkTileCandidateIndex(
    game: game,
    playerId: playerId,
    tileKeysByRegion: world.tileKeysByRegionAndProvince,
    resourceByTile: world.resourceByTileKey,
    purchasedTiles: world.purchasedTilesByTileKey,
    ownedProvinceIds: ownedProvinceIds,
    tileMapByRegion: tileMapByRegion,
    factionMembership: factionMembership,
  ).candidateTilesForWorkTarget(
    workTarget,
    exploreProvinceScope: exploreProvinceScope,
  );
}

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
  final probe = prepareWorkOrderTileKeyProbe(
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

  final valid = collectValidWorkOrderTileKeys(
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

  final probe = prepareWorkOrderTileKeyProbe(
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

  return collectValidWorkOrderTileKeys(
    probe: probe,
    tileKeysToProbe: sortedVisibleWorkTargetCandidates(
      view,
      probe.rawCandidateTileKeys,
    ),
  );
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
