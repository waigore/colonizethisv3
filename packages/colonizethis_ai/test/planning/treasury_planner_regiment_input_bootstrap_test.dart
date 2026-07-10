// Table-driven consolidation of treasury planner regiment build-input
// bootstrap / bid-side suites (Refs #3941).
//
// Single contract file for lock-recovery bootstrap, improvement-input, and
// castIron domestic-production pins. Shared fixtures live in
// `treasury_planner_regiment_input_support.dart`; case bodies are in
// `treasury_planner_regiment_input_bootstrap_cases.dart`.
//
// Coverage is preserved 1:1 from the former
// `treasury_planner_regiment_input_{bootstrap,improvement_bootstrap,
// castiron_production}_test.dart` shards.

import 'treasury_planner_regiment_input_bootstrap_cases.dart';

void main() {
  registerTreasuryRegimentInputBootstrapCases();
}
