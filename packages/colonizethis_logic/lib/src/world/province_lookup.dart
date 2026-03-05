import 'package:colonizethis_models/colonizethis_models.dart' show Province, ProvinceId, WorldState;

import '../constants.dart';

/// Central province lookup. In a multi-region world, province must be located
/// using regionId + provinceId (or a prefixed full id). SPEC/game/world-model.
///
/// Use [getProvince] when the province is required; it throws [StateError] if
/// not found. Do not fall back to oldWorld/newWorld.

/// Resolves [provinceId] to full form (regionId|localId). If already prefixed, returns as-is.
/// Legacy: accepts short (unprefixed) id and resolves by searching oldWorld then newWorld; when
/// the same local id exists in both regions, first match (oldWorld) wins. New code should use
/// prefixed id only. SPEC/game/world-model-identity.md.
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

/// Returns the province for [fullProvinceId] (prefixed regionId|localId or legacy short id).
/// Throws [StateError] if the id cannot be resolved or the province is not found.
Province getProvince(WorldState world, String fullProvinceId) {
  final resolved = resolveToFullProvinceId(world, fullProvinceId);
  final regionId = ProvinceId.regionIdFrom(resolved);
  final localId = ProvinceId.localIdFrom(resolved);
  final region = regionId == kRegionOldWorld
      ? world.oldWorld
      : (regionId == kRegionNewWorld ? world.newWorld : null);
  if (region == null) {
    throw StateError('Unknown region "$regionId" for province "$fullProvinceId"');
  }
  final idx = region.provinces.indexWhere((p) =>
      p.id == resolved || (p.regionId == regionId && p.id == localId));
  if (idx < 0) {
    throw StateError('Province not found: "$fullProvinceId" in region "$regionId"');
  }
  return region.provinces[idx];
}

/// Optional lookup. Returns null if province is not found. Accepts prefixed or legacy short id.
Province? tryGetProvince(WorldState world, String fullProvinceId) {
  final resolved = ProvinceId.isPrefixed(fullProvinceId)
      ? fullProvinceId
      : _resolveShort(world, fullProvinceId);
  if (resolved == null) return null;
  final regionId = ProvinceId.regionIdFrom(resolved);
  final localId = ProvinceId.localIdFrom(resolved);
  final region = regionId == kRegionOldWorld
      ? world.oldWorld
      : (regionId == kRegionNewWorld ? world.newWorld : null);
  if (region == null) return null;
  final idx = region.provinces.indexWhere((p) =>
      p.id == resolved || (p.regionId == regionId && p.id == localId));
  if (idx < 0) return null;
  return region.provinces[idx];
}
