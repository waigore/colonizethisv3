import 'dart:collection' show UnmodifiableListView;

import 'package:colonizethis_models/colonizethis_models.dart'
    show Province, WorldState;

import 'package:colonizethis_world/src/utils/expando_index.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart'
    show allProvinces;

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
class ProvinceOwnerCache {
  ProvinceOwnerCache._({
    required Map<String, String?> ownerByProvinceId,
    required Map<String, List<Province>> provincesByOwner,
    required List<Province> unownedProvinces,
  }) : _ownerByProvinceId = ownerByProvinceId,
       _provincesByOwner = provincesByOwner,
       _unownedProvinces = unownedProvinces;

  /// Builds an unmemoised projection from [world].
  ///
  /// Prefer [ProvinceOwnerCache.of] on hot paths so the projection is reused
  /// for the lifetime of a [WorldState] instance; use [build] for direct or
  /// test construction.
  factory ProvinceOwnerCache.build(WorldState world) {
    final ownerByProvinceId = <String, String?>{};
    final provincesByOwner = <String, List<Province>>{};
    final unowned = <Province>[];

    void visit(Province province) {
      final owner = province.ownerId;
      ownerByProvinceId[province.id] = owner;
      if (owner == null) {
        unowned.add(province);
        return;
      }
      (provincesByOwner[owner] ??= <Province>[]).add(province);
    }

    for (final province in allProvinces(world)) {
      visit(province);
    }

    return ProvinceOwnerCache._(
      ownerByProvinceId: ownerByProvinceId,
      provincesByOwner: provincesByOwner,
      unownedProvinces: unowned,
    );
  }

  final Map<String, String?> _ownerByProvinceId;
  final Map<String, List<Province>> _provincesByOwner;
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
