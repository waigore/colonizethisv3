// Shared ProductionPanel pump and finder helpers (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

Finder productionNinePatchLabeled(String label) =>
    find.byWidgetPredicate((Widget w) {
      if (w is! CtNinePatchButton) return false;
      final child = w.child;
      return child is Text && child.data == label;
    });

Future<void> pumpProductionPanelSettled(
  WidgetTester tester, {
  required Player player,
  Game? gameOverride,
  Map<String, int> desiredOutputByRecipe = const {},
  ValueChanged<Map<String, int>>? onDesiredOutputChanged,
  VoidCallback? onOpenCommodityBreakdown,
  void Function(String commodityId)? onOpenTradeMarket,
  double width = 800,
  double height = 500,
}) async {
  await tester.pumpWidget(
    buildProductionPanel(
      player: player,
      gameOverride: gameOverride,
      desiredOutputByRecipe: desiredOutputByRecipe,
      onDesiredOutputChanged: onDesiredOutputChanged,
      onOpenCommodityBreakdown: onOpenCommodityBreakdown,
      onOpenTradeMarket: onOpenTradeMarket,
      width: width,
      height: height,
    ),
  );
  await pumpSettleCapped(tester);
}

int productionRecipeIndex(String recipeId) {
  final index = ProductionRecipesCatalog.all.indexWhere(
    (r) => r.id == recipeId,
  );
  expect(index, greaterThanOrEqualTo(0));
  return index;
}

Future<void> tapProductionAllocationSemantic(
  WidgetTester tester, {
  required String semanticLabel,
  required int recipeIndex,
}) async {
  await tester.tap(find.bySemanticsLabel(semanticLabel).at(recipeIndex));
  await pumpSyncFrames(tester);
}

int expectedLumberMaxForPlayer(Player player, {required int currentDesired}) {
  const lumberId = 'lumber_from_timber';
  final displayGame = productionPanelTestGameFor(player);
  final regimentCounts = regimentTypeCountsForPlayer(
    displayGame.worldState,
    player.id,
  );
  final shipCounts = shipTypeCountsForPlayer(displayGame.worldState, player.id);
  final effectiveLabour = effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
    foodCounts: MilitaryNavyFoodCounts(
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    ),
  );
  return computeRecipeAffordance(
    recipe: ProductionRecipesCatalog.byId[lumberId]!,
    stockpile: player.stockpile,
    desiredOutputByRecipe: {lumberId: currentDesired},
    effectiveLabour: effectiveLabour,
  ).maxDesiredOutput;
}

AppLocalizations productionEnL10n() =>
    lookupAppLocalizations(const Locale('en'));
