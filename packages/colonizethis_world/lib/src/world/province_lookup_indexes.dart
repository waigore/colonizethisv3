import 'dart:collection' show UnmodifiableMapView;

import 'package:colonizethis_models/colonizethis_models.dart'
    show Province, ProvinceId, RegionData, WorldState;

import '../world_constants.dart';
import 'package:colonizethis_world/src/utils/expando_index.dart';

/// Id → first list index for one [RegionData.provinces] list instance (Refs #2394).
/// First matching id wins, matching [List.indexWhere] semantics on duplicates.
final ExpandoIndex<List<Province>, Map<String, int>>
provinceFirstIndexByIdForProvinceList =
    ExpandoIndex<List<Province>, Map<String, int>>(
      'provinceFirstIndexByIdForProvinceList',
      (provinces) {
        final built = <String, int>{};
        for (var i = 0; i < provinces.length; i++) {
          built.putIfAbsent(provinces[i].id, () => i);
        }
        return built;
      },
    );

/// Id → province row for one [RegionData.provinces] list instance (Refs #2394).
/// First matching id wins, matching [List.indexWhere] semantics on duplicates.
final ExpandoIndex<List<Province>, Map<String, Province>>
provinceByIdForProvinceList =
    ExpandoIndex<List<Province>, Map<String, Province>>(
      'provinceByIdForProvinceList',
      (provinces) {
        final index = <String, Province>{};
        for (final p in provinces) {
          index.putIfAbsent(p.id, () => p);
        }
        return index;
      },
    );

Map<String, int> provinceFirstIndexByIdForList(List<Province> provinces) =>
    provinceFirstIndexByIdForProvinceList.get(provinces);

Map<String, Province> provinceIdIndexForList(List<Province> provinces) =>
    provinceByIdForProvinceList.get(provinces);

/// O(1) check that [provinces] contains a row whose [Province.id] equals [provinceId].
///
/// Uses the same per-list index as region-scoped lookup (Refs #2394).
bool provinceListContainsProvinceId(
  List<Province> provinces,
  String provinceId,
) => provinceIdIndexForList(provinces).containsKey(provinceId);

/// First index in [provinces] whose [Province.id] equals [provinceId], or null
/// when none match. Matches [List.indexWhere] semantics on duplicate ids
/// (first occurrence wins). Refs #2394.
int? provinceListIndexOfProvinceId(
  List<Province> provinces,
  String provinceId,
) => provinceFirstIndexByIdForList(provinces)[provinceId];

/// When a row with [provinceId] exists, returns a new list with that row's
/// [Province.fortLevel] decremented by one (clamped 0–3). Otherwise returns
/// [provinces] unchanged (same reference).
List<Province> decrementFortLevelForProvinceIdIfPresent(
  List<Province> provinces,
  String provinceId,
) {
  if (!provinceIdIndexForList(provinces).containsKey(provinceId)) {
    return provinces;
  }
  return [
    for (final p in provinces)
      if (p.id == provinceId)
        p.copyWith(fortLevel: (p.fortLevel - 1).clamp(0, 3))
      else
        p,
  ];
}

/// Old-world-first id → province row (Refs #2836 item 4).
final class WorldProvinceIndex {
  WorldProvinceIndex({required Map<String, Province> byId})
    : byIdUnmodifiable = UnmodifiableMapView<String, Province>(byId);

  final UnmodifiableMapView<String, Province> byIdUnmodifiable;
}

/// Lazily built per [WorldState] instance. A new [WorldState] from
/// [WorldState.copyWith] gets a fresh cache via identity.
final ExpandoIndex<WorldState, WorldProvinceIndex>
worldProvinceIndexByState =
    ExpandoIndex<WorldState, WorldProvinceIndex>('worldProvinceIndexByState', (
      world,
    ) {
      final byId = <String, Province>{};
      for (final p in world.oldWorld.provinces) {
        byId.putIfAbsent(p.id, () => p);
      }
      for (final p in world.newWorld.provinces) {
        byId.putIfAbsent(p.id, () => p);
      }
      return WorldProvinceIndex(byId: byId);
    });

WorldProvinceIndex provinceIndexForWorld(WorldState world) =>
    worldProvinceIndexByState.get(world);

RegionData? regionForId(WorldState world, String regionId) {
  return regionId == kRegionOldWorld
      ? world.oldWorld
      : (regionId == kRegionNewWorld ? world.newWorld : null);
}

Province? findProvinceInRegion(
  RegionData region,
  String regionId,
  String localId,
) {
  final fullId = ProvinceId.full(regionId, localId);
  return provinceIdIndexForList(region.provinces)[fullId];
}
