/// Projected effects after dry-run of orders. For UI feedback.
/// SPEC/program/order-engine.md (Projected Effects), order-projections.md.
class ProjectedEffects {
  const ProjectedEffects({
    this.workerCount,
    this.unitLocations,
    this.stockpileDeltas,
    this.treasuryDelta,
    this.extractionByCommodity,
    this.productionByRecipe,
  });

  final int? workerCount;
  final Map<String, String>? unitLocations;
  final Map<String, int>? stockpileDeltas;
  final int? treasuryDelta;

  /// Optional; when feasible. See SPEC/program/order-projections.md (Output).
  final Map<String, int>? extractionByCommodity;

  /// Optional; when feasible. See SPEC/program/order-projections.md (Output).
  final Map<String, int>? productionByRecipe;
}
