// Recruitment planner: unified worker recruit/train + regiment/ship build
// decisions for one AI-controlled Great Power per turn. SPEC/ai/economy-planner.md
// § Recruitment planner. Refs #2692 S8.

import 'package:colonizethis_logic/order_suggestion_api.dart';

import '../perception/perception_snapshot.dart';
import 'ai_commodity_ids.dart';
import 'growth_stage.dart';
import 'observer_goal_phase.dart';
import 'planning_imports.dart';

part 'recruitment_planner_candidates.dart';

final _log = packageLogger('recruitment_planner');

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

/// Bundles inputs for [runRecruitmentPlanner] (Refs #3972 AC5).
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

/// Plans worker recruit / train, regiment builds, and ship builds for one
/// AI-controlled player on one turn. Deterministic given inputs.
///
/// Contract (stable across #2509 orchestrator changes; Refs #2692 §20):
///
/// - Emitted orders MUST come from `suggestionApi.suggestRecruitWorkerOrders`
///   / `suggestionApi.suggestBuildOrders` for the same
///   `(view, game, currentOrders)`. The planner does not re-validate.
/// - Peasant reservation: `availablePeasants = pool.peasants − pending
///   consumes − accepted peasant-consuming emissions in this plan`. Civilian
///   builds do not consume peasants. Over-budget candidates are dropped into
///   [RecruitmentPlan.rejected] with reason
///   [kRecruitmentRejectInsufficientWorkers].
/// - Soft luxury cap (SPEC/game/workers-and-population.md §10): for trained
///   tier T (apprentice / journeyman / master), reject when projected count
///   exceeds `sustainableTrainedCount[T]` (no-deficit) or `1.2 ×
///   sustainableTrainedCount[T]` (deficit). Above `1.2 ×` the planner MUST
///   NOT emit further recruit / train orders for that tier this turn.
/// - Emit order by [goalPhase]: DEVELOP processes recruit / train candidates
///   first; EXPAND / COLONIAL-lite / COLONIAL process build candidates first.
///   Within each step, candidates are iterated in suggestion-API order
///   (deterministic per SPEC/program/order-suggestions.md).
/// - Shared paper budget (Refs #3793 AC7, design decision #11): when
///   [paperBudgetLedgerEnabled] is `true`, the planner reserves research paper
///   up to `researchReservedPaper(currentPaper)` then allocates the remainder
///   via the same phase emit order against a running ledger. A paper-costing
///   candidate (trained-worker recruit or — when [includeCivilianBuilds] is
///   `true` — civilian build) is dropped with reason
///   [kRecruitmentRejectPaperBudget] when its paper cost would push the
///   remaining budget below `0`. When `false` (the default) the planner emits
///   no paper checks and behaves byte-identically to the pre-#3793 path.
///
/// Candidate gather / evaluate / emit live in
/// `recruitment_planner_candidates.dart` (Refs #3997 AC5 concern split).
RecruitmentPlan runRecruitmentPlanner(RecruitmentPlannerInput input) {
  final playerId = input.view.playerId;
  final player = input.game.playerById(playerId);
  if (player == null) {
    _log.w('no player for $playerId');
    return RecruitmentPlan.empty;
  }

  final prepared = _prepareRecruitmentPlan(input: input, player: player);
  final recruitOrders = <RecruitWorkerOrder>[];
  final buildUnitOrders = <BuildUnitOrder>[];
  final rejected = <RejectedRecruitmentSuggestion>[];

  void processRecruit() {
    _processRecruitCandidates(
      prepared: prepared,
      recruitOrders: recruitOrders,
      rejected: rejected,
    );
  }

  void processBuilds() {
    _processBuildCandidates(
      prepared: prepared,
      buildUnitOrders: buildUnitOrders,
      rejected: rejected,
    );
  }

  if (input.goalPhase == ObserverGoalPhase.develop) {
    processRecruit();
    processBuilds();
  } else {
    processBuilds();
    processRecruit();
  }

  _log.d(
    'recruitment plan playerId=$playerId goalPhase=${input.goalPhase.name} '
    'recruit=${recruitOrders.length} build=${buildUnitOrders.length} '
    'rejected=${rejected.length} seed=${input.seeds.economySeed} '
    'personality=${input.config.personalityId}',
  );

  return RecruitmentPlan(
    recruitOrders: List<RecruitWorkerOrder>.unmodifiable(recruitOrders),
    buildUnitOrders: List<BuildUnitOrder>.unmodifiable(buildUnitOrders),
    rejected: List<RejectedRecruitmentSuggestion>.unmodifiable(rejected),
  );
}
