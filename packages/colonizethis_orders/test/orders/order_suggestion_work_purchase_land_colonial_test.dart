// Pins the **must-have #2 (Merchant `purchase_land`)** AC from issue #2509:
//
//   Given a GP in **COLONIAL** phase with idle Merchant units, embassy with a
//   tribe, a visible `newWorld|` province containing a valid `purchase_land`
//   target tile (resource present, prospected if mineral, treasury
//   sufficient), when civilian work planning runs, then a `purchase_land`
//   work order toward that tile is among suggested orders before lower-
//   priority colonial work (deterministic for fixed seed).
//
// Pins the *candidate-emission* contract at the logic suggestion API
// (`DefaultOrderSuggestionAPI.suggestWorkOrders`) — the same boundary
// `order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`
// (PR #2603) pins for the `establishOverture` / `declareWar` diplomatic
// passes. The AI-side ordering of `purchase_land` versus lower-priority
// colonial work is separately pinned by
// `packages/colonizethis_logic/test/full_ai_civilian_work_selection_colonial_test.dart`
// ("Merchant prefers purchase_land in newWorld tribe province"), and the
// AI-side COLONIAL-phase orchestrator integration is pinned by
// `packages/colonizethis_ai/test/domain_planner_orchestrator_colonial_civilian_work_test.dart`
// ("COLONIAL phase emits purchase_land when merchant work is suggested").
// Both rely on the candidate set actually surfacing `purchase_land` from
// the logic API — that pre-requisite was previously implicit. This file
// makes it explicit so future tuning cannot silently drop the
// `purchase_land` candidate for the embassy-stage NW tribe scenario.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Colonial expansion (Full AI) and
//     § Observer goal phases (Full AI) — COLONIAL imperative pursues NW
//     acquisition via the existing colonial paths (Join Empire,
//     `purchase_land`, declare-war + invasion).
//   - `SPEC/program/order-suggestions.md` § Rules / Work orders —
//     `suggestWorkOrders` is the canonical suggestion entry point.
//   - `SPEC/game/civilian-units.md` § Merchant — purchase_land cost +
//     embassy / treasury / resource preconditions.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_purchase_land_colonial_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'colonial purchase_land suggestions (Refs #2509)',
    orderSuggestionWorkPurchaseLandColonialScenarios(),
    runOrderSuggestionWorkPurchaseLandColonialScenario,
  );
}
