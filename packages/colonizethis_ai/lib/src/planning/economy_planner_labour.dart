part of 'economy_planner.dart';

/// Commodity ids the cheapest regiment still needs in the stockpile before
/// `suggestBuildOrders` will surface it (Refs #2847 H8).
Set<String> _missingCheapestRegimentBuildInputIds(Stockpile stockpile) {
  final missing = <String>{};
  for (final entry in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) {
      missing.add(entry.key);
    }
  }
  return missing;
}

List<AssignedRecipe> _allocateLabour({
  required Stockpile stockpile,
  required WorkerPool workers,
  required int effectiveLabour,
  required AIConfig config,
  required AISeedBundle seeds,
  Map<String, bool>? techUnlocked,
  bool militaryRebuildCrisis = false,
  bool regimentBuildInputProductionBoost = false,
  Set<String> missingRegimentBuildInputIds = const {},
  Set<String> supplierReleaseImprovementInputIds = const {},
  Set<String> feedstockReserveOutputIds = const {},
  bool castIronLabourPeasantRecruitFabricBoost = false,
  GrowthStage? growthStage,
}) {
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
  final feedstockReserve =
      _feedstockReserveForOutputs(feedstockReserveOutputIds);
  final labourByRecipe = <String, int>{};

  if (castIronLabourPeasantRecruitFabricBoost) {
    _assignCastIronLabourFabricPrePass(
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
            : _stockpileWithReserve(virtual, feedstockReserve);
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

  final rankedRecipes = sortByScore(
    candidates,
    (a, b) => a.id.compareTo(b.id),
  );

  for (final recipe in rankedRecipes) {
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
            ? virtual
            : _stockpileWithReserve(virtual, feedstockReserve);
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

/// Assigns the lowest-`id` feasible fabric recipe before the general greedy
/// pass when the castIron-labour peasant-recruit fabric path is active, so
/// scarce effective labour is not consumed by competing boosted recipes
/// (`castIron`, `lumber`) on the same turn (Refs #2847).
void _assignCastIronLabourFabricPrePass({
  required Stockpile virtual,
  required int remainingLabour,
  required Map<CommodityId, int> feedstockReserve,
  required Set<String> feedstockReserveOutputIds,
  required Map<String, int> labourByRecipe,
  required void Function(Stockpile virtual, int remainingLabour) onStateUpdated,
  Map<String, bool>? techUnlocked,
}) {
  final fabricId = kAiCommodityIds.fabric;
  final fabricRecipes = ProductionRecipesCatalog.producing(fabricId).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  var nextVirtual = virtual;
  var nextRemainingLabour = remainingLabour;
  for (final recipe in fabricRecipes) {
    // Tech-locked fabric recipes (e.g. `fabric_from_cotton` without
    // `cotton_weaving`) are not assignable. Refs #3470 Slice C.
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    if (nextRemainingLabour < recipe.labourPerOutput) continue;
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
            ? nextVirtual
            : _stockpileWithReserve(nextVirtual, feedstockReserve);
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: feasibilityStock,
      remainingLabour: nextRemainingLabour,
    );
    if (runs <= 0) continue;
    final labourUsed = runs * recipe.labourPerOutput;
    labourByRecipe[recipe.id] = (labourByRecipe[recipe.id] ?? 0) + labourUsed;
    nextRemainingLabour -= labourUsed;
    for (final entry in recipe.inputQuantities.entries) {
      nextVirtual = nextVirtual.applyDelta(entry.key, -entry.value * runs);
    }
    nextVirtual = nextVirtual.applyDelta(
      recipe.outputCommodityId,
      recipe.outputQuantity * runs,
    );
    onStateUpdated(nextVirtual, nextRemainingLabour);
    return;
  }
}

/// The subset of [outputIds] whose lowest-`id` producing recipe consumes more
/// than one distinct input commodity (Refs #2847 § H8-extraction feedstock
/// co-availability; S7-D lumber re-localization). Only these multi-input
/// outputs (e.g. `castIron` from `timber` + `iron`) can have a competing
/// single-input recipe drain their partial feedstock, so only they need a
/// feedstock reserve. Single-input outputs (e.g. `lumber` from `timber`) are
/// excluded: reserving their feedstock would needlessly withhold it and, by
/// marking them reserve targets, defeat the reserve they are meant to respect.
/// Deterministic over the static `ProductionRecipesCatalog`; returns the empty
/// set when [outputIds] is empty so feasibility falls back to the unreduced
/// stockpile (behaviour-equal).
Set<String> _multiInputImprovementOutputs(Set<String> outputIds) {
  if (outputIds.isEmpty) return const <String>{};
  final result = <String>{};
  for (final outputId in outputIds) {
    final recipe = _lowestIdRecipeProducingOutput(outputId);
    if (recipe == null) continue;
    if (recipe.inputQuantities.length > 1) result.add(outputId);
  }
  return result;
}

/// The production recipe with the lowest `id` whose output is [outputId], or
/// `null` when no recipe produces it. Deterministic over the static
/// `ProductionRecipesCatalog`; uses the O(1) `producing` index instead of an
/// O(recipes) full-catalog scan (Refs #3288 step 5).
ProductionRecipe? _lowestIdRecipeProducingOutput(String outputId) {
  ProductionRecipe? best;
  for (final recipe in ProductionRecipesCatalog.producing(outputId)) {
    if (best == null || recipe.id.compareTo(best.id) < 0) best = recipe;
  }
  return best;
}

/// One production run's input requirements for each output id in
/// [outputIds], summed across outputs. Used to reserve the multi-input
/// feedstock (`timber` + `iron` for `castIron`) a domestically-produced
/// improvement input needs so single-input competitors (`lumber_from_timber`)
/// cannot drain it before the multi-input recipe accumulates a full run
/// (Refs #2847 H8-extraction feedstock co-availability). Deterministic: the
/// lowest-`id` recipe is chosen per output via the O(1) `producing` index
/// (Refs #3288 step 5) and reserve accumulation is order-independent. Returns
/// an empty map when [outputIds] is empty.
Map<CommodityId, int> _feedstockReserveForOutputs(Set<String> outputIds) {
  if (outputIds.isEmpty) return const {};
  final reserve = <CommodityId, int>{};
  for (final out in outputIds) {
    final recipe = _lowestIdRecipeProducingOutput(out);
    if (recipe == null) continue;
    for (final entry in recipe.inputQuantities.entries) {
      reserve[entry.key] = (reserve[entry.key] ?? 0) + entry.value;
    }
  }
  return reserve;
}

/// [base] with each [reserve] quantity withheld (clamped at zero). The
/// reserved feedstock is invisible to non-target recipes so they cannot
/// consume it (Refs #2847 H8-extraction feedstock co-availability). Returns
/// [base] unchanged when [reserve] is empty.
Stockpile _stockpileWithReserve(Stockpile base, Map<CommodityId, int> reserve) {
  if (reserve.isEmpty) return base;
  var adjusted = base;
  for (final entry in reserve.entries) {
    final have = adjusted.quantityOf(entry.key);
    final reduce = entry.value < have ? entry.value : have;
    if (reduce > 0) adjusted = adjusted.applyDelta(entry.key, -reduce);
  }
  return adjusted;
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

