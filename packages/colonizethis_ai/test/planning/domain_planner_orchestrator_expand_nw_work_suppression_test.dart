// Pins the EXPAND-phase New World work-order filter at the
// `runDomainPlanners` integration boundary (Refs #2509, #2847 Phase 3
// work-order filter wiring):
//
//   - With default soft-phase weights (`newWorldAcquisition > 0`), NW
//     `purchase_land` and NW `build_improvement` suggestions survive the
//     EXPAND filter so colonial civilian work can engage at low priority.
//   - With `newWorldAcquisition == 0.0`, the legacy hard-suppress path drops
//     those NW civilian work orders again.
//
// Conquest army-move scoring (OW vs NW preference under early-sprint weight)
// remains pinned separately below.
//
// Existing tests pin the underlying predicate
// (`packages/colonizethis_ai/test/observer_goal_phase_test.dart` group
// `shouldFilterObserverPhaseWorkOrder`) and the selection priority among
// already-suggested work orders
// (`packages/colonizethis_logic/test/full_ai_civilian_work_selection_colonial_test.dart`).
// Neither pins the **integration** that the orchestrator actually applies the
// EXPAND filter when merging civilian work into `runDomainPlanners` output —
// a tuning change that left the predicate intact but bypassed the filter
// call would silently emit NW work orders while below quota.
//
// The negative control asserts a GP at quota with visible colonial targets
// (`ObserverGoalPhase.colonial`) does not drop the same NW work orders, so a
// regression that over-suppresses NW work in COLONIAL is also caught.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI)
//   - `SPEC/program/order-suggestions.md` § Work orders (visibility)

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

import 'domain_planner_orchestrator_expand_nw_work_suppression_cases.dart';

void main() {
  registerDomainPlannerOrchestratorExpandNwWorkSuppressionCases();
}
