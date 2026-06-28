import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'bundled_civilian_work_order.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_visibility.dart';
import 'order_work_constants.dart';
import 'orders_application_helpers.dart';
import 'work_suggestion_pipeline.dart';

({WorkOrder? chosen, String lastReason}) _tryExploreWorkOrderForProvince({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required Province prov,
  required OrderResolutionContext resolution,
  required List<DiplomaticOrder> diplomatic,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required IncrementalCandidateValidator candidateValidator,
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
      resolution: resolution,
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
  if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
    return (chosen: candidate, lastReason: '');
  }
  return (chosen: null, lastReason: 'engine_rejected');
}

void addExplorerWorkSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String regionId,
  required String provinceId,
  required List<Province> partiallyRevealedProvincesSorted,
  required Set<String> colonialIntelExploreProvinceIds,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final resolution = orderResolutionContextFromView(view, game);
  final diplomatic =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ?? const [];

  final pendingOrClaimed = existingTargetsByUnit[unit.id];
  if (pendingOrClaimed != null && pendingOrClaimed.isNotEmpty) {
    for (final target in [kWorkTargetExplore, kWorkTargetProspect]) {
      logWorkOrderSuggestion(
        unitId: unit.id,
        unitType: unit.type,
        unitRegionId: regionId,
        atProvinceId: provinceId,
        workTarget: target,
        outcome: 'excluded',
        reason: 'duplicate_pending',
      );
    }
    return;
  }

  final provinces = partiallyRevealedProvincesSorted;
  var lastReason = 'no_valid_tile';
  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: unit.type,
    unitRegionId: regionId,
    atProvinceId: provinceId,
    workTarget: kWorkTargetExplore,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    candidatesProvider: () sync* {
      var provinceProbes = 0;
      for (final prov in provinces) {
        provinceProbes++;
        if (provinceProbes > kMaxExploreProvinceProbesPerUnit) {
          break;
        }
        final attempt = _tryExploreWorkOrderForProvince(
          view: view,
          game: game,
          topology: topology,
          currentOrders: currentOrders,
          playerId: playerId,
          unit: unit,
          prov: prov,
          resolution: resolution,
          diplomatic: diplomatic,
          tileKeysByRegion: tileKeysByRegion,
          candidateValidator: candidateValidator,
          tileMapByRegion: tileMapByRegion,
        );
        if (attempt.chosen != null) {
          yield attempt.chosen!;
        } else {
          lastReason = attempt.lastReason;
        }
      }
    },
    candidateAcceptor: (_) => true,
    noCandidateReason: 'no_valid_tile',
    resolveNoCandidateReason: () => lastReason,
    includeAllAccepted: true,
    probeBudget: workProbeBudget,
  );

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
    candidateValidator: candidateValidator,
    workProbeBudget: workProbeBudget,
    resolution: resolution,
    tileMapByRegion: tileMapByRegion,
  );
}

/// Every engine-valid prospect tile in [tilesInProvince], in sorted tile order.
/// [lastReason] is the last rejection reason when the list is empty.
({List<String> tiles, String lastReason}) _allAcceptedProspectTilesInProvince({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required List<String> tilesInProvince,
  required Set<String> prospected,
  required OrderResolutionContext resolution,
  required List<DiplomaticOrder> diplomaticOrders,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
  Map<String, TileMapResult>? tileMapByRegion,

  /// When `false`, this province's tile probes are exempt from the shared
  /// per-pass [WorkSuggestionProbeBudget] — used for the Explorer's **own**
  /// (current) province so a co-located owned mineral prospect candidate is
  /// never starved by earlier units' explore/prospect probes draining the
  /// shared budget (Refs #2847 § Old World mineral feedstock prospect
  /// localization). The per-province [kMaxWorkProbeAttemptsPerUnitPerTarget]
  /// cap still bounds the probe count.
  bool consumeSharedBudget = true,
}) {
  var lastReason = 'no_valid_tile';
  final sortedTiles = List<String>.from(tilesInProvince)..sort();
  final accepted = <String>[];
  final needsProvinceMoveLeg =
      sortedTiles.isNotEmpty &&
      civilianBundledWorkNeedsProvinceMoveLeg(
        game,
        unit,
        WorkOrder(
          unitId: unit.id,
          target: kWorkTargetProspect,
          targetTileKey: sortedTiles.first,
        ),
      );
  if (needsProvinceMoveLeg) {
    final bundled = validateCivilianBundledWorkMoveLeg(
      game: game,
      topology: topology,
      playerId: playerId,
      unit: unit,
      order: WorkOrder(
        unitId: unit.id,
        target: kWorkTargetProspect,
        targetTileKey: sortedTiles.first,
      ),
      resolution: resolution,
      diplomaticOrders: diplomaticOrders,
    );
    if (!bundled.isAccepted) {
      return (
        tiles: const <String>[],
        lastReason: bundled.reason ?? 'no_single_hop',
      );
    }
  }
  // Own-province prospect probes are exempt from the shared per-pass budget
  // ([consumeSharedBudget] false) and must not be capped at
  // [kMaxWorkProbeAttemptsPerUnitPerTarget] when other accepted mineral tiles in
  // the same province sort earlier — otherwise a co-located feedstock `iron`
  // tile never reaches the suggestion list (Refs #2847).
  final maxTileProbes = consumeSharedBudget
      ? kMaxWorkProbeAttemptsPerUnitPerTarget
      : sortedTiles.length;
  var probeAttempts = 0;
  for (final tk in sortedTiles) {
    probeAttempts++;
    if (probeAttempts > maxTileProbes) {
      break;
    }
    if (prospected.contains(tk)) continue;
    if (!isMineralEligibleTile(game, tileMapByRegion, tk)) continue;
    final candidate = WorkOrder(
      unitId: unit.id,
      target: kWorkTargetProspect,
      targetTileKey: tk,
    );
    if (consumeSharedBudget && !workProbeBudget.consume()) {
      break;
    }
    if (isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
      accepted.add(tk);
    } else {
      lastReason = 'engine_rejected';
    }
  }
  return (tiles: accepted, lastReason: lastReason);
}

/// Provinces scanned for `prospect` candidates, with [unit]'s
/// [Unit.locationProvinceId] first so the [kMaxExploreProvinceProbesPerUnit]
/// cap still reaches a co-located mineral tile on large maps (Refs #2847).
List<Province> _prospectProvincesSortedForExplorer({
  required PlayerView view,
  required Unit unit,
}) {
  final provinces = view.provincesById.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final at = unit.locationProvinceId;
  if (at.isEmpty) return provinces;
  final atProv = view.provincesById[at];
  if (atProv == null) return provinces;
  return [atProv, ...provinces.where((p) => p.id != at)];
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
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
  required OrderResolutionContext resolution,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  // Early bail mirrors [WorkSuggestionPipeline]'s duplicate-pending check so we
  // skip the per-unit `unitsByIdFromWorld` / province snapshot setup below
  // when this explorer already has a pending `prospect` order this turn.
  // The pipeline would log the same `duplicate_pending` line if reached.
  final existingProspect = existingTargetsByUnit[unit.id];
  if (existingProspect != null &&
      existingProspect.contains(kWorkTargetProspect)) {
    logWorkOrderSuggestion(
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

  final diplomatic =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ?? const [];

  final prospected = game.worldState.prospectedTilesForPlayer(playerId);
  // [buildPlayerView] already aggregates every province row into
  // [PlayerView.provincesById]; reuse that snapshot instead of scanning
  // [allProvinces] again for each explorer prospect probe (Refs #2394,
  // SPEC/program/order-suggestions.md). Probe the explorer's current province
  // first so [kMaxExploreProvinceProbesPerUnit] still reaches co-located
  // mineral tiles on seed-scale maps (Refs #2847).
  final provinces = _prospectProvincesSortedForExplorer(view: view, unit: unit);
  final atProvinceFullId = unit.locationProvinceId;

  var lastReason = 'no_valid_tile';
  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: unit.type,
    unitRegionId: regionId,
    atProvinceId: provinceId,
    workTarget: kWorkTargetProspect,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    candidatesProvider: () sync* {
      var provinceProbes = 0;
      for (final prov in provinces) {
        provinceProbes++;
        if (provinceProbes > kMaxExploreProvinceProbesPerUnit) {
          break;
        }
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
        final scan = _allAcceptedProspectTilesInProvince(
          view: view,
          game: game,
          topology: topology,
          currentOrders: currentOrders,
          playerId: playerId,
          unit: unit,
          tilesInProvince: tilesInP,
          prospected: prospected,
          resolution: resolution,
          diplomaticOrders: diplomatic,
          candidateValidator: candidateValidator,
          workProbeBudget: workProbeBudget,
          tileMapByRegion: tileMapByRegion,
          // The Explorer's own province carries the highest-value, bounded
          // prospect candidate (a co-located owned mineral tile); exempt it
          // from the shared per-pass budget so earlier units cannot starve it
          // (Refs #2847). Remote provinces still consume the shared budget.
          consumeSharedBudget: provinceIdFull != atProvinceFullId,
        );
        lastReason = scan.lastReason;
        for (final tk in scan.tiles) {
          yield WorkOrder(
            unitId: unit.id,
            target: kWorkTargetProspect,
            targetTileKey: tk,
          );
        }
      }
    },
    candidateAcceptor: (_) => true,
    noCandidateReason: 'no_valid_tile',
    resolveNoCandidateReason: () => lastReason,
    includeAllAccepted: true,
    maxProbeAttempts:
        kMaxExploreProvinceProbesPerUnit *
        kMaxWorkProbeAttemptsPerUnitPerTarget,
  );
}
