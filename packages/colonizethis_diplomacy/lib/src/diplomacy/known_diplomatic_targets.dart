import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_world/src/world/sea_reachable_provinces.dart';

/// Faction ids the player may target with diplomatic suggestions.
///
/// Diplomacy-domain visibility helper: derives the targetable faction set from
/// existing relations, tile visibility, and sea-reachable New World provinces.
/// Relocated from `orders/order_suggestion_helpers.dart` so the diplomacy
/// domain owns its own targeting logic and never imports `orders/`
/// (one-way `orders -> diplomacy` edge, Refs #3290 Phase 2).
///
/// SPEC/program/order-suggestions.md § Diplomatic orders (visibility).
Set<String> knownDiplomaticTargetFactionIds({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
}) {
  final knownFactionIds = <String>{};
  final playerId = view.playerId;

  for (final rel in game.diplomacyRelations) {
    if (rel.factionId1 == playerId) {
      knownFactionIds.add(rel.factionId2);
    } else if (rel.factionId2 == playerId) {
      knownFactionIds.add(rel.factionId1);
    }
  }

  for (final entry in view.visibilityByTile.entries) {
    if (entry.value == VisibilityLevel.unknown) continue;
    final parsed = parseTileKeyCoordinates(entry.key);
    if (parsed == null) continue;
    final regionId = parsed.regionId;
    final provinceLocalId = parsed.provinceLocalId;
    final provinceId = ProvinceId.full(regionId, provinceLocalId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    if (ownerId != null && ownerId != playerId) {
      knownFactionIds.add(ownerId);
    }
  }

  final anchorProvinces = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == playerId) anchorProvinces.add(p.key);
  }
  for (final u in view.ownUnits) {
    if (u.locationProvinceId.isNotEmpty) {
      anchorProvinces.add(u.locationProvinceId);
    }
  }
  final seaReachableNw = reachableNonOwnedProvinceIdsViaSeas(
    topology,
    anchorProvinces,
    view,
    regionIdFilter: kRegionNewWorld,
  );
  for (final provId in seaReachableNw) {
    final ownerId = view.provincesById[provId]?.ownerId;
    if (ownerId == null || ownerId == playerId) continue;
    if (game.tribes.any((t) => t.id == ownerId)) {
      knownFactionIds.add(ownerId);
    }
  }

  return knownFactionIds;
}
