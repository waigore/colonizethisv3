// Shared types + constants for the recruitment planner root and its
// candidates module. Extracted to avoid a
// recruitment_planner.dart <-> recruitment_planner_candidates.dart import
// cycle (Refs #4079 Slice A).

import 'package:colonizethis_logic/order_suggestion_api.dart';

import '../perception/perception_snapshot.dart';
import 'growth_stage.dart';
import 'observer_goal_phase.dart';
import 'planning_imports.dart';

/// Result of the recruitment planner.
///
/// Spec: SPEC/ai/economy-planner.md § Recruitment planner (Refs #2692 S8).
class RecruitmentPlan {
  const RecruitmentPlan({
    required this.recruitOrders,
    required this.buildUnitOrders,
    required this.rejected,
  });

  /// Empty plan returned when the player view is missing or both candidate
  /// lists are empty after planner-side filtering.
  static const RecruitmentPlan empty = RecruitmentPlan(
    recruitOrders: [],
    buildUnitOrders: [],
    rejected: [],
  );

  /// Recruit / train orders the planner has decided to emit this turn.
  /// Drawn from `OrderSuggestionAPI.suggestRecruitWorkerOrders` only.
  final List<RecruitWorkerOrder> recruitOrders;

  /// Build (regiment + ship) orders the planner has decided to emit this turn.
  /// Drawn from `OrderSuggestionAPI.suggestBuildOrders` only.
  final List<BuildUnitOrder> buildUnitOrders;

  /// Candidates dropped by planner-side rules (peasant reservation or soft
  /// luxury cap). Order is stable for the same inputs.
  final List<RejectedRecruitmentSuggestion> rejected;
}

/// Stable rejection reason: candidate would exceed the peasant reservation
/// ledger including pending consumes from `currentOrders` and accepted
/// emissions earlier in this plan.
const String kRecruitmentRejectInsufficientWorkers = 'Insufficient workers';

/// Stable rejection reason: candidate would push the trained-tier count
/// above the (deficit-aware) soft luxury cap defined in
/// `SPEC/game/workers-and-population.md` Requirement #10.
const String kRecruitmentRejectSoftLuxuryCap = 'Soft luxury cap exceeded';

/// Stable rejection reason: growth-stage military priority is below the build
/// suppression threshold (Refs #3371).
const String kRecruitmentRejectMilitaryBuildSuppressed =
    'Military build suppressed';

/// Stable rejection reason: a fabric-costing peasant-recruit candidate is
/// dropped so the GP's scarce fabric is reserved to fund a regiment build
/// (Refs #3371 AC13 — growth-stage military fabric reservation).
const String kRecruitmentRejectMilitaryFabricReservation =
    'Military fabric reservation';

/// Stable rejection reason: a paper-costing candidate (trained-worker recruit
/// or civilian build) is dropped because emitting it would push the shared
/// paper budget — current paper minus the research reservation
/// (`researchReservedPaper`) minus paper already committed by pending orders
/// and accepted emissions earlier in this plan — below `0`
/// (Refs #3793 AC7 — shared paper budget ledger).
const String kRecruitmentRejectPaperBudget = 'Paper budget exceeded';

/// One dropped candidate from [runRecruitmentPlanner]. Refs #2692 S8.
class RejectedRecruitmentSuggestion {
  const RejectedRecruitmentSuggestion({
    required this.reason,
    required this.targetTier,
  });

  /// Stable reason token. One of
  /// [kRecruitmentRejectInsufficientWorkers] or
  /// [kRecruitmentRejectSoftLuxuryCap].
  final String reason;

  /// For recruit candidates: `WorkerTier.name`.
  /// For build candidates: `BuildUnitOrder.unitType`.
  final String targetTier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RejectedRecruitmentSuggestion &&
          reason == other.reason &&
          targetTier == other.targetTier;

  @override
  int get hashCode => Object.hash(reason, targetTier);

  @override
  String toString() =>
      'RejectedRecruitmentSuggestion(reason: $reason, tier: $targetTier)';
}

/// Bundles inputs for `runRecruitmentPlanner` (Refs #3972 AC5).
final class RecruitmentPlannerInput {
  const RecruitmentPlannerInput({
    required this.game,
    required this.view,
    required this.currentOrders,
    required this.config,
    required this.seeds,
    required this.goalPhase,
    required this.suggestionApi,
    this.topology,
    this.economyPlanHint,
    this.growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
    this.paperBudgetLedgerEnabled = false,
    this.includeCivilianBuilds = false,
    this.snapshot,
  });

  final Game game;
  final PlayerView view;
  final Orders currentOrders;
  final AIConfig config;
  final AISeedBundle seeds;
  final ObserverGoalPhase goalPhase;
  final OrderSuggestionAPI suggestionApi;
  final MapTopology? topology;
  final EconomyPlan? economyPlanHint;
  final bool growthStagePlannerEnabled;
  final bool paperBudgetLedgerEnabled;
  final bool includeCivilianBuilds;
  final AIWorldSnapshot? snapshot;
}
