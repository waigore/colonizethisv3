import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/player_state_pipeline.dart';

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
///
/// Debug logging for land totals applied during extraction auto-transport.
/// SPEC/program/auto-transport.md; grep token `extraction auto_transport land`.
void logExtractionAutoTransportLand(
  String playerId,
  Map<CommodityId, int> land,
) {
  if (land.isEmpty) return;
  final totalUnits = land.values.fold<int>(0, (a, b) => a + b);
  final detail = land.entries.map((e) => '${e.key}=${e.value}').join(',');
  economyLog.d(
    'extraction auto_transport land playerId=$playerId totalUnits=$totalUnits detail=$detail',
  );
}

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

  return game.mapPlayers((player) {
    final extracted = extractedByPlayerId[player.id];
    if (extracted == null || extracted.isEmpty) {
      return player;
    }
    final updatedStockpile = applyExtractionToStockpile(
      player.stockpile,
      extracted,
    );
    return player.copyWith(stockpile: updatedStockpile);
  });
}
