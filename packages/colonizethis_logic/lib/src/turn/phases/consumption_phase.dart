import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/src/economy/economy_consumption.dart';
import 'package:colonizethis_world/src/world/player_state_pipeline.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

/// Consumption phase; returns new pipeline state with updated feeding maps.
TurnPipelineState runConsumptionPipelinePhase(TurnPipelineState acc) {
  final game = acc.game;
  final landFeeding = Map<String, double>.from(
    acc.landFeedingCoverageByPlayerId,
  );
  final navalFeeding = Map<String, double>.from(
    acc.navalFeedingCoverageByPlayerId,
  );
  final idleLabour = Map<String, WorkerIdleCounts>.from(
    acc.idleLabourByPlayerId,
  );
  final militaryCounts = militaryTypeCountsByPlayer(game.worldState);

  final mappedGame = game.mapPlayers((player) {
    final regimentCounts =
        militaryCounts.regimentCountsByPlayerId[player.id] ??
        const <String, int>{};
    final shipCounts =
        militaryCounts.shipCountsByPlayerId[player.id] ?? const <String, int>{};

    final result = resolveConsumption(
      stockpile: player.stockpile,
      workers: player.workerPool,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );

    double landCoverage;
    if (result.totalRegiments <= 0) {
      landCoverage = 1.0;
    } else {
      landCoverage = result.fullyFedRegiments / result.totalRegiments;
      if (landCoverage < 0) landCoverage = 0;
      if (landCoverage > 1) landCoverage = 1;
    }
    landFeeding[player.id] = landCoverage;

    double navalCoverage;
    if (result.totalShips <= 0) {
      navalCoverage = 1.0;
    } else {
      navalCoverage = result.fullyFedShips / result.totalShips;
      if (navalCoverage < 0) navalCoverage = 0;
      if (navalCoverage > 1) navalCoverage = 1;
    }
    navalFeeding[player.id] = navalCoverage;
    idleLabour[player.id] = result.idleLabour;
    return player.copyWith(
      stockpile: result.stockpile,
      workerPool: result.workerPool,
    );
  });

  return acc.copyWith(
    game: mappedGame,
    landFeedingCoverageByPlayerId: landFeeding,
    navalFeedingCoverageByPlayerId: navalFeeding,
    idleLabourByPlayerId: idleLabour,
  );
}

TurnPhaseStepOutcome consumptionTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(runConsumptionPipelinePhase(acc));
