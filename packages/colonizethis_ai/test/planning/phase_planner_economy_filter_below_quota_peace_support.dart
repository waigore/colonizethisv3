// Shared fixtures for `phase_planner_economy_filter_below_quota_peace_*` pins.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// Non-default content for the "structural exclusion ignores sibling
// slots" guards in both groups. The resolvers must read only
// `outcome.phase` (and their documented per-turn inputs), so populated
// COLONIAL slots under EXPAND / COLONIAL-lite / DEVELOP must still
// resolve to `false`. Duplicated from
// `phase_planner_economy_filter_test.dart` because the constants are
// file-private; keeping the test file self-contained avoids exposing
// fixture symbols through a shared library just for two test files.
const ColonialAcquisitionTarget belowQuotaPeaceColonialAcquisitionPopulated =
    ColonialAcquisitionTarget(
      targetFactionId: 'tribe1',
      method: AcquisitionMethod.declareWar,
    );

const ColonialMilitaryPlan belowQuotaPeaceColonialMilitaryPopulated =
    ColonialMilitaryPlan(
      priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
      priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
    );

const ColonialNavalPlan belowQuotaPeaceColonialNavalPopulated =
    ColonialNavalPlan(
      priorityInvasionTransportProvinceIdsSorted: <String>[
        'newWorld|tribe1_a',
      ],
      priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
    );

const List<WorkOrder> belowQuotaPeaceColonialCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'm1',
    target: 'purchase_land',
    targetTileKey: 'newWorld|tribe1_a|0|0',
  ),
];
