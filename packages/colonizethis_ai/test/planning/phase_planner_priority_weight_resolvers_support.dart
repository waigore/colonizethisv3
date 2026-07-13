// Shared fixtures for phase_planner_priority_weight_resolvers pin cases (Refs #3997 Phase 8).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan, ExpandMilitaryPlan;
import 'package:colonizethis_models/colonizethis_models.dart';
// Unique per-field values so a field-mix-up regression (e.g. a
// resolver that mistakenly returns `oldWorldCivilian` instead of
// `oldWorldConquest`) produces a hard test failure rather than
// silently matching the curve default.
const PhasePriorityWeights kPriorityWeightResolversUnique = PhasePriorityWeights(
  oldWorldConquest: 0.11,
  newWorldAcquisition: 0.22,
  oldWorldCivilian: 0.33,
  newWorldCivilian: 0.44,
);

const PhasePriorityWeights kPriorityWeightResolversAlt = PhasePriorityWeights(
  oldWorldConquest: 0.91,
  newWorldAcquisition: 0.82,
  oldWorldCivilian: 0.73,
  newWorldCivilian: 0.64,
);

// Non-default content for every full-COLONIAL slot used by the
// "sibling-slot independence" guards. The weight resolvers must
// read only `priorityWeights`, so populated COLONIAL slots must not
// change any returned `double`.
const ColonialAcquisitionTarget kPriorityWeightResolversColonialAcquisitionPopulated =
    ColonialAcquisitionTarget(
      targetFactionId: 'tribe1',
      method: AcquisitionMethod.declareWar,
    );

const ColonialMilitaryPlan kPriorityWeightResolversColonialMilitaryPopulated = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialNavalPlan kPriorityWeightResolversColonialNavalPopulated = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const List<WorkOrder> kPriorityWeightResolversColonialCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'm1',
    target: 'purchase_land',
    targetTileKey: 'newWorld|tribe1_a|0|0',
  ),
];

const ExpandEconomyPlan kPriorityWeightResolversExpandEconomyPopulated = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

const ExpandMilitaryPlan kPriorityWeightResolversExpandMilitaryPopulated = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
);

PhasePlanOutcome priorityWeightResolversOutcomeWithWeights({
  required ObserverGoalPhase phase,
  required PhasePriorityWeights weights,
  bool populateSiblingSlots = false,
}) {
  if (!populateSiblingSlots) {
    return PhasePlanOutcome(phase: phase, priorityWeights: weights);
  }
  return PhasePlanOutcome(
    phase: phase,
    expandDeclareWarTargetFactionId: 'gp2',
    expandPeaceTargetFactionIdsSorted: const <String>['gp3', 'gp4'],
    expandEconomyPlan: kPriorityWeightResolversExpandEconomyPopulated,
    expandMilitaryPlan: kPriorityWeightResolversExpandMilitaryPopulated,
    expandGpOnlyInvadableFrontierActive: true,
    expandPrimaryInvadableGpBlockerFactionId: 'gp2',
    colonialLiteOverturesSorted: const <String>['tribe1'],
    colonialAcquisitionTarget: kPriorityWeightResolversColonialAcquisitionPopulated,
    colonialPeaceTargetFactionIdsSorted: const <String>['gp5'],
    colonialMilitaryPlan: kPriorityWeightResolversColonialMilitaryPopulated,
    colonialNavalPlan: kPriorityWeightResolversColonialNavalPopulated,
    colonialCivilianWorkOrders: kPriorityWeightResolversColonialCivilianPopulated,
    developPeaceTargetFactionIdsSorted: const <String>['gp6'],
    developCivilianWorkOrders: kPriorityWeightResolversColonialCivilianPopulated,
    priorityWeights: weights,
  );
}
