// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Allocation-section expected texts for ProductionPanel.
// Mirrors app/lib/features/game/widgets/production/production_panel.dart for e2e.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance_copy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

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

void addProductionPanelAllocationTexts(
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
    final locked = !ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      player.techUnlocked,
    );
    final affordance = computeRecipeAffordance(
      recipe: recipe,
      stockpile: player.stockpile,
      desiredOutputByRecipe: desiredOutputByRecipe,
      effectiveLabour: effectiveLabour,
    );
    // A locked (tech-gated) recipe forces maxAchievable to 0 and renders the
    // localized (locked) marker as a separate Text after the recipe label,
    // mirroring ProductionAllocationRow / _AllocationSubpanel._buildRecipeLabel.
    final maxAchievable = locked ? 0 : affordance.maxDesiredOutput;

    out.add(_recipeLabelText(recipe));
    if (locked) {
      out.add(l10n.production_recipeLocked);
    } else {
      out.add(
        formatProductionRecipeAffordanceCopy(
          l10n: l10n,
          affordance: affordance,
          maxAchievable: maxAchievable,
        ).displayText,
      );
    }
    out.add(desired.toString());
  }

  out.add(l10n.production_totalLabour(totalRequiredLabour, effectiveLabour));
  if (labourInsufficient) {
    out.add(l10n.production_labourInsufficient);
  }
}
