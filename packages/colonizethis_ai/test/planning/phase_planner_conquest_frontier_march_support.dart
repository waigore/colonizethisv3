// Shared fixtures for phase_planner_conquest_frontier_march pin cases (Refs #4079 Slice D).
library;

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const ExpandMilitaryPlan kFrontierMarchExpandOwOnly = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|minor1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
);

const ColonialMilitaryPlan kFrontierMarchColonialNwOnly = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);
