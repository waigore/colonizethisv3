import 'package:colonizethis_models/colonizethis_models.dart' show Province, ProvinceId, WorldState;

/// Central province lookup. In a multi-region world, province must be located
/// using regionId + provinceId (or a prefixed full id). SPEC/game/world-model.
///
/// Use [getProvince] when the province is required; it throws [StateError] if
/// not found. Do not fall back to oldWorld/newWorld.

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

/// Resolves [provinceId] to full form (regionId|localId). If already prefixed, returns as-is.
/// Otherwise finds a province in [world] with matching local id and returns ProvinceId.full(regionId, provinceId).
/// Throws [StateError] if not prefixed and no matching province found.
String resolveToFullProvinceId(WorldState world, String provinceId) {
  if (ProvinceId.isPrefixed(provinceId)) return provinceId;
  final r = _resolveShort(world, provinceId);
  if (r == null) throw StateError('Province not found: $provinceId');
  return r;
}

String? _resolveShort(WorldState world, String provinceId) {
  for (final p in world.oldWorld.provinces) {
    if (p.id == provinceId) return ProvinceId.full(_regionOldWorld, provinceId);
  }
  for (final p in world.newWorld.provinces) {
    if (p.id == provinceId) return ProvinceId.full(_regionNewWorld, provinceId);
  }
  return null;
}

/// Returns the province for [fullProvinceId] (format regionId|localId) or short local id.
/// Throws [StateError] if the id cannot be resolved or the province is not found.
Province getProvince(WorldState world, String fullProvinceId) {
  final resolved = resolveToFullProvinceId(world, fullProvinceId);
  final regionId = ProvinceId.regionIdFrom(resolved);
  final localId = ProvinceId.localIdFrom(resolved);
  final region = regionId == _regionOldWorld
      ? world.oldWorld
      : (regionId == _regionNewWorld ? world.newWorld : null);
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

/// Optional lookup. Returns null if province is not found or id (when short) cannot be resolved.
Province? tryGetProvince(WorldState world, String fullProvinceId) {
  final resolved = ProvinceId.isPrefixed(fullProvinceId)
      ? fullProvinceId
      : _resolveShort(world, fullProvinceId);
  if (resolved == null) return null;
  final regionId = ProvinceId.regionIdFrom(resolved);
  final localId = ProvinceId.localIdFrom(resolved);
  final region = regionId == _regionOldWorld
      ? world.oldWorld
      : (regionId == _regionNewWorld ? world.newWorld : null);
  if (region == null) return null;
  final idx = region.provinces.indexWhere((p) =>
      p.id == resolved || (p.regionId == regionId && p.id == localId));
  if (idx < 0) return null;
  return region.provinces[idx];
}
