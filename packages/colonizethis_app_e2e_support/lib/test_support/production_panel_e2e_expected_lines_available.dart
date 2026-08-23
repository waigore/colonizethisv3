// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Available-commodity and worker-pool expected texts for ProductionPanel.
// Mirrors app/lib/features/game/widgets/production/production_panel.dart for e2e.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
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

void addProductionPanelAvailableTexts(
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
  out.add(l10n.production_labourThisTurn(effectiveLabour));
}
