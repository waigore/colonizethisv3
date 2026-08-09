import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../bundled_civilian_work_order.dart';
import '../incremental_candidate_validator.dart';
import '../order_resolution_context.dart';
import '../order_suggestion_context.dart';
import '../order_visibility.dart';
import '../order_work_constants.dart';
import '../orders_application_helpers.dart';
import '../work_suggestion_pipeline.dart';

// Shared province/tile probe scaffolding for Explorer explore + prospect paths.
// Explore-only gates (usefulness, visibility ok, bundled move leg) stay in
// `order_suggestion_work_explorer.dart`. Spec: SPEC/program/order-suggestions.md.

/// Tile keys for [province] from the per-pass [tileKeysByRegion] snapshot.
List<String> tileKeysForProvinceInRegion(
  Map<String, Map<String, List<String>>> tileKeysByRegion,
  Province province,
) =>
    tileKeysByRegion[province.regionId]?[province.id] ?? const <String>[];

/// Provinces from [view], sorted by id with [unit]'s location province first
/// so [kMaxExploreProvinceProbesPerUnit] still reaches co-located mineral tiles
/// on seed-scale maps (Refs #2847).
List<Province> provincesWithUnitLocationFirst(PlayerView view, Unit unit) {
  final provinces = view.provincesById.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final at = unit.locationProvinceId;
  if (at.isEmpty) return provinces;
  final atProv = view.provincesById[at];
  if (atProv == null) return provinces;
  return [atProv, ...provinces.where((p) => p.id != at)];
}

/// Yields provinces from [provinces] up to [kMaxExploreProvinceProbesPerUnit].
Iterable<Province> cappedExploreProvinceProbes(Iterable<Province> provinces) sync* {
  var provinceProbes = 0;
  for (final prov in provinces) {
    provinceProbes++;
    if (provinceProbes > kMaxExploreProvinceProbesPerUnit) {
      return;
    }
    yield prov;
  }
}

/// True when [province] is at least fogged for [view] (explore/prospect gate).
bool provinceHasFoggedVisibilityForExplore(PlayerView view, Province province) {
  return provinceHasAtLeastVisibility(
    view,
    province.regionId,
    province.id,
    VisibilityLevel.fogged,
  );
}

/// First tile in sorted [tilesInProvince] with non-unknown visibility, else first.
String pickFirstKnownOrFirstSortedTile(
  PlayerView view,
  List<String> tilesInProvince,
) {
  final sortedTiles = List<String>.from(tilesInProvince)..sort();
  return sortedTiles.firstWhere(
    (tk) => view.visibilityForTile(tk) != VisibilityLevel.unknown,
    orElse: () => sortedTiles.first,
  );
}

/// Every engine-valid prospect tile in [tilesInProvince], in sorted tile order.
/// [lastReason] is the last rejection reason when the list is empty.
({List<String> tiles, String lastReason}) acceptedProspectTilesInProvince({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
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
  if (sortedTiles.isNotEmpty) {
    final moveLegReason = bundledWorkMoveLegRejectionReason(
      game: game,
      topology: topology,
      playerId: playerId,
      unit: unit,
      probe: WorkOrder(
        unitId: unit.id,
        target: kWorkTargetProspect,
        targetTileKey: sortedTiles.first,
      ),
      resolution: resolution,
      diplomatic: diplomaticOrders,
    );
    if (moveLegReason != null) {
      return (tiles: const <String>[], lastReason: moveLegReason);
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
