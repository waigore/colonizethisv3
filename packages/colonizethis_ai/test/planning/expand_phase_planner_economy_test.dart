// Thin contract for expand_phase_planner_economy pin suite (Refs #4079 Slice D).
// Unit tests for `planExpandEconomy` in expand_phase_planner.dart
// (Refs #2509 S2 / S10). Case bodies live in sibling `*_cases.dart` modules.
//
// Spec contract (issue #2509 § EXPAND phase planner § planExpandEconomy):
//   Force-regiment-rebuild when ow < 10 AND ([A] reg==0 + invadable,
//   [B] 0<reg<min + treasury>=cheapest, or [C] treasury<cheapest cargo boost).
// Effective treasury is `Player.treasury + pendingRichesTreasuryDelta(...)`.

import 'expand_phase_planner_economy_cases.dart';

void main() {
  registerExpandPhasePlannerEconomyCases();
}
