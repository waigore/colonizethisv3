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
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/production_recipe_affordance.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

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

  if (availableFood.isNotEmpty) {
    out.add(l10n.production_food);
    for (final c in availableFood) {
      final name = c.displayName ?? c.id;
      final qty = player.stockpile.quantityOf(c.id);
      final change = netChanges[c.id] ?? 0;
      final changeSeg = change == 0 ? '' : ' (${change > 0 ? '+' : ''}$change)';
      out.add(l10n.production_commodityStock(name, qty, changeSeg));
    }
  }

  out.add(l10n.production_rawMaterials);
  for (final c in rawMaterials) {
    final name = c.displayName ?? c.id;
    final qty = player.stockpile.quantityOf(c.id);
    final change = netChanges[c.id] ?? 0;
    final changeSeg = change == 0 ? '' : ' (${change > 0 ? '+' : ''}$change)';
    out.add(l10n.production_commodityStock(name, qty, changeSeg));
  }

  if (manufactured.isNotEmpty) {
    out.add(l10n.production_manufactured);
    for (final c in manufactured) {
      final name = c.displayName ?? c.id;
      final qty = player.stockpile.quantityOf(c.id);
      final change = netChanges[c.id] ?? 0;
      final changeSeg = change == 0 ? '' : ' (${change > 0 ? '+' : ''}$change)';
      out.add(l10n.production_commodityStock(name, qty, changeSeg));
    }
  }

  out.add(l10n.production_workers);
  out.add(
    l10n.production_workerCount(
      _workerDisplayName('peasant', l10n),
      player.workerPool.peasants,
    ),
  );
  out.add(
    l10n.production_workerCount(
      _workerDisplayName('apprentice', l10n),
      player.workerPool.apprentices,
    ),
  );
  out.add(
    l10n.production_workerCount(
      _workerDisplayName('journeyman', l10n),
      player.workerPool.journeymen,
    ),
  );
  out.add(
    l10n.production_workerCount(
      _workerDisplayName('master', l10n),
      player.workerPool.masters,
    ),
  );
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
  _addAllocationTexts(out, snap, l10n, effectiveLabour);
  return out;
}
