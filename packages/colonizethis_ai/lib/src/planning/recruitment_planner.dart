// Recruitment planner: unified worker recruit/train + regiment/ship build
// decisions for one AI-controlled Great Power per turn. SPEC/ai/economy-planner.md
// § Recruitment planner. Refs #2692 S8.

import 'package:colonizethis_logic/order_suggestion_api.dart';

import '../perception/perception_snapshot.dart';
import 'growth_stage.dart';
import 'observer_goal_phase.dart';
import 'planning_imports.dart';

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
RecruitmentPlan runRecruitmentPlanner({
  required Game game,
  required PlayerView view,
  required Orders currentOrders,
  required AIConfig config,
  required AISeedBundle seeds,
  required ObserverGoalPhase goalPhase,
  required OrderSuggestionAPI suggestionApi,
  MapTopology? topology,
  EconomyPlan? economyPlanHint,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  bool paperBudgetLedgerEnabled = false,
  bool includeCivilianBuilds = false,
  AIWorldSnapshot? snapshot,
}) {
  final playerId = view.playerId;
  final player = game.playerById(playerId);
  if (player == null) {
    _log.w('no player for $playerId');
    return RecruitmentPlan.empty;
  }

  final mapTopology = topology ?? const MapTopology(nodes: [], edges: []);

  final growthStage = growthStagePlannerEnabled
      ? GrowthStage.compute(game, playerId, snapshot: snapshot)
      : null;
  final suppressMilitaryBuilds =
      growthStage != null &&
      growthStage.militaryPriority < kMilitaryBuildSuppressionThreshold;

  final recruitCandidates = suggestionApi.suggestRecruitWorkerOrders(
    view,
    game,
    mapTopology,
    currentOrders,
  );
  final buildCandidates = suggestionApi.suggestBuildOrders(
    view,
    game,
    mapTopology,
    currentOrders,
    // Refs #3793 AC7: civilian build candidates join the shared paper ledger
    // only when explicitly opted in; default `false` keeps the candidate pool
    // byte-identical to the military+naval path.
    includeCivilianBuilds: includeCivilianBuilds,
  );

  // Refs #3371 AC13: a military-ready GP reserves its scarce fabric for the
  // regiment build instead of draining it on the fabric-costing peasant-recruit
  // action. Only meaningful when a fabric-consuming military/naval build is
  // actually on offer this turn.
  final reserveFabricForMilitary =
      growthStage != null &&
      !suppressMilitaryBuilds &&
      buildCandidates.any(_buildConsumesPeasant) &&
      growthStageReservesFabricForMilitary(
        stage: growthStage,
        treasury: player.treasury,
        fabricHeld: player.stockpile.quantityOf(CommodityCatalog.fabric.id),
        cheapestRegimentTreasuryCost: cheapestRegimentBuildTreasuryCost(),
      );

  // Refs #3793 AC7: the shared paper budget the ledger allocates to
  // paper-costing candidates is the GP's current paper minus the research
  // reservation minus paper already committed by pending orders. Floored at 0
  // and only consulted when the ledger is enabled.
  final currentPaper = player.stockpile.quantityOf(CommodityCatalog.paper.id);
  final paperBudgetRaw =
      currentPaper -
      researchReservedPaper(currentPaper) -
      _pendingPaperConsumes(currentOrders, playerId);
  final paperBudget = !paperBudgetLedgerEnabled || paperBudgetRaw < 0
      ? 0
      : paperBudgetRaw;

  final state = _PlanState(
    workerPool: player.workerPool,
    stockpile: player.stockpile,
    pendingPeasantConsumes: _pendingPeasantConsumes(currentOrders, playerId),
    sustainable: _sustainableTrainedCounts(
      stockpile: player.stockpile,
      economyPlanHint: economyPlanHint,
    ),
    inDeficit: _isLabourDeficit(
      player: player,
      economyPlanHint: economyPlanHint,
    ),
    paperBudgetLedgerEnabled: paperBudgetLedgerEnabled,
    paperBudget: paperBudget,
  );

  final recruitOrders = <RecruitWorkerOrder>[];
  final buildUnitOrders = <BuildUnitOrder>[];
  final rejected = <RejectedRecruitmentSuggestion>[];

  void processRecruit() {
    for (final candidate in recruitCandidates) {
      if (reserveFabricForMilitary && _recruitConsumesFabric(candidate)) {
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectMilitaryFabricReservation,
            targetTier: candidate.targetTier.name,
          ),
        );
        continue;
      }
      final outcome = _evaluateRecruitCandidate(candidate, state);
      switch (outcome) {
        case _CandidateOutcome.accepted:
          recruitOrders.add(candidate);
          state.applyRecruit(candidate);
        case _CandidateOutcome.rejectedInsufficientWorkers:
          rejected.add(
            RejectedRecruitmentSuggestion(
              reason: kRecruitmentRejectInsufficientWorkers,
              targetTier: candidate.targetTier.name,
            ),
          );
        case _CandidateOutcome.rejectedSoftCap:
          rejected.add(
            RejectedRecruitmentSuggestion(
              reason: kRecruitmentRejectSoftLuxuryCap,
              targetTier: candidate.targetTier.name,
            ),
          );
        case _CandidateOutcome.rejectedPaperBudget:
          rejected.add(
            RejectedRecruitmentSuggestion(
              reason: kRecruitmentRejectPaperBudget,
              targetTier: candidate.targetTier.name,
            ),
          );
      }
    }
  }

  void processBuilds() {
    for (final candidate in buildCandidates) {
      if (suppressMilitaryBuilds && _buildConsumesPeasant(candidate)) {
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectMilitaryBuildSuppressed,
            targetTier: candidate.unitType,
          ),
        );
        continue;
      }
      final outcome = _evaluateBuildCandidate(candidate, state);
      switch (outcome) {
        case _CandidateOutcome.accepted:
          buildUnitOrders.add(candidate);
          state.applyBuild(candidate);
        case _CandidateOutcome.rejectedInsufficientWorkers:
          rejected.add(
            RejectedRecruitmentSuggestion(
              reason: kRecruitmentRejectInsufficientWorkers,
              targetTier: candidate.unitType,
            ),
          );
        case _CandidateOutcome.rejectedSoftCap:
          // Builds are not gated by the soft luxury cap; defensive only.
          rejected.add(
            RejectedRecruitmentSuggestion(
              reason: kRecruitmentRejectSoftLuxuryCap,
              targetTier: candidate.unitType,
            ),
          );
        case _CandidateOutcome.rejectedPaperBudget:
          rejected.add(
            RejectedRecruitmentSuggestion(
              reason: kRecruitmentRejectPaperBudget,
              targetTier: candidate.unitType,
            ),
          );
      }
    }
  }

  if (goalPhase == ObserverGoalPhase.develop) {
    processRecruit();
    processBuilds();
  } else {
    processBuilds();
    processRecruit();
  }

  _log.d(
    'recruitment plan playerId=$playerId goalPhase=${goalPhase.name} '
    'recruit=${recruitOrders.length} build=${buildUnitOrders.length} '
    'rejected=${rejected.length} seed=${seeds.economySeed} '
    'personality=${config.personalityId}',
  );

  return RecruitmentPlan(
    recruitOrders: List<RecruitWorkerOrder>.unmodifiable(recruitOrders),
    buildUnitOrders: List<BuildUnitOrder>.unmodifiable(buildUnitOrders),
    rejected: List<RejectedRecruitmentSuggestion>.unmodifiable(rejected),
  );
}

enum _CandidateOutcome {
  accepted,
  rejectedInsufficientWorkers,
  rejectedSoftCap,
  rejectedPaperBudget,
}

/// Mutable per-plan state: tracks peasant ledger plus projected per-tier
/// emissions for the soft luxury cap rule, plus the shared paper budget ledger
/// (Refs #3793 AC7).
class _PlanState {
  _PlanState({
    required this.workerPool,
    required this.stockpile,
    required this.pendingPeasantConsumes,
    required this.sustainable,
    required this.inDeficit,
    required this.paperBudgetLedgerEnabled,
    required this.paperBudget,
  });

  final WorkerPool workerPool;
  final Stockpile stockpile;
  final int pendingPeasantConsumes;
  final Map<WorkerTier, int> sustainable;
  final bool inDeficit;

  /// Refs #3793 AC7: when `false`, no paper checks apply (legacy behaviour).
  final bool paperBudgetLedgerEnabled;

  /// Refs #3793 AC7: paper available to worker-training and civilian-build
  /// candidates after the research reservation and pending commitments.
  final int paperBudget;

  int _emittedPeasantConsumes = 0;
  int _emittedPaperSpend = 0;
  final Map<WorkerTier, int> _emittedTrainedCount = <WorkerTier, int>{};

  int availablePeasants() =>
      workerPool.peasants - pendingPeasantConsumes - _emittedPeasantConsumes;

  int projectedTrainedCount(WorkerTier tier) =>
      _currentTierCount(workerPool, tier) + (_emittedTrainedCount[tier] ?? 0);

  /// Paper still available to allocate after emissions accepted earlier in
  /// this plan (Refs #3793 AC7).
  int remainingPaper() => paperBudget - _emittedPaperSpend;

  /// True when [paperCost] units of paper would overrun the remaining budget
  /// while the ledger is active (Refs #3793 AC7).
  bool paperOverBudget(int paperCost) =>
      paperBudgetLedgerEnabled && paperCost > 0 && paperCost > remainingPaper();

  void applyRecruit(RecruitWorkerOrder order) {
    final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
    if (row.consumesPeasant) {
      _emittedPeasantConsumes += 1;
    }
    if (order.targetTier != WorkerTier.peasant) {
      _emittedTrainedCount[order.targetTier] =
          (_emittedTrainedCount[order.targetTier] ?? 0) + 1;
    }
    if (paperBudgetLedgerEnabled) {
      _emittedPaperSpend += _recruitPaperCost(order);
    }
  }

  void applyBuild(BuildUnitOrder order) {
    if (_buildConsumesPeasant(order)) {
      _emittedPeasantConsumes += 1;
    }
    if (paperBudgetLedgerEnabled) {
      _emittedPaperSpend += _buildPaperCost(order);
    }
  }
}

_CandidateOutcome _evaluateRecruitCandidate(
  RecruitWorkerOrder candidate,
  _PlanState state,
) {
  // Refs #3793 AC7: the shared paper budget is the dominant gate — a
  // paper-costing trained-worker recruit that would overrun the remaining
  // budget is dropped before the peasant / soft-cap checks.
  if (state.paperOverBudget(_recruitPaperCost(candidate))) {
    return _CandidateOutcome.rejectedPaperBudget;
  }
  final row = WorkerActionEconomyCatalog.forTier(candidate.targetTier);
  if (row.consumesPeasant && state.availablePeasants() < 1) {
    return _CandidateOutcome.rejectedInsufficientWorkers;
  }
  if (candidate.targetTier != WorkerTier.peasant) {
    final projected = state.projectedTrainedCount(candidate.targetTier) + 1;
    final sustainable = state.sustainable[candidate.targetTier] ?? 0;
    final cap = state.inDeficit
        ? _softLuxuryCapDeficitLimit(sustainable)
        : sustainable;
    if (projected > cap) {
      return _CandidateOutcome.rejectedSoftCap;
    }
  }
  return _CandidateOutcome.accepted;
}

_CandidateOutcome _evaluateBuildCandidate(
  BuildUnitOrder candidate,
  _PlanState state,
) {
  // Refs #3793 AC7: civilian builds consume paper; drop one whose paper cost
  // would overrun the remaining shared budget before the peasant check.
  if (state.paperOverBudget(_buildPaperCost(candidate))) {
    return _CandidateOutcome.rejectedPaperBudget;
  }
  if (_buildConsumesPeasant(candidate) && state.availablePeasants() < 1) {
    return _CandidateOutcome.rejectedInsufficientWorkers;
  }
  return _CandidateOutcome.accepted;
}

/// Paper units a trained-worker recruit consumes from the stockpile
/// (`WorkerActionEconomy.materialCosts[paper]`); `0` for the peasant row,
/// which costs fabric (Refs #3793 AC7).
int _recruitPaperCost(RecruitWorkerOrder order) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  return row.materialCosts[CommodityCatalog.paper.id] ?? 0;
}

/// Paper units a civilian build consumes (`CivilianEconomy.buildInputs[paper]`).
/// Military/naval builds carry no paper input, so the lookup returns `0` for
/// them (Refs #3793 AC7).
int _buildPaperCost(BuildUnitOrder order) {
  final civilian = CivilianEconomyCatalog.byId[order.unitType];
  if (civilian == null) return 0;
  return civilian.buildInputs[CommodityCatalog.paper.id] ?? 0;
}

/// Integer-floor `1.2 × sustainable` per SPEC/ai/economy-planner.md
/// § Recruitment planner (Requirement #10).
int _softLuxuryCapDeficitLimit(int sustainable) {
  if (sustainable <= 0) return 0;
  return (sustainable * 12) ~/ 10;
}

/// True iff `effectiveLabour < targetRecipesLabour × 0.8`. When the hint is
/// null or carries zero assigned labour, returns `false` (no deficit override).
bool _isLabourDeficit({
  required Player player,
  required EconomyPlan? economyPlanHint,
}) {
  if (economyPlanHint == null) return false;
  final target = _totalAssignedLabour(economyPlanHint);
  if (target <= 0) return false;
  final effective = effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
  );
  return effective * 10 < target * 8;
}

int _totalAssignedLabour(EconomyPlan plan) {
  var total = 0;
  for (final a in plan.productionAssignments) {
    total += a.assignedLabour;
  }
  return total;
}

/// Sustainable trained-worker count per tier:
/// `stockpile[T-luxury] + projectedThisTurnOutput[T-luxury]`. Luxury
/// commodities: apprentice → refinedSugar, journeyman → cigars, master →
/// furHats. Projected output comes from the economy plan hint when present;
/// otherwise it is zero (SPEC/ai/economy-planner.md § Recruitment planner).
Map<WorkerTier, int> _sustainableTrainedCounts({
  required Stockpile stockpile,
  required EconomyPlan? economyPlanHint,
}) {
  final projected = _projectedLuxuryOutput(economyPlanHint);
  return {
    WorkerTier.apprentice:
        stockpile.quantityOf(CommodityCatalog.refinedSugar.id) +
        (projected[CommodityCatalog.refinedSugar.id] ?? 0),
    WorkerTier.journeyman:
        stockpile.quantityOf(CommodityCatalog.cigars.id) +
        (projected[CommodityCatalog.cigars.id] ?? 0),
    WorkerTier.master:
        stockpile.quantityOf(CommodityCatalog.furHats.id) +
        (projected[CommodityCatalog.furHats.id] ?? 0),
  };
}

Map<String, int> _projectedLuxuryOutput(EconomyPlan? plan) {
  if (plan == null) return const {};
  final out = <String, int>{};
  for (final assigned in plan.productionAssignments) {
    final recipe = ProductionRecipesCatalog.byId[assigned.recipeId];
    if (recipe == null) continue;
    final outputId = recipe.outputCommodityId;
    if (outputId != CommodityCatalog.refinedSugar.id &&
        outputId != CommodityCatalog.cigars.id &&
        outputId != CommodityCatalog.furHats.id) {
      continue;
    }
    final labourPer = recipe.labourPerOutput;
    if (labourPer <= 0) continue;
    final runs = assigned.assignedLabour ~/ labourPer;
    if (runs <= 0) continue;
    out[outputId] = (out[outputId] ?? 0) + runs * recipe.outputQuantity;
  }
  return out;
}

int _pendingPeasantConsumes(Orders currentOrders, String playerId) {
  var count = 0;
  final recruits =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  for (final r in recruits) {
    final row = WorkerActionEconomyCatalog.forTier(r.targetTier);
    if (row.consumesPeasant) count += 1;
  }
  final builds =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  for (final b in builds) {
    if (_buildConsumesPeasant(b)) count += 1;
  }
  return count;
}

/// Paper already committed this turn by pending orders in [currentOrders]:
/// trained-worker recruits plus civilian builds (Refs #3793 AC7). Subtracted
/// from the paper budget so the ledger never double-spends paper the engine
/// will already consume when resolving the pending orders.
int _pendingPaperConsumes(Orders currentOrders, String playerId) {
  var paper = 0;
  final recruits =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  for (final r in recruits) {
    paper += _recruitPaperCost(r);
  }
  final builds =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  for (final b in builds) {
    paper += _buildPaperCost(b);
  }
  return paper;
}

/// Military regiments and naval ships consume one peasant per build.
/// Civilian builds do not. See SPEC/game/workers-and-population.md §
/// Peasant reservation and SPEC/game/military-units.md /
/// SPEC/game/ships-and-naval.md.
bool _buildConsumesPeasant(BuildUnitOrder order) {
  final category = buildUnitCategoryForUnitType(order.unitType);
  return category == BuildUnitCategory.military ||
      category == BuildUnitCategory.naval;
}

/// True when the recruit/train action for [order]'s tier costs `fabric`.
/// Only the peasant-recruit row carries a fabric material cost (Refs #3371
/// AC13); trained tiers cost `paper`.
bool _recruitConsumesFabric(RecruitWorkerOrder order) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  return (row.materialCosts[CommodityCatalog.fabric.id] ?? 0) > 0;
}

int _currentTierCount(WorkerPool pool, WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return pool.peasants;
    case WorkerTier.apprentice:
      return pool.apprentices;
    case WorkerTier.journeyman:
      return pool.journeymen;
    case WorkerTier.master:
      return pool.masters;
  }
}
