// Recruitment planner: unified worker recruit/train + regiment/ship build
// decisions for one AI-controlled Great Power per turn. SPEC/ai/economy-planner.md
// § Recruitment planner. Refs #2692 S8.

import 'observer_goal_phase.dart';
import 'planning_imports.dart';
import 'recruitment_planner_candidates.dart';
import 'recruitment_planner_types.dart';

export 'recruitment_planner_types.dart';

final _log = packageLogger('recruitment_planner');

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

  final prepared = prepareRecruitmentPlan(input: input, player: player);
  final recruitOrders = <RecruitWorkerOrder>[];
  final buildUnitOrders = <BuildUnitOrder>[];
  final rejected = <RejectedRecruitmentSuggestion>[];

  void processRecruit() {
    processRecruitCandidates(
      prepared: prepared,
      recruitOrders: recruitOrders,
      rejected: rejected,
    );
  }

  void processBuilds() {
    processBuildCandidates(
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
