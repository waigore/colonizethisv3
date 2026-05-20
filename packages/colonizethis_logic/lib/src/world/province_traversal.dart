import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'province_lookup.dart';

/// One province row during a dual-region traversal (Refs #2560).
final class ProvinceTraversalEntry {
  const ProvinceTraversalEntry({
    required this.regionId,
    required this.province,
    this.tileKeys,
  });

  final String regionId;
  final Province province;

  /// Land tile keys for [province] when present in
  /// [WorldState.tileKeysByRegionAndProvince] (full id, then local id).
  final List<String>? tileKeys;

  String get provinceId => province.id;
  String? get ownerId => province.ownerId;
}

/// Invokes [action] for each known region in fixed order (old world, new world).
void forEachWorldRegion(
  WorldState world,
  void Function(String regionId, RegionData regionData) action,
) {
  for (final regionId in const [kRegionOldWorld, kRegionNewWorld]) {
    final regionData = regionDataForId(world, regionId);
    if (regionData != null) {
      action(regionId, regionData);
    }
  }
}

/// Yields every province in both regions with optional [where] filter.
Iterable<ProvinceTraversalEntry> traverseProvinces(
  WorldState world, {
  bool Function(String regionId, Province province)? where,
}) sync* {
  for (final regionId in const [kRegionOldWorld, kRegionNewWorld]) {
    final regionData = regionDataForId(world, regionId);
    if (regionData == null) continue;
    final tilesByProvince = world.tileKeysByRegionAndProvince[regionId];
    for (final province in regionData.provinces) {
      if (where != null && !where(regionId, province)) {
        continue;
      }
      yield ProvinceTraversalEntry(
        regionId: regionId,
        province: province,
        tileKeys: _tileKeysForProvince(tilesByProvince, province.id),
      );
    }
  }
}

/// Single dual-region pass yielding `{ provinceId: ownerId }` across both
/// regions. Mirrors the inline `{ for (... in traverseProvinces(world))
/// e.provinceId: e.ownerId }` idiom several scanners had repeated; centralizing
/// it keeps fog/movement/spy decay readers semantically aligned with the same
/// canonical ordering used by [traverseProvinces]. Refs #2560.
Map<String, String?> ownerByProvinceIdMap(WorldState world) => {
  for (final entry in traverseProvinces(world))
    entry.provinceId: entry.ownerId,
};

List<String>? _tileKeysForProvince(
  Map<String, List<String>>? tilesByProvince,
  String provinceId,
) {
  if (tilesByProvince == null) return null;
  final byFull = tilesByProvince[provinceId];
  if (byFull != null && byFull.isNotEmpty) {
    return byFull;
  }
  return tilesByProvince[ProvinceId.localIdFrom(provinceId)];
}
