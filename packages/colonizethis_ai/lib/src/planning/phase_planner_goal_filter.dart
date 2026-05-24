/// Phase-planner goal-scoring directive resolvers (Refs #2509 S5 slice).
///
/// Replaces the legacy `colonial_pressure.dart` / `observer_goal_phase.dart`
/// compound predicates in `strategic_ai.dart` and `goal_manager.dart` with
/// structural phase gates. `generateStrategicOrders` resolves
/// `observerGoalPhaseFor` once per player turn and threads the phase into
/// goal evaluation instead of recomputing `isStalledOldWorldGpBlockerFocus ||
/// isBelowObserverConquestQuota` and the three-predicate colonial-pressure
/// block on every goal score.
library;

import 'observer_goal_phase.dart';

/// When `true`, `evaluateStrategicGoalScores` must not apply the late-game
/// colonial-pressure conquer/expand/diplomacy/trade score floors.
///
/// Field-equal to legacy
/// `isStalledOldWorldGpBlockerFocus(game, snapshot) ||
/// isBelowObserverConquestQuota(ow)` because below-quota phases already
/// satisfy `isBelowObserverConquestQuota` and the GP-blocker arm is a
/// subset of that condition.
///
/// Active under EXPAND and COLONIAL-lite (both require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at phase
/// entry). COLONIAL and DEVELOP return `false`.
bool resolvePhaseGoalSuppressColonialPressure(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.expand ||
    phase == ObserverGoalPhase.colonialLite;

/// When `true`, `evaluateStrategicGoalScores` applies the colonial-pressure
/// score floors (`kMinimumColonialConquerScoreWhenPressure`, etc.).
///
/// Field-equal to legacy
/// `!suppressColonialPressure &&
/// hasColonialAcquisitionTargets(snapshot.colonial) &&
/// !shouldSuppressNewWorldColonialOrders(snapshot, game)` on the
/// production path: suppress is below-quota only, acquisition targets
/// gate COLONIAL phase entry, and NW colonial orders are suppressed only
/// under EXPAND.
///
/// Active only under [ObserverGoalPhase.colonial], mirroring
/// [resolvePhaseEconomyColonialPressureActive] and
/// [resolvePhaseConquestColonialPressureActive].
bool resolvePhaseGoalColonialPressureActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.colonial;
