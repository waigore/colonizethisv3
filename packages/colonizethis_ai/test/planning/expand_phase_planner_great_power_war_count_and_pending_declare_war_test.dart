// Pins the canonical `greatPowerWarCountOnTarget` and `pendingDeclareWarFrom`
// declare-war coordination helpers in `expand_phase_planner.dart`
// (Refs #2509 S1).
//
// Both helpers were relocated from `colonial_pressure.dart` so they survive
// the now-completed S1 deletion of that file. The canonical implementations
// live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `greatPowerWarCountOnTarget` is consumed by
//     `diplomatic_candidate_scoring_declare_war.dart` § war concentration
//     scoring to suppress dogpile declarations when the prospective target
//     is already engaged in multiple GP-vs-GP wars (resolved relations
//     plus same-turn declare-war orders from earlier Full-AI players).
//   * `pendingDeclareWarFrom` is consumed by
//     `diplomatic_candidate_scoring_declare_war.dart` § same-turn
//     declare-war suppression so the active player does not re-issue a
//     declaration that the prospective target has already committed
//     earlier in the same turn (mutual declarations are not re-issued).
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `greatPowerWarCountOnTarget` counts every Great Power currently at
//      war with the target via [Game.diplomacyRelations]; minor and tribe
//      relations are ignored ([Game.playerById] filter).
//   2. The count folds same-turn declare-war orders from
//      [Orders.diplomaticOrdersByPlayerId] into the same set so a GP that
//      both has an at-war relation AND a same-turn declare-war is counted
//      exactly once (set semantics; no double counting).
//   3. The same-turn fold ignores minor / tribe declarers
//      ([Game.playerById] filter) and ignores orders that are not
//      `DiplomaticOrderType.declareWar` against the target.
//   4. `pendingDeclareWarFrom` returns `false` when
//      [sameTurnPriorDiplomaticOrders] is `null` (no earlier Full-AI
//      player has committed orders yet this turn).
//   5. `pendingDeclareWarFrom` returns `true` exactly when
//      [Orders.diplomaticOrdersByPlayerId] under [declarerFactionId]
//      contains a `DiplomaticOrderType.declareWar` order whose
//      [DiplomaticOrder.targetFactionId] equals [targetFactionId].
//   6. Both helpers are deterministic across repeated calls — required by
//      issue #2509 Must-have #7 (phase planners are pure functions with
//      deterministic inputs).
//
// Thin contract for great-power war count / pending declare-war pin suite
// (Refs #4310 Slice D). Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_great_power_war_count_and_pending_declare_war_cases.dart';

void main() {
  registerExpandPhasePlannerGreatPowerWarCountAndPendingDeclareWarCases();
}
