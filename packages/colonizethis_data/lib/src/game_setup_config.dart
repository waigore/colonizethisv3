import 'starting_resources_config.dart';

/// Game setup parameters. SPEC/game/game-setup.md, SPEC/game/ruleset-config.md.
/// Program-level config only (no JSON in MVP).
class GameSetupConfig {
  GameSetupConfig({
    this.selectedGreatPowerIds = _defaultSelectedGreatPowerIds,
    this.leaderVariantByGpId = const {},
    this.continentCount = 4,
    this.minorNationCount = 6,
    this.tribeCount = 10,
    this.numProvincesOldWorld = 60,
    this.numProvincesNewWorld = 80,
    this.minProvincesPerMinor = 3,
    this.seed = 42,
    this.startingResources = const StartingResourcesConfig(),
  })  : assert(selectedGreatPowerIds.isNotEmpty, 'At least one Great Power required'),
        assert(continentCount >= 1),
        assert(minorNationCount >= 0),
        assert(tribeCount >= 0),
        assert(minProvincesPerMinor >= 0),
        assert(numProvincesNewWorld >= 1);

  static const List<String> _defaultSelectedGreatPowerIds = [
    'england',
    'france',
    'spain',
    'portugal',
    'netherlands',
    'prussia',
  ];

  final List<String> selectedGreatPowerIds;

  /// For GPs with multiple leader variants (e.g. Prussia), maps gpId -> chosen variantId.
  /// When absent for a GP, use default (first variant).
  final Map<String, String> leaderVariantByGpId;

  /// Number of Great Powers in the game (derived from selection).
  int get greatPowerCount => selectedGreatPowerIds.length;

  final int continentCount;
  final int minorNationCount;
  final int tribeCount;
  final int numProvincesOldWorld;
  final int numProvincesNewWorld;
  /// Minimum provinces the ruleset attempts to reserve per Minor Nation on the Old World map.
  final int minProvincesPerMinor;
  final int seed;
  final StartingResourcesConfig startingResources;

  /// Default config for Phase 2.
  static final GameSetupConfig defaultConfig = GameSetupConfig();
}
