// Pins the DEVELOP-phase `declareWar` suppression AC from issue #2509 at the
// `runDomainPlanners` integration boundary. Case bodies live in the sibling
// `domain_planner_orchestrator_develop_declare_war_suppression_cases.dart`.

import 'package:colonizethis_test/test.dart';

import 'domain_planner_orchestrator_develop_declare_war_suppression_cases.dart';

void main() {
  registerDomainPlannerOrchestratorDevelopDeclareWarSuppressionCases();
}
