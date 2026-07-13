// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'treasury_planner_regiment_input_market_supply_cases.dart';
import 'treasury_planner_regiment_input_retention_feedstock_cases.dart';

void registerTreasuryRegimentInputSupplyRetentionCases() {
  registerTreasuryRegimentInputMarketSupplyCases();
  registerTreasuryRegimentInputRetentionFeedstockCases();
}
