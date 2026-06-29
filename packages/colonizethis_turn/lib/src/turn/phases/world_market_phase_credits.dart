import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show getRelation, hasEmbassyOverture;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// World-market overseas profit-share credit helper (Refs #2992 D4 + #3753 R8).
// Extracted from `world_market_phase.dart` so the phase handler stays within
// the function-size budget; behaviour is unchanged.

/// Computes the two-tier overseas profit-share credits for a resolved set of
/// [filledDeals]: the tile-owning GP receives the full relation-linear share
/// (R8.2) and every other embassy-holding GP receives a 10% kickback of its
/// relation portion (R8.3).
///
/// Embassy kickbacks apply only to Minor/Tribe sellers (overseas profit-share
/// is a Minor/Tribe-sale concept; GP–GP sales are excluded even though GPs hold
/// auto-embassies). The eligible-source set is built once and a per-source
/// cache of embassy-holding GPs and their decimal relation scores keeps the
/// credits aggregator a deterministic pure function.
FirstRightCreditsResult computeWorldMarketFirstRightCredits({
  required Game game,
  required List<FilledDeal> filledDeals,
  required PurchasedTileIndex purchasedTileIndex,
}) {
  final minorTribeSellerIds = <String>{
    for (final m in game.minorNations) m.id,
    for (final t in game.tribes) t.id,
  };
  final embassyRelationsCache = <String, Map<String, num>>{};
  Map<String, num> embassyGpRelationsFor(String sourceFactionId) {
    if (!minorTribeSellerIds.contains(sourceFactionId)) {
      return const <String, num>{};
    }
    final cached = embassyRelationsCache[sourceFactionId];
    if (cached != null) return cached;
    final relations = <String, num>{};
    for (final player in game.players) {
      if (player.id == sourceFactionId) continue;
      if (!hasEmbassyOverture(game, player.id, sourceFactionId)) continue;
      relations[player.id] =
          getRelation(game, player.id, sourceFactionId)?.score ?? 0;
    }
    embassyRelationsCache[sourceFactionId] = relations;
    return relations;
  }

  return computeFirstRightCredits(
    filledDeals: filledDeals,
    purchasedTileIndex: purchasedTileIndex,
    relationScoreFor: (owningGpId, sourceFactionId) =>
        getRelation(game, owningGpId, sourceFactionId)?.score ?? 0,
    embassyGpRelationsFor: embassyGpRelationsFor,
  );
}
