import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/province_lookup.dart';

const kCivilianCapitalTileMissingReason =
    'No capital tile to spawn civilian unit';

/// Resolves the effective spawn province for a build order.
///
/// Rules:
/// - Naval builds always resolve to player's capital province.
/// - Civilian/military builds use [order.spawnProvinceId] when it exists and is
///   owned by the player.
/// - Empty, invalid, unknown, or foreign spawn province falls back to capital.
/// - Returns null when no capital exists.
String? resolveBuildSpawnProvinceId({
  required Player player,
  required WorldState worldState,
  required BuildUnitOrder order,
}) {
  final capitalProvinceId = player.capitalProvinceId;
  final hasCapital =
      capitalProvinceId != null && capitalProvinceId.trim().isNotEmpty;

  final isNavalBuild = ShipEconomyCatalog.byId.containsKey(order.unitType);
  if (isNavalBuild) {
    // Naval spawns are always capital-based.
    return hasCapital ? capitalProvinceId : null;
  }

  final requested = order.spawnProvinceId.trim();
  if (requested.isEmpty) {
    return hasCapital ? capitalProvinceId : null;
  }

  final province = worldState.tryGetProvince(requested);
  if (province != null && province.ownerId == player.id) {
    return requested;
  }

  return hasCapital ? capitalProvinceId : null;
}

/// Resolves civilian spawn tile as the player's capital tile key.
///
/// Returns null when capital tile cannot be resolved.
String? resolveCivilianSpawnTileKey({
  required Player player,
  required WorldState worldState,
}) {
  final capitalTile = player.capitalTile;
  if (capitalTile == null) return null;
  final tileKey = capitalTile.toTileKey();
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  final province = worldState.tryGetProvince(provinceId);
  if (province == null || province.ownerId != player.id) return null;
  return tileKey;
}
