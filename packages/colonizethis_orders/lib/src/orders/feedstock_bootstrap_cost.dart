/// Work-order material-cost waivers for the H8 feedstock bootstrap.
///
/// Lives in `orders/` because these helpers compute effective `build_improvement`
/// material cost (consumed by `WorkOrderCostCalculator`); they consume
/// `feedstock_extraction_targets.dart` from the same domain. Relocated out of
/// `src/ai/` to keep the orders -> ai import edge one-way. Refs #3290; #2847 § H8.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'feedstock_extraction_targets.dart';

bool _isUnimprovedFeedstockTile(
  Game game,
  String playerId,
  String targetTileKey,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  final resourceId = ws.resourceByTileKey[targetTileKey];
  if (resourceId == null || !feedstockIds.contains(resourceId)) return false;
  if (ws.tileState.improvementLevel(targetTileKey) >= 1) return false;
  return true;
}

bool _isFeedstockBootstrapTarget(
  Game game,
  String playerId,
  String targetTileKey,
) {
  return _isUnimprovedFeedstockTile(
    game,
    playerId,
    targetTileKey,
    feedstockExtractionResourceIdsForPlayer(game, playerId),
  );
}

/// Improvement-input feedstock tiles (`timber` / `iron`) only — excludes the
/// regiment-build-input fabric feedstock (`wool` / `cotton`) so the lumber
/// bootstrap does not zero-cost-improve the fabric chain and regress peer OW
/// conquest on seed 42.
bool _isImprovementInputFeedstockBootstrapTarget(
  Game game,
  String playerId,
  String targetTileKey,
) {
  return _isUnimprovedFeedstockTile(
    game,
    playerId,
    targetTileKey,
    <String>{
      ...sellerImprovementInputFeedstockExtractionResourceIds(game, playerId),
      ...supplierImprovementInputFeedstockExtractionResourceIds(game, playerId),
    },
  );
}

Player? _playerById(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p;
  }
  return null;
}

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
  if (!_isFeedstockBootstrapTarget(game, playerId, targetTileKey)) {
    return false;
  }
  final player = _playerById(game, playerId);
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

/// True when level-0 `build_improvement` on an unimproved feedstock tile under
/// the H8 feedstock-extraction gate may omit the `lumber` material input.
///
/// Closes the lumber circular dependency pinned on seed 42 (S7-D
/// re-localization): improving the seller's own `timber` feedstock tile costs
/// `lumber`, but the seller holds `lumber == 0` because `lumber_from_timber`
/// needs extracted `timber`, which only arrives after the tile is improved.
/// The waiver applies only while the gate is active, the target tile hosts an
/// unimproved feedstock resource, and the GP is short **both** `lumber` and
/// `castIron` for the level-0 cost — the full bootstrap deadlock before any
/// improvement-input is on hand. Once the GP holds enough `lumber`, only the
/// existing [feedstockBootstrapBuildImprovementCastIronWaived] path applies.
/// Refs #2847 H8-extraction; S7-D lumber bootstrap.
bool feedstockBootstrapBuildImprovementLumberWaived(
  Game game,
  String playerId,
  String targetTileKey,
) {
  if (!_isImprovementInputFeedstockBootstrapTarget(
    game,
    playerId,
    targetTileKey,
  )) {
    return false;
  }
  final player = _playerById(game, playerId);
  if (player == null) return false;
  final baseCost = workOrderCostBuildImprovement(0);
  final lumberId = CommodityCatalog.lumber.id;
  final lumberRequired = baseCost[lumberId] ?? 0;
  if (lumberRequired <= 0) return false;
  if (player.stockpile.quantityOf(lumberId) >= lumberRequired) return false;
  final castIronId = CommodityCatalog.castIron.id;
  final castIronRequired = baseCost[castIronId] ?? 0;
  if (castIronRequired > 0 &&
      player.stockpile.quantityOf(castIronId) >= castIronRequired) {
    return false;
  }
  return true;
}

/// Effective level-0 `build_improvement` material cost for [targetTileKey]
/// after H8 feedstock-bootstrap waivers. Returns the base cost when no waiver
/// applies. Refs #2847 H8-extraction.
Map<String, int> feedstockBootstrapBuildImprovementEffectiveCost(
  Game game,
  String playerId,
  String targetTileKey,
) {
  final baseCost = workOrderCostBuildImprovement(0);
  if (!_isFeedstockBootstrapTarget(game, playerId, targetTileKey)) {
    return baseCost;
  }
  final effective = Map<String, int>.from(baseCost);
  if (feedstockBootstrapBuildImprovementLumberWaived(
    game,
    playerId,
    targetTileKey,
  )) {
    // Full bootstrap deadlock: waive both inputs so the first feedstock tile
    // can improve with zero material cost.
    effective.remove(CommodityCatalog.lumber.id);
    effective.remove(CommodityCatalog.castIron.id);
  } else if (feedstockBootstrapBuildImprovementCastIronWaived(
    game,
    playerId,
    targetTileKey,
  )) {
    effective.remove(CommodityCatalog.castIron.id);
  }
  return Map<String, int>.unmodifiable(effective);
}
