/// Embassy / purchased-land stake detection for intervention prompts.
/// SPEC/game/diplomacy.md § Intervention; Refs #4267.
library;

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_relation_lookup.dart';

/// Whether the intervening GP holds an Embassy and/or purchased land with
/// the defender under attack.
class InterventionHoldFlags {
  const InterventionHoldFlags({
    required this.hasEmbassy,
    required this.hasPurchasedLand,
  });

  final bool hasEmbassy;
  final bool hasPurchasedLand;

  bool get isEmpty => !hasEmbassy && !hasPurchasedLand;
}

/// Derives hold flags from live diplomacy and purchased-tile state.
InterventionHoldFlags interventionHoldFlags({
  required Game game,
  required String interveningGpId,
  required String defenderMinorOrTribeId,
}) {
  final hasEmbassy =
      hasEmbassyOverture(game, interveningGpId, defenderMinorOrTribeId);
  final purchasedTiles = PurchasedTileIndex.fromGame(game);
  final hasPurchasedLand = purchasedTiles.attributions.any(
    (attribution) =>
        attribution.owningGpId == interveningGpId &&
        attribution.sourceFactionId == defenderMinorOrTribeId,
  );
  return InterventionHoldFlags(
    hasEmbassy: hasEmbassy,
    hasPurchasedLand: hasPurchasedLand,
  );
}
