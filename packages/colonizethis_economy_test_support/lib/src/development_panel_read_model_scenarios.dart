// dart format off
// Table-driven Development panel read-model scenarios (Refs #4175, #4014, #4410).

enum DevelopmentPanelReadModelTarget {
  ownedProvinceListsImprovableGrain,
  modelBuildsWithPendingWorkOrders,
  playerViewFiltersUnrevealedImprovableTiles,
  assignedCiviliansIncludePendingBuilder,
}

typedef DevelopmentPanelReadModelScenario = ({
  String label,
  DevelopmentPanelReadModelTarget target,
  String? refs,
});

List<DevelopmentPanelReadModelScenario> developmentPanelReadModelScenarios() =>
    [
      (
        label: 'owned province lists improvable grain from Available parity',
        target: DevelopmentPanelReadModelTarget.ownedProvinceListsImprovableGrain,
        refs: '#4175',
      ),
      (
        label: 'model builds with pending work orders without throwing',
        target: DevelopmentPanelReadModelTarget.modelBuildsWithPendingWorkOrders,
        refs: '#4175',
      ),
      (
        label: 'playerView filters unrevealed improvable tiles from counts',
        target:
            DevelopmentPanelReadModelTarget.playerViewFiltersUnrevealedImprovableTiles,
        refs: '#4175',
      ),
      (
        label: 'assigned civilians include pending builder in region',
        target: DevelopmentPanelReadModelTarget.assignedCiviliansIncludePendingBuilder,
        refs: '#4175',
      ),
    ];
// dart format on
