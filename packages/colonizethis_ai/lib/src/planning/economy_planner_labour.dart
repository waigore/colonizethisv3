import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'ai_commodity_ids.dart';
import 'economy_planner_constants.dart';
import 'economy_planner_labour_fabric_prepass.dart';
import 'economy_planner_labour_feedstock.dart';
import 'growth_stage.dart';
import 'planning_imports.dart';
import 'recipe_scoring.dart';
import 'scored_candidate.dart';

export 'economy_planner_labour_feedstock.dart'
    show multiInputImprovementOutputs;

final _log = packageLogger('economy_planner_labour');

bool _delegatesToIndustryCounselCore(LabourAllocationInput input) {
  if (input.castIronLabourPeasantRecruitFabricBoost) return false;
  if (input.feedstockReserveOutputIds.isNotEmpty) return false;
  if (input.militaryRebuildCrisis) return false;
  if (input.regimentBuildInputProductionBoost) return false;
  if (input.missingRegimentBuildInputIds.isNotEmpty) return false;
  if (input.supplierReleaseImprovementInputIds.isNotEmpty) return false;
  if (input.growthStage != null && !kGrowthStagePlannerEnabled) return false;
  return true;
}

IndustryCounselGrowthStage? _industryCounselGrowthStage(GrowthStage? stage) {
  if (stage == null) return null;
  return IndustryCounselGrowthStage(
    workerGrowthPriority: stage.workerGrowthPriority,
    infrastructurePriority: stage.infrastructurePriority,
    resourceProductionPriority: stage.resourceProductionPriority,
    militaryPriority: stage.militaryPriority,
  );
}

/// Bundles inputs for [allocateLabour] (Refs #3977 AC5).
final class LabourAllocationInput {
  const LabourAllocationInput({
    required this.stockpile,
    required this.workers,
    required this.effectiveLabour,
    required this.config,
    required this.seeds,
    this.techUnlocked,
    this.militaryRebuildCrisis = false,
    this.regimentBuildInputProductionBoost = false,
    this.missingRegimentBuildInputIds = const {},
    this.supplierReleaseImprovementInputIds = const {},
    this.feedstockReserveOutputIds = const {},
    this.castIronLabourPeasantRecruitFabricBoost = false,
    this.growthStage,
  });

  final Stockpile stockpile;
  final WorkerPool workers;
  final int effectiveLabour;
  final AIConfig config;
  final AISeedBundle seeds;
  final Map<String, bool>? techUnlocked;
  final bool militaryRebuildCrisis;
  final bool regimentBuildInputProductionBoost;
  final Set<String> missingRegimentBuildInputIds;
  final Set<String> supplierReleaseImprovementInputIds;
  final Set<String> feedstockReserveOutputIds;
  final bool castIronLabourPeasantRecruitFabricBoost;
  final GrowthStage? growthStage;
}

/// Commodity ids the cheapest regiment still needs in the stockpile before
/// `suggestBuildOrders` will surface it (Refs #2847 H8).
Set<String> missingCheapestRegimentBuildInputIds(Stockpile stockpile) {
  final missing = <String>{};
  for (final entry
      in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) {
      missing.add(entry.key);
    }
  }
  return missing;
}

List<AssignedRecipe> allocateLabour(LabourAllocationInput input) {
  if (_delegatesToIndustryCounselCore(input)) {
    return industryCounselAllocateLabourCore(
      stockpile: input.stockpile,
      workers: input.workers,
      effectiveLabour: input.effectiveLabour,
      techUnlocked: input.techUnlocked,
      agendaId: input.config.hiddenAgendaId,
      growthStage: _industryCounselGrowthStage(input.growthStage),
      growthStagePlannerEnabled: kGrowthStagePlannerEnabled,
    );
  }

  final stockpile = input.stockpile;
  final workers = input.workers;
  final effectiveLabour = input.effectiveLabour;
  final config = input.config;
  final techUnlocked = input.techUnlocked;
  final militaryRebuildCrisis = input.militaryRebuildCrisis;
  final regimentBuildInputProductionBoost =
      input.regimentBuildInputProductionBoost;
  final missingRegimentBuildInputIds = input.missingRegimentBuildInputIds;
  final supplierReleaseImprovementInputIds =
      input.supplierReleaseImprovementInputIds;
  final feedstockReserveOutputIds = input.feedstockReserveOutputIds;
  final castIronLabourPeasantRecruitFabricBoost =
      input.castIronLabourPeasantRecruitFabricBoost;
  final growthStage = input.growthStage;
  // Labour allocation scores every feasible recipe to pick the best runs, so
  // this is an intrinsic full-catalog pass, not an output-keyed lookup that the
  // producing()/byId index could replace (Refs #3288).
  // ignore: disallowed_ast_ai_full_recipe_catalog_scan
  final recipes = ProductionRecipesCatalog.all;
  final agendaId = config.hiddenAgendaId;
  Stockpile virtual = stockpile;
  var remainingLabour = effectiveLabour;
  final result = <AssignedRecipe>[];

  // One production run's feedstock reserved for the multi-input improvement
  // recipes the GP is actively producing (Refs #2847 H8-extraction feedstock
  // co-availability). Empty when no such recipe is targeted, in which case
  // feasibility falls back to the unreduced stockpile (behaviour-equal).
  final feedstockReserve = feedstockReserveForOutputs(feedstockReserveOutputIds);
  final labourByRecipe = <String, int>{};

  if (castIronLabourPeasantRecruitFabricBoost) {
    assignCastIronLabourFabricPrePass(
      virtual: virtual,
      remainingLabour: remainingLabour,
      feedstockReserve: feedstockReserve,
      feedstockReserveOutputIds: feedstockReserveOutputIds,
      labourByRecipe: labourByRecipe,
      techUnlocked: techUnlocked,
      onStateUpdated: (nextVirtual, nextRemainingLabour) {
        virtual = nextVirtual;
        remainingLabour = nextRemainingLabour;
      },
    );
  }

  // Build feasible recipes with scores. Feasible = can run at least 1 full run.
  final candidates = <ScoredRecipe>[];
  for (final recipe in recipes) {
    // Skip recipes the player has not unlocked (e.g. `fabric_from_cotton`
    // requires `cotton_weaving`) so the AI never assigns labour to or suggests
    // a tech-locked recipe. SPEC/game/production-recipes.md
    // § Technology-gated recipes; Refs #3470 Slice C.
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    if (castIronLabourPeasantRecruitFabricBoost &&
        recipe.outputCommodityId == kAiCommodityIds.fabric) {
      continue;
    }
    final labourPerOutput = recipe.labourPerOutput;
    if (labourPerOutput <= 0) continue;
    // A reserve-target recipe consumes its own reserved feedstock, so it sees
    // the full stockpile; every other recipe sees the reserve withheld so it
    // cannot drain the feedstock the target recipe is assembling.
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
        ? virtual
        : stockpileWithFeedstockReserve(virtual, feedstockReserve);
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: feasibilityStock,
      remainingLabour: remainingLabour,
    );
    if (runs <= 0) continue;

    final score = growthStage != null
        ? stageScaledRecipeScore(
            recipe: recipe,
            stockpile: virtual,
            workers: workers,
            agendaId: agendaId,
            stage: growthStage,
          )
        : () {
            var legacy = scoreRecipe(
              recipe: recipe,
              stockpile: virtual,
              workers: workers,
              agendaId: agendaId,
            );
            if (militaryRebuildCrisis && _isMilitaryInputRecipe(recipe)) {
              legacy += 40;
            }
            if (regimentBuildInputProductionBoost &&
                missingRegimentBuildInputIds.contains(
                  recipe.outputCommodityId,
                )) {
              legacy += kRegimentBuildInputProductionScoreBoost;
            }
            if (supplierReleaseImprovementInputIds.contains(
              recipe.outputCommodityId,
            )) {
              legacy += kSupplierBuildInputReleaseProductionScoreBoost;
            }
            return legacy;
          }();
    candidates.add(ScoredRecipe(item: recipe, score: score));
  }

  if (candidates.isEmpty && labourByRecipe.isEmpty) return result;

  if (_log.debugEnabled) {
    _log.d(
      'recipe eval playerId=${config.leaderId} effectiveLabour=$effectiveLabour '
      'candidates=${candidates.map((c) => "${c.item.id}:${c.score.toStringAsFixed(2)}").toList()}',
    );
  }

  final rankedRecipes = sortByScore(candidates, (a, b) => a.id.compareTo(b.id));

  for (final recipe in rankedRecipes) {
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
        ? virtual
        : stockpileWithFeedstockReserve(virtual, feedstockReserve);
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: feasibilityStock,
      remainingLabour: remainingLabour,
    );
    if (runs <= 0) continue;

    final labourUsed = runs * recipe.labourPerOutput;
    labourByRecipe[recipe.id] = (labourByRecipe[recipe.id] ?? 0) + labourUsed;
    remainingLabour -= labourUsed;
    for (final entry in recipe.inputQuantities.entries) {
      virtual = virtual.applyDelta(entry.key, -entry.value * runs);
    }
    virtual = virtual.applyDelta(
      recipe.outputCommodityId,
      recipe.outputQuantity * runs,
    );
  }

  for (final entry in labourByRecipe.entries) {
    result.add(
      AssignedRecipe(recipeId: entry.key, assignedLabour: entry.value),
    );
  }

  if (_log.debugEnabled) {
    _log.d(
      'allocation effectiveLabour=$effectiveLabour '
      'labourByRecipe=$labourByRecipe assignmentsCount=${result.length}',
    );
  }
  return result;
}

bool _isMilitaryInputRecipe(ProductionRecipe recipe) {
  const militaryOutputIds = {
    'castIron',
    'steel',
    'bronze',
    'lumber',
    'fabric',
    'iron',
    'timber',
  };
  return militaryOutputIds.contains(recipe.outputCommodityId);
}
