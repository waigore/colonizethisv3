// Per-pass NW owner lookup for advanced-start world knowledge and colonization.
// SPEC/game/advanced-starts.md (steps 8–9). Refs #4054.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Builds local NW province id → owner id once per pass from [game]'s New World
/// provinces (pre-pass ownership; same accept order as the former linear scans).
///
/// Keys are local ids matching flood-fill / reveal probes. Entries are included
/// only when `ProvinceId.prefixedFrom(province.regionId, province.id)` equals
/// `ProvinceId.full(kRegionNewWorld, localId)`, preserving the previous
/// `_ownerIdForLocalProvince` match contract.
Map<String, String?> nwOwnerByLocalProvinceId(Game game) {
  final owners = <String, String?>{};
  for (final province in game.worldState.newWorld.provinces) {
    final localId = ProvinceId.localFromMaybePrefixed(province.id);
    final prefixed = ProvinceId.prefixedFrom(province.regionId, province.id);
    if (prefixed != ProvinceId.full(kRegionNewWorld, localId)) continue;
    owners[localId] = province.ownerId;
  }
  return owners;
}

/// Builds local NW province id → tribe owner id once per pass.
///
/// Only provinces whose owner is in [game.tribes] are included (same filter as
/// the former `_tribeOwnerForLocalProvince` linear scan). Tribe membership is
/// snapshotted from [game] at build time.
Map<String, String> nwTribeOwnerByLocalProvinceId(Game game) {
  final tribeIds = {for (final tribe in game.tribes) tribe.id};
  final owners = <String, String>{};
  for (final province in game.worldState.newWorld.provinces) {
    final localId = ProvinceId.localFromMaybePrefixed(province.id);
    final prefixed = ProvinceId.prefixedFrom(province.regionId, province.id);
    if (prefixed != ProvinceId.full(kRegionNewWorld, localId)) continue;
    final ownerId = province.ownerId;
    if (ownerId != null && tribeIds.contains(ownerId)) {
      owners[localId] = ownerId;
    }
  }
  return owners;
}
