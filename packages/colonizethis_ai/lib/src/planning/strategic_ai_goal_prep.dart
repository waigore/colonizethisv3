import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_goal_filter.dart';
import 'phase_priority_weights.dart';
import 'planning_imports.dart';
import 'strategic_planning_input.dart';

final _log = packageLogger();

/// Goal selection and conquest army prep before phase dispatch (Refs #4530).
final class StrategicAiGoalPrep {
  const StrategicAiGoalPrep({
    required this.turn,
    required this.snapshot,
    required this.observerGoalPhase,
    required this.primaryGoal,
    required this.goalScores,
    required this.planningGame,
    required this.planningView,
    required this.planningSnapshot,
  });

  final int turn;
  final AIWorldSnapshot snapshot;
  final ObserverGoalPhase observerGoalPhase;
  final StrategicGoal primaryGoal;
  final Map<StrategicGoal, int> goalScores;
  final Game planningGame;
  final PlayerView planningView;
  final AIWorldSnapshot planningSnapshot;
}

/// Snapshot, primary goal, and optional Home Army split for one AI player.
StrategicAiGoalPrep prepareStrategicAiGoalAndArmy(
  StrategicPlanningInput input,
) {
  final turn = input.game.worldState.turnState.turnNumber;
  final snapshot = AIWorldSnapshot.fromPlayerView(
    input.view,
    topology: input.topology,
  );
  final observerGoalPhase = observerGoalPhaseFor(
    snapshot: snapshot,
    game: input.game,
  );
  final suppressColonialPressure = resolvePhaseGoalSuppressColonialPressure(
    observerGoalPhase,
  );
  // Refs #2847 Phase 3 goal-score wiring: pre-compute the soft-phase
  // priority weights from the pre-prep snapshot/game so the
  // `evaluateStrategicGoalScores` colonial-pressure penalty/floor pass
  // can scale continuously with `newWorldAcquisition` instead of switching
  // on/off at the EXPAND→COLONIAL hard-phase boundary.
  // `goalColonialPressureWeightFor` derives the EXPAND economy plan from the
  // pre-prep `(game, snapshot)` so the treasury-recovery resource-need
  // override lifts the goal-score NW acquisition weight to its `0.60` floor
  // for a below-quota peer-war-locked GP — matching the conquest / naval /
  // diplomacy scoring sites that already consume the dispatched plan's
  // weights. Goal selection precedes `prepareConquestFieldArmy`, so the
  // pre-prep state is the correct input here (Refs #2847 § Resource-need
  // overrides).
  final goalColonialPressureWeight = goalColonialPressureWeightFor(
    snapshot: snapshot,
    game: input.game,
  );
  final goalScores = evaluateStrategicGoalScores(
    snapshot,
    input.config,
    observerGoalPhase: observerGoalPhase,
    colonialPressureWeight: goalColonialPressureWeight,
  );
  var primaryGoal = selectPrimaryGoal(
    snapshot,
    input.config,
    input.seeds.goalSeed,
    nationId: input.nationId,
    turn: turn,
    observerGoalPhase: observerGoalPhase,
    colonialPressureWeight: goalColonialPressureWeight,
  );
  if (suppressColonialPressure &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold) {
    primaryGoal = StrategicGoal.conquer;
  }
  _log.d('primaryGoal=$primaryGoal');
  final planningGame = prepareConquestFieldArmy(
    game: input.game,
    nationId: input.nationId,
    provincesToVictory: snapshot.conquest.provincesToVictory,
    oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
    primaryGoal: primaryGoal,
  );
  final planningView = planningGame == input.game
      ? input.view
      : buildPlayerView(planningGame, input.topology, input.nationId);
  final planningSnapshot = planningView == input.view
      ? snapshot
      : AIWorldSnapshot.fromPlayerView(planningView, topology: input.topology);
  return StrategicAiGoalPrep(
    turn: turn,
    snapshot: snapshot,
    observerGoalPhase: observerGoalPhase,
    primaryGoal: primaryGoal,
    goalScores: goalScores,
    planningGame: planningGame,
    planningView: planningView,
    planningSnapshot: planningSnapshot,
  );
}
