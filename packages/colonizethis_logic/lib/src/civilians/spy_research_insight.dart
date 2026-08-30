import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show kUnitTypeSpy, projectedCivilianTileKey;
import 'package:colonizethis_world/colonizethis_world.dart';

/// Commit-time gist for rival-GP spy posts (Refs #4679).
enum SpyResearchInsightGistKind {
  none,
  maySpeedResearch,
  alreadyGrantsInsight,
}

/// True when [prefixedProvinceId] is owned by a rival Great Power.
bool isRivalGreatPowerProvinceForPlayer({
  required Game game,
  required String prefixedProvinceId,
  required String humanPlayerId,
}) {
  final province = game.worldState.tryGetProvince(prefixedProvinceId);
  if (province == null) return false;
  final ownerId = province.ownerId;
  if (ownerId == null || ownerId == humanPlayerId) return false;
  return game.playerById(ownerId) != null;
}

/// Counts human Spies whose projected tile lies in a province owned by
/// [rivalGpId].
int countOwnSpiesProjectedInRivalGp({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String rivalGpId,
}) {
  if (rivalGpId.isEmpty) return 0;
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);
  var count = 0;
  for (final unit in game.worldState.allUnitsById.values) {
    if (unit.ownerId != humanPlayerId) continue;
    if (unit.type != kUnitTypeSpy) continue;
    final tileKey = projectedCivilianTileKey(
      unit: unit,
      playerId: humanPlayerId,
      orders: orders,
    );
    if (tileKey == null) continue;
    final provinceFullId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceFullId == null) continue;
    if (ownerByProvince[provinceFullId] == rivalGpId) {
      count++;
    }
  }
  return count;
}

/// Gist kind for stationing in [prefixedProvinceId]; omits Minor/Tribe posts.
SpyResearchInsightGistKind spyResearchInsightGistKindForProvince({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String prefixedProvinceId,
}) {
  final province = game.worldState.tryGetProvince(prefixedProvinceId);
  if (province == null) return SpyResearchInsightGistKind.none;
  final ownerId = province.ownerId;
  if (ownerId == null || ownerId == humanPlayerId) {
    return SpyResearchInsightGistKind.none;
  }
  if (game.playerById(ownerId) == null) {
    return SpyResearchInsightGistKind.none;
  }
  if (countOwnSpiesProjectedInRivalGp(
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        rivalGpId: ownerId,
      ) >=
      1) {
    return SpyResearchInsightGistKind.alreadyGrantsInsight;
  }
  return SpyResearchInsightGistKind.maySpeedResearch;
}

/// Gist kind for the province containing [tileKey].
SpyResearchInsightGistKind spyResearchInsightGistKindForTile({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String tileKey,
}) {
  final provinceFullId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceFullId == null) return SpyResearchInsightGistKind.none;
  return spyResearchInsightGistKindForProvince(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
    prefixedProvinceId: provinceFullId,
  );
}
