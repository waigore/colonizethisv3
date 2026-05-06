import 'package:colonizethis_models/colonizethis_models.dart'
    show Province, ProvinceId, RegionData, Unit, WorldState;

import '../constants.dart';

RegionData? _regionForId(WorldState world, String regionId) {
  return regionId == kRegionOldWorld
      ? world.oldWorld
      : (regionId == kRegionNewWorld ? world.newWorld : null);
}

Province? _findProvinceInRegion(
  RegionData region,
  String regionId,
  String localId,
) {
  final fullId = ProvinceId.full(regionId, localId);
  final idx = region.provinces.indexWhere((p) => p.id == fullId);
  if (idx < 0) return null;
  return region.provinces[idx];
}

/// Returns the region data for [regionId], or null if unknown.
/// Use when callers need [RegionData] (e.g. to iterate provinces) without full province lookup.
RegionData? regionDataForId(WorldState world, String regionId) =>
    _regionForId(world, regionId);

/// All provinces in both regions (old world first, then new world).
/// Use when iterating over every province without needing region separation.
Iterable<Province> allProvinces(WorldState world) sync* {
  yield* world.oldWorld.provinces;
  yield* world.newWorld.provinces;
}

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
    'Province id must be prefixed (regionId|localId); short id not allowed: $provinceId',
  );
}

/// Returns [provinceId] if already prefixed, otherwise [ProvinceId.full](regionId, provinceId).
/// Use when keying or looking up by an id that may be local or full (e.g. player view).
String toFullProvinceId(String regionId, String provinceId) {
  return ProvinceId.isPrefixed(provinceId)
      ? provinceId
      : ProvinceId.full(regionId, provinceId);
}

/// Region-scoped lookup: returns the province in [regionId] with local id [localId]. Looks only in that region.
/// Throws [StateError] if the region is unknown or the province is not found.
Province getProvinceByRegion(
  WorldState world,
  String regionId,
  String localId,
) {
  final region = _regionForId(world, regionId);
  if (region == null) {
    throw StateError(
      'Unknown region "$regionId" for province $regionId|$localId',
    );
  }
  final p = _findProvinceInRegion(region, regionId, localId);
  if (p == null) {
    throw StateError(
      'Province not found: $regionId|$localId in region "$regionId"',
    );
  }
  return p;
}

/// Optional region-scoped lookup: province in [regionId] with local id [localId], or null.
Province? tryGetProvinceByRegion(
  WorldState world,
  String regionId,
  String localId,
) {
  final region = _regionForId(world, regionId);
  if (region == null) return null;
  return _findProvinceInRegion(region, regionId, localId);
}

/// Returns the province for [fullProvinceId]. Requires full disambiguated id (regionId|localId);
/// resolution is region-scoped. Throws [StateError] if id is not prefixed or province is not found.
Province getProvince(WorldState world, String fullProvinceId) {
  final resolved = resolveToFullProvinceId(world, fullProvinceId);
  return getProvinceByRegion(
    world,
    ProvinceId.regionIdFrom(resolved),
    ProvinceId.localIdFrom(resolved),
  );
}

/// Optional lookup by full id. Requires prefixed id; non-prefixed returns null. Region-scoped.
Province? tryGetProvince(WorldState world, String fullProvinceId) {
  if (!ProvinceId.isPrefixed(fullProvinceId)) return null;
  return tryGetProvinceByRegion(
    world,
    ProvinceId.regionIdFrom(fullProvinceId),
    ProvinceId.localIdFrom(fullProvinceId),
  );
}

/// Resolves a province row for transfer paths that accept either a prefixed id
/// or a legacy short [Province.id] (tests and some fixtures).
///
/// Returns the authoritative [Province.id] as [canonicalProvinceId] for bucket
/// keys and timer maps.
({Province province, String canonicalProvinceId})?
resolveProvinceRowForOwnershipTransfer(WorldState world, String provinceKey) {
  final prefixed = tryGetProvince(world, provinceKey);
  if (prefixed != null) {
    return (province: prefixed, canonicalProvinceId: prefixed.id);
  }
  for (final p in world.allProvinces()) {
    if (p.id == provinceKey) {
      return (province: p, canonicalProvinceId: p.id);
    }
  }
  return null;
}

/// Returns land tile keys for a province bucket using canonical full province id.
///
/// This helper intentionally does not fall back to local-only ids. Callers must
/// pass `regionId|localId` to keep multi-region lookups deterministic.
List<String> landTileKeysForProvinceBucket(
  WorldState world,
  String regionId,
  String fullProvinceId,
) {
  return List<String>.from(
    world.tileKeysByRegionAndProvince[regionId]?[fullProvinceId] ?? const [],
  );
}

/// Province lookup helpers on [WorldState] to avoid repeatedly passing the world state.
extension WorldStateProvinceLookup on WorldState {
  RegionData? regionDataForId(String regionId) => _regionForId(this, regionId);

  Iterable<Province> allProvinces() sync* {
    yield* oldWorld.provinces;
    yield* newWorld.provinces;
  }

  /// Returns [kRegionOldWorld] or [kRegionNewWorld] when a province row's `id`
  /// equals [key] in that region (old world checked first). For canonical
  /// lookups prefer [tryGetProvince] with a prefixed id; this exists for
  /// legacy short ids and tests (waigore/colonizethis#2071 Phase 1).
  String? tryGetRegionIdForLegacyProvinceKey(String key) {
    if (oldWorld.provinces.indexWhere((p) => p.id == key) >= 0) {
      return kRegionOldWorld;
    }
    if (newWorld.provinces.indexWhere((p) => p.id == key) >= 0) {
      return kRegionNewWorld;
    }
    return null;
  }

  String resolveToFullProvinceId(String provinceId) =>
      ProvinceId.isPrefixed(provinceId)
      ? provinceId
      : (throw StateError(
          'Province id must be prefixed (regionId|localId); short id not allowed: $provinceId',
        ));

  String toFullProvinceId(String regionId, String provinceId) =>
      ProvinceId.isPrefixed(provinceId)
      ? provinceId
      : ProvinceId.full(regionId, provinceId);

  Province getProvinceByRegion(String regionId, String localId) {
    final region = _regionForId(this, regionId);
    if (region == null) {
      throw StateError(
        'Unknown region "$regionId" for province $regionId|$localId',
      );
    }
    final p = _findProvinceInRegion(region, regionId, localId);
    if (p == null) {
      throw StateError(
        'Province not found: $regionId|$localId in region "$regionId"',
      );
    }
    return p;
  }

  Province? tryGetProvinceByRegion(String regionId, String localId) {
    final region = _regionForId(this, regionId);
    if (region == null) return null;
    return _findProvinceInRegion(region, regionId, localId);
  }

  Province getProvince(String fullProvinceId) {
    final resolved = resolveToFullProvinceId(fullProvinceId);
    return getProvinceByRegion(
      ProvinceId.regionIdFrom(resolved),
      ProvinceId.localIdFrom(resolved),
    );
  }

  Province? tryGetProvince(String fullProvinceId) {
    if (!ProvinceId.isPrefixed(fullProvinceId)) return null;
    return tryGetProvinceByRegion(
      ProvinceId.regionIdFrom(fullProvinceId),
      ProvinceId.localIdFrom(fullProvinceId),
    );
  }

  /// Replaces [oldWorld] and [newWorld] via [update].
  ///
  /// [update] receives [kRegionOldWorld] or [kRegionNewWorld] and the current
  /// [RegionData] for that region. Refactor helper (waigore/colonizethis#2071).
  WorldState mapBothRegions(
    RegionData Function(String regionId, RegionData region) update,
  ) {
    return copyWith(
      oldWorld: update(kRegionOldWorld, oldWorld),
      newWorld: update(kRegionNewWorld, newWorld),
    );
  }

  /// Updates unit lists in both regions; province rows are unchanged.
  WorldState mapBothRegionUnits(
    List<Unit> Function(String regionId, List<Unit> units) updateUnits,
  ) {
    return mapBothRegions(
      (regionId, region) => RegionData(
        provinces: region.provinces,
        units: updateUnits(regionId, region.units),
      ),
    );
  }
}
