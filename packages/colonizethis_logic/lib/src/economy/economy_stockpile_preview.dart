import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../turn/turn_resolver.dart';
import 'economy_preview_stockpile_phase.dart';
import 'economy_production.dart';

/// Preview net stockpile change for one player after economy phases that feed
/// the production panel. SPEC/ui/production-panel.md.
///
/// Phases: Extraction → Riches-to-treasury → Consumption → Production, using
/// the same rules as [applyEconomyPhasesForPreview]. Other players are
/// simulated in lockstep so extraction ordering (e.g. fleet updates from
/// trade interception) matches a full turn.
///
/// Returns only commodities whose quantity changes; omit zero deltas.
Map<String, int> previewStockpileNetDeltaByCommodityForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  final beforePlayer = game.playerById(playerId);
  if (beforePlayer == null) {
    return {};
  }
  final before = beforePlayer.stockpile;
  final afterGame = applyEconomyPhasesForPreview(
    game: game,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
  final after = afterGame.playerById(playerId)?.stockpile ?? before;
  final keys = <String>{...before.quantities.keys, ...after.quantities.keys};
  final out = <String, int>{};
  for (final id in keys) {
    final delta = after.quantityOf(id) - before.quantityOf(id);
    if (delta != 0) {
      out[id] = delta;
    }
  }
  return out;
}

/// Per-phase stockpile commodity deltas for the production panel breakdown
/// dialog. Same parameters and phase order as [previewStockpileNetDeltaByCommodityForPlayer].
///
/// Inner maps omit zero deltas. For every commodity id, the sum of deltas
/// across [EconomyPreviewStockpilePhase.values] equals
/// [previewStockpileNetDeltaByCommodityForPlayer] for that id (or zero if absent).
Map<EconomyPreviewStockpilePhase, Map<String, int>>
previewStockpilePhaseDeltasByCommodityForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  return economyPreviewStockpilePhaseDeltasForPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
}
