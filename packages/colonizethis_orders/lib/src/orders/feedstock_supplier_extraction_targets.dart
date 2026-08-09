import 'package:colonizethis_models/colonizethis_models.dart';

import 'feedstock_common.dart';
import 'feedstock_extraction_gate_shared.dart';
import 'feedstock_seller_extraction_targets.dart';

/// Resource ids an affluent **supplier** should extract so it can over-produce
/// the domestically-produced level-0 `build_improvement` input a *peer*
/// below-quota zero-NW lock-recovery seller needs (Refs #2847 § H8-extraction).
Set<String> supplierImprovementInputFeedstockExtractionResourceIds(
  Game game,
  String playerId,
) {
  if (isBelowQuotaZeroNwSeller(game, playerId)) return const <String>{};
  final neededInputs = peerLockRecoverySellerNeededProducibleImprovementInputs(
    game,
    excludePlayerId: playerId,
  );
  if (neededInputs.isEmpty) return const <String>{};
  final feedstock = feedstockCommodityIdsForRecipeOutputs(neededInputs);
  if (feedstock.isEmpty) return const <String>{};
  return feedstockExtractionWhenOwnsUnimprovedTile(game, playerId, feedstock);
}
