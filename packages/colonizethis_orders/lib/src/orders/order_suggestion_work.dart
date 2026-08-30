library order_suggestion_work;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_helpers.dart';
import 'order_suggestion_pass_context.dart';
import 'order_suggestion_work_merchant_candidates.dart';
import 'order_suggestion_work_unit_loop.dart';
import 'connectivity_dev_snapshot.dart';
import 'unit_type_helpers.dart';
import 'work_suggestion_pipeline.dart';
import 'partial_province_reveal.dart';

export 'order_suggestion_work_merchant_candidates.dart'
    show merchantPurchaseLandCandidateTileKeys;

/// Suggests candidate work orders for explorers and civilian workers owned by
/// [view.playerId]. Worker units (Builder, Engineer, Rail Builder): at least
/// one suggestion per (unit, allowed target) when any **player-controlled** tile
/// (owned or purchased) is valid under visibility and the order engine — same
/// scope as work-order validation, not limited to the unit’s current province.
/// Explorers/Spies/Merchants follow type-specific rules. Visibility per
/// SPEC/program/fog-and-exploration-resolution.md.
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders, tileMapByRegion)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394,
/// `SPEC/program/order-suggestions.md` § Throughput bounds). When omitted, this
/// function constructs its own validator. The shared instance must be built
/// with the same inputs; observable suggestions must match the default path.
List<WorkOrder> suggestWorkOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestWorkOrders',
    tileMapByRegion: tileMapByRegion,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final playerId = pass.playerId;
  final suggestions = <WorkOrder>[];
  final factionMembership = pass.factionMembership;
  final candidateValidator = pass.candidateValidator;

  // Index existing work orders per unit to avoid suggesting duplicates (by unit + target).
  final existingTargetsByUnit = indexExistingTargetsByEntityId(
    currentOrders.workOrdersByPlayerId[playerId],
    (o) => o.unitId,
    (o) => o.target,
  );

  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final partiallyRevealedProvinceCache =
      partiallyRevealedPrefixedProvinceIdsForPlayer(game: game, view: view);
  final partiallyRevealedProvincesSorted =
      sortedProvincesForPartialRevealPrefixedIds(
        view: view,
        partiallyRevealedPrefixedProvinceIds: partiallyRevealedProvinceCache,
      );
  final colonialIntelExploreProvinceIds = colonialIntelExploreProvinceIdsSorted(
    view: view,
    topology: topology,
  ).toSet();
  final explorerProvincesSorted = explorerProvincesSortedForWork(
    view: view,
    partiallyRevealedProvincesSorted: partiallyRevealedProvincesSorted,
    colonialIntelExploreProvinceIds: colonialIntelExploreProvinceIds,
  );

  final playerOwnedProvinceIds = ownedProvinceIdsFromView(view, playerId);

  // Pre-filter + visibility sort per workTarget; reused across worker units.
  final visibleCandidatesSortedByWorkTarget = <String, List<String>>{};

  final devExclusiveReservedTiles = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
  );

  var needsMerchantPurchaseLandTileIndex = false;
  for (final unit in view.ownUnits) {
    if (unit.currentWork != null) continue;
    if (isMerchantUnit(unit.type)) {
      needsMerchantPurchaseLandTileIndex = true;
      break;
    }
  }
  final merchantPurchaseLandTileKeys = needsMerchantPurchaseLandTileIndex
      ? merchantPurchaseLandCandidateTileKeys(
          game: game,
          tileKeysByRegion: tileKeysByRegion,
          devExclusiveReservedTiles: devExclusiveReservedTiles,
        )
      : const <String>[];

  final workProbeBudget = WorkSuggestionProbeBudget();

  final connectivityDev = buildConnectivityDevSnapshot(
    game: game,
    playerId: playerId,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );

  for (final unit in view.ownUnits) {
    addWorkSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      tileKeysByRegion: tileKeysByRegion,
      playerId: playerId,
      unit: unit,
      existingTargetsByUnit: existingTargetsByUnit,
      partiallyRevealedProvinceCache: partiallyRevealedProvinceCache,
      partiallyRevealedProvincesSorted: explorerProvincesSorted,
      colonialIntelExploreProvinceIds: colonialIntelExploreProvinceIds,
      visibleCandidatesSortedByWorkTarget: visibleCandidatesSortedByWorkTarget,
      playerOwnedProvinceIds: playerOwnedProvinceIds,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      merchantPurchaseLandTileKeys: merchantPurchaseLandTileKeys,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
      factionMembership: factionMembership,
      workProbeBudget: workProbeBudget,
      connectivityDev: connectivityDev,
    );
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    final targetCmp = a.target.compareTo(b.target);
    if (targetCmp != 0) return targetCmp;
    return a.targetTileKey.compareTo(b.targetTileKey);
  });

  orderSuggestionLog.d(
    'suggestWorkOrders player=$playerId candidates=${suggestions.length}',
  );
  final uniqueUnits = suggestions.map((o) => o.unitId).toSet().length;
  orderSuggestionLog.d(
    'suggestWorkOrders summary player=$playerId '
    'candidates=${suggestions.length} uniqueUnits=$uniqueUnits',
  );
  if (suggestions.isEmpty) {
    orderSuggestionLog.w('suggestWorkOrders no candidates player=$playerId');
  }
  return suggestions;
}
