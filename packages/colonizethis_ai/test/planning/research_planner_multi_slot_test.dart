// Thin contract for research-planner multi-slot funding pin (Refs #3472,
// #4310 Slice D). Case bodies live in sibling `*_cases.dart` modules.
//
// Treasury-aware multi-slot funding for the Full-AI research planner.
// SPEC/ai/ai-architecture.md § Research.

import 'research_planner_multi_slot_cases.dart';

void main() {
  registerResearchPlannerMultiSlotCases();
}
