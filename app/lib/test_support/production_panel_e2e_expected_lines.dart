// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProductionPanel (wide layout ≥ kNarrowBreakpoint).
// Mirrors app/lib/features/game/widgets/production_panel.dart for e2e.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/production_recipe_affordance.dart';
import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';

Set<String> _inputCommodityIds() {
  final inputIds = <String>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    inputIds.addAll(recipe.inputQuantities.keys);
  }
  return inputIds;
}

String _workerDisplayName(String workerType, AppLocalizations l10n) {
  switch (workerType) {
    case 'peasant':
      return l10n.production_workers_peasants;
    case 'apprentice':
      return l10n.production_workers_apprentices;
    case 'journeyman':
      return l10n.production_workers_journeymen;
    case 'master':
      return l10n.production_workers_masters;
    default:
      return workerType;
  }
}

void _addAvailableTexts(
  List<String> out,
  CtE2eProductionPanelSnapshot snap,
  AppLocalizations l10n,
  int effectiveLabour,
) {
  final player = snap.player;
  final netChanges = snap.netDeltasByCommodity;
  final inputCommodityIds = _inputCommodityIds();

  final rawMaterials = CommodityCatalog.all
      .where(
        (c) =>
            c.category == CommodityCategory.rawMaterial &&
            inputCommodityIds.contains(c.id),
      )
      .toList();
  final manufactured = CommodityCatalog.all
      .where((c) => c.category == CommodityCategory.manufactured)
      .toList();
  final availableFood = CommodityCatalog.all
      .where((c) => c.category == CommodityCategory.food)
      .toList();

  out.add(l10n.production_available);
  out.add(l10n.production_breakdown);

  void addCommodityCellTexts(Commodity c) {
    final name = c.displayName ?? c.id;
    final qty = player.stockpile.quantityOf(c.id);
    final change = netChanges[c.id] ?? 0;
    out.add(name);
    out.add(CtResourceCell.formatQuantity(qty));
    if (change != 0) {
      out.add(CtResourceCell.formattedDeltaText(change)!);
    }
  }

  void addWorkerCellTexts(String workerType, int count) {
    out.add(_workerDisplayName(workerType, l10n));
    out.add(CtResourceCell.formatQuantity(count));
  }

  if (availableFood.isNotEmpty) {
    out.add(l10n.production_food.toUpperCase());
    for (final c in availableFood) {
      addCommodityCellTexts(c);
    }
  }

  out.add(l10n.production_rawMaterials.toUpperCase());
  for (final c in rawMaterials) {
    addCommodityCellTexts(c);
  }

  if (manufactured.isNotEmpty) {
    out.add(l10n.production_manufactured.toUpperCase());
    for (final c in manufactured) {
      addCommodityCellTexts(c);
    }
  }

  out.add(l10n.production_workers.toUpperCase());
  addWorkerCellTexts('peasant', player.workerPool.peasants);
  addWorkerCellTexts('apprentice', player.workerPool.apprentices);
  addWorkerCellTexts('journeyman', player.workerPool.journeymen);
  addWorkerCellTexts('master', player.workerPool.masters);
  out.add(l10n.production_effectiveLabour(effectiveLabour));
}

String _recipeLabelText(ProductionRecipe recipe) {
  final outputCommodity = CommodityCatalog.byId[recipe.outputCommodityId];
  final outputName = outputCommodity?.displayName ?? recipe.outputCommodityId;
  final inputParts = recipe.inputQuantities.entries
      .map((e) {
        final comm = CommodityCatalog.byId[e.key];
        final name = comm?.displayName ?? e.key;
        return '$name ×${e.value}';
      })
      .join(', ');
  return '$outputName ($inputParts)';
}

void _addAllocationTexts(
  List<String> out,
  CtE2eProductionPanelSnapshot snap,
  AppLocalizations l10n,
  int effectiveLabour,
) {
  final player = snap.player;
  final desiredOutputByRecipe = snap.desiredOutputByRecipe;

  var totalRequiredLabour = 0;
  for (final e in desiredOutputByRecipe.entries) {
    final recipe = ProductionRecipesCatalog.byId[e.key];
    if (recipe == null) continue;
    totalRequiredLabour += e.value * recipe.labourPerOutput;
  }
  final labourInsufficient = totalRequiredLabour > effectiveLabour;

  out.add(l10n.production_allocation);
  out.add(l10n.common_reset);

  for (final recipe in ProductionRecipesCatalog.all) {
    final desired = desiredOutputByRecipe[recipe.id] ?? 0;
    final affordance = computeRecipeAffordance(
      recipe: recipe,
      stockpile: player.stockpile,
      desiredOutputByRecipe: desiredOutputByRecipe,
      effectiveLabour: effectiveLabour,
    );

    out.add(_recipeLabelText(recipe));
    out.add(
      l10n.production_recipeAffordance(
        affordance.maxDesiredOutput,
        affordance.limitingLabel,
      ),
    );
    out.add(desired.toString());
  }

  out.add(l10n.production_totalLabour(totalRequiredLabour, effectiveLabour));
  if (labourInsufficient) {
    out.add(l10n.production_labourInsufficient);
  }
}

String _labourTierDisplayName(WorkerTier tier, AppLocalizations l10n) {
  switch (tier) {
    case WorkerTier.peasant:
      return l10n.production_workers_peasants;
    case WorkerTier.apprentice:
      return l10n.production_workers_apprentices;
    case WorkerTier.journeyman:
      return l10n.production_workers_journeymen;
    case WorkerTier.master:
      return l10n.production_workers_masters;
  }
}

/// Expected in-order [Text.data] for the Labour Controls section the
/// production panel appends to the Workers section (`ProductionPanel`
/// `_buildWorkerSection`, gated on a non-null `currentOrders`). Mirrors the
/// `CtSectionLabel` header plus one [ProductionLabourSection] row per tier.
///
/// Per-row order matches `_ProductionLabourTierRow.build`: the tier label, an
/// optional `Queued: N` segment (only when `queuedCount > 0`), then — when
/// [canEdit] is true — the `Disband` label. The Disband label is emitted for
/// every tier: trained tiers render a real [CtDangerTextButton] and the
/// peasant row reserves an opacity-0 [CtDangerTextButton] placeholder that the
/// pre-order text collector still visits. `CtSectionLabel` upper-cases its
/// text, matching the other section headers in this mirror.
List<String> productionLabourControlsExpectedTexts({
  required Player player,
  required Orders currentOrders,
  required bool canEdit,
  required AppLocalizations l10n,
}) {
  final out = <String>[];
  out.add(l10n.production_labourControlsSectionLabel.toUpperCase());
  final rows = buildProductionLabourRowData(
    player: player,
    currentOrders: currentOrders,
    canEdit: canEdit,
  );
  for (final row in rows) {
    final tierName = _labourTierDisplayName(row.tier, l10n);
    final state = row.techUnlocked
        ? l10n.production_labourTierUnlocked
        : l10n.production_labourTierLocked;
    out.add(l10n.production_labourTierLabel(tierName, state));
    if (row.queuedCount > 0) {
      out.add(l10n.production_labourQueued(row.queuedCount));
    }
    if (canEdit) {
      out.add(l10n.production_labourDisband);
    }
  }
  return out;
}

/// In-order [Text.data] for wide [ProductionPanel] preorder traversal.
List<String> productionPanelWideExpectedTexts(
  CtE2eProductionPanelSnapshot snap,
  AppLocalizations l10n,
) {
  final regimentCounts = regimentTypeCountsForPlayer(
    snap.game.worldState,
    snap.player.id,
  );
  final shipCounts = shipTypeCountsForPlayer(
    snap.game.worldState,
    snap.player.id,
  );
  final effectiveLabour = effectiveLabourForWorkers(
    workers: snap.player.workerPool,
    stockpile: snap.player.stockpile,
    regimentCountsById: regimentCounts,
    shipCountsById: shipCounts,
  );

  final out = <String>[];
  _addAvailableTexts(out, snap, l10n, effectiveLabour);
  out.addAll(
    productionLabourControlsExpectedTexts(
      player: snap.player,
      currentOrders: snap.currentOrders,
      canEdit: snap.canEditLabour,
      l10n: l10n,
    ),
  );
  _addAllocationTexts(out, snap, l10n, effectiveLabour);
  return out;
}
