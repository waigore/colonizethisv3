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
    this.minorNationCount = 6,
    this.tribeCount = 10,
    this.numProvincesOldWorld = 60,
    this.numProvincesNewWorld = 30,
    this.minProvincesPerMinor = 3,
    this.seed = 42,
    this.infiniteMode = false,
    this.terrainVariation = 0.5,
    this.startingResources = const StartingResourcesConfig(),
    this.preferredInitialMapZoomMultiplier,
    Set<int>? humanGreatPowerSlotIndices,
    Set<String>? initTownRoadWiringRegionIds,
  }) : humanGreatPowerSlotIndices =
           humanGreatPowerSlotIndices ?? const {0},
       initTownRoadWiringRegionIds =
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
       assert(seed >= 0),
       assert(terrainVariation >= 0.0 && terrainVariation <= 1.0) {
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

  /// When true, the campaign does not halt at the calendar year-1800 cap.
  /// Chosen at new-game setup only; immutable after game creation.
  final bool infiniteMode;

  /// 0.0–1.0. Controls Pass 6b.5 noise perturbation strength for both
  /// Old World and New World map generation. 0.0 bypasses the pass and
  /// preserves byte-identical legacy output (no RNG advance);
  /// 0.5 (default) yields ~25% expected interior-cell change per blob;
  /// 1.0 yields ~50%. Immutable after game creation.
  /// SPEC/program/tile-map-gen-algorithm.md § Pass 6b.5.
  final double terrainVariation;

  final StartingResourcesConfig startingResources;

  /// Optional explicit fit-relative map zoom multiplier (`m`) for fresh campaign
  /// initialization. When null, setup uses pipeline default behavior.
  final double? preferredInitialMapZoomMultiplier;

  /// Region ids (`oldWorld`, `newWorld`, …) where init runs **town → capital**
  /// road wiring on **owned tiles only** after §7d town assignment.
  /// Empty set disables. Default `{oldWorld}` — New World tribes are skipped unless
  /// wired explicitly. SPEC/game/capital-and-connectivity.md § Init town roads.
  final Set<String> initTownRoadWiringRegionIds;

  /// Great Power **slot** indices (0-based, into [selectedGreatPowerIds] /
  /// runtime `gp{i+1}`) that are **human-controlled** at creation. Default
  /// `{0}` — slot 0 (`gp1`) is human and the rest are AI, reproducing the
  /// prior hardcoded behavior byte-for-byte. An empty set creates a fully-AI
  /// game (used by the Full-AI observer). Indices are validated against
  /// `[0, greatPowerCount)` at init; out-of-range fails with
  /// `human_slot_index_out_of_range`. SPEC/program/game-setup-pipeline.md
  /// § Human/AI slot assignment.
  final Set<int> humanGreatPowerSlotIndices;

  /// Default config for Phase 2.
  static final GameSetupConfig defaultConfig = GameSetupConfig();

  /// True for the locked full-init delivery profile (GitHub #1822 / #1830).
  bool get isLockedFullInitProfile =>
      greatPowerCount == 6 &&
      minorNationCount == 6 &&
      continentCount == 4 &&
      tribeCount == 10 &&
      numProvincesOldWorld == 60 &&
      numProvincesNewWorld == 30 &&
      minProvincesPerMinor == 3;
}
