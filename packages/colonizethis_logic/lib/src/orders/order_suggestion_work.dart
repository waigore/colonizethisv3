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

Set<String> _partiallyRevealedProvinceCacheForPlayer({
  required Game game,
  required PlayerView view,
}) {
  final cached = <String>{};
  for (final regionEntry
      in game.worldState.tileKeysByRegionAndProvince.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (!isPartiallyRevealedProvinceLandTilesForPlayer(
        view,
        provinceEntry.value,
      )) {
        continue;
      }
      cached.add(provinceId);
    }
  }
  return cached;
}

({WorkOrder? chosen, String lastReason}) _tryExploreWorkOrderForProvince({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required Province prov,
  required Map<String, Unit> unitsById,
  required List<DiplomaticOrder> diplomatic,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final regionIdP = prov.regionId;
  final provinceIdFull = prov.id;
  final tilesInP =
      tileKeysByRegion[regionIdP]?[provinceIdFull] ?? const <String>[];
  if (tilesInP.isEmpty) {
    return (chosen: null, lastReason: 'no_valid_tile');
  }
  final sortedTilesInP = List<String>.from(tilesInP)..sort();
  final targetTileKey = sortedTilesInP.firstWhere(
    (tk) => view.visibilityForTile(tk) != VisibilityLevel.unknown,
    orElse: () => sortedTilesInP.first,
  );

  if (!workOrderVisibilityOk(
    view,
    unit,
    kWorkTargetExplore,
    targetTileKey: targetTileKey,
    worldState: game.worldState,
  )) {
    return (chosen: null, lastReason: 'visibility');
  }
  if (!provinceHasAtLeastVisibility(
    view,
    regionIdP,
    provinceIdFull,
    VisibilityLevel.fogged,
  )) {
    return (chosen: null, lastReason: 'visibility');
  }
  if (!exploreProvinceStillUsefulFromAuthoritativeTiles(view, tilesInP)) {
    return (chosen: null, lastReason: 'not_applicable');
  }
  final probe = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetExplore,
    targetTileKey: targetTileKey,
  );
  if (civilianBundledWorkNeedsProvinceMoveLeg(game, unit, probe)) {
    final bundled = validateCivilianBundledWorkMoveLeg(
      game: game,
      topology: topology,
      playerId: playerId,
      unit: unit,
      order: probe,
      view: view,
      unitsById: unitsById,
      diplomaticOrders: diplomatic,
    );
    if (!bundled.isAccepted) {
      return (chosen: null, lastReason: bundled.reason ?? 'no_single_hop');
    }
  }
  final candidate = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetExplore,
    targetTileKey: targetTileKey,
  );
  if (isWorkOrderAccepted(
    game,
    topology,
    playerId,
    currentOrders,
    candidate,
    tileMapByRegion: tileMapByRegion,
  )) {
    return (chosen: candidate, lastReason: '');
  }
  return (chosen: null, lastReason: 'engine_rejected');
}

void _addExplorerWorkSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required Set<String> partiallyRevealedProvinceCache,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final unitsById = Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));
  final diplomatic =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ?? const [];

  final existing = existingTargetsByUnit[unit.id];
  if (existing != null && existing.contains(kWorkTargetExplore)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: unit.type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      workTarget: kWorkTargetExplore,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
  } else {
    final provinces =
        allProvinces(
            game.worldState,
          ).where((p) => partiallyRevealedProvinceCache.contains(p.id)).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    WorkOrder? chosen;
    var lastReason = 'no_valid_tile';
    for (final prov in provinces) {
      final attempt = _tryExploreWorkOrderForProvince(
        view: view,
        game: game,
        topology: topology,
        currentOrders: currentOrders,
        playerId: playerId,
        unit: unit,
        prov: prov,
        unitsById: unitsById,
        diplomatic: diplomatic,
        tileKeysByRegion: tileKeysByRegion,
        tileMapByRegion: tileMapByRegion,
      );
      if (attempt.chosen != null) {
        chosen = attempt.chosen;
        break;
      }
      lastReason = attempt.lastReason;
    }
    if (chosen != null) {
      suggestions.add(chosen);
      existingTargetsByUnit
          .putIfAbsent(unit.id, () => <String>{})
          .add(kWorkTargetExplore);
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: unit.type,
        unitRegionId: regionId,
        atProvinceId: provinceId,
        workTarget: kWorkTargetExplore,
        outcome: 'included',
        tile: chosen.targetTileKey,
      );
    } else {
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: unit.type,
        unitRegionId: regionId,
        atProvinceId: provinceId,
        workTarget: kWorkTargetExplore,
        outcome: 'excluded',
        reason: lastReason,
      );
    }
  }

  _addProspectSuggestionIfEligible(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    playerId: playerId,
    unit: unit,
    regionId: regionId,
    provinceId: provinceId,
    tileKeysByRegion: tileKeysByRegion,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    tileMapByRegion: tileMapByRegion,
  );
}

({String? tileKey, String lastReason}) _firstAcceptedProspectTileInProvince({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required List<String> tilesInProvince,
  required Set<String> prospected,
  required Map<String, Unit> unitsById,
  required List<DiplomaticOrder> diplomaticOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  var lastReason = 'no_valid_tile';
  for (final tk in tilesInProvince) {
    if (prospected.contains(tk)) continue;
    if (!isMineralEligibleTile(game, tileMapByRegion, tk)) continue;
    final candidate = WorkOrder(
      unitId: unit.id,
      target: kWorkTargetProspect,
      targetTileKey: tk,
    );
    if (civilianBundledWorkNeedsProvinceMoveLeg(game, unit, candidate)) {
      final bundled = validateCivilianBundledWorkMoveLeg(
        game: game,
        topology: topology,
        playerId: playerId,
        unit: unit,
        order: candidate,
        view: view,
        unitsById: unitsById,
        diplomaticOrders: diplomaticOrders,
      );
      if (!bundled.isAccepted) {
        lastReason = bundled.reason ?? 'no_single_hop';
        continue;
      }
    }
    if (isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      return (tileKey: tk, lastReason: lastReason);
    }
    lastReason = 'engine_rejected';
  }
  return (tileKey: null, lastReason: lastReason);
}

void _addProspectSuggestionIfEligible({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final existingProspect = existingTargetsByUnit[unit.id];
  if (existingProspect != null &&
      existingProspect.contains(kWorkTargetProspect)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: unit.type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      workTarget: kWorkTargetProspect,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }

  final unitsById = Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));
  final diplomatic =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ?? const [];

  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  final provinces = allProvinces(game.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  String? prospectTileKey;
  var lastReason = 'no_valid_tile';
  for (final prov in provinces) {
    final regionIdP = prov.regionId;
    final provinceIdFull = prov.id;
    if (!provinceHasAtLeastVisibility(
      view,
      regionIdP,
      provinceIdFull,
      VisibilityLevel.fogged,
    )) {
      lastReason = 'visibility';
      continue;
    }
    final tilesInP =
        tileKeysByRegion[regionIdP]?[provinceIdFull] ?? const <String>[];
    if (tilesInP.isEmpty) {
      lastReason = 'no_valid_tile';
      continue;
    }
    final scan = _firstAcceptedProspectTileInProvince(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      playerId: playerId,
      unit: unit,
      tilesInProvince: tilesInP,
      prospected: prospected,
      unitsById: unitsById,
      diplomaticOrders: diplomatic,
      tileMapByRegion: tileMapByRegion,
    );
    lastReason = scan.lastReason;
    prospectTileKey = scan.tileKey;
    if (prospectTileKey != null) {
      break;
    }
  }
  if (prospectTileKey == null) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: unit.type,
      unitRegionId: regionId,
      atProvinceId: provinceId,
      workTarget: kWorkTargetProspect,
      outcome: 'excluded',
      reason: lastReason,
    );
    return;
  }

  final candidate = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetProspect,
    targetTileKey: prospectTileKey,
  );
  suggestions.add(candidate);
  existingTargetsByUnit
      .putIfAbsent(unit.id, () => <String>{})
      .add(kWorkTargetProspect);
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: unit.type,
    unitRegionId: regionId,
    atProvinceId: provinceId,
    workTarget: kWorkTargetProspect,
    outcome: 'included',
    tile: prospectTileKey,
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
  orderSuggestionLog.d(
    'suggestWorkOrders full list ${suggestions.map((o) => "${o.unitId}:${o.target}").toList()}',
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

void _addWorkerSuggestionsForUnit({
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
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  for (final target in allowedTargets) {
    final existing = existingTargetsByUnit[unit.id];
    if (existing != null && existing.contains(target)) {
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: type,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: target,
        outcome: 'excluded',
        reason: 'duplicate_pending',
      );
      continue;
    }

    final sortedVisible = visibleCandidatesSortedByWorkTarget.putIfAbsent(
      target,
      () {
        final raw = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: target,
          tileMapByRegion: tileMapByRegion,
        );
        return sortedVisibleWorkTargetCandidates(view, raw);
      },
    );

    final accepted = _firstAcceptedWorkerCandidate(
      game: game,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      playerId: playerId,
      unitId: unit.id,
      target: target,
      sortedVisibleTileKeys: sortedVisible,
      devExclusiveReservedTiles: devExclusiveReservedTiles,
    );
    if (accepted != null) {
      orderSuggestionLog.d('suggestWorkOrders candidate=$accepted');
      suggestions.add(accepted);
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: type,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: target,
        outcome: 'included',
        tile: accepted.targetTileKey,
      );
      continue;
    }

    final reason = sortedVisible.isEmpty ? 'no_valid_tile' : 'engine_rejected';
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: target,
      outcome: 'excluded',
      reason: reason,
    );
    orderSuggestionLog.d(
      'suggestWorkOrders rejected target=$target unit=${unit.id} (no valid tile)',
    );
  }
}

WorkOrder? _firstAcceptedWorkerCandidate({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required String unitId,
  required String target,
  required List<String> sortedVisibleTileKeys,
  required Set<String> devExclusiveReservedTiles,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  for (final tk in sortedVisibleTileKeys) {
    if (isDevExclusiveWorkTarget(target) &&
        devExclusiveReservedTiles.contains(tk)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: target,
      targetTileKey: tk,
    );
    if (isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      return candidate;
    }
  }
  return null;
}

void _addSpySuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required String? ownerId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  _addCounterSpySuggestionIfEligible(
    allowedTargets: allowedTargets,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    playerId: playerId,
    unit: unit,
    type: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    ownerId: ownerId,
    tilesInProvince: tilesInProvince,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    tileMapByRegion: tileMapByRegion,
  );

  if (!allowedTargets.contains(kWorkTargetStealTech)) return;
  final existingSteal = existingTargetsByUnit[unit.id];
  if (existingSteal != null && existingSteal.contains(kWorkTargetStealTech)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetStealTech,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }
  var sawStealCandidate = false;
  for (final other in game.players) {
    if (other.id == playerId || other.capitalProvinceId == null) continue;
    final capProvinceId = other.capitalProvinceId!;
    final capRegionId = ProvinceId.regionIdFrom(capProvinceId);
    final capTiles = tileKeysByRegion[capRegionId]?[capProvinceId] ?? const [];
    if (capTiles.isEmpty) continue;
    sawStealCandidate = true;
    final candidate = WorkOrder(
      unitId: unit.id,
      target: kWorkTargetStealTech,
      targetTileKey: capTiles.first,
    );
    if (isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      suggestions.add(candidate);
      existingTargetsByUnit
          .putIfAbsent(unit.id, () => <String>{})
          .add(kWorkTargetStealTech);
      _suggestionWorkLog(
        unitId: unit.id,
        unitType: type,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: kWorkTargetStealTech,
        outcome: 'included',
        tile: candidate.targetTileKey,
      );
      return;
    }
  }
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetStealTech,
    outcome: 'excluded',
    reason: sawStealCandidate ? 'engine_rejected' : 'no_valid_tile',
  );
}

void _addCounterSpySuggestionIfEligible({
  required List<String> allowedTargets,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required String? ownerId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (!allowedTargets.contains(kWorkTargetCounterSpy)) return;
  final existingCounterSpy = existingTargetsByUnit[unit.id];
  if (existingCounterSpy != null &&
      existingCounterSpy.contains(kWorkTargetCounterSpy)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }
  if (ownerId != playerId) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'excluded',
      reason: 'not_applicable',
    );
    return;
  }

  final candidate = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetCounterSpy,
    targetTileKey: tilesInProvince.first,
  );
  if (isWorkOrderAccepted(
    game,
    topology,
    playerId,
    currentOrders,
    candidate,
    tileMapByRegion: tileMapByRegion,
  )) {
    suggestions.add(candidate);
    existingTargetsByUnit
        .putIfAbsent(unit.id, () => <String>{})
        .add(kWorkTargetCounterSpy);
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'included',
      tile: candidate.targetTileKey,
    );
    return;
  }
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetCounterSpy,
    outcome: 'excluded',
    reason: 'engine_rejected',
  );
}

void _addMerchantSuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required Map<String, Set<String>> existingTargetsByUnit,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null ||
      !allowedTargets.contains(kWorkTargetPurchaseLand)) {
    return;
  }

  final existing = existingTargetsByUnit[unit.id];
  if (existing != null && existing.contains(kWorkTargetPurchaseLand)) {
    _suggestionWorkLog(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetPurchaseLand,
      outcome: 'excluded',
      reason: 'duplicate_pending',
    );
    return;
  }

  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = game.players.map((p) => p.id).toSet();
  var sawCandidate = false;
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
    final regionId = p.regionId;
    final tiles = tileKeysByRegion[regionId]?[p.id] ?? const [];
    for (final tk in tiles) {
      if (resourceByTile[tk] == null) continue;
      sawCandidate = true;
      if (devExclusiveReservedTiles.contains(tk)) continue;
      final candidate = WorkOrder(
        unitId: unit.id,
        target: kWorkTargetPurchaseLand,
        targetTileKey: tk,
      );
      if (isWorkOrderAccepted(
        game,
        topology,
        playerId,
        currentOrders,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )) {
        suggestions.add(candidate);
        existingTargetsByUnit
            .putIfAbsent(unit.id, () => <String>{})
            .add(kWorkTargetPurchaseLand);
        _suggestionWorkLog(
          unitId: unit.id,
          unitType: type,
          unitRegionId: unitRegionId,
          atProvinceId: atProvinceId,
          workTarget: kWorkTargetPurchaseLand,
          outcome: 'included',
          tile: candidate.targetTileKey,
        );
        return;
      }
    }
  }
  _suggestionWorkLog(
    unitId: unit.id,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetPurchaseLand,
    outcome: 'excluded',
    reason: sawCandidate ? 'engine_rejected' : 'no_valid_tile',
  );
}
