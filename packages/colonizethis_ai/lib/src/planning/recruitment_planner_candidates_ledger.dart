import 'ai_commodity_ids.dart';
import 'planning_imports.dart';

/// Paper / luxury / pending-consume helpers for recruitment candidates
/// (Refs #4104 Slice B).
/// Paper units a trained-worker recruit consumes from the stockpile
/// (`WorkerActionEconomy.materialCosts[paper]`); `0` for the peasant row,
/// which costs fabric (Refs #3793 AC7).
int recruitPaperCost(RecruitWorkerOrder order) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  return row.materialCosts[CommodityCatalog.paper.id] ?? 0;
}

/// Paper units a civilian build consumes (`CivilianEconomy.buildInputs[paper]`).
/// Military/naval builds carry no paper input, so the lookup returns `0` for
/// them (Refs #3793 AC7).
int buildPaperCost(BuildUnitOrder order) {
  final civilian = CivilianEconomyCatalog.byId[order.unitType];
  if (civilian == null) return 0;
  return civilian.buildInputs[CommodityCatalog.paper.id] ?? 0;
}

/// Integer-floor `1.2 × sustainable` per SPEC/ai/economy-planner.md
/// § Recruitment planner (Requirement #10).
int softLuxuryCapDeficitLimit(int sustainable) {
  if (sustainable <= 0) return 0;
  return (sustainable * 12) ~/ 10;
}

/// True iff `effectiveLabour < targetRecipesLabour × 0.8`. When the hint is
/// null or carries zero assigned labour, returns `false` (no deficit override).
bool isRecruitmentLabourDeficit({
  required Player player,
  required EconomyPlan? economyPlanHint,
}) {
  if (economyPlanHint == null) return false;
  final target = totalAssignedLabourInEconomyPlan(economyPlanHint);
  if (target <= 0) return false;
  final effective = effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
  );
  return effective * 10 < target * 8;
}

int totalAssignedLabourInEconomyPlan(EconomyPlan plan) {
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
Map<WorkerTier, int> sustainableTrainedCounts({
  required Stockpile stockpile,
  required EconomyPlan? economyPlanHint,
}) {
  final projected = projectedLuxuryOutput(economyPlanHint);
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

Map<String, int> projectedLuxuryOutput(EconomyPlan? plan) {
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

int pendingPeasantConsumes(Orders currentOrders, String playerId) {
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
    if (buildConsumesPeasant(b)) count += 1;
  }
  return count;
}

/// Paper already committed this turn by pending orders in [currentOrders]:
/// trained-worker recruits plus civilian builds (Refs #3793 AC7). Subtracted
/// from the paper budget so the ledger never double-spends paper the engine
/// will already consume when resolving the pending orders.
int pendingPaperConsumes(Orders currentOrders, String playerId) {
  var paper = 0;
  final recruits =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  for (final r in recruits) {
    paper += recruitPaperCost(r);
  }
  final builds =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  for (final b in builds) {
    paper += buildPaperCost(b);
  }
  return paper;
}

/// Military regiments and naval ships consume one peasant per build.
/// Civilian builds do not. See SPEC/game/workers-and-population.md §
/// Peasant reservation and SPEC/game/military-units.md /
/// SPEC/game/ships-and-naval.md.
bool buildConsumesPeasant(BuildUnitOrder order) {
  final category = buildUnitCategoryForUnitType(order.unitType);
  return category == BuildUnitCategory.military ||
      category == BuildUnitCategory.naval;
}

/// True when the recruit/train action for [order]'s tier costs `fabric`.
/// Only the peasant-recruit row carries a fabric material cost (Refs #3371
/// AC13); trained tiers cost `paper`.
bool recruitConsumesFabric(RecruitWorkerOrder order) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  return (row.materialCosts[kAiCommodityIds.fabric] ?? 0) > 0;
}

int currentWorkerTierCount(WorkerPool pool, WorkerTier tier) {
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
