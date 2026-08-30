// Pins the COLONIAL-lite phase naval move ALLOW contract at `runDomainPlanners`
// (Refs #2509 S10).
// Case bodies: `domain_planner_orchestrator_colonial_lite_naval_allow_cases.dart`.

import 'domain_planner_orchestrator_colonial_lite_naval_allow_cases.dart';

void main() {
  registerDomainPlannerOrchestratorColonialLiteNavalAllowCases();
  registerDomainPlannerOrchestratorColonialLiteNavalAllowTailCases();
}
