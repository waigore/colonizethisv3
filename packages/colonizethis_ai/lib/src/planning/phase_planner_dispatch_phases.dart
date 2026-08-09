import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_phase_planner.dart';
import 'develop_phase_planner.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_priority_weights.dart';
import 'phase_planner_dispatch_outcome.dart';
import 'planning_helpers.dart';

PhasePlanOutcome expandPhasePlanOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? personalityId,
}) {
  final declareWarTarget = planExpandDeclareWar(game: game, snapshot: snapshot);
  final expandFrontier = expandFrontierContext(game: game, snapshot: snapshot);
  final expandEconomyPlan = planExpandEconomy(game: game, snapshot: snapshot);
  final priorityWeights = computePhasePriorityWeights(
    snapshot: snapshot,
    game: game,
    expandEconomyPlan: expandEconomyPlan,
  );
  final colonial = priorityWeights.newWorldAcquisition > 0.0
      ? colonialPlannerBundle(
          game: game,
          snapshot: snapshot,
          personalityId: personalityId,
          expandEconomyPlan: expandEconomyPlan,
        )
      : null;
  return PhasePlanOutcome.expand(
    expandDeclareWarTargetFactionId: declareWarTarget,
    expandPeaceTargetFactionIdsSorted: planExpandPeace(
      game: game,
      snapshot: snapshot,
    ),
    expandDistractionPeaceTargetFactionIdsSorted:
        expandDistractionPeaceTargets(game: game, snapshot: snapshot),
    expandEconomyPlan: expandEconomyPlan,
    expandMilitaryPlan: planExpandMilitary(
      game: game,
      snapshot: snapshot,
      declaredWarTargetFactionId: declareWarTarget,
    ),
    expandGpOnlyInvadableFrontierActive:
        expandFrontier.gpOnlyInvadableFrontierActive,
    expandPrimaryInvadableGpBlockerFactionId:
        expandFrontier.primaryInvadableGpBlockerFactionId,
    colonialAcquisitionTarget: colonial?.acquisition,
    colonialPeaceTargetFactionIdsSorted:
        colonial?.peaceTargets ?? const <String>[],
    colonialMilitaryPlan:
        colonial?.military ?? ColonialMilitaryPlan.defaultPlan,
    colonialNavalPlan: colonial?.naval ?? ColonialNavalPlan.defaultPlan,
    colonialCivilianWorkOrders: colonial?.civilian ?? const <WorkOrder>[],
    priorityWeights: priorityWeights,
  );
}

PhasePlanOutcome colonialLitePhasePlanOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final declareWarTarget = planExpandDeclareWar(game: game, snapshot: snapshot);
  final expandFrontier = expandFrontierContext(game: game, snapshot: snapshot);
  final expandEconomyPlan = planExpandEconomy(game: game, snapshot: snapshot);
  return PhasePlanOutcome.colonialLite(
    expandDeclareWarTargetFactionId: declareWarTarget,
    expandPeaceTargetFactionIdsSorted: planExpandPeace(
      game: game,
      snapshot: snapshot,
    ),
    expandDistractionPeaceTargetFactionIdsSorted:
        expandDistractionPeaceTargets(game: game, snapshot: snapshot),
    expandEconomyPlan: expandEconomyPlan,
    expandMilitaryPlan: planExpandMilitary(
      game: game,
      snapshot: snapshot,
      declaredWarTargetFactionId: declareWarTarget,
    ),
    expandGpOnlyInvadableFrontierActive:
        expandFrontier.gpOnlyInvadableFrontierActive,
    expandPrimaryInvadableGpBlockerFactionId:
        expandFrontier.primaryInvadableGpBlockerFactionId,
    colonialLiteOverturesSorted: planColonialLiteOvertures(
      game: game,
      snapshot: snapshot,
    ),
    colonialLiteNavalPlan: planColonialLiteNaval(
      game: game,
      snapshot: snapshot,
    ),
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: expandEconomyPlan,
    ),
  );
}

({
  ColonialAcquisitionTarget? acquisition,
  List<String> peaceTargets,
  ColonialMilitaryPlan military,
  ColonialNavalPlan naval,
  List<WorkOrder> civilian,
})
colonialPlannerBundle({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? personalityId,
  ExpandEconomyPlan expandEconomyPlan = ExpandEconomyPlan.defaultPlan,
}) {
  final acquisition = planColonialAcquisition(
    game: game,
    snapshot: snapshot,
    personalityId: personalityId,
    expandEconomyPlan: expandEconomyPlan,
  );
  final declaredColonialTarget =
      (acquisition != null &&
          acquisition.method == AcquisitionMethod.declareWar)
      ? acquisition.targetFactionId
      : null;
  return (
    acquisition: acquisition,
    peaceTargets: planColonialPeace(game: game, snapshot: snapshot),
    military: planColonialMilitary(
      game: game,
      snapshot: snapshot,
      colonialDeclaredWarTargetFactionId: declaredColonialTarget,
      expandEconomyPlan: expandEconomyPlan,
    ),
    naval: planColonialNaval(
      game: game,
      snapshot: snapshot,
      colonialDeclaredWarTargetFactionId: declaredColonialTarget,
      expandEconomyPlan: expandEconomyPlan,
    ),
    civilian: planColonialCivilian(game: game, snapshot: snapshot),
  );
}

PhasePlanOutcome colonialPhasePlanOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
  required String? personalityId,
}) {
  final colonial = colonialPlannerBundle(
    game: game,
    snapshot: snapshot,
    personalityId: personalityId,
    expandEconomyPlan: planExpandEconomy(game: game, snapshot: snapshot),
  );
  return PhasePlanOutcome.colonial(
    colonialAcquisitionTarget: colonial.acquisition,
    colonialPeaceTargetFactionIdsSorted: colonial.peaceTargets,
    colonialMilitaryPlan: colonial.military,
    colonialNavalPlan: colonial.naval,
    colonialCivilianWorkOrders: colonial.civilian,
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
    ),
  );
}

PhasePlanOutcome developPhasePlanOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return PhasePlanOutcome.develop(
    developPeaceTargetFactionIdsSorted: planDevelopPeace(
      game: game,
      snapshot: snapshot,
    ),
    developCivilianWorkOrders: planDevelopCivilian(
      game: game,
      snapshot: snapshot,
    ),
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
    ),
  );
}

/// EXPAND below-quota tribe distraction peace for the production
/// phase-plan path (Refs #2847 § H5).
List<String> expandDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => belowQuotaRegimentThinTribeDistractionPeaceTargets(
  game: game,
  snapshot: snapshot,
);

({
  bool gpOnlyInvadableFrontierActive,
  String? primaryInvadableGpBlockerFactionId,
})
expandFrontierContext({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return (
    gpOnlyInvadableFrontierActive: isOldWorldGpOnlyInvadableFrontier(
      game: game,
      snapshot: snapshot,
    ),
    primaryInvadableGpBlockerFactionId: primaryInvadableOldWorldGpBlocker(
      game: game,
      snapshot: snapshot,
    ),
  );
}
