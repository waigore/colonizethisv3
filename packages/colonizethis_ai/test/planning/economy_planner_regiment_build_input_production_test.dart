// Thin contract for regiment build-input production pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'economy_planner_regiment_build_input_production_fabric_domestic_supplier_cases.dart';
import 'economy_planner_regiment_build_input_production_feedstock_staging_cases.dart';

void main() {
  registerEconomyPlannerRegimentBuildInputProductionFabricDomesticSupplierCases();
  registerEconomyPlannerRegimentBuildInputProductionFeedstockStagingCases();
}
