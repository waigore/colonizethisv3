// Case-library barrel (Refs #3997 Phase 8 / #4291 Slice D).
// Thin aggregator so existing contracts keep a stable import.

import 'treasury_planner_regiment_input_retention_cases.dart';
import 'treasury_planner_regiment_input_feedstock_cases.dart';

void registerTreasuryRegimentInputRetentionFeedstockCases() {
  registerTreasuryRegimentInputRetentionCases();
  registerTreasuryRegimentInputFeedstockCases();
}
