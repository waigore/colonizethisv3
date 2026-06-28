import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_lookup.dart';

/// Returns true when [tileKey] is under [playerId]'s control for purposes of
/// civilian development work.
///
/// A tile is controlled when:
/// - It lies in a province owned by the player, or
/// - It appears in [WorldState.purchasedTilesByTileKey] with buyer [playerId]
///   (Merchant purchase_land).
bool isTileControlledByPlayer(Game game, String playerId, String tileKey) {
  final purchased = game.worldState.purchasedTilesByTileKey;
  if (purchased[tileKey] == playerId) return true;

  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return false;

  final province = game.worldState.tryGetProvince(provinceId);
  if (province == null) return false;

  return province.ownerId == playerId;
}
