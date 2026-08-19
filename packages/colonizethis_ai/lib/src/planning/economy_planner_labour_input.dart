import 'growth_stage.dart';
import 'planning_imports.dart';

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
