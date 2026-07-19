import 'ai_commodity_ids.dart';
import 'growth_stage.dart';
import 'planning_imports.dart';
import 'recruitment_planner_types.dart';

// Candidate gather / evaluate / emit for the recruitment planner
// (Refs #3997 AC5 concern split; de-parted Refs #4079 Slice A).

/// Prepared candidate pools + ledger state for one `runRecruitmentPlanner` call.
final class _PreparedRecruitmentPlan {
  const _PreparedRecruitmentPlan({
    required this.recruitCandidates,
    required this.buildCandidates,
    required this.state,
    required this.suppressMilitaryBuilds,
    required this.reserveFabricForMilitary,
  });

  final List<RecruitWorkerOrder> recruitCandidates;
  final List<BuildUnitOrder> buildCandidates;
  final _PlanState state;
  final bool suppressMilitaryBuilds;
  final bool reserveFabricForMilitary;
}

_PreparedRecruitmentPlan prepareRecruitmentPlan({
  required RecruitmentPlannerInput input,
  required Player player,
}) {
  final playerId = input.view.playerId;
  final mapTopology =
      input.topology ?? const MapTopology(nodes: [], edges: []);

  final growthStage = input.growthStagePlannerEnabled
      ? GrowthStage.compute(input.game, playerId, snapshot: input.snapshot)
      : null;
  final suppressMilitaryBuilds =
      growthStage != null &&
      growthStage.militaryPriority < kMilitaryBuildSuppressionThreshold;

  final recruitCandidates = input.suggestionApi.suggestRecruitWorkerOrders(
    input.view,
    input.game,
    mapTopology,
    input.currentOrders,
  );
  final buildCandidates = input.suggestionApi.suggestBuildOrders(
    input.view,
    input.game,
    mapTopology,
    input.currentOrders,
    // Refs #3793 AC7: civilian build candidates join the shared paper ledger
    // only when explicitly opted in; default `false` keeps the candidate pool
    // byte-identical to the military+naval path.
    includeCivilianBuilds: input.includeCivilianBuilds,
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
        fabricHeld: player.stockpile.quantityOf(kAiCommodityIds.fabric),
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
      _pendingPaperConsumes(input.currentOrders, playerId);
  final paperBudget =
      !input.paperBudgetLedgerEnabled || paperBudgetRaw < 0 ? 0 : paperBudgetRaw;

  final state = _PlanState(
    workerPool: player.workerPool,
    stockpile: player.stockpile,
    pendingPeasantConsumes: _pendingPeasantConsumes(
      input.currentOrders,
      playerId,
    ),
    sustainable: _sustainableTrainedCounts(
      stockpile: player.stockpile,
      economyPlanHint: input.economyPlanHint,
    ),
    inDeficit: _isLabourDeficit(
      player: player,
      economyPlanHint: input.economyPlanHint,
    ),
    paperBudgetLedgerEnabled: input.paperBudgetLedgerEnabled,
    paperBudget: paperBudget,
  );

  return _PreparedRecruitmentPlan(
    recruitCandidates: recruitCandidates,
    buildCandidates: buildCandidates,
    state: state,
    suppressMilitaryBuilds: suppressMilitaryBuilds,
    reserveFabricForMilitary: reserveFabricForMilitary,
  );
}

void processRecruitCandidates({
  required _PreparedRecruitmentPlan prepared,
  required List<RecruitWorkerOrder> recruitOrders,
  required List<RejectedRecruitmentSuggestion> rejected,
}) {
  for (final candidate in prepared.recruitCandidates) {
    if (prepared.reserveFabricForMilitary &&
        _recruitConsumesFabric(candidate)) {
      rejected.add(
        RejectedRecruitmentSuggestion(
          reason: kRecruitmentRejectMilitaryFabricReservation,
          targetTier: candidate.targetTier.name,
        ),
      );
      continue;
    }
    final outcome = _evaluateRecruitCandidate(candidate, prepared.state);
    switch (outcome) {
      case _CandidateOutcome.accepted:
        recruitOrders.add(candidate);
        prepared.state.applyRecruit(candidate);
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

void processBuildCandidates({
  required _PreparedRecruitmentPlan prepared,
  required List<BuildUnitOrder> buildUnitOrders,
  required List<RejectedRecruitmentSuggestion> rejected,
}) {
  for (final candidate in prepared.buildCandidates) {
    if (prepared.suppressMilitaryBuilds && _buildConsumesPeasant(candidate)) {
      rejected.add(
        RejectedRecruitmentSuggestion(
          reason: kRecruitmentRejectMilitaryBuildSuppressed,
          targetTier: candidate.unitType,
        ),
      );
      continue;
    }
    final outcome = _evaluateBuildCandidate(candidate, prepared.state);
    switch (outcome) {
      case _CandidateOutcome.accepted:
        buildUnitOrders.add(candidate);
        prepared.state.applyBuild(candidate);
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
  return (row.materialCosts[kAiCommodityIds.fabric] ?? 0) > 0;
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
