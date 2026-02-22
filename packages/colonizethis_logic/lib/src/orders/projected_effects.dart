/// Projected effects after dry-run of orders. For UI feedback.
/// SPEC/program/order-engine.md (Projected Effects).
class ProjectedEffects {
  const ProjectedEffects({
    this.workerCount,
    this.unitLocations,
    this.stockpileDeltas,
    this.treasuryDelta,
  });

  final int? workerCount;
  final Map<String, String>? unitLocations;
  final Map<String, int>? stockpileDeltas;
  final int? treasuryDelta;
}
