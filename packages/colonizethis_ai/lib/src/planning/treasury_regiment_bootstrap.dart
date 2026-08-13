import 'ai_commodity_ids.dart';
import 'planning_imports.dart';
import 'treasury_market_pricing.dart';
import 'treasury_regiment_bootstrap_quantities.dart';

export 'treasury_regiment_bootstrap_feedstock_ids.dart';
export 'treasury_regiment_bootstrap_quantities.dart';

// Lock-recovery seller regiment build-input bootstrap: feedstock reservation,
// improvement-input bids, and domestic-production feedstock staging for the
// treasury planner (Refs #2847 § H8 / H8-extraction; #3288 / #4104 / #4365).

/// Adds the feedstock bid for the first viable [feedstockCandidates] entry so a
/// lock-recovery seller can domestically produce a missing regiment build input.
/// Returns true when a feedstock bid was queued (still accumulating feedstock).
bool addRegimentBuildInputFeedstockBootstrapNeed({
  required List<CommodityId> feedstockCandidates,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
  bool peasantRecruitFabricStaging = false,
}) {
  for (final feedstockId in feedstockCandidates) {
    final qtyNeeded = feedstockQuantityForOneMissingBuildInputRun(
      feedstockId,
      projected,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    );
    if (qtyNeeded <= 0) continue;
    final held =
        projected.quantityOf(feedstockId) +
        (carryForwardBids[feedstockId] ?? 0);
    if (held >= qtyNeeded) return false;
    need[feedstockId] = qtyNeeded - held;
    return true;
  }
  return false;
}

/// Adds bids for the level-0 `build_improvement` inputs (lumber + cast iron) a
/// lock-recovery seller must hold to extract its owned fabric feedstock tile,
/// when the regiment build-input feedstock-extraction gate is active
/// (Refs #2847 § H8-extraction).
bool addRegimentFeedstockImprovementInputNeed({
  required Game game,
  required String playerId,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
}) {
  final cost = regimentBuildInputFeedstockImprovementInputCost(game, playerId);
  if (cost.isEmpty) return false;
  final inputIds = cost.keys.toList()..sort();

  var queued = false;
  for (final inputId in inputIds) {
    if (kDomesticProductionImprovementInputIds.contains(inputId) &&
        !marketHasStandingOfferSupplyFromOthers(
          state: game.worldMarketState,
          commodityId: inputId,
          excludePlayerId: playerId,
        )) {
      continue;
    }
    final held =
        projected.quantityOf(inputId) + (carryForwardBids[inputId] ?? 0);
    final missing = cost[inputId]! - held;
    if (missing > 0) {
      need[inputId] = missing;
      queued = true;
    }
  }
  if (queued) return true;

  for (final inputId in inputIds) {
    if (!kDomesticProductionImprovementInputIds.contains(inputId)) continue;
    final held =
        projected.quantityOf(inputId) + (carryForwardBids[inputId] ?? 0);
    if (cost[inputId]! - held <= 0) continue;
    addImprovementInputProductionFeedstockNeed(
      improvementInputId: inputId,
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
    );
    queued = true;
  }
  return queued;
}

/// Bids the production feedstock for one run of [improvementInputId] when a
/// lock-recovery seller is short of the feedstock to produce it domestically.
void addImprovementInputProductionFeedstockNeed({
  required CommodityId improvementInputId,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
}) {
  final recipe = lowestIdRecipeProducing(improvementInputId);
  if (recipe == null) return;
  for (final entry in recipe.inputQuantities.entries) {
    final held =
        projected.quantityOf(entry.key) + (carryForwardBids[entry.key] ?? 0);
    final missing = entry.value - held;
    if (missing > 0) {
      need[entry.key] = (need[entry.key] ?? 0) + missing;
    }
  }
}

/// Adds direct bids for any missing `peasant_levies` build input when no
/// feedstock bootstrap bid is pending. Refs #2847 § castIron-labour.
void addRegimentBuildInputDirectNeed({
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
  bool peasantRecruitFabricStaging = false,
}) {
  for (final input
      in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    var targetQty = input.value;
    if (peasantRecruitFabricStaging && input.key == kAiCommodityIds.fabric) {
      final peasantFabricCost =
          WorkerActionEconomyCatalog.peasant.materialCosts[input.key] ?? 0;
      if (peasantFabricCost > targetQty) {
        targetQty = peasantFabricCost;
      }
    }
    final held =
        projected.quantityOf(input.key) + (carryForwardBids[input.key] ?? 0);
    if (held < targetQty) {
      need[input.key] = targetQty - held;
    }
  }
}

/// Level-0 `build_improvement` improvement-input commodities a lock-recovery
/// seller must produce domestically because the world market structurally lacks
/// supply for them on seed 42. Refs #2847 § H8-extraction castIron residual.
const Set<CommodityId> kDomesticProductionImprovementInputIds = {'castIron'};
