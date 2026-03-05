import 'package:colonizethis_models/colonizethis_models.dart' show Province, ProvinceId, WorldState;

import '../constants.dart';

/// Central province lookup. Lookup is by **full disambiguated id** (`regionId|localId`)
/// and is **region-scoped**: resolution happens only within the given region.
/// SPEC/game/world-model-identity.md.
///
/// Prefer [getProvince]/[tryGetProvince] with a prefixed id or [getProvinceByRegion]/[tryGetProvinceByRegion]
/// with explicit (regionId, localId). Do not rely on short-id resolution for new code.

/// Resolves [provinceId] to full form (regionId|localId). If already prefixed, returns as-is.
/// **Legacy (deprecated):** Accepts short (unprefixed) id by searching oldWorld then newWorld;
/// that is not region-scoped. New code must use prefixed id only. SPEC/game/world-model-identity.md.
String resolveToFullProvinceId(WorldState world, String provinceId) {
  if (ProvinceId.isPrefixed(provinceId)) return provinceId;
  final r = _resolveShort(world, provinceId);
  if (r == null) throw StateError('Province not found: $provinceId');
  return r;
}

String? _resolveShort(WorldState world, String provinceId) {
  for (final p in world.oldWorld.provinces) {
    final localId = ProvinceId.isPrefixed(p.id) ? ProvinceId.localIdFrom(p.id) : p.id;
    if (p.id == provinceId || localId == provinceId) {
      return ProvinceId.full(kRegionOldWorld, localId);
    }
  }
  for (final p in world.newWorld.provinces) {
    final localId = ProvinceId.isPrefixed(p.id) ? ProvinceId.localIdFrom(p.id) : p.id;
    if (p.id == provinceId || localId == provinceId) {
      return ProvinceId.full(kRegionNewWorld, localId);
    }
  }
  return null;
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

/// Returns the province for [fullProvinceId]. Use full disambiguated id (regionId|localId); resolution is
/// region-scoped within the region implied by the id. Legacy: accepts short id via [resolveToFullProvinceId].
/// Throws [StateError] if the id cannot be resolved or the province is not found.
Province getProvince(WorldState world, String fullProvinceId) {
  final resolved = resolveToFullProvinceId(world, fullProvinceId);
  return getProvinceByRegion(world, ProvinceId.regionIdFrom(resolved), ProvinceId.localIdFrom(resolved));
}

/// Optional lookup by full id. Prefer prefixed id; resolution is region-scoped. Legacy: accepts short id.
Province? tryGetProvince(WorldState world, String fullProvinceId) {
  final resolved = ProvinceId.isPrefixed(fullProvinceId)
      ? fullProvinceId
      : _resolveShort(world, fullProvinceId);
  if (resolved == null) return null;
  return tryGetProvinceByRegion(world, ProvinceId.regionIdFrom(resolved), ProvinceId.localIdFrom(resolved));
}
