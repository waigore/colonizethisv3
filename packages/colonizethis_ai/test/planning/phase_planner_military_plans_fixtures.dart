// Shared fixtures for `phase_planner_military_plans_test.dart` cases
// (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialMilitaryPlan;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandMilitaryPlan;
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart';

/// Legacy hard-suppress contract: explicit zero NW weight (Refs #2847).
const PhasePriorityWeights nwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const ExpandMilitaryPlan expandSingleOwner = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|nation_a|p1'],
  priorityTargetOwnerFactionIdsSorted: <String>['nation_a'],
);

const ExpandMilitaryPlan expandMultiOwner = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>[
    'oldWorld|nation_a|p1',
    'oldWorld|nation_b|p2',
    'oldWorld|nation_b|p3',
  ],
  priorityTargetOwnerFactionIdsSorted: <String>['nation_a', 'nation_b'],
);

const ColonialMilitaryPlan colonialSingleOwner = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe_a|nw1'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
);

const ColonialMilitaryPlan colonialMultiOwner = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>[
    'newWorld|tribe_a|nw1',
    'newWorld|tribe_b|nw2',
    'newWorld|tribe_b|nw3',
  ],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe_a', 'tribe_b'],
);
