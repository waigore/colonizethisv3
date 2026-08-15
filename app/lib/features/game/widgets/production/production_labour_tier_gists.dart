// Cost / upkeep / Requires gist formatters for Labour Controls rows.
// SPEC/ui/production-panel.md § Labour Controls (12-A) Cost, upkeep, and tech gist.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../core/utils/currency_format.dart';
import '../../../../widgets/commodity_display_name.dart';

/// One catalog-cost fragment. [danger] is true when that resource is why **+**
/// is disabled.
class LabourCostGistSegment {
  const LabourCostGistSegment({required this.text, required this.danger});

  final String text;
  final bool danger;
}

int labourPerTurnForWorkerTier(WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return WorkerPool.labourPerPeasantTurn;
    case WorkerTier.apprentice:
      return WorkerPool.labourPerApprenticeTurn;
    case WorkerTier.journeyman:
      return WorkerPool.labourPerJourneymanTurn;
    case WorkerTier.master:
      return WorkerPool.labourPerMasterTurn;
  }
}

/// Catalog cost segments (display names, not raw ids).
List<LabourCostGistSegment> labourCostGistSegments({
  required WorkerTier tier,
  required AppLocalizations l10n,
  required bool canAppend,
  required String? appendRefusalReason,
  required Set<String> insufficientMaterialIds,
}) {
  final row = WorkerActionEconomyCatalog.forTier(tier);
  final treasuryDanger =
      !canAppend && appendRefusalReason == kRecruitWorkerInsufficientTreasury;
  final peasantDanger =
      !canAppend && appendRefusalReason == kRecruitWorkerInsufficientWorkers;
  final materialsDanger =
      !canAppend && appendRefusalReason == kRecruitWorkerInsufficientMaterials;
  final segments = <LabourCostGistSegment>[];
  if (row.treasuryCost > 0) {
    segments.add(
      LabourCostGistSegment(
        text: formatTreasuryCurrency(row.treasuryCost),
        danger: treasuryDanger,
      ),
    );
  }
  for (final entry in row.materialCosts.entries) {
    final name = commodityDisplayName(l10n, entry.key);
    segments.add(
      LabourCostGistSegment(
        text: l10n.production_labourCostMaterial(name, entry.value),
        danger: materialsDanger && insufficientMaterialIds.contains(entry.key),
      ),
    );
  }
  if (row.consumesPeasant) {
    segments.add(
      LabourCostGistSegment(
        text: l10n.production_labourCostPeasantConsume,
        danger: peasantDanger,
      ),
    );
  }
  return segments;
}

String labourCostGistPlain(List<LabourCostGistSegment> segments) {
  return segments.map((s) => s.text).join(' + ');
}

/// Labour + food/luxury upkeep from Consumption-phase helpers.
String labourUpkeepGist({
  required WorkerTier tier,
  required AppLocalizations l10n,
}) {
  final labour = l10n.production_labourUpkeepLabour(
    labourPerTurnForWorkerTier(tier),
  );
  final ids = workerFoodCommodityIdsInConsumeOrder;
  final grain = commodityDisplayName(l10n, ids[0]);
  final meat = commodityDisplayName(l10n, ids[1]);
  final food = workerFoodPerUnitForTier(tier) <= kWorkerFoodPerPeasant
      ? l10n.production_labourUpkeepFoodOr(grain, meat)
      : l10n.production_labourUpkeepFoodAnd(grain, meat);
  final luxuryId = workerLuxuryCommodityIdForTier(tier);
  if (luxuryId == null) {
    return '$labour · $food';
  }
  return '$labour · $food · ${commodityDisplayName(l10n, luxuryId)}';
}

String? labourRequiresGist({
  required WorkerTier tier,
  required bool techUnlocked,
  required AppLocalizations l10n,
}) {
  if (techUnlocked) return null;
  final names = WorkerActionEconomyCatalog.forTier(
    tier,
  ).requiredTechIds.map(techDisplayName).join(', ');
  if (names.isEmpty) return null;
  return l10n.production_labourRequires(names);
}
