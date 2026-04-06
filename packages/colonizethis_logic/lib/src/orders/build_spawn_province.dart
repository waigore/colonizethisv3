import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/province_lookup.dart';

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
