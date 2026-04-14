import 'package:colonizethis_data/package_logger.dart';

import 'starting_resources_config.dart';

final _log = packageLogger();

/// Game setup parameters. SPEC/game/game-setup.md, SPEC/game/ruleset-config.md,
/// SPEC/program/game-setup-pipeline.md.
///
/// **Current product:** Program-level defaults and constructor/CLI fields only; no Base →
/// Difficulty → Scenario JSON merge (see ruleset-config.md, GitHub #57 / #58).
class GameSetupConfig {
  GameSetupConfig({
    this.selectedGreatPowerIds = _defaultSelectedGreatPowerIds,
    this.leaderVariantByGpId = const {},
    this.continentCount = 4,
    this.minorNationCount = 3,
    this.tribeCount = 10,
    this.numProvincesOldWorld = 60,
    this.numProvincesNewWorld = 80,
    this.minProvincesPerMinor = 3,
    this.seed = 42,
    this.startingResources = const StartingResourcesConfig(),
    this.enforceFairGpOldWorldAssignment = false,
    this.preferredInitialMapZoomMultiplier,
    Set<String>? initTownRoadWiringRegionIds,
  }) : initTownRoadWiringRegionIds =
           initTownRoadWiringRegionIds ?? const {'oldWorld'},
       assert(
         selectedGreatPowerIds.isNotEmpty,
         'At least one Great Power required',
       ),
       assert(continentCount >= 1),
       assert(minorNationCount >= 0),
       assert(tribeCount >= 0),
       assert(minProvincesPerMinor >= 0),
       assert(numProvincesNewWorld >= 1),
       assert(seed >= 0) {
    _log.d(
      'GameSetupConfig created OW=$numProvincesOldWorld NW=$numProvincesNewWorld',
    );
  }

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

  /// When true, run GP Old World land connectivity repair and assignment retries
  /// per SPEC/game/game-setup.md. When false, use a single assignment pass with no
  /// repair (faster; a GP may own disconnected P–P components).
  final bool enforceFairGpOldWorldAssignment;

  /// Optional explicit fit-relative map zoom multiplier (`m`) for fresh campaign
  /// initialization. When null, setup uses pipeline default behavior.
  final double? preferredInitialMapZoomMultiplier;

  /// Region ids (`oldWorld`, `newWorld`, …) where init runs **town → capital**
  /// road wiring on **owned tiles only** after §7d town assignment.
  /// Empty set disables. Default `{oldWorld}` — New World tribes are skipped unless
  /// wired explicitly. SPEC/game/capital-and-connectivity.md § Init town roads.
  final Set<String> initTownRoadWiringRegionIds;

  /// Default config for Phase 2.
  static final GameSetupConfig defaultConfig = GameSetupConfig();
}
