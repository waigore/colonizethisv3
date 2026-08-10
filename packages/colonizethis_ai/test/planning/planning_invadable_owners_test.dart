// Thin contract for `planning_invadable_owners.dart` pin suite (Refs #4310).
// Case bodies live in sibling `*_cases.dart` modules; Game fixtures in support.

import 'planning_invadable_owners_predicate_cases.dart';
import 'planning_invadable_owners_wiring_cases.dart';

void main() {
  registerPlanningInvadableOwnersPredicateCases();
  registerPlanningInvadableOwnersWiringCases();
}
