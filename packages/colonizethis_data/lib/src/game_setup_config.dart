/// Game setup parameters. SPEC/game/game-setup.md, SPEC/game/ruleset-config.md.
/// Program-level config only (no JSON in MVP).
class GameSetupConfig {
  const GameSetupConfig({
    this.greatPowerCount = 7,
    this.continentCount = 4,
    this.minorNationCount = 6,
    this.tribeCount = 10,
    this.numProvincesOldWorld = 40,
    this.numProvincesNewWorld = 30,
    this.seed = 42,
  })  : assert(greatPowerCount >= 1),
        assert(continentCount >= 1),
        assert(minorNationCount >= 0),
        assert(tribeCount >= 0),
        assert(numProvincesOldWorld >= greatPowerCount),
        assert(numProvincesNewWorld >= 1);

  final int greatPowerCount;
  final int continentCount;
  final int minorNationCount;
  final int tribeCount;
  final int numProvincesOldWorld;
  final int numProvincesNewWorld;
  final int seed;

  /// Default config for Phase 2.
  static const GameSetupConfig defaultConfig = GameSetupConfig();
}
