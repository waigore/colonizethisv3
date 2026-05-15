library order_suggestion_work;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';
import 'bundled_civilian_work_order.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_work_tile_keys.dart';
import 'order_suggestion_work_tile_prefilter.dart';
import 'order_suggestion_context.dart';
import 'order_visibility.dart';
import 'work_suggestion_pipeline.dart';
import 'partial_province_reveal.dart';
import 'orders_application_helpers.dart';
import 'unit_type_helpers.dart';

part 'order_suggestion_work_explorer.dart';
part 'order_suggestion_work_worker.dart';
part 'order_suggestion_work_spy.dart';
part 'order_suggestion_work_merchant.dart';

/// Tile keys that are merchant purchase-land suggestion candidates for [game]:
/// tiles in provinces not owned by any [Game.players] entry that carry a
/// resource, excluding development-exclusive tiles.
///
/// Built once per [suggestWorkOrders] pass when any merchant unit is present so
/// each merchant does not rescan [allProvinces] (Refs #2394,
/// SPEC/program/order-suggestions.md).
List<String> merchantPurchaseLandCandidateTileKeys({
  required Game game,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> devExclusiveReservedTiles,
}) {
  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = {for (final p in game.players) p.id};
  final out = <String>[];
  for (final province in allProvinces(game.worldState)) {
    final ownerId = province.ownerId;
    if (ownerId == null || playerIds.contains(ownerId)) continue;
    final regionId = province.regionId;
    final tiles = tileKeysByRegion[regionId]?[province.id] ?? const <String>[];
    for (final tk in tiles) {
      if (resourceByTile[tk] == null) continue;
      if (devExclusiveReservedTiles.contains(tk)) continue;
      out.add(tk);
    }
  }
  return out;
}

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
  orderSuggestionLog.d('suggestWorkOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <WorkOrder>[];

  // Index existing work orders per unit to avoid suggesting duplicates (by unit + target).
  final existingTargetsByUnit = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingTargetsByUnit.putIfAbsent(o.unitId, () => <String>{}).add(o.target);
  }

  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final partiallyRevealedProvinceCache =
      partiallyRevealedPrefixedProvinceIdsForPlayer(game: game, view: view);
  final partiallyRevealedProvincesSorted =
      sortedProvincesForPartialRevealPrefixedIds(
        world: game.worldState,
        partiallyRevealedPrefixedProvinceIds: partiallyRevealedProvinceCache,
      );

  // Reuse [view.provincesById] (same full-id keys as [buildPlayerView]) instead
  // of a second [allProvinces] scan over world state (Refs #2394).
  final playerOwnedProvinceIds = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == playerId) e.key,
  };

  // Pre-filter + visibility sort per workTarget; reused across worker units.
  final visibleCandidatesSortedByWorkTarget = <String, List<String>>{};

  final devExclusiveReservedTiles = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
  );

  // One validator per suggestion pass: amortizes buildPlayerView + unit map
  // across all units (Refs #2394, IncrementalCandidateValidator.forPlayer).
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  final factionMembership = DiplomacyFactionMembership.from(game);
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

  for (final unit in view.ownUnits) {
    _addWorkSuggestionsForUnit(
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
      partiallyRevealedProvincesSorted: partiallyRevealedProvincesSorted,
      visibleCandidatesSortedByWorkTarget: visibleCandidatesSortedByWorkTarget,
      playerOwnedProvinceIds: playerOwnedProvinceIds,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      merchantPurchaseLandTileKeys: merchantPurchaseLandTileKeys,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
      factionMembership: factionMembership,
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

void _addWorkSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required Map<String, Set<String>> existingTargetsByUnit,
  required Set<String> partiallyRevealedProvinceCache,
  required List<Province> partiallyRevealedProvincesSorted,
  required Map<String, List<String>> visibleCandidatesSortedByWorkTarget,
  required Set<String> playerOwnedProvinceIds,
  required Set<String> devExclusiveReservedTiles,
  required List<String> merchantPurchaseLandTileKeys,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required DiplomacyFactionMembership factionMembership,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (unit.currentWork != null) return;

  final type = unit.type;
  final isExplorer = isExplorerUnit(type);
  final isWorker = isCivilianWorkerUnit(type);
  final isSpy = isSpyUnit(type);
  final isMerchant = isMerchantUnit(type);
  if (!isExplorer && !isWorker && !isSpy && !isMerchant) return;

  final regionId = regionIdForUnit(view, unit);
  final provinceId = unit.locationProvinceId;
  final province = view.provinceByRegionAndId(regionId, provinceId);
  final ownerId = province?.ownerId;
  final tilesInProvince = tileKeysByRegion[regionId]?[provinceId] ?? const [];

  if (isExplorer) {
    _addExplorerWorkSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      unit: unit,
      regionId: regionId,
      provinceId: provinceId,
      partiallyRevealedProvincesSorted: partiallyRevealedProvincesSorted,
      tileKeysByRegion: tileKeysByRegion,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
      tileMapByRegion: tileMapByRegion,
    );
    return;
  }

  if (isWorker) {
    _addWorkerSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      unit: unit,
      type: type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      existingTargetsByUnit: existingTargetsByUnit,
      visibleCandidatesSortedByWorkTarget: visibleCandidatesSortedByWorkTarget,
      playerOwnedProvinceIds: playerOwnedProvinceIds,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
      tileMapByRegion: tileMapByRegion,
      factionMembership: factionMembership,
    );
  }

  if (isSpy && tilesInProvince.isNotEmpty) {
    _addSpySuggestionsForUnit(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileKeysByRegion: tileKeysByRegion,
      playerId: playerId,
      unit: unit,
      type: type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      ownerId: ownerId,
      tilesInProvince: tilesInProvince,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
    );
  }

  if (isMerchant) {
    _addMerchantSuggestionsForUnit(
      unit: unit,
      type: type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      existingTargetsByUnit: existingTargetsByUnit,
      purchaseLandCandidateTileKeys: merchantPurchaseLandTileKeys,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
    );
  }
}
