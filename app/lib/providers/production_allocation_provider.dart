import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
  final list = <AssignedRecipe>[];
  for (final entry in desiredByRecipe.entries) {
    if (entry.value <= 0) continue;
    final recipe = ProductionRecipesCatalog.byId[entry.key];
    if (recipe == null) continue;
    final labour = entry.value * recipe.labourPerOutput;
    if (labour <= 0) continue;
    list.add(AssignedRecipe(recipeId: entry.key, assignedLabour: labour));
  }
  return list;
}
