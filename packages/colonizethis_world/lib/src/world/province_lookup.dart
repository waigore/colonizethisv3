import 'package:colonizethis_models/colonizethis_models.dart'
    show Province, ProvinceId, RegionData, WorldState;

import 'province_lookup_extension.dart';
import 'province_lookup_indexes.dart' as indexes;

export 'province_lookup_extension.dart' show WorldStateProvinceLookup;
export 'province_lookup_indexes.dart'
    show
        decrementFortLevelForProvinceIdIfPresent,
        provinceListContainsProvinceId,
        provinceListIndexOfProvinceId;

/// Returns the region data for [regionId], or null if unknown.
/// Use when callers need [RegionData] (e.g. to iterate provinces) without full province lookup.
RegionData? regionDataForId(WorldState world, String regionId) =>
    indexes.regionForId(world, regionId);

/// All provinces in both regions (old world first, then new world).
/// Use when iterating over every province without needing region separation.
///
/// Delegates to [WorldStateProvinceLookup.allProvinces] so there is a single
/// definition of the cross-region traversal (Refs #3710); this free function is
/// retained for callers that pass a [WorldState] positionally.
Iterable<Province> allProvinces(WorldState world) => world.allProvinces();

/// Central province lookup. Lookup is by **full disambiguated id** (`regionId|localId`)
/// and is **region-scoped**: resolution happens only within the given region.
/// SPEC/game/world-model-identity.md.
///
/// [WorldStateProvinceLookup.getProvince], [WorldStateProvinceLookup.tryGetProvince],
/// and [resolveToFullProvinceId] **require** prefixed id only; non-prefixed ids are invalid
/// (no short-id resolution). Use [WorldStateProvinceLookup.getProvinceByRegion] /
/// [WorldStateProvinceLookup.tryGetProvinceByRegion] for explicit (regionId, localId) lookup.

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

/// Resolves a province row for transfer paths that accept either a prefixed id
/// or a legacy short [Province.id] (tests and some fixtures).
///
/// Returns the authoritative [Province.id] as [canonicalProvinceId] for bucket
/// keys and timer maps.
({Province province, String canonicalProvinceId})?
resolveProvinceRowForOwnershipTransfer(WorldState world, String provinceKey) {
  final prefixed = world.tryGetProvince(provinceKey);
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
/// By default this helper resolves the **full id** bucket only
/// (`regionId|localId`) to keep multi-region lookups deterministic, and returns
/// a fresh mutable copy of the bucket (or an empty list when absent).
///
/// Pass [allowLocalIdFallback] `true` only for naval/fog ship-reveal and dock
/// visibility paths that must also resolve fixtures or legacy maps whose
/// `tileKeysByRegionAndProvince[regionId]` bucket is keyed by **local** id
/// (`localId`) when the full-id bucket is missing or empty. The fallback never
/// shadows a present full-id bucket: a non-empty full-id bucket always wins.
/// This is the single canonical definition (Refs #3403 Phase 1) — the former
/// duplicate in `naval_coastal_visibility.dart` routed its fallback callers
/// here.
List<String> landTileKeysForProvinceBucket(
  WorldState world,
  String regionId,
  String fullProvinceId, {
  bool allowLocalIdFallback = false,
}) {
  final byProvince = world.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null) return const [];
  final byFull = byProvince[fullProvinceId];
  if (byFull != null && byFull.isNotEmpty) {
    return List<String>.from(byFull);
  }
  if (allowLocalIdFallback) {
    final byLocal = byProvince[ProvinceId.localIdFrom(fullProvinceId)];
    if (byLocal != null) return List<String>.from(byLocal);
  }
  return byFull == null ? const [] : List<String>.from(byFull);
}
