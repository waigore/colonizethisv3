import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'feedstock_common.dart';
import 'feedstock_extraction_gate_shared.dart';

/// Resource ids a below-quota zero-NW lock-recovery seller should extract to
/// domestically produce the cheapest regiment's missing build input
/// (Refs #2847 § H8-extraction).
Set<String> regimentBuildInputFeedstockExtractionResourceIds(
  Game game,
  String playerId,
) {
  final player = game.playerById(playerId);
  if (player == null) return const <String>{};
  if (regimentCountForPlayer(game, playerId) != 0) return const <String>{};
  if (!isBelowQuotaZeroNwSeller(game, playerId)) return const <String>{};
  final missingInputs = <CommodityId>{
    for (final entry
        in RegimentEconomyCatalog.peasantLevies.buildInputs.entries)
      if (player.stockpile.quantityOf(entry.key) < entry.value) entry.key,
  };
  if (missingInputs.isEmpty) return const <String>{};
  return feedstockCommodityIdsForRecipeOutputs(missingInputs);
}

/// Level-0 `build_improvement` material cost a below-quota zero-NW
/// lock-recovery seller must hold to extract its own fabric feedstock tile.
Map<String, int> regimentBuildInputFeedstockImprovementInputCost(
  Game game,
  String playerId,
) {
  final feedstockIds = regimentBuildInputFeedstockExtractionResourceIds(
    game,
    playerId,
  );
  if (feedstockIds.isEmpty) return const <String, int>{};
  if (!ownsUnimprovedFeedstockResourceTile(game, playerId, feedstockIds)) {
    return const <String, int>{};
  }
  return Map<String, int>.unmodifiable(workOrderCostBuildImprovement(0));
}

/// Resource ids a below-quota zero-NW lock-recovery **seller** should extract so
/// it can domestically produce level-0 `build_improvement` inputs it is short of.
Set<String> sellerImprovementInputFeedstockExtractionResourceIds(
  Game game,
  String playerId,
) {
  final feedstock = sellerImprovementInputFeedstockResourceIds(game, playerId);
  return feedstockExtractionWhenOwnsUnimprovedTile(game, playerId, feedstock);
}

/// The production-recipe feedstock commodities of every recipe whose output is
/// a producible level-0 `build_improvement` input the seller still needs.
Set<String> sellerImprovementInputFeedstockResourceIds(
  Game game,
  String playerId,
) {
  final neededInputs = selfLockRecoverySellerNeededProducibleImprovementInputs(
    game,
    playerId,
  );
  if (neededInputs.isEmpty) return const <String>{};
  return feedstockCommodityIdsForRecipeOutputs(neededInputs);
}

/// Producible level-0 `build_improvement` input commodities still missing from
/// at least one *other* below-quota zero-NW lock-recovery seller.
Set<String> peerLockRecoverySellerNeededProducibleImprovementInputs(
  Game game, {
  required String excludePlayerId,
}) {
  final result = <String>{};
  for (final player in game.players) {
    if (player.id == excludePlayerId) continue;
    result.addAll(
      producibleImprovementInputsShortForPlayer(
        game,
        player,
        regimentBuildInputFeedstockImprovementInputCost,
      ),
    );
  }
  return result;
}

/// Producible level-0 `build_improvement` input commodities [playerId] is
/// itself short of and can produce domestically.
Set<String> selfLockRecoverySellerNeededProducibleImprovementInputs(
  Game game,
  String playerId,
) {
  for (final player in game.players) {
    if (player.id != playerId) continue;
    return producibleImprovementInputsShortForPlayer(
      game,
      player,
      regimentBuildInputFeedstockImprovementInputCost,
    );
  }
  return const <String>{};
}
