import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'feedstock_common.dart';
import 'province_tile_lookup.dart';

/// True iff [playerId] holds Old World land below the observer conquest quota
/// (`oldWorldProvinceCountOwnedBy` in `[2, kObserverConquestMinOwProvincesPerGp)`)
/// and owns zero New World provinces — the Path F lock-recovery seller band the
/// supplier role must exclude.
bool isBelowQuotaZeroNwSeller(Game game, String playerId) {
  final ow = oldWorldProvinceCountOwnedBy(game, playerId);
  if (ow < 2) return false;
  if (!isBelowObserverConquestQuota(ow)) return false;
  return newWorldProvinceCountOwnedBy(game, playerId) == 0;
}

int newWorldProvinceCountOwnedBy(Game game, String playerId) {
  return ProvinceOwnerCache.of(
    game.worldState,
  ).countOwnedByInRegion(playerId, kRegionNewWorld);
}

/// True iff [playerId] owns at least one province tile hosting a resource in
/// [feedstockIds] that is still unimproved (`improvementLevel < 1`).
bool ownsUnimprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    final province = tryGetProvinceAtTileKey(ws, entry.key);
    if (province == null || province.ownerId != playerId) continue;
    if (ws.tileState.improvementLevel(entry.key) < 1) return true;
  }
  return false;
}

Set<String> feedstockExtractionWhenOwnsUnimprovedTile(
  Game game,
  String playerId,
  Set<String> feedstock,
) {
  if (feedstock.isEmpty) return const <String>{};
  if (!ownsUnimprovedFeedstockResourceTile(game, playerId, feedstock)) {
    return const <String>{};
  }
  return feedstock;
}

/// The producible level-0 `build_improvement` input commodities [player] is
/// short of at its active improvement-cost gate.
Set<String> producibleImprovementInputsShortForPlayer(
  Game game,
  Player player,
  Map<String, int> Function(Game game, String playerId) improvementInputCost,
) {
  final cost = improvementInputCost(game, player.id);
  if (cost.isEmpty) return const <String>{};
  final result = <String>{};
  for (final entry in cost.entries) {
    final producible = ProductionRecipesCatalog.all.any(
      (r) => r.outputCommodityId == entry.key,
    );
    if (!producible) continue;
    if (player.stockpile.quantityOf(entry.key) < entry.value) {
      result.add(entry.key);
    }
  }
  return result;
}
