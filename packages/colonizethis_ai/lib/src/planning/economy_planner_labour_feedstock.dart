import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'planning_imports.dart';

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
Set<String> multiInputImprovementOutputs(Set<String> outputIds) {
  if (outputIds.isEmpty) return const <String>{};
  final result = <String>{};
  for (final outputId in outputIds) {
    final recipe = lowestIdRecipeProducingOutput(outputId);
    if (recipe == null) continue;
    if (recipe.inputQuantities.length > 1) result.add(outputId);
  }
  return result;
}

/// The production recipe with the lowest `id` whose output is [outputId], or
/// `null` when no recipe produces it. Deterministic over the static
/// `ProductionRecipesCatalog`; uses the O(1) `producing` index instead of an
/// O(recipes) full-catalog scan (Refs #3288 step 5).
ProductionRecipe? lowestIdRecipeProducingOutput(String outputId) {
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
Map<CommodityId, int> feedstockReserveForOutputs(Set<String> outputIds) {
  if (outputIds.isEmpty) return const {};
  final reserve = <CommodityId, int>{};
  for (final out in outputIds) {
    final recipe = lowestIdRecipeProducingOutput(out);
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
Stockpile stockpileWithFeedstockReserve(
  Stockpile base,
  Map<CommodityId, int> reserve,
) {
  if (reserve.isEmpty) return base;
  var adjusted = base;
  for (final entry in reserve.entries) {
    final have = adjusted.quantityOf(entry.key);
    final reduce = entry.value < have ? entry.value : have;
    if (reduce > 0) adjusted = adjusted.applyDelta(entry.key, -reduce);
  }
  return adjusted;
}
