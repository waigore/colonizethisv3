/// Starting resources and units per Great Power at game start.
/// TDD 09 (Great Powers), GDD 05 (Units). Scenario overlay may override per TDD 19.
class StartingResourcesConfig {
  const StartingResourcesConfig({
    this.initialPeasants = 4,
    this.initialGrainTurns = 10,
    this.initialTreasury = 5000,
    this.initialImprovementSlots = 4,
    this.initialMilitaryRegiments = 5,
    this.initialNavalShips = 3,
    this.startingCivilianUnits = _defaultStartingCivilianUnits,
  })  : assert(initialPeasants >= 0),
        assert(initialGrainTurns >= 0),
        assert(initialTreasury >= 0),
        assert(initialImprovementSlots >= 0),
        assert(initialMilitaryRegiments >= 0),
        assert(initialNavalShips >= 0);

  /// Number of peasant workers (lowest tier) at game start.
  final int initialPeasants;

  /// Number of turns of grain to stockpile; total grain = initialPeasants * initialGrainTurns
  /// (1 food per worker per turn). Commodity: grain.
  final int initialGrainTurns;

  /// Starting treasury in ducats (game currency).
  final int initialTreasury;

  /// Number of level-1 extraction improvements the starting stockpile can support.
  /// Each slot represents 1 lumber + 1 castIron available for a Builder to spend
  /// on a level-1 improvement per SPEC/game/extraction-and-improvements.md.
  final int initialImprovementSlots;

  /// Number of starting land regiments to spawn in each Great Power's capital.
  /// Concrete regiment type is chosen from the regiment catalog based on ruleset/tech.
  final int initialMilitaryRegiments;

  /// Number of starting merchant ships to place in each Great Power's home fleet.
  /// Concrete ship type is chosen from the ship economy/naval stats catalogs.
  final int initialNavalShips;

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
