// Case-library barrel for research-planner multi-slot pin (Refs #4310 Slice D).

import 'research_planner_multi_slot_decision_trace_cases.dart';
import 'research_planner_multi_slot_funding_cap_cases.dart';
import 'research_planner_multi_slot_funding_cases.dart';

void registerResearchPlannerMultiSlotCases() {
  registerResearchPlannerMultiSlotFundingCases();
  registerResearchPlannerMultiSlotFundingCapCases();
  registerResearchPlannerMultiSlotDecisionTraceCases();
}
