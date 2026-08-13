import 'ai_commodity_ids.dart';
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricShort;
import 'planning_imports.dart';

/// The production recipe with the lowest `id` whose output is [commodityId], or
/// `null` when no recipe produces it. Deterministic over the static
/// `ProductionRecipesCatalog`.
ProductionRecipe? lowestIdRecipeProducing(CommodityId commodityId) {
  ProductionRecipe? best;
  for (final recipe in ProductionRecipesCatalog.producing(commodityId)) {
    if (best == null || recipe.id.compareTo(best.id) < 0) {
      best = recipe;
    }
  }
  return best;
}

int maxInt(int a, int b) => a >= b ? a : b;

/// Per-run feedstock input quantity required to produce one unit of a missing
/// `peasant_levies` build input via a production recipe consuming [feedstockId].
int feedstockQuantityForOneMissingBuildInputRun(
  CommodityId feedstockId,
  Stockpile projected, {
  bool peasantRecruitFabricStaging = false,
}) {
  var needed = 0;
  for (final entry
      in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    if (projected.quantityOf(entry.key) >= entry.value) continue;
    for (final recipe in ProductionRecipesCatalog.producing(entry.key)) {
      final perRun = recipe.inputQuantities[feedstockId];
      if (perRun != null && perRun > needed) {
        needed = perRun;
      }
    }
  }
  if (peasantRecruitFabricStaging) {
    needed = maxInt(
      needed,
      feedstockQuantityForPeasantRecruitFabricStaging(feedstockId, projected),
    );
  }
  return needed;
}

/// Feedstock units required to domestically produce the remaining `fabric` for
/// a peasant recruit (2 total) when the regiment build input (1) may already
/// be on hand. Refs #2847 § castIron-labour peasant-recruit fabric staging.
int feedstockQuantityForPeasantRecruitFabricStaging(
  CommodityId feedstockId,
  Stockpile projected,
) {
  if (!isCastIronLabourPeasantRecruitFabricShort(projected)) return 0;
  final fabricId = kAiCommodityIds.fabric;
  final required =
      WorkerActionEconomyCatalog.peasant.materialCosts[fabricId] ?? 0;
  if (required <= 0) return 0;
  final missingFabric = required - projected.quantityOf(fabricId);
  if (missingFabric <= 0) return 0;
  var needed = 0;
  for (final recipe in ProductionRecipesCatalog.producing(fabricId)) {
    final perRun = recipe.inputQuantities[feedstockId];
    if (perRun == null) continue;
    final total = perRun * missingFabric;
    if (total > needed) needed = total;
  }
  return needed;
}
