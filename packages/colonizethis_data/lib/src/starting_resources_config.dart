/// Starting resources and units per Great Power at game start.
/// TDD 09 (Great Powers), GDD 05 (Units). Scenario overlay may override per TDD 19.
class StartingResourcesConfig {
  const StartingResourcesConfig({
    this.initialPeasants = 4,
    this.initialGrainTurns = 10,
    this.initialTreasury = 5000,
    this.startingCivilianUnits = _defaultStartingCivilianUnits,
  })  : assert(initialPeasants >= 0),
        assert(initialGrainTurns >= 0),
        assert(initialTreasury >= 0);

  /// Number of peasant workers (lowest tier) at game start.
  final int initialPeasants;

  /// Number of turns of grain to stockpile; total grain = initialPeasants * initialGrainTurns
  /// (1 food per worker per turn). Commodity: grain.
  final int initialGrainTurns;

  /// Starting treasury in ducats (game currency).
  final int initialTreasury;

  /// Civilian unit type id -> count at start. GDD 05: 2 Explorers, 2 Builders, 1 Engineer.
  final Map<String, int> startingCivilianUnits;

  static const Map<String, int> _defaultStartingCivilianUnits = {
    'Explorer': 2,
    'Builder': 2,
    'Engineer': 1,
  };

  /// Default config for Phase 2+.
  static const StartingResourcesConfig defaultConfig = StartingResourcesConfig();
}
