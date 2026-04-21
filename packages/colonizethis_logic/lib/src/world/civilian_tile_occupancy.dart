import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import 'province_lookup.dart';

/// True when [tileKey] is a known land tile: listed in [WorldState.tileKeysByRegionAndProvince],
/// or (fallback for sparse test worlds) a 4-part key whose enclosing prefixed province exists.
/// SPEC/program/movement.md; civilian tile moves (#1877).
bool isLandTileKeyForGame(Game game, String tileKey) {
  if (tileKey.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final tiles in byProvince.values) {
      if (tiles.contains(tileKey)) return true;
    }
  }
  final parts = tileKey.split('|');
  if (parts.length == 4) {
    final provinceId = '${parts[0]}|${parts[1]}';
    if (tryGetProvince(ws, provinceId) != null) return true;
  }
  return false;
}

/// Whether [playerId]'s civilian unit of [unitType] may **stand on** [destinationTileKey]
/// this turn from a **territorial control** perspective (tile-level purchase, then province owner).
///
/// Does **not** check visibility, draft ordering, or unit existence — callers enforce those.
/// Spy may occupy province-derived Great Power land without a diplomatic / war gate.
/// Non-Spy civilians may not occupy another GP's province-derived land unless the mover
/// holds the tile via [WorldState.purchasedTilesByTileKey] (or equivalent tile-level control).
///
/// SPEC/program/orders.md; issue #1877.
/// All distinct land tile keys indexed on [world], sorted lexicographically.
List<String> sortedLandTileKeys(WorldState world) {
  final out = <String>{};
  for (final byProvince in world.tileKeysByRegionAndProvince.values) {
    for (final tiles in byProvince.values) {
      out.addAll(tiles);
    }
  }
  final list = out.toList()..sort();
  return list;
}

bool civilianMayOccupyLandTileKey({
  required Game game,
  required String playerId,
  required String unitType,
  required String destinationTileKey,
}) {
  if (destinationTileKey.isEmpty) return false;
  if (!isLandTileKeyForGame(game, destinationTileKey)) return false;

  final purchased = game.worldState.purchasedTilesByTileKey[destinationTileKey];
  if (purchased == playerId) return true;

  final provinceId = Unit.provinceIdFromTileKey(destinationTileKey);
  if (provinceId == null) return false;
  final province = tryGetProvince(game.worldState, provinceId);
  if (province == null) return false;

  final ownerId = province.ownerId;
  if (ownerId == null || ownerId.isEmpty) {
    return isExplorerUnit(unitType) ||
        isMerchantUnit(unitType) ||
        isSpyUnit(unitType);
  }
  if (ownerId == playerId) return true;

  if (isGreatPower(game, ownerId)) {
    return isSpyUnit(unitType);
  }
  if (isMinorOrTribe(game, ownerId)) {
    return isExplorerUnit(unitType) ||
        isMerchantUnit(unitType) ||
        isSpyUnit(unitType);
  }
  return false;
}
