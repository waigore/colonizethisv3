/// Phase-planner civilian work-order suggestion filter for orchestrator
/// wiring (Refs #2509 S5 slice — companion to
/// `phase_planner_civilian_work_orders.dart`).
///
/// The orchestrator's economy pass pulls civilian work suggestions from
/// [OrderSuggestionAPI.suggestWorkOrders] (a broader candidate pool than
/// the phase planners directly emit) and then drops the suggestions that
/// the active observer phase forbids by spec. Historically this drop was
/// performed by a now-removed legacy helper in
/// `observer_goal_phase.dart` (Refs #2509 S10), which re-invoked
/// `observerGoalPhaseFor` on every candidate. With the [PhasePlanOutcome]
/// dispatcher already
/// resolving the phase once per player turn
/// (`SPEC/ai/phase-planner-dispatch.md`), the orchestrator can read the
/// suppression contract directly off [PhasePlanOutcome.phase] without
/// repeating the phase computation per candidate.
///
/// This adapter is the orchestrator-side companion to
/// `civilianWorkOrdersFromPhasePlan`: that adapter surfaces the phase
/// planner's own civilian work orders (COLONIAL + DEVELOP), while this
/// adapter rejects suggestion-API candidates that contradict the
/// EXPAND / COLONIAL-lite / DEVELOP suppression matrix below.
///
/// Suppression matrix (mirrors `SPEC/ai/ai-architecture.md` § Observer
/// goal phases (Full AI) and `SPEC/ai/phase-planner-dispatch.md`
/// § Suppression matrix):
///
/// | Phase | Suggestion suppressed |
/// |---|---|
/// | [ObserverGoalPhase.expand] | NW `purchase_land` and NW `build_improvement` (any NW civilian work order) |
/// | [ObserverGoalPhase.colonialLite] | NW `purchase_land` only (NW `build_improvement` passes through so EXPAND-side OW push tolerates incidental NW improvement candidates) |
/// | [ObserverGoalPhase.colonial] | nothing (COLONIAL imperative needs every NW civilian path) |
/// | [ObserverGoalPhase.develop] | NW `purchase_land` only (NW `build_improvement` passes through so the 70 % improvement gate stays reachable) |
///
/// The adapter is pure and deterministic — identical inputs always yield
/// identical outputs (Refs #2509 Must-have #7 determinism). It performs
/// no I/O, no logging, and never re-invokes `observerGoalPhaseFor`
/// because [PhasePlanOutcome] already pinned the active phase.
///
/// Behaviour parity: this adapter reproduces every branch of the
/// now-removed legacy work-order filter exactly. OW `purchase_land`,
/// OW `build_improvement`, and non-acquisition / non-improvement
/// targets in any region always pass through under every phase.
library;

import 'package:colonizethis_data/colonizethis_data.dart' show kNewWorldRegionId;
import 'package:colonizethis_logic/ai_api.dart'
    show kWorkTargetBuildImprovement, kWorkTargetPurchaseLand;
import 'package:colonizethis_models/colonizethis_models.dart'
    show ProvinceId, WorkOrder;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns `true` when [order] must be dropped from the orchestrator's
/// civilian work suggestion pool under [outcome]'s active phase.
///
/// See the library docstring for the full suppression matrix. The short
/// version is: EXPAND drops every NW civilian work order, COLONIAL-lite
/// and DEVELOP drop NW `purchase_land` only, COLONIAL keeps every
/// candidate.
///
/// The function is pure — the same `(order, outcome.phase)` pair always
/// returns the same boolean — so the orchestrator can call it inside a
/// `where(...)` predicate without losing determinism (Refs #2509
/// Must-have #7).
bool shouldSuppressWorkOrderFromPhasePlan(
  WorkOrder order,
  PhasePlanOutcome outcome,
) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
      return _isNewWorldCivilianAcquisitionOrImprovement(order);
    case ObserverGoalPhase.colonialLite:
    case ObserverGoalPhase.develop:
      return _isNewWorldPurchaseLand(order);
    case ObserverGoalPhase.colonial:
      return false;
  }
}

bool _isNewWorldPurchaseLand(WorkOrder order) {
  if (order.target != kWorkTargetPurchaseLand) {
    return false;
  }
  return ProvinceId.regionIdFrom(order.targetTileKey) == kNewWorldRegionId;
}

bool _isNewWorldCivilianAcquisitionOrImprovement(WorkOrder order) {
  if (ProvinceId.regionIdFrom(order.targetTileKey) != kNewWorldRegionId) {
    return false;
  }
  return order.target == kWorkTargetPurchaseLand ||
      order.target == kWorkTargetBuildImprovement;
}
