import 'package:colonizethis_models/colonizethis_models.dart'
    show Province, ProvinceId, RegionData, Unit, WorldState;

import '../world_constants.dart';
import 'province_lookup_indexes.dart' as indexes;

/// Province lookup helpers on [WorldState] to avoid repeatedly passing the world state.
extension WorldStateProvinceLookup on WorldState {
  /// Cross-region province-by-id map (old-world entries first, then new world).
  ///
  /// Returns an unmodifiable view cached per [WorldState] identity (Refs #2836
  /// item 4). Keys are [Province.id] rows from both regions. For prefixed-id
  /// resolution that parses region segments, use [tryGetProvince].
  Map<String, Province> get allProvincesById =>
      indexes.provinceIndexForWorld(this).byIdUnmodifiable;

  RegionData? regionDataForId(String regionId) =>
      indexes.regionForId(this, regionId);

  /// Strict variant of [regionDataForId]: returns the region for [regionId] or
  /// throws [StateError] when unknown.
  ///
  /// Use in code paths whose contract guarantees [regionId] is canonical (i.e.
  /// [kRegionOldWorld] or [kRegionNewWorld]) and where a silent fallback would
  /// hide a malformed id. Mirrors the `Unknown region` contract of
  /// [updateRegionById] for symmetry between read and write paths
  /// (Refs #2836 item 1).
  RegionData regionDataForIdOrThrow(String regionId) {
    final region = indexes.regionForId(this, regionId);
    if (region == null) {
      throw StateError('Unknown region "$regionId"');
    }
    return region;
  }

  /// Provinces belonging to [regionId]. Returns an empty iterable when the
  /// region is unknown. Use in `lib/src/**` callers that need a region-scoped
  /// province iteration without hand-rolled `if (regionId == kRegionOldWorld)`
  /// branching against `oldWorld.provinces`/`newWorld.provinces`
  /// (SPEC/program/logic-dual-region-province-access.md).
  Iterable<Province> provincesForRegion(String regionId) =>
      indexes.regionForId(this, regionId)?.provinces ?? const <Province>[];

  /// Both regions in canonical order (old world first, then new world), each
  /// paired with its region id.
  ///
  /// Single source of truth for dual-region iteration ordering (Refs #3710):
  /// [allProvinces], [forEachRegion], and the `province_traversal.dart` /
  /// `province_visibility_index.dart` generators all derive their region order
  /// from here instead of repeating inline `[oldWorld, newWorld]` /
  /// `[kRegionOldWorld, kRegionNewWorld]` literals. Lazy so `lib/src/**`
  /// generators can `yield*` per region without materializing a list
  /// (SPEC/program/logic-dual-region-province-access.md).
  Iterable<({String regionId, RegionData region})> get regionsInOrder sync* {
    yield (regionId: kRegionOldWorld, region: oldWorld);
    yield (regionId: kRegionNewWorld, region: newWorld);
  }

  Iterable<Province> allProvinces() sync* {
    for (final entry in regionsInOrder) {
      yield* entry.region.provinces;
    }
  }

  /// Returns [kRegionOldWorld] or [kRegionNewWorld] when a province row's `id`
  /// equals [key] in that region (old world checked first). For canonical
  /// lookups prefer [tryGetProvince] with a prefixed id; this exists for
  /// legacy short ids and tests (waigore/colonizethis#2071 Phase 1).
  String? tryGetRegionIdForLegacyProvinceKey(String key) {
    if (indexes.provinceIdIndexForList(oldWorld.provinces).containsKey(key)) {
      return kRegionOldWorld;
    }
    if (indexes.provinceIdIndexForList(newWorld.provinces).containsKey(key)) {
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
    final region = indexes.regionForId(this, regionId);
    if (region == null) {
      throw StateError(
        'Unknown region "$regionId" for province $regionId|$localId',
      );
    }
    final p = indexes.findProvinceInRegion(region, regionId, localId);
    if (p == null) {
      throw StateError(
        'Province not found: $regionId|$localId in region "$regionId"',
      );
    }
    return p;
  }

  Province? tryGetProvinceByRegion(String regionId, String localId) {
    final region = indexes.regionForId(this, regionId);
    if (region == null) return null;
    return indexes.findProvinceInRegion(region, regionId, localId);
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

  /// Read-only iteration over both regions. [action] is invoked first with
  /// ([kRegionOldWorld], [oldWorld]), then ([kRegionNewWorld], [newWorld]) —
  /// same order as [mapBothRegions]. Use for symmetric side-effecting work on
  /// both regions that does not produce a new [WorldState], replacing
  /// hand-rolled `processRegion(oldWorld); processRegion(newWorld);` pairs in
  /// `lib/src/**` (Refs #2836 item 1,
  /// SPEC/program/logic-dual-region-province-access.md).
  void forEachRegion(void Function(String regionId, RegionData region) action) {
    for (final entry in regionsInOrder) {
      action(entry.regionId, entry.region);
    }
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

  /// Updates a single region by [regionId], preserving the other region.
  ///
  /// Throws [StateError] when [regionId] is unknown.
  WorldState updateRegionById(
    String regionId,
    RegionData Function(RegionData region) update,
  ) {
    if (regionId == kRegionOldWorld) {
      return copyWith(oldWorld: update(oldWorld));
    }
    if (regionId == kRegionNewWorld) {
      return copyWith(newWorld: update(newWorld));
    }
    throw StateError('Unknown region "$regionId"');
  }

  /// Returns fresh mutable copies of the province lists for both regions,
  /// keyed by [kRegionOldWorld] and [kRegionNewWorld].
  ///
  /// Use this from `lib/src/**` callers that stage imperative bulk-mutation
  /// over both regions before applying via [mapBothRegions] /
  /// [updateRegionById], replacing hand-rolled
  /// `List<Province>.from(worldState.oldWorld.provinces)` /
  /// `List<Province>.from(worldState.newWorld.provinces)` pairs (orders
  /// application work pipeline, setup naming). Each returned list is an
  /// independent mutable copy; mutating one does not affect the other or
  /// the source [WorldState]. The map is mutable; callers may add region
  /// keys defensively but the canonical contract returns exactly the two
  /// keys above (Refs #2836 AC 5;
  /// SPEC/program/logic-dual-region-province-access.md).
  Map<String, List<Province>> mutableProvinceListsByRegion() {
    return <String, List<Province>>{
      kRegionOldWorld: List<Province>.from(oldWorld.provinces),
      kRegionNewWorld: List<Province>.from(newWorld.provinces),
    };
  }
}
