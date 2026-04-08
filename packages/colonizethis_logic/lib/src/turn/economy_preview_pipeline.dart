import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../economy/economy_preview_stockpile_phase.dart';
import '../economy/build_cost.dart';
import 'phases/consumption_phase.dart';
import 'phases/extraction_phase.dart';
import 'phases/production_phase.dart';
import 'phases/riches_to_treasury_phase.dart';
import 'turn_pipeline_state.dart';

Map<String, int> _stockpileCommodityDeltaMap(
  Stockpile before,
  Stockpile after,
) {
  final keys = <String>{...before.quantities.keys, ...after.quantities.keys};
  final out = <String, int>{};
  for (final k in keys) {
    final d = after.quantityOf(k) - before.quantityOf(k);
    if (d != 0) {
      out[k] = d;
    }
  }
  return out;
}

Game _applyPendingBuildTrainCostsPreview({
  required Game game,
  required Orders pendingOrders,
}) {
  if (pendingOrders.buildUnitOrdersByPlayerId.isEmpty) {
    return game;
  }
  var nextGame = game;
  for (final player in nextGame.players) {
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;
    final buildOrders =
        pendingOrders.buildUnitOrdersByPlayerId[player.id] ?? const [];
    for (final order in buildOrders) {
      final afford = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!afford.canAfford) {
        continue;
      }
      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
    nextGame = nextGame.copyWith(
      players: nextGame.players
          .map(
            (p) => p.id == player.id
                ? p.copyWith(
                    workerPool: workers,
                    stockpile: stockpile,
                    treasury: treasury,
                  )
                : p,
          )
          .toList(),
    );
  }
  return nextGame;
}

/// Per-phase stockpile commodity deltas for [playerId] when running the same
/// preview pipeline as [applyEconomyPhasesForPreview]. Maps omit zero deltas.
Map<EconomyPreviewStockpilePhase, Map<String, int>>
economyPreviewStockpilePhaseDeltasForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  Orders pendingOrders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  final empty = {
    for (final p in EconomyPreviewStockpilePhase.values) p: <String, int>{},
  };
  if (game.playerById(playerId) == null) {
    return empty;
  }

  Stockpile stockpileForViewed(Game g) {
    final p = g.playerById(playerId);
    return p?.stockpile ?? const Stockpile();
  }

  var acc = TurnPipelineState(game: game);

  final beforePendingBuildTrainCosts = stockpileForViewed(acc.game);
  acc = acc.copyWith(
    game: _applyPendingBuildTrainCostsPreview(
      game: acc.game,
      pendingOrders: pendingOrders,
    ),
  );
  final pendingBuildTrainCosts = _stockpileCommodityDeltaMap(
    beforePendingBuildTrainCosts,
    stockpileForViewed(acc.game),
  );

  final beforeExtraction = stockpileForViewed(acc.game);
  acc = acc.copyWith(
    game: runExtractionPhase(
      acc.game,
      topology,
      tileMapByRegion,
      extractedByPlayerId,
    ),
  );
  final extraction = _stockpileCommodityDeltaMap(
    beforeExtraction,
    stockpileForViewed(acc.game),
  );

  final beforeRiches = stockpileForViewed(acc.game);
  acc = acc.copyWith(game: runRichesToTreasuryPhase(acc.game));
  final richesToTreasury = _stockpileCommodityDeltaMap(
    beforeRiches,
    stockpileForViewed(acc.game),
  );

  final beforeConsumption = stockpileForViewed(acc.game);
  acc = runConsumptionPipelinePhase(acc);
  final consumption = _stockpileCommodityDeltaMap(
    beforeConsumption,
    stockpileForViewed(acc.game),
  );

  final beforeProduction = stockpileForViewed(acc.game);
  acc = runProductionPipelinePhase(
    acc,
    defaultAssignments,
    defaultAssignmentsByPlayerId,
    null,
  );
  final production = _stockpileCommodityDeltaMap(
    beforeProduction,
    stockpileForViewed(acc.game),
  );

  return {
    EconomyPreviewStockpilePhase.pendingBuildTrainCosts: pendingBuildTrainCosts,
    EconomyPreviewStockpilePhase.extraction: extraction,
    EconomyPreviewStockpilePhase.richesToTreasury: richesToTreasury,
    EconomyPreviewStockpilePhase.consumption: consumption,
    EconomyPreviewStockpilePhase.production: production,
  };
}

/// Runs Extraction → Riches-to-treasury → Consumption → Production only.
Game applyEconomyPhasesForPreview({
  required Game game,
  required MapTopology topology,
  Orders pendingOrders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  var acc = TurnPipelineState(game: game);
  acc = acc.copyWith(
    game: _applyPendingBuildTrainCostsPreview(
      game: acc.game,
      pendingOrders: pendingOrders,
    ),
  );
  acc = acc.copyWith(
    game: runExtractionPhase(
      acc.game,
      topology,
      tileMapByRegion,
      extractedByPlayerId,
    ),
  );
  acc = acc.copyWith(game: runRichesToTreasuryPhase(acc.game));
  acc = runConsumptionPipelinePhase(acc);
  acc = runProductionPipelinePhase(
    acc,
    defaultAssignments,
    defaultAssignmentsByPlayerId,
    null,
  );
  return acc.game;
}
