import 'package:colonizethis_economy/colonizethis_economy.dart' show assignedRecipesFromDesiredOutput;
import 'package:colonizethis_models/colonizethis_models.dart' show AssignedRecipe;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desired output units per recipe (recipe id → units). Used by Production panel
/// and passed to nextTurn as production assignments. SPEC/ui/production-panel.md.
class ProductionDesiredOutputNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void replaceAll(Map<String, int> next) {
    state = next;
  }
}

final productionDesiredOutputProvider =
    NotifierProvider<ProductionDesiredOutputNotifier, Map<String, int>>(
      ProductionDesiredOutputNotifier.new,
    );

/// Builds [AssignedRecipe] list from desired output map for the turn resolver.
List<AssignedRecipe> desiredOutputToAssignments(Map<String, int> desiredByRecipe) {
  return assignedRecipesFromDesiredOutput(desiredByRecipe);
}
