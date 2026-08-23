// Pins the EXPAND-phase New World work-order filter at the
// `runDomainPlanners` integration boundary (Refs #2509, #2847, #4602).
// SPEC: `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI);
// `SPEC/program/order-suggestions.md` § Work orders.

import 'domain_planner_orchestrator_expand_nw_work_suppression_army_cases.dart';
import 'domain_planner_orchestrator_expand_nw_work_suppression_cases.dart';

void main() {
  registerDomainPlannerOrchestratorExpandNwWorkSuppressionCases();
  registerDomainPlannerOrchestratorExpandNwWorkSuppressionArmyCases();
}
