/// Projected effects after dry-run of orders. For UI feedback.
/// SPEC/program/order-engine.md (Projected Effects), order-projections.md.
///
/// Owned by the `orders` domain (Refs #3290 C2): relocated from the neutral
/// `lib/src/projections/` core module so the orders source tree (the future
/// `colonizethis_orders` package) does not depend on the thin logic core for
/// its own projection output type.
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
