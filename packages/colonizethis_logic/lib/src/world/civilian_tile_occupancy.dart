import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import 'province_lookup.dart';
import 'tile_key_coordinates.dart';

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
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords != null) {
    final provinceId = '${coords.regionId}|${coords.provinceLocalId}';
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
  if (!_isValidDestinationLandTile(game, destinationTileKey)) return false;
  if (_isTilePurchasedByMover(game, playerId, destinationTileKey)) return true;
  final ownerId = _provinceOwnerIdForDestination(game, destinationTileKey);
  return _isOccupancyAllowedByProvinceOwner(game, playerId, unitType, ownerId);
}

bool _isValidDestinationLandTile(Game game, String destinationTileKey) =>
    destinationTileKey.isNotEmpty &&
    isLandTileKeyForGame(game, destinationTileKey);

bool _isTilePurchasedByMover(
  Game game,
  String playerId,
  String destinationTileKey,
) => game.worldState.purchasedTilesByTileKey[destinationTileKey] == playerId;

String? _provinceOwnerIdForDestination(Game game, String destinationTileKey) {
  final provinceId = Unit.provinceIdFromTileKey(destinationTileKey);
  if (provinceId == null) return null;
  return tryGetProvince(game.worldState, provinceId)?.ownerId;
}

bool _isOccupancyAllowedByProvinceOwner(
  Game game,
  String playerId,
  String unitType,
  String? ownerId,
) {
  if (ownerId == null || ownerId.isEmpty)
    return _isExplorerMerchantOrSpy(unitType);
  if (ownerId == playerId) return true;
  if (isGreatPower(game, ownerId)) return isSpyUnit(unitType);
  if (isMinorOrTribe(game, ownerId)) return _isExplorerMerchantOrSpy(unitType);
  return false;
}

bool _isExplorerMerchantOrSpy(String unitType) =>
    isExplorerUnit(unitType) || isMerchantUnit(unitType) || isSpyUnit(unitType);
