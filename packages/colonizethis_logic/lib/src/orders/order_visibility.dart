import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import 'orders_application_helpers.dart';
import 'partial_province_reveal.dart';

/// Order visibility rules. SPEC/program/fog-and-exploration-resolution.md.
///
/// Shared helpers used by the order engine and order suggestion API so both
/// enforce the same visibility rules using the same data (PlayerView).

/// Visibility level ordering: unknown < fogged < fullyVisible.
bool _visibilityAtLeast(VisibilityLevel actual, VisibilityLevel min) {
  return actual.index >= min.index;
}

/// True iff at least one tile in [regionId]/[provinceId] has visibility >= [min].
/// Tile keys use format regionId|localId|x|y. [provinceId] may be full (regionId|localId) or local.
bool provinceHasAtLeastVisibility(
  PlayerView view,
  String regionId,
  String provinceId,
  VisibilityLevel min,
) {
  final localId = ProvinceId.isPrefixed(provinceId)
      ? ProvinceId.localIdFrom(provinceId)
      : provinceId;
  return view.visibilityByTile.entries.any((e) {
    final parsed = parseTileKeyCoordinates(e.key);
    if (parsed == null) return false;
    return parsed.regionId == regionId &&
        parsed.provinceLocalId == localId &&
        _visibilityAtLeast(e.value, min);
  });
}

/// True iff [tileKey] has visibility >= [min].
bool tileHasAtLeastVisibility(
  PlayerView view,
  String tileKey,
  VisibilityLevel min,
) {
  return _visibilityAtLeast(view.visibilityForTile(tileKey), min);
}

/// Move order: source province must be known (not unknown).
bool moveSourceVisibilityOk(
  PlayerView view,
  String regionId,
  String provinceId,
) {
  return provinceHasAtLeastVisibility(
    view,
    regionId,
    provinceId,
    VisibilityLevel.fogged,
  );
}

/// Move order: destination province must be known (not unknown).
/// Optional refinement: non-explorer civilians could require fogged+; for now
/// we require at least fogged (same as source).
bool moveDestVisibilityOk(
  PlayerView view,
  String regionId,
  String provinceId,
  String unitType,
) {
  final min = VisibilityLevel.fogged;
  return provinceHasAtLeastVisibility(view, regionId, provinceId, min);
}

/// Civilian move order: destination **tile** must be at least fogged.
bool moveDestinationTileVisibilityOk(
  PlayerView view,
  String destinationTileKey,
) {
  return tileHasAtLeastVisibility(
    view,
    destinationTileKey,
    VisibilityLevel.fogged,
  );
}

/// Resolves regionId for [unit]: from tileKey, compound provinceId, [view].provincesById, or visibility tile keys.
/// Shared by order_suggestion and order_visibility (SPEC/program/order-suggestions.md, fog-and-exploration-resolution.md).
String regionIdForUnit(PlayerView view, Unit unit) {
  if (unit.tileKey != null && unit.tileKey!.isNotEmpty) {
    return Unit.requireRegionIdFromTileKey(unit.tileKey);
  }
  if (ProvinceId.isPrefixed(unit.locationProvinceId)) {
    return ProvinceId.regionIdFrom(unit.locationProvinceId);
  }
  for (final key in view.provincesById.keys) {
    if (key == unit.locationProvinceId ||
        key.endsWith('|${unit.locationProvinceId}')) {
      return ProvinceId.regionIdFrom(key);
    }
  }
  for (final tileKey in view.visibilityByTile.keys) {
    final parsed = parseTileKeyCoordinates(tileKey);
    if (parsed != null && parsed.provinceLocalId == unit.locationProvinceId) {
      return parsed.regionId;
    }
  }
  if (!ProvinceId.isPrefixed(unit.locationProvinceId)) {
    throw StateError(
      'regionIdForUnit: cannot resolve region for non-prefixed '
      'locationProvinceId "${unit.locationProvinceId}" (unit ${unit.id})',
    );
  }
  return ProvinceId.regionIdFrom(unit.locationProvinceId);
}

typedef _WorkTargetVisibilityFn =
    bool Function(
      PlayerView view,
      String regionId,
      String provinceId,
      bool isOwned,
      WorldState? worldState,
    );

bool _workVisExplorePartialReveal(
  PlayerView view,
  String regionId,
  String provinceId,
  bool isOwned,
  WorldState? worldState,
) {
  final ws = worldState;
  if (ws == null) {
    return false;
  }
  final fullProvinceId = ProvinceId.isPrefixed(provinceId)
      ? provinceId
      : ProvinceId.full(regionId, provinceId);
  final landKeys = landTileKeysForProvinceBucket(
    ws,
    regionId,
    fullProvinceId,
  );
  return isPartiallyRevealedProvinceLandTilesForPlayer(view, landKeys);
}

bool _workVisFoggedOrBetterProvince(
  PlayerView view,
  String regionId,
  String provinceId,
  bool isOwned,
  WorldState? _,
) {
  return provinceHasAtLeastVisibility(
    view,
    regionId,
    provinceId,
    VisibilityLevel.fogged,
  );
}

bool _workVisFoggedProvince(
  PlayerView view,
  String regionId,
  String provinceId,
  bool isOwned,
  WorldState? _,
) {
  return provinceHasAtLeastVisibility(
    view,
    regionId,
    provinceId,
    VisibilityLevel.fogged,
  );
}

bool _workVisOwnedOrFoggedProvince(
  PlayerView view,
  String regionId,
  String provinceId,
  bool isOwned,
  WorldState? _,
) {
  return isOwned ||
      provinceHasAtLeastVisibility(
        view,
        regionId,
        provinceId,
        VisibilityLevel.fogged,
      );
}

/// Map dispatch for work-target visibility (Refs #1531); unknown targets use default.
final Map<String, _WorkTargetVisibilityFn> _workOrderVisibilityByTarget =
    <String, _WorkTargetVisibilityFn>{
      kWorkTargetExplore: _workVisExplorePartialReveal,
      kWorkTargetProspect: _workVisFoggedProvince,
      kWorkTargetBuildImprovement: _workVisOwnedOrFoggedProvince,
      kWorkTargetUpgradeTown: _workVisOwnedOrFoggedProvince,
      kWorkTargetBuildRoad: _workVisOwnedOrFoggedProvince,
      kWorkTargetBuildPort: _workVisOwnedOrFoggedProvince,
      kWorkTargetBuildFort: _workVisOwnedOrFoggedProvince,
      'build_rail': _workVisOwnedOrFoggedProvince,
      kWorkTargetPurchaseLand: _workVisFoggedOrBetterProvince,
      kWorkTargetStealTech: _workVisFoggedOrBetterProvince,
      kWorkTargetCounterSpy: _workVisOwnedOrFoggedProvince,
    };

/// Work order: true iff the unit's province (and [targetTileKey] when applicable) meets
/// the minimum visibility for [workTarget]. SPEC/program/fog-and-exploration-resolution.md.
///
/// [worldState] is required for [kWorkTargetExplore] (partial-reveal land bucket).
bool workOrderVisibilityOk(
  PlayerView view,
  Unit unit,
  String workTarget, {
  String? targetTileKey,
  WorldState? worldState,
}) {
  final regionId = targetTileKey != null && targetTileKey.isNotEmpty
      ? Unit.requireRegionIdFromTileKey(targetTileKey)
      : regionIdForUnit(view, unit);
  final provinceId = targetTileKey != null && targetTileKey.isNotEmpty
      ? (Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId)
      : unit.locationProvinceId;
  final province = view.provinceByRegionAndId(regionId, provinceId);
  final isOwned = province?.ownerId == view.playerId;

  final fn = _workOrderVisibilityByTarget[workTarget];
  if (fn != null) {
    return fn(view, regionId, provinceId, isOwned, worldState);
  }
  return false;
}
