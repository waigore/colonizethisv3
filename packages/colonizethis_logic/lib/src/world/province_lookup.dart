import 'package:colonizethis_models/colonizethis_models.dart' show Province, ProvinceId, WorldState;

import '../constants.dart';

/// Central province lookup. Lookup is by **full disambiguated id** (`regionId|localId`)
/// and is **region-scoped**: resolution happens only within the given region.
/// SPEC/game/world-model-identity.md.
///
/// [getProvince], [tryGetProvince], and [resolveToFullProvinceId] **require** prefixed id only;
/// non-prefixed ids are invalid (no short-id resolution). Use [getProvinceByRegion]/[tryGetProvinceByRegion]
/// for explicit (regionId, localId) lookup.

/// Returns [provinceId] unchanged if it is prefixed (regionId|localId). Throws if not prefixed.
/// No short-id resolution; SPEC/game/world-model-identity.md.
String resolveToFullProvinceId(WorldState world, String provinceId) {
  if (ProvinceId.isPrefixed(provinceId)) return provinceId;
  throw StateError(
      'Province id must be prefixed (regionId|localId); short id not allowed: $provinceId');
}

/// Region-scoped lookup: returns the province in [regionId] with local id [localId]. Looks only in that region.
/// Throws [StateError] if the region is unknown or the province is not found.
Province getProvinceByRegion(WorldState world, String regionId, String localId) {
  final region = regionId == kRegionOldWorld
      ? world.oldWorld
      : (regionId == kRegionNewWorld ? world.newWorld : null);
  if (region == null) {
    throw StateError('Unknown region "$regionId" for province $regionId|$localId');
  }
  final fullId = ProvinceId.full(regionId, localId);
  final idx = region.provinces.indexWhere((p) =>
      p.id == fullId || (p.regionId == regionId && (p.id == localId || ProvinceId.localIdFrom(p.id) == localId)));
  if (idx < 0) {
    throw StateError('Province not found: $regionId|$localId in region "$regionId"');
  }
  return region.provinces[idx];
}

/// Optional region-scoped lookup: province in [regionId] with local id [localId], or null.
Province? tryGetProvinceByRegion(WorldState world, String regionId, String localId) {
  final region = regionId == kRegionOldWorld
      ? world.oldWorld
      : (regionId == kRegionNewWorld ? world.newWorld : null);
  if (region == null) return null;
  final fullId = ProvinceId.full(regionId, localId);
  final idx = region.provinces.indexWhere((p) =>
      p.id == fullId || (p.regionId == regionId && (p.id == localId || ProvinceId.localIdFrom(p.id) == localId)));
  if (idx < 0) return null;
  return region.provinces[idx];
}

/// Returns the province for [fullProvinceId]. Requires full disambiguated id (regionId|localId);
/// resolution is region-scoped. Throws [StateError] if id is not prefixed or province is not found.
Province getProvince(WorldState world, String fullProvinceId) {
  final resolved = resolveToFullProvinceId(world, fullProvinceId);
  return getProvinceByRegion(world, ProvinceId.regionIdFrom(resolved), ProvinceId.localIdFrom(resolved));
}

/// Optional lookup by full id. Requires prefixed id; non-prefixed returns null. Region-scoped.
Province? tryGetProvince(WorldState world, String fullProvinceId) {
  if (!ProvinceId.isPrefixed(fullProvinceId)) return null;
  return tryGetProvinceByRegion(
      world, ProvinceId.regionIdFrom(fullProvinceId), ProvinceId.localIdFrom(fullProvinceId));
}
