import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'turn_resolution_result.dart';

/// Immutable carry-over between economy and combat phases (feeding coverage,
/// idle labour). [game] is the world state after the latest applied phase.
class TurnPipelineState {
  TurnPipelineState({
    required this.game,
    Map<String, double>? landFeedingCoverageByPlayerId,
    Map<String, double>? navalFeedingCoverageByPlayerId,
    Map<String, WorkerIdleCounts>? idleLabourByPlayerId,
    Map<String, int>? overseasExtractionShippedTonnageByPlayerId,
  }) : landFeedingCoverageByPlayerId = Map<String, double>.from(
         landFeedingCoverageByPlayerId ?? const {},
       ),
       navalFeedingCoverageByPlayerId = Map<String, double>.from(
         navalFeedingCoverageByPlayerId ?? const {},
       ),
       idleLabourByPlayerId = Map<String, WorkerIdleCounts>.from(
         idleLabourByPlayerId ?? const {},
       ),
       overseasExtractionShippedTonnageByPlayerId = Map<String, int>.from(
         overseasExtractionShippedTonnageByPlayerId ?? const {},
       );

  final Game game;
  final Map<String, double> landFeedingCoverageByPlayerId;
  final Map<String, double> navalFeedingCoverageByPlayerId;
  final Map<String, WorkerIdleCounts> idleLabourByPlayerId;

  /// Per-Great-Power total cargo-hold tonnage actually shipped by the
  /// extraction phase's overseas auto-transport step this turn.
  ///
  /// The sum is the **post-cargo-cap, pre-interception** allocation
  /// returned by `allocateOverseasToStockpile`: those holds are committed
  /// at departure regardless of any subsequent trade-interception losses,
  /// so they consume ship capacity for the rest of the turn. Per
  /// `SPEC/game/world-market.md` § Cargo and the *Cargo released by
  /// under-used extraction* AC, phase 13 (World Market) computes per-GP
  /// trade cargo capacity as
  /// `max(0, cargoHoldsForHomeFleet − overseasExtractionShippedTonnage)`,
  /// so any reserved-but-unused extraction capacity is released to trade.
  ///
  /// Missing entries (or scripted-extraction runs that bypass the
  /// auto-transport loop) are treated as zero tonnage by the world-market
  /// phase, preserving the legacy contract for callers that have not
  /// wired this signal.
  final Map<String, int> overseasExtractionShippedTonnageByPlayerId;

  TurnPipelineState copyWith({
    Game? game,
    Map<String, double>? landFeedingCoverageByPlayerId,
    Map<String, double>? navalFeedingCoverageByPlayerId,
    Map<String, WorkerIdleCounts>? idleLabourByPlayerId,
    Map<String, int>? overseasExtractionShippedTonnageByPlayerId,
  }) {
    return TurnPipelineState(
      game: game ?? this.game,
      landFeedingCoverageByPlayerId:
          landFeedingCoverageByPlayerId ?? this.landFeedingCoverageByPlayerId,
      navalFeedingCoverageByPlayerId:
          navalFeedingCoverageByPlayerId ?? this.navalFeedingCoverageByPlayerId,
      idleLabourByPlayerId: idleLabourByPlayerId ?? this.idleLabourByPlayerId,
      overseasExtractionShippedTonnageByPlayerId:
          overseasExtractionShippedTonnageByPlayerId ??
              this.overseasExtractionShippedTonnageByPlayerId,
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
