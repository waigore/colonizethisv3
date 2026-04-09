/// Starting resources and units per Great Power at game start.
/// TDD 09 (Great Powers), GDD 05 (Units). Scenario overlay may override per TDD 19.
class StartingResourcesConfig {
  const StartingResourcesConfig({
    this.initialPeasants = 4,
    this.initialGrainTurns = 10,
    this.initialTreasury = 5000,
    this.initialImprovementSlots = 5,
    this.initialWool = 4,
    this.initialPaper = 2,
    this.initialMilitaryRegiments = 3,
    this.initialNavalShips = 1,
    this.capitalTileGrainBonusPerTurn = 5,
    this.startingCivilianUnits = _defaultStartingCivilianUnits,
  }) : assert(initialPeasants >= 0),
       assert(initialGrainTurns >= 0),
       assert(initialTreasury >= 0),
       assert(initialImprovementSlots >= 0),
       assert(initialWool >= 0),
       assert(initialPaper >= 0),
       assert(initialMilitaryRegiments >= 0),
       assert(initialNavalShips >= 0),
       assert(capitalTileGrainBonusPerTurn >= 0);

  /// Number of peasant workers (lowest tier) at game start.
  final int initialPeasants;

  /// Number of turns of grain to stockpile; total grain = initialPeasants * initialGrainTurns
  /// (1 food per worker per turn). Commodity: grain.
  final int initialGrainTurns;

  /// Starting treasury in ducats (game currency).
  final int initialTreasury;

  /// Number of level-1 extraction improvements the starting stockpile can support (bootstrap).
  /// Default 5: each player has enough to build 5 level-1 improvements at game start.
  /// Each slot = 1 lumber + 1 castIron per SPEC/game/extraction-and-improvements.md.
  final int initialImprovementSlots;

  /// Starting quantity of wool in each Great Power's central stockpile.
  /// Default 4: every Great Power begins the game with 4 wool (ruleset-config § Starting stockpiles).
  final int initialWool;

  /// Starting quantity of paper (commodity id `paper`) in each Great Power's central stockpile.
  /// Default 2: supports early civilian training per SPEC/game/civilian-units.md.
  final int initialPaper;

  /// Number of starting land regiments to spawn in each Great Power's capital.
  /// Default type is `peasant_levies` (bootstrap per SPEC/program/game-setup-pipeline.md §7f).
  final int initialMilitaryRegiments;

  /// Number of starting merchant ships to place in each Great Power's home fleet.
  /// Concrete ship type is chosen from the ship economy/naval stats catalogs.
  final int initialNavalShips;

  /// Grain added to land extraction each turn per Great Power that has a capital
  /// tile. Unconditional on connectivity. SPEC/game/extraction-and-improvements.md.
  final int capitalTileGrainBonusPerTurn;

  /// Civilian unit type id -> count at start. GDD 05: 2 Explorers, 2 Builders, 1 Engineer.
  final Map<String, int> startingCivilianUnits;

  static const Map<String, int> _defaultStartingCivilianUnits = {
    'Explorer': 2,
    'Builder': 2,
    'Engineer': 1,
  };

  /// Default config for Phase 2+.
  static const StartingResourcesConfig defaultConfig =
      StartingResourcesConfig();
}
