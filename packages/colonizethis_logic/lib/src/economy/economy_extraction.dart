import 'package:colonizethis_models/colonizethis_models.dart';

/// Extraction and auto-transport helpers.
/// SPEC/game/extraction-and-improvements.md
/// SPEC/game/stockpiles-and-production.md
/// SPEC/program/auto-transport.md
///
/// World-level extraction from tiles/provinces is resolved elsewhere; this
/// helper applies per-commodity extracted quantities to a player's stockpile
/// with auto-transport semantics (all to central stockpile). The stockpile is
/// a strategic abstraction with no warehouse capacity clamp — see
/// stockpiles-and-production § Strategic abstraction.

/// Applies [extracted] commodity quantities to [stockpile], returning the
/// updated stockpile. Negative values in [extracted] are treated as zero.
/// There is no maximum stockpile size; deltas add without storage caps.
Stockpile applyExtractionToStockpile(
  Stockpile stockpile,
  Map<CommodityId, int> extracted,
) {
  var result = stockpile;
  for (final entry in extracted.entries) {
    final qty = entry.value;
    if (qty <= 0) continue;
    result = result.applyDelta(entry.key, qty);
  }
  return result;
}

/// Applies per-player extracted quantities to all players in [game], returning
/// a new [Game] with updated player stockpiles.
///
/// [extractedByPlayerId] is keyed by player id; each value is a commodity id →
/// quantity map, already aggregated from world/province state.
Game applyExtractionForPlayers(
  Game game,
  Map<String, Map<CommodityId, int>> extractedByPlayerId,
) {
  if (extractedByPlayerId.isEmpty) return game;

  final updatedPlayers = <Player>[];
  for (final player in game.players) {
    final extracted = extractedByPlayerId[player.id];
    if (extracted == null || extracted.isEmpty) {
      updatedPlayers.add(player);
      continue;
    }
    final updatedStockpile = applyExtractionToStockpile(
      player.stockpile,
      extracted,
    );
    updatedPlayers.add(player.copyWith(stockpile: updatedStockpile));
  }

  return game.copyWith(players: updatedPlayers);
}

