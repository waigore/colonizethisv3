// Shared fixtures for phase_planner_economy_filter pin cases (Refs #3997 Phase 8).
library;

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
// Non-default content for every full-COLONIAL slot used by the
// "structural exclusion ignores sibling slots" guards. The resolver must
// read only `outcome.phase`, so populated COLONIAL slots under EXPAND /
// COLONIAL-lite / DEVELOP must still resolve to `false`.
const ColonialAcquisitionTarget kEconomyFilterColonialAcquisitionPopulated =
    ColonialAcquisitionTarget(
      targetFactionId: 'tribe1',
      method: AcquisitionMethod.declareWar,
    );

const ColonialMilitaryPlan kEconomyFilterColonialMilitaryPopulated = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialNavalPlan kEconomyFilterColonialNavalPopulated = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const List<WorkOrder> kEconomyFilterColonialCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'm1',
    target: 'purchase_land',
    targetTileKey: 'newWorld|tribe1_a|0|0',
  ),
];
