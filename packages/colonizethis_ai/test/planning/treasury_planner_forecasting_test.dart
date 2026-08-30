// Thin contract for treasury_planner_forecasting pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'treasury_planner_forecasting_partial_fill_cases.dart';
import 'treasury_planner_forecasting_partial_fill_tail_cases.dart';
import 'treasury_planner_forecasting_clamp_cases.dart';
import 'treasury_planner_forecasting_clamp_determinism_cases.dart';

void main() {
  registerTreasuryPlannerForecastingPartialFillCases();
  registerTreasuryPlannerForecastingPartialFillTailCases();
  registerTreasuryPlannerForecastingClampCases();
  registerTreasuryPlannerForecastingClampDeterminismCases();
}
