import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_orders/src/orders/bundled_civilian_work_order.dart'
    show validateCivilianBundledWorkMoveLeg;
import 'package:colonizethis_orders/src/orders/order_resolution_context.dart'
    show OrderResolutionContext, orderResolutionContextFromView;
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart'
    show
        buildIncrementalCandidateValidator,
        isWorkOrderAcceptedWithValidator;
import 'package:colonizethis_orders/src/orders/order_suggestion_work.dart'
    show suggestWorkOrders;
import 'package:colonizethis_orders/src/orders/order_visibility.dart'
    show provinceHasAtLeastVisibility;
import 'package:colonizethis_orders/src/orders/orders_application_helpers.dart'
    show isMineralEligibleTile;
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

/// Per-gate pass signals for a co-located mineral-eligible feedstock `prospect`
/// probe (Refs #2847 § H8-extraction prospect intra-pass localization).
typedef ColocatedFeedstockProspectIntraPassGates = ({
  bool provinceFoggedVisibility,
  bool bundledMoveLeg,
  bool validatorAccepted,
});

/// True iff the **real** Full-AI work-order suggestion pass
/// ([suggestWorkOrders]) emits a `prospect` candidate targeting one of
/// [playerId]'s owned, **unprospected**, **mineral-eligible** Old World
/// feedstock tiles in [feedstockIds] that is co-located with an **idle**
/// Explorer (Refs #2847 § H8-extraction Old World mineral feedstock prospect
/// localization).
///
/// Splits the residual one gate finer than
/// [ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile]:
/// that predicate proved an idle Explorer is co-located with an owned,
/// unprospected, mineral-eligible Old World feedstock tile on every gate-active
/// turn, yet the supplier still never prospects it. The next gates the
/// `prospect` candidate must clear after [isMineralEligibleTile] all live
/// **inside** the suggestion pass (`_addProspectSuggestionIfEligible` /
/// `_allAcceptedProspectTilesInProvince`): the province `fogged`+ visibility
/// gate, the bundled move-leg validation, and the incremental-validator
/// acceptance (`isWorkOrderAcceptedWithValidator` — prospect material cost /
/// visibility precheck). Running the actual pass and inspecting its output —
/// rather than re-deriving a single gate — keeps this faithful to the live
/// generation path and distinguishes:
///
///   * **true on gate turns** → the pass *does* emit the co-located feedstock
///     `prospect` candidate (it is generated and validator-accepted), so the
///     residual is **selection ranking** — the accepted `prospect` suggestion
///     loses to a competing `explore` suggestion in
///     `selectFullAiCivilianWorkOrders`, and the reserved idle Explorer never
///     receives the prospect as its chosen order.
///   * **false while
///     [ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile]
///     is true** → the pass emits **no** such `prospect` candidate despite the
///     co-located mineral-eligible tile, so the residual is **inside
///     generation** (the province visibility gate, the move-leg validation, or
///     the incremental-validator material-cost / visibility precheck), not
///     selection ranking.
///
/// Uses an empty [Orders] base context (matching the diagnostic's other
/// candidate-probe call sites); read-only and deterministic over
/// `(game, topology, view, playerId, feedstockIds, tileMapByRegion)`.
bool suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
  Game game,
  MapTopology topology,
  PlayerView view,
  String playerId,
  Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  // Owned, unprospected, mineral-eligible Old World feedstock tiles grouped by
  // province — the same scan the mineral-eligibility predicate performs, but
  // retaining the tile keys so the emitted `prospect` target can be matched.
  final eligibleTileKeysByProvince = <String, Set<String>>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (!kMineralResourceIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    if (prospected.contains(entry.key)) continue;
    if (!isMineralEligibleTile(game, tileMapByRegion, entry.key)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    (eligibleTileKeysByProvince[provinceId] ??= <String>{}).add(entry.key);
  }
  if (eligibleTileKeysByProvince.isEmpty) return false;
  // Restrict to tiles whose province hosts an idle Explorer (the precondition
  // the mineral-eligibility predicate asserts), so this predicate's truth
  // region is a strict refinement of that one.
  final targetTileKeys = <String>{};
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork != null) continue;
    final tiles = eligibleTileKeysByProvince[unit.locationProvinceId];
    if (tiles != null) targetTileKeys.addAll(tiles);
  }
  if (targetTileKeys.isEmpty) return false;
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
    tileMapByRegion: tileMapByRegion,
  );
  for (final suggestion in suggestions) {
    if (suggestion.target != kWorkTargetProspect) continue;
    if (targetTileKeys.contains(suggestion.targetTileKey)) return true;
  }
  return false;
}

/// Co-located mineral-eligible feedstock tile paired with the idle Explorer
/// that shares its province — the probe target for intra-pass gate checks.
typedef _ColocatedFeedstockProspectProbe = ({
  Unit unit,
  String tileKey,
  String provinceIdFull,
  String regionId,
});

List<_ColocatedFeedstockProspectProbe>
_colocatedMineralEligibleFeedstockProspectProbes({
  required Game game,
  required String playerId,
  required Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (feedstockIds.isEmpty) return const [];
  final ws = game.worldState;
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  final eligibleTileKeysByProvince = <String, Set<String>>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (!kMineralResourceIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    if (prospected.contains(entry.key)) continue;
    if (!isMineralEligibleTile(game, tileMapByRegion, entry.key)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    (eligibleTileKeysByProvince[provinceId] ??= <String>{}).add(entry.key);
  }
  if (eligibleTileKeysByProvince.isEmpty) return const [];
  final probes = <_ColocatedFeedstockProspectProbe>[];
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork != null) continue;
    final tiles = eligibleTileKeysByProvince[unit.locationProvinceId];
    if (tiles == null) continue;
    for (final tileKey in tiles) {
      final regionId = Unit.regionIdFromTileKey(tileKey);
      if (regionId == null) continue;
      probes.add((
        unit: unit,
        tileKey: tileKey,
        provinceIdFull: unit.locationProvinceId,
        regionId: regionId,
      ));
    }
  }
  return probes;
}

/// True iff the bundled move-leg gate accepts [candidate] for [probe]'s
/// Explorer. [validateCivilianBundledWorkMoveLeg] already returns
/// `accepted()` when no province move-leg is required, so this collapses the
/// "no move leg" and "validated move leg" branches into one flat check (Refs
/// #2847 prospect intra-pass localization).
bool _probeBundledMoveLegAccepted({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required _ColocatedFeedstockProspectProbe probe,
  required WorkOrder candidate,
  required OrderResolutionContext resolution,
  required List<DiplomaticOrder> diplomatic,
}) {
  final bundled = validateCivilianBundledWorkMoveLeg(
    game: game,
    topology: topology,
    playerId: playerId,
    unit: probe.unit,
    order: candidate,
    resolution: resolution,
    diplomaticOrders: diplomatic,
  );
  return bundled.isAccepted;
}

/// Evaluates the three post-eligibility `prospect` generation gates from
/// `_addProspectSuggestionIfEligible` → `_allAcceptedProspectTilesInProvince`
/// for co-located mineral-eligible feedstock tiles (Refs #2847 § H8-extraction
/// prospect intra-pass localization).
///
/// Each field is `true` iff **at least one** co-located probe passes that gate
/// using the same inputs as a real `suggestWorkOrders` pass (empty [Orders]
/// base, [buildIncrementalCandidateValidator], [orderResolutionContextFromView]).
/// Comparing against
/// [ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile]
/// and [suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile]
/// localizes which intra-pass gate rejects the co-located feedstock tile when
/// the suggestion pass emits no `prospect` candidate.
ColocatedFeedstockProspectIntraPassGates
colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates({
  required Game game,
  required MapTopology topology,
  required PlayerView view,
  required String playerId,
  required Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final probes = _colocatedMineralEligibleFeedstockProspectProbes(
    game: game,
    playerId: playerId,
    feedstockIds: feedstockIds,
    tileMapByRegion: tileMapByRegion,
  );
  if (probes.isEmpty) {
    return (
      provinceFoggedVisibility: false,
      bundledMoveLeg: false,
      validatorAccepted: false,
    );
  }
  final resolution = orderResolutionContextFromView(view, game);
  final candidateValidator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: const Orders(),
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
  );
  final diplomatic =
      const Orders().diplomaticOrdersByPlayerId[playerId] ?? const [];
  var provinceFoggedVisibility = false;
  var bundledMoveLeg = false;
  var validatorAccepted = false;
  for (final probe in probes) {
    if (!provinceFoggedVisibility &&
        provinceHasAtLeastVisibility(
          view,
          probe.regionId,
          probe.provinceIdFull,
          VisibilityLevel.fogged,
        )) {
      provinceFoggedVisibility = true;
    }
    final candidate = WorkOrder(
      unitId: probe.unit.id,
      target: kWorkTargetProspect,
      targetTileKey: probe.tileKey,
    );
    if (!bundledMoveLeg &&
        _probeBundledMoveLegAccepted(
          game: game,
          topology: topology,
          playerId: playerId,
          probe: probe,
          candidate: candidate,
          resolution: resolution,
          diplomatic: diplomatic,
        )) {
      bundledMoveLeg = true;
    }
    if (!validatorAccepted &&
        isWorkOrderAcceptedWithValidator(candidateValidator, candidate)) {
      validatorAccepted = true;
    }
    if (provinceFoggedVisibility && bundledMoveLeg && validatorAccepted) {
      break;
    }
  }
  return (
    provinceFoggedVisibility: provinceFoggedVisibility,
    bundledMoveLeg: bundledMoveLeg,
    validatorAccepted: validatorAccepted,
  );
}
