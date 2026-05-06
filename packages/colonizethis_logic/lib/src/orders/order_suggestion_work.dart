library order_suggestion_work;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';
import 'bundled_civilian_work_order.dart';
import 'order_suggestion_build_research.dart';
import 'order_suggestion_context.dart';
import 'order_visibility.dart';
import 'partial_province_reveal.dart';
import 'orders_application_helpers.dart';
import 'unit_type_helpers.dart';

part 'order_suggestion_work_explorer.dart';
part 'order_suggestion_work_worker.dart';
part 'order_suggestion_work_spy.dart';
part 'order_suggestion_work_merchant.dart';

void _suggestionWorkLog({
  required String unitId,
  required String unitType,
  required String unitRegionId,
  required String atProvinceId,
  required String workTarget,
  required String outcome,
  String reason = '-',
  String tile = '-',
}) {
  orderSuggestionLog.d(
    'suggest_work unitId=$unitId unitType=$unitType region=$unitRegionId '
    'at=$atProvinceId target=$workTarget outcome=$outcome reason=$reason tile=$tile',
  );
}

/// Suggests candidate work orders for explorers and civilian workers owned by
/// [view.playerId]. Worker units (Builder, Engineer, Rail Builder): at least
/// one suggestion per (unit, allowed target) when any **player-controlled** tile
/// (owned or purchased) is valid under visibility and the order engine — same
/// scope as work-order validation, not limited to the unit’s current province.
/// Explorers/Spies/Merchants follow type-specific rules. Visibility per
/// SPEC/program/fog-and-exploration-resolution.md.
List<WorkOrder> suggestWorkOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
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
      _partiallyRevealedProvinceCacheForPlayer(game: game, view: view);

  // Pre-filter + visibility sort per workTarget; reused across worker units.
  final visibleCandidatesSortedByWorkTarget = <String, List<String>>{};

  final devExclusiveReservedTiles = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
  );

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
      visibleCandidatesSortedByWorkTarget: visibleCandidatesSortedByWorkTarget,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
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
  const previewCap = 40;
  if (suggestions.isEmpty) {
    orderSuggestionLog.d('suggestWorkOrders detail preview empty');
  } else {
    final preview = suggestions
        .take(previewCap)
        .map((o) => '${o.unitId}:${o.target}')
        .join(', ');
    final truncated = suggestions.length > previewCap
        ? ' (+${suggestions.length - previewCap} more truncated)'
        : '';
    orderSuggestionLog.d(
      'suggestWorkOrders detail preview first_$previewCap=$preview$truncated',
    );
  }
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
  required Map<String, List<String>> visibleCandidatesSortedByWorkTarget,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
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

  orderSuggestionLog.d(
    'suggestWorkOrders unit=${unit.id} provinceId=$provinceId provinceName=${province?.displayName} ownerId=$ownerId regionId=$regionId tilesInProvince=${tilesInProvince.length}',
  );

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
      partiallyRevealedProvinceCache: partiallyRevealedProvinceCache,
      tileKeysByRegion: tileKeysByRegion,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
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
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
      tileMapByRegion: tileMapByRegion,
    );
  }

  if (isSpy && tilesInProvince.isNotEmpty) {
    _addSpySuggestionsForUnit(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
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
    );
  }

  if (isMerchant) {
    _addMerchantSuggestionsForUnit(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      tileKeysByRegion: tileKeysByRegion,
      playerId: playerId,
      unit: unit,
      type: type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      existingTargetsByUnit: existingTargetsByUnit,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
      suggestions: suggestions,
    );
  }
}
