/// Combat morale tier from land or naval feeding coverage.
///
/// Breakpoints match [moraleMultiplierForFeedingCoverage] in colonizethis_combat
/// (SPEC/program/turn-resolution-phase-details.md § Consumption).
enum ForceFeedingCombatTier {
  /// Coverage ≥ 1.0 — full combat strength.
  full,

  /// Coverage in [0.5, 1.0) — 0.75 morale multiplier.
  moderate,

  /// Coverage < 0.5 — 0.5 morale multiplier.
  severe,
}

/// Snapshot for Production forces-food strip and decision-point soft warnings.
class ForceFeedingSnapshot {
  const ForceFeedingSnapshot({
    required this.totalRegiments,
    required this.fullyFedRegiments,
    required this.totalShips,
    required this.fullyFedShips,
    required this.landCombatTier,
    required this.navalCombatTier,
    required this.forcesFoodDemand,
  });

  final int totalRegiments;
  final int fullyFedRegiments;
  final int totalShips;
  final int fullyFedShips;
  final ForceFeedingCombatTier landCombatTier;
  final ForceFeedingCombatTier navalCombatTier;

  /// Combined grain+meat demand for land military and navy this turn.
  final int forcesFoodDemand;

  bool get hasLandForces => totalRegiments > 0;

  bool get hasNavalForces => totalShips > 0;

  bool get hasAnyForces => hasLandForces || hasNavalForces;

  bool get isLandFullyFed => !hasLandForces || landCombatTier == ForceFeedingCombatTier.full;

  bool get isNavalFullyFed => !hasNavalForces || navalCombatTier == ForceFeedingCombatTier.full;

  bool get isFullyFed => isLandFullyFed && isNavalFullyFed;
}
