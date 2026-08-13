import 'ai_commodity_ids.dart';
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricShort;
import 'planning_imports.dart';

/// Feedstock commodity ids consumed by production recipes whose output is a
/// currently-missing cheapest-regiment (`peasant_levies`) build input.
/// Refs #2847 § H8-supply.
Set<CommodityId> regimentBuildInputFeedstockIds(
  Stockpile projected, {
  bool peasantRecruitFabricStaging = false,
}) {
  final missingInputs = <CommodityId>{
    for (final entry
        in RegimentEconomyCatalog.peasantLevies.buildInputs.entries)
      if (projected.quantityOf(entry.key) < entry.value) entry.key,
  };
  if (peasantRecruitFabricStaging &&
      isCastIronLabourPeasantRecruitFabricShort(projected)) {
    missingInputs.add(kAiCommodityIds.fabric);
  }
  if (missingInputs.isEmpty) return const <CommodityId>{};
  final feedstock = <CommodityId>{};
  for (final buildInputId in missingInputs) {
    for (final recipe in ProductionRecipesCatalog.producing(buildInputId)) {
      feedstock.addAll(recipe.inputQuantities.keys);
    }
  }
  return feedstock;
}

/// Build-input feedstock ids ordered so Old World lock-recovery sellers extract
/// wool before cotton (seed-42), then alphabetically for determinism.
List<CommodityId> sortedRegimentBuildInputFeedstockIds(
  Stockpile projected, {
  bool peasantRecruitFabricStaging = false,
}) {
  return regimentBuildInputFeedstockIds(
    projected,
    peasantRecruitFabricStaging: peasantRecruitFabricStaging,
  ).toList()..sort((a, b) {
    if (a == CommodityCatalog.wool.id) return -1;
    if (b == CommodityCatalog.wool.id) return 1;
    return a.compareTo(b);
  });
}
