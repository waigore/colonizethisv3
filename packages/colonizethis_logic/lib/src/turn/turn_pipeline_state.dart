import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/game_world_mutations.dart';
import 'turn_resolution_result.dart';

/// Immutable carry-over between economy and combat phases (feeding coverage,
/// idle labour). [game] is the world state after the latest applied phase.
class TurnPipelineState {
  TurnPipelineState({
    required this.game,
    Map<String, double>? landFeedingCoverageByPlayerId,
    Map<String, double>? navalFeedingCoverageByPlayerId,
    Map<String, WorkerIdleCounts>? idleLabourByPlayerId,
  }) : landFeedingCoverageByPlayerId = Map<String, double>.from(
         landFeedingCoverageByPlayerId ?? const {},
       ),
       navalFeedingCoverageByPlayerId = Map<String, double>.from(
         navalFeedingCoverageByPlayerId ?? const {},
       ),
       idleLabourByPlayerId = Map<String, WorkerIdleCounts>.from(
         idleLabourByPlayerId ?? const {},
       );

  final Game game;
  final Map<String, double> landFeedingCoverageByPlayerId;
  final Map<String, double> navalFeedingCoverageByPlayerId;
  final Map<String, WorkerIdleCounts> idleLabourByPlayerId;

  TurnPipelineState copyWith({
    Game? game,
    Map<String, double>? landFeedingCoverageByPlayerId,
    Map<String, double>? navalFeedingCoverageByPlayerId,
    Map<String, WorkerIdleCounts>? idleLabourByPlayerId,
  }) {
    return TurnPipelineState(
      game: game ?? this.game,
      landFeedingCoverageByPlayerId:
          landFeedingCoverageByPlayerId ?? this.landFeedingCoverageByPlayerId,
      navalFeedingCoverageByPlayerId:
          navalFeedingCoverageByPlayerId ?? this.navalFeedingCoverageByPlayerId,
      idleLabourByPlayerId: idleLabourByPlayerId ?? this.idleLabourByPlayerId,
    );
  }

  /// Returns a copy whose [game.worldState] is updated via [update] (Refs #2560).
  TurnPipelineState updateWorldState(
    WorldState Function(WorldState current) update,
  ) => copyWith(game: game.updateWorldState(update));
}

/// Result of stepping one turn phase: continue the pipeline or exit with a
/// pending [TurnResolutionResult].
sealed class TurnPhaseStepOutcome {
  const TurnPhaseStepOutcome();
}

final class TurnPhaseStepContinue extends TurnPhaseStepOutcome {
  const TurnPhaseStepContinue(this.pipeline);
  final TurnPipelineState pipeline;
}

final class TurnPhaseStepExit extends TurnPhaseStepOutcome {
  const TurnPhaseStepExit(this.result);
  final TurnResolutionResult result;
}
