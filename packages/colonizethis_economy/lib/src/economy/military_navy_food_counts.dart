/// Military and navy food-demand counts for consumption and labour preview
/// (Refs #3979). Threads the same inputs through [previewWorkerIdleLabour],
/// [resolveConsumption], and [effectiveLabourForWorkers] without changing
/// consumption rules.
final class MilitaryNavyFoodCounts {
  const MilitaryNavyFoodCounts({
    this.militaryUnits = 0,
    this.regimentCountsById = const {},
    this.shipCountsById = const {},
  });

  /// Fallback land-military headcount when [regimentCountsById] is empty
  /// (2 food per unit).
  final int militaryUnits;

  /// Per-regiment-type counts; when non-empty, overrides [militaryUnits].
  final Map<String, int> regimentCountsById;

  /// Per-ship-type counts for navy food upkeep.
  final Map<String, int> shipCountsById;
}
