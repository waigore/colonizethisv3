import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show getRelation, hasConsulateOverture;
import 'package:colonizethis_models/colonizethis_models.dart';

// World-market sell-priority relation tiebreaker input builder (#3753 R7.3).
// Extracted from `world_market_phase.dart` so the phase handler stays within
// the function-size budget; the result feeds `DealMatchInputs`.

/// Builds the #3753 R7.3 sell-priority relation map consumed by the deal
/// matcher: for each Minor/Tribe seller that has an offer this turn, the
/// consulate-holding (or higher) Great-Power buyers and their relation score
/// with that seller (`SPEC/game/world-market.md` § Sell-priority relation
/// tiebreaker, `SPEC/program/world-market-resolution.md` § Step B item 4).
///
/// Only Minor/Tribe sellers that actually appear in [offersByFactionId] are
/// scanned (bounded work per turn). Great-Power sellers are intentionally
/// excluded — the tiebreaker applies to Minor/Tribe sellers only, so GP-seller
/// offers keep the legacy buyer ordering. A seller with no consulate-holding
/// buyer is omitted entirely so the matcher preserves default ordering for it.
Map<String, Map<String, num>> computeSellPriorityRelations({
  required Game game,
  required Map<String, List<TradeOrder>> offersByFactionId,
}) {
  final minorTribeIds = <String>{
    for (final m in game.minorNations) m.id,
    for (final t in game.tribes) t.id,
  };
  if (minorTribeIds.isEmpty) return const <String, Map<String, num>>{};

  final result = <String, Map<String, num>>{};
  for (final sellerId in offersByFactionId.keys) {
    if (!minorTribeIds.contains(sellerId)) continue;
    final relations = <String, num>{};
    for (final player in game.players) {
      if (player.id == sellerId) continue;
      if (!hasConsulateOverture(game, player.id, sellerId)) continue;
      relations[player.id] = getRelation(game, player.id, sellerId)?.score ?? 0;
    }
    if (relations.isNotEmpty) result[sellerId] = relations;
  }
  return result;
}
