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
import 'phase_priority_weights.dart';

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

/// Advisory `[0.0, 1.0]` multiplier for the goal-score colonial-pressure
/// floors (`kMinimumColonialConquerScoreWhenPressure`, etc.) sourced
/// from [PhasePriorityWeights.newWorldAcquisition] (Refs #2847 Phase 2
/// scaffolding).
///
/// Weight-aware companion of the structural booleans
/// [resolvePhaseGoalSuppressColonialPressure] and
/// [resolvePhaseGoalColonialPressureActive]; the booleans remain the
/// production source of truth in this scaffolding slice — Phase 3
/// orchestrator wiring will migrate goal-score sites to multiply the
/// floors by this weight so colonial pressure scales continuously with
/// the active NW acquisition priority instead of switching on/off at
/// the EXPAND→COLONIAL boundary.
///
/// Accepts the [PhasePriorityWeights] value directly (rather than a
/// `PhasePlanOutcome`) because the goal-score call sites operate on
/// the weight slot only and never need the rest of the phase-plan
/// outcome. Pure and deterministic — identical inputs always yield
/// identical results (Refs #2509 Must-have #7).
double resolvePhaseGoalColonialPressureWeight(PhasePriorityWeights weights) =>
    weights.newWorldAcquisition;

/// Advisory `[0.0, 1.0]` multiplier for the goal-score OW-conquest
/// bias sourced from [PhasePriorityWeights.oldWorldConquest] (Refs
/// #2847 Phase 2 scaffolding).
///
/// Companion to [resolvePhaseGoalColonialPressureWeight]; the two
/// resolvers form the OW/NW weight pair the Phase 3 orchestrator
/// wiring will multiply into the goal-score conquer/expand bias. The
/// booleans remain the production source of truth in this slice.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseGoalOldWorldConquestWeight(PhasePriorityWeights weights) =>
    weights.oldWorldConquest;
