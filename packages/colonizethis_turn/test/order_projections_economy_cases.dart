// Economy fixtures for order_projections_test (Refs #4740 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_projections_cases.dart';

Game orderProjectionsTreasuryStockpileGame() {
  return orderProjectionsSingleProvinceGame(
    player: Player(
      id: 'p1',
      displayName: 'A',
      isHuman: true,
      treasury: 100,
      stockpile: Stockpile(quantities: {'grain': 10, 'iron': 5}),
    ),
  );
}

Game orderProjectionsGrainConsumptionGame() {
  return orderProjectionsSingleProvinceGame(
    player: Player(
      id: 'p1',
      displayName: 'A',
      isHuman: true,
      stockpile: Stockpile(quantities: {'grain': 1}),
      workerPool: WorkerPool(peasants: 1),
    ),
  );
}

Game orderProjectionsProductionGame() {
  return orderProjectionsSingleProvinceGame(
    player: Player(
      id: 'p1',
      displayName: 'A',
      isHuman: true,
      stockpile: Stockpile(quantities: {'timber': 4, 'grain': 4}),
      workerPool: WorkerPool(peasants: 4),
    ),
  );
}

List<AssignedRecipe> orderProjectionsLumberAssignments() {
  return const [
    AssignedRecipe(
      recipeId: orderProjectionsLumberRecipeId,
      assignedLabour: 4,
    ),
  ];
}
