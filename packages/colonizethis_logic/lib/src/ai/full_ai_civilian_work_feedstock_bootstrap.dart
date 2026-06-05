import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'full_ai_civilian_work_selection.dart';

/// True when level-0 `build_improvement` on an unimproved feedstock tile under
/// the H8 feedstock-extraction gate may omit the `castIron` material input.
///
/// Closes the circular dependency pinned on seed 42: improving the `timber` /
/// `iron` (or seller `wool` / `cotton`) feedstock tile costs `castIron`, but
/// no GP holds `castIron` until that tile is improved and production runs.
/// The waiver applies only while the gate is active, the target tile hosts an
/// unimproved feedstock resource, and the GP holds enough `lumber` for the
/// level-0 cost but not enough `castIron`. Once `castIron` is affordable, the
/// full `{lumber, castIron}` cost applies. Refs #2847 H8-extraction.
bool feedstockBootstrapBuildImprovementCastIronWaived(
  Game game,
  String playerId,
  String targetTileKey,
) {
  final feedstockIds = feedstockExtractionResourceIdsForPlayer(game, playerId);
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  final resourceId = ws.resourceByTileKey[targetTileKey];
  if (resourceId == null || !feedstockIds.contains(resourceId)) return false;
  if (ws.tileState.improvementLevel(targetTileKey) >= 1) return false;
  Player? player;
  for (final p in game.players) {
    if (p.id == playerId) {
      player = p;
      break;
    }
  }
  if (player == null) return false;
  final baseCost = workOrderCostBuildImprovement(0);
  final castIronId = CommodityCatalog.castIron.id;
  final castIronRequired = baseCost[castIronId] ?? 0;
  if (castIronRequired <= 0) return false;
  if (player.stockpile.quantityOf(castIronId) >= castIronRequired) {
    return false;
  }
  final lumberId = CommodityCatalog.lumber.id;
  final lumberRequired = baseCost[lumberId] ?? 0;
  return player.stockpile.quantityOf(lumberId) >= lumberRequired;
}
