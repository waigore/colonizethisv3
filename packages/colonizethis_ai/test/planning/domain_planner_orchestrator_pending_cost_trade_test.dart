// Pins the Refs #3122 orchestrator wiring for the
// `recomputeTradeOrdersWithPendingCosts` flag on
// `runDomainPlannersWithOutcome`. Case bodies live in sibling modules.

import 'domain_planner_orchestrator_pending_cost_trade_cases.dart';

void main() {
  registerDomainPlannerOrchestratorPendingCostTradeCases();
}
