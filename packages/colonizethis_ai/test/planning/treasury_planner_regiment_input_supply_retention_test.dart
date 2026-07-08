// Table-driven consolidation of treasury planner regiment build-input
// supply / retention / offer-side suites (Refs #3941).
//
// Single contract file for market supply, produced-build-input retention,
// feedstock reservation, and castIron-labour peasant-recruit pins. Shared
// fixtures live in `treasury_planner_regiment_input_support.dart`; case
// bodies are in `treasury_planner_regiment_input_supply_retention_cases.dart`.
//
// Coverage is preserved 1:1 from the former
// `treasury_planner_regiment_input_{market_supply,retention,feedstock}_test.dart`
// shards.

import 'treasury_planner_regiment_input_supply_retention_cases.dart';

void main() {
  registerTreasuryRegimentInputSupplyRetentionCases();
}
