import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../economy_phase_sequence.dart';
import '../turn_phase_handler_helpers.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_helpers.dart';
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

    final landCoverage = result.totalRegiments <= 0
        ? 1.0
        : clamp01(result.fullyFedRegiments / result.totalRegiments);
    landFeeding[player.id] = landCoverage;

    final navalCoverage = result.totalShips <= 0
        ? 1.0
        : clamp01(result.fullyFedShips / result.totalShips);
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
) => simplePipelinePhase(
  (pipeline) => runEconomyConsumptionStep(
    pipeline,
    economyPhaseStepContextFromConfig(config),
  ),
)(acc, config, turn);
