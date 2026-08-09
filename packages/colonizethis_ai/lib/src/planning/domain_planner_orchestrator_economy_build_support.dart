import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import '../util/orders_builder.dart';
import 'build_planner.dart';
import 'economy_phase_gates.dart';
import 'expand_phase_planner_economy.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'planner_context.dart';
import 'planning_helpers.dart' show oldWorldProvinceLeadOver;
import 'planning_imports.dart';

class BuildPassResult {
  const BuildPassResult({
    required this.buildPlannerRan,
    required this.buildThreshold,
  });

  final bool buildPlannerRan;
  final int buildThreshold;
}

/// Bundles inputs for [appendEconomyBuildOrders] (Refs #3977 AC5).
final class EconomyBuildPassInput {
  const EconomyBuildPassInput({
    required this.ctx,
    required this.snapshot,
    required this.phasePlan,
    required this.economyPhaseGates,
    required this.economyPlan,
    required this.ordersBuilder,
    required this.colonialPressure,
    required this.buildCandidates,
    required this.civilianScoring,
    required this.domainEconomyWeight,
  });

  final PlannerContext ctx;
  final AIWorldSnapshot snapshot;
  final PhasePlanOutcome phasePlan;
  final EconomyPhaseGates economyPhaseGates;
  final EconomyPlan economyPlan;
  final OrdersBuilder ordersBuilder;
  final bool colonialPressure;
  final List<BuildUnitOrder> buildCandidates;
  final CivilianBuildScoringInput? civilianScoring;
  final int domainEconomyWeight;
}

/// Resolved gate state for the economy build pass (Refs #3977 AC6).
final class EconomyBuildPassGate {
  const EconomyBuildPassGate({
    required this.buildThreshold,
    required this.forceRegimentRebuild,
    required this.firstNavalTransportBootstrap,
    required this.candidatesForBuild,
    required this.colonialPressureWeight,
    required this.atWarWithGpBlocker,
    required this.brokeBelowQuotaAtPeace,
    required this.belowQuotaZeroRegimentsRebuild,
    required this.belowQuotaPeaceInsufficientRegiments,
    required this.observerQuotaPressure,
    required this.regimentCount,
    required this.expandEconomy,
    required this.skipWithoutRunning,
  });

  final int buildThreshold;
  final bool forceRegimentRebuild;
  final bool firstNavalTransportBootstrap;
  final List<BuildUnitOrder> candidatesForBuild;
  final double colonialPressureWeight;
  final bool atWarWithGpBlocker;
  final bool brokeBelowQuotaAtPeace;
  final bool belowQuotaZeroRegimentsRebuild;
  final bool belowQuotaPeaceInsufficientRegiments;
  final bool observerQuotaPressure;
  final int regimentCount;
  final ExpandEconomyPlan expandEconomy;
  final bool skipWithoutRunning;
}

int computeBaseBuildThreshold({
  required PlannerContext ctx,
  required EconomyPhaseGates economyPhaseGates,
  required bool expandQuotaPressure,
}) {
  var buildThreshold =
      30 - getAgendaBuildOrderModifier(ctx.config.hiddenAgendaId);
  if (expandQuotaPressure) {
    buildThreshold = math.min(buildThreshold, 15);
  }
  if (expandQuotaPressure && economyPhaseGates.expandGpBlockerFocusActive) {
    buildThreshold = math.min(buildThreshold, 8);
  }
  final colonialBuildCap = economyPhaseGates.colonialBuildOrderThresholdCap;
  if (colonialBuildCap != null) {
    buildThreshold = math.min(buildThreshold, colonialBuildCap);
  }
  return buildThreshold;
}

typedef RegimentFloorContext = ({
  bool atWarWithGpBlocker,
  String? gpBlocker,
  bool criticallyWeakNoGpWar,
  bool criticallyWeakBelowQuota,
  bool needRegimentsToExpand,
  bool belowQuotaZeroRegimentsRebuild,
});

int computeMinRegimentFloor({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required RegimentFloorContext floorContext,
}) {
  var minRegimentFloor = floorContext.atWarWithGpBlocker
      ? kStalledMinRegimentCountWhenGpBlockerAtWar
      : kStalledMinRegimentCountWhenAtWar;
  if (floorContext.atWarWithGpBlocker && floorContext.gpBlocker != null) {
    final deficit = oldWorldProvinceLeadOver(
      game: ctx.game,
      snapshot: snapshot,
      factionId: floorContext.gpBlocker!,
    );
    if (deficit > 0) {
      minRegimentFloor +=
          deficit * kStalledMinRegimentCountPerProvinceDeficitVsBlocker;
    }
  }
  if (floorContext.criticallyWeakNoGpWar &&
      snapshot.threats.atWarWith.isNotEmpty &&
      minRegimentFloor < kStalledMinRegimentCountWhenCriticallyWeakNoGpWar) {
    minRegimentFloor = kStalledMinRegimentCountWhenCriticallyWeakNoGpWar;
  }
  if (floorContext.criticallyWeakBelowQuota &&
      (snapshot.threats.atWarWith.isNotEmpty ||
          floorContext.needRegimentsToExpand) &&
      minRegimentFloor < kStalledMinRegimentCountWhenCriticallyWeakBelowQuota) {
    minRegimentFloor = kStalledMinRegimentCountWhenCriticallyWeakBelowQuota;
  }
  if (floorContext.belowQuotaZeroRegimentsRebuild) {
    minRegimentFloor = 1;
  }
  return minRegimentFloor;
}
