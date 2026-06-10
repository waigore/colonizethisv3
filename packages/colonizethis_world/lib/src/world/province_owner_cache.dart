import 'dart:collection' show UnmodifiableListView;

import 'package:colonizethis_models/colonizethis_models.dart'
    show Province, WorldState;

import 'package:colonizethis_world/src/utils/expando_index.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionNewWorld, kRegionOldWorld;

/// Read-only projection of province ownership over a single [WorldState].
///
/// Memoises the deterministic per-owner province groupings that domain
/// packages otherwise recompute by repeatedly scanning every province
/// (`provincesForRegion(...).where((p) => p.ownerId == playerId)`,
/// `allProvinces().where(...)`). Those uncapped global scans inside
/// per-player / per-target loops are a recognised next-turn-budget risk
/// (`colonizethis-turn-resolution-budget.mdc`).
///
/// The projection is built once per [WorldState] and never mutates it.
/// Ownership is read from [Province.ownerId] (`null` = unowned).
///
/// Determinism (SPEC/program/worldstate-projection.md): provinces are visited
/// old-world-first then new-world, each in [WorldState] list order; per-owner
/// lists and [ownerIds] preserve that order ([ownerIds] in first-seen order).
/// Per-region groupings ([provincesOwnedByInRegion]) are keyed by the region
/// the province was visited in ([kRegionOldWorld] / [kRegionNewWorld]) and
/// preserve the same per-region list order.
class ProvinceOwnerCache {
  ProvinceOwnerCache._({
    required Map<String, String?> ownerByProvinceId,
    required Map<String, List<Province>> provincesByOwner,
    required Map<String, Map<String, List<Province>>> provincesByOwnerAndRegion,
    required List<Province> unownedProvinces,
  }) : _ownerByProvinceId = ownerByProvinceId,
       _provincesByOwner = provincesByOwner,
       _provincesByOwnerAndRegion = provincesByOwnerAndRegion,
       _unownedProvinces = unownedProvinces;

  /// Builds an unmemoised projection from [world].
  ///
  /// Prefer [ProvinceOwnerCache.of] on hot paths so the projection is reused
  /// for the lifetime of a [WorldState] instance; use [build] for direct or
  /// test construction.
  factory ProvinceOwnerCache.build(WorldState world) {
    final ownerByProvinceId = <String, String?>{};
    final provincesByOwner = <String, List<Province>>{};
    final provincesByOwnerAndRegion = <String, Map<String, List<Province>>>{};
    final unowned = <Province>[];

    void visit(Province province, String regionId) {
      final owner = province.ownerId;
      ownerByProvinceId[province.id] = owner;
      if (owner == null) {
        unowned.add(province);
        return;
      }
      (provincesByOwner[owner] ??= <Province>[]).add(province);
      ((provincesByOwnerAndRegion[owner] ??= <String, List<Province>>{})[regionId] ??=
              <Province>[])
          .add(province);
    }

    for (final province in world.oldWorld.provinces) {
      visit(province, kRegionOldWorld);
    }
    for (final province in world.newWorld.provinces) {
      visit(province, kRegionNewWorld);
    }

    return ProvinceOwnerCache._(
      ownerByProvinceId: ownerByProvinceId,
      provincesByOwner: provincesByOwner,
      provincesByOwnerAndRegion: provincesByOwnerAndRegion,
      unownedProvinces: unowned,
    );
  }

  final Map<String, String?> _ownerByProvinceId;
  final Map<String, List<Province>> _provincesByOwner;
  final Map<String, Map<String, List<Province>>> _provincesByOwnerAndRegion;
  final List<Province> _unownedProvinces;

  /// Owner id of the province with [fullProvinceId], or `null` when the
  /// province is unowned or not present in either region.
  String? ownerOf(String fullProvinceId) =>
      _ownerByProvinceId[fullProvinceId];

  /// Whether the province with [fullProvinceId] is owned by [ownerId].
  bool isOwnedBy(String fullProvinceId, String ownerId) =>
      _ownerByProvinceId[fullProvinceId] == ownerId;

  /// Provinces owned by [ownerId] in deterministic iteration order.
  ///
  /// Returns an unmodifiable, possibly empty list. The returned view shares
  /// no mutable state with callers.
  List<Province> provincesOwnedBy(String ownerId) => UnmodifiableListView(
    _provincesByOwner[ownerId] ?? const <Province>[],
  );

  /// Number of provinces owned by [ownerId].
  int countOwnedBy(String ownerId) =>
      _provincesByOwner[ownerId]?.length ?? 0;

  /// Provinces owned by [ownerId] in region [regionId] (e.g. [kRegionOldWorld]
  /// or [kRegionNewWorld]) in deterministic iteration order.
  ///
  /// Equivalent to the per-region scan
  /// `world.<region>.provinces.where((p) => p.ownerId == ownerId)` but read
  /// from the memoised projection. Returns an unmodifiable, possibly empty
  /// list.
  List<Province> provincesOwnedByInRegion(String ownerId, String regionId) =>
      UnmodifiableListView(
        _provincesByOwnerAndRegion[ownerId]?[regionId] ?? const <Province>[],
      );

  /// Whether [ownerId] owns at least one province in region [regionId].
  ///
  /// Equivalent to `world.<region>.provinces.any((p) => p.ownerId == ownerId)`.
  bool ownsAnyInRegion(String ownerId, String regionId) =>
      _provincesByOwnerAndRegion[ownerId]?[regionId]?.isNotEmpty ?? false;

  /// Number of provinces owned by [ownerId] in region [regionId].
  ///
  /// Equivalent to
  /// `world.<region>.provinces.where((p) => p.ownerId == ownerId).length`.
  int countOwnedByInRegion(String ownerId, String regionId) =>
      _provincesByOwnerAndRegion[ownerId]?[regionId]?.length ?? 0;

  /// Distinct non-null owner ids in first-seen iteration order.
  List<String> get ownerIds =>
      UnmodifiableListView(_provincesByOwner.keys.toList());

  /// Provinces with no owner (`ownerId == null`) in iteration order.
  List<Province> get unownedProvinces =>
      UnmodifiableListView(_unownedProvinces);

  /// Memoised projection for [world], built once per [WorldState] identity and
  /// reused on later calls until the state is garbage collected. A new
  /// [WorldState] from `copyWith` gets a fresh cache.
  static ProvinceOwnerCache of(WorldState world) => _cacheByState.get(world);

  static final ExpandoIndex<WorldState, ProvinceOwnerCache> _cacheByState =
      ExpandoIndex<WorldState, ProvinceOwnerCache>(
        'provinceOwnerCacheByState',
        ProvinceOwnerCache.build,
      );
}
