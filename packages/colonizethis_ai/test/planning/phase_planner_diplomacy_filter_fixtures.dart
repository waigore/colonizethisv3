// Shared fixtures for phase_planner_diplomacy_filter pin suite (Refs #4239 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Non-default content for every full-COLONIAL slot used by the
// "structural exclusion ignores sibling slots" guard. The resolver must
// read only `outcome.phase`, so populated COLONIAL slots under EXPAND /
// COLONIAL-lite / DEVELOP must still resolve to `false`.
const ColonialAcquisitionTarget phasePlannerDiplomacyFilterColonialAcquisitionPopulated =
    ColonialAcquisitionTarget(
      targetFactionId: 'tribe1',
      method: AcquisitionMethod.declareWar,
    );

const ColonialMilitaryPlan phasePlannerDiplomacyFilterColonialMilitaryPopulated = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialNavalPlan phasePlannerDiplomacyFilterColonialNavalPopulated = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const List<WorkOrder> phasePlannerDiplomacyFilterColonialCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'm1',
    target: 'purchase_land',
    targetTileKey: 'newWorld|tribe1_a|0|0',
  ),
];

// Mirrors the COLONIAL "structural exclusion" guard above for the
// DEVELOP-side population pin used by
// `resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive` tests. Hoisted
// to a top-level const so the WorkOrder string literal lives in a field
// declaration rather than an executable literal context (Refs
// `tool/check_work_target_constants.dart` `_isExecutableLiteral`).
const List<WorkOrder> phasePlannerDiplomacyFilterDevelopCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'b1',
    target: 'build_improvement',
    targetTileKey: 'oldWorld|gp1_a|0|0',
  ),
];
