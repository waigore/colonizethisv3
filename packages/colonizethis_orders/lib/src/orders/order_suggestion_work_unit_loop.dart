import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_suggestion_work_explorer.dart';
import 'order_suggestion_work_merchant.dart';
import 'order_suggestion_work_spy.dart';
import 'order_suggestion_work_worker.dart';
import 'connectivity_dev_snapshot.dart';
import 'order_visibility.dart';
import 'unit_type_helpers.dart';
import 'work_suggestion_pipeline.dart';

/// Colonial intel NW provinces first, then partially revealed (deduped).
List<Province> explorerProvincesSortedForWork({
  required PlayerView view,
  required List<Province> partiallyRevealedProvincesSorted,
  required Set<String> colonialIntelExploreProvinceIds,
}) {
  if (colonialIntelExploreProvinceIds.isEmpty) {
    return partiallyRevealedProvincesSorted;
  }
  final seen = <String>{};
  final out = <Province>[];
  for (final id in colonialIntelExploreProvinceIds.toList()..sort()) {
    if (!seen.add(id)) continue;
    final p = view.provincesById[id];
    if (p != null) out.add(p);
  }
  for (final p in partiallyRevealedProvincesSorted) {
    if (seen.add(p.id)) out.add(p);
  }
  return out;
}

void addWorkSuggestionsForUnit({
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
  required Set<String> colonialIntelExploreProvinceIds,
  required Map<String, List<String>> visibleCandidatesSortedByWorkTarget,
  required Set<String> playerOwnedProvinceIds,
  required Set<String> devExclusiveReservedTiles,
  required List<String> merchantPurchaseLandTileKeys,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required DiplomacyFactionMembership factionMembership,
  required WorkSuggestionProbeBudget workProbeBudget,
  Map<String, TileMapResult>? tileMapByRegion,
  ConnectivityDevSnapshot? connectivityDev,
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
    addExplorerWorkSuggestionsForUnit(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      unit: unit,
      regionId: regionId,
      provinceId: provinceId,
      partiallyRevealedProvincesSorted: partiallyRevealedProvincesSorted,
      colonialIntelExploreProvinceIds: colonialIntelExploreProvinceIds,
      tileKeysByRegion: tileKeysByRegion,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
      tileMapByRegion: tileMapByRegion,
      workProbeBudget: workProbeBudget,
    );
    return;
  }

  if (isWorker) {
    addWorkerSuggestionsForUnit(
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
      workProbeBudget: workProbeBudget,
      connectivityDev: connectivityDev,
    );
  }

  if (isSpy && tilesInProvince.isNotEmpty) {
    addSpySuggestionsForUnit(
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
      workProbeBudget: workProbeBudget,
    );
  }

  if (isMerchant) {
    addMerchantSuggestionsForUnit(
      unit: unit,
      type: type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      existingTargetsByUnit: existingTargetsByUnit,
      purchaseLandCandidateTileKeys: merchantPurchaseLandTileKeys,
      suggestions: suggestions,
      candidateValidator: candidateValidator,
      workProbeBudget: workProbeBudget,
    );
  }
}
