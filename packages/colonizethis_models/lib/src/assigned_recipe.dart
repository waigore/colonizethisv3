/// Labour assignment for one production recipe. SPEC/game/production-recipes.md.
class AssignedRecipe {
  const AssignedRecipe({required this.recipeId, required this.assignedLabour})
    : assert(assignedLabour >= 0, 'assignedLabour must be non-negative');

  final String recipeId;
  final int assignedLabour;
}
