// Thin contract for phase_priority_weights pin suite (Refs #4291 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_priority_weights_curve_cases.dart';
import 'phase_priority_weights_override_cases.dart';

void main() {
  registerPhasePriorityWeightsCurveCases();
  registerPhasePriorityWeightsOverrideCases();
}
