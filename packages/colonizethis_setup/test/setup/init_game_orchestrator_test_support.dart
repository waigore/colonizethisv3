import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
// Reuse the production province–province adjacency + connected-components
// helpers instead of byte-identical test reimplementations (Refs #3740):
// `provinceNeighboursFromTopology` and `connectedComponentsInSubset` both
// arrive through the colonizethis_logic barrel (the latter published from the
// colonizethis_world barrel, Refs #4054), so no world src/ deep import.

import 'init_game_orchestrator_locked_ac_expectations.dart';
export 'init_game_orchestrator_locked_ac_expectations.dart';

/// AC-11 regression seeds for locked full-init profile (#1830 / #1861).
const lockedFullInitAc11Seeds = <int>[
  101,
  257,
  509,
  1009,
  2003,
  3001,
  4001,
  5003,
  6007,
  7001,
  8011,
  9001,
  10007,
  11003,
  12007,
  13001,
  14009,
  15013,
  16001,
  17011,
];

/// Runs [runInitGame] for each AC-11 seed and asserts locked full-init
/// postconditions when procedural partitions match the locked profile.
void runLockedFullInitAc11SeedBatch({
  required void Function(InitGameResult result, int seed) assertResult,
}) {
  for (final seed in lockedFullInitAc11Seeds) {
    final config = lockedFullInitConfig(seed: seed);
    final result = runInitGame(config: config, options: defaultInitOptions);
    assertResult(result, seed);
    expectLockedFullInitAcWhenPartitionsMatch(result, seed: seed);
  }
}

/// Shared init options for orchestrator tests (no PNG render, 8px cells).
/// Replaces the `const InitGameOptions(cellSize: 8, renderPng: false)` literal
/// repeated across nearly every orchestrator test (Refs #3712).
const defaultInitOptions = InitGameOptions(cellSize: 8, renderPng: false);

final Map<String, InitGameResult> _sharedInitGameResultBySignature = {};

/// Memoized full [runInitGame] pipeline run for [config] with
/// [defaultInitOptions] (Refs #4054). Assert-only tests that share an
/// identical config reuse one map-generation + setup run per distinct
/// [initGameConfigSignature] instead of regenerating everything.
///
/// Contract:
/// - The cached [InitGameResult] is shared: treat it (and its [Game]) as
///   **read-only**; never mutate it from a test.
/// - Determinism-comparison tests must keep explicit repeated [runInitGame]
///   calls; do not route them through this harness.
/// - Only [defaultInitOptions] runs are memoized; tests needing custom
///   [InitGameOptions] call [runInitGame] directly.
/// - `seed: 0` selects a time-based effective seed, so such configs are not
///   cacheable (asserted below).
InitGameResult sharedInitGameResult(GameSetupConfig config) {
  assert(
    config.seed != 0,
    'seed 0 is time-based (non-deterministic); call runInitGame directly',
  );
  return _sharedInitGameResultBySignature.putIfAbsent(
    initGameConfigSignature(config),
    () => runInitGame(config: config, options: defaultInitOptions),
  );
}

/// Canonical signature covering every [GameSetupConfig] field (including the
/// nested [StartingResourcesConfig]) so distinct configs never collide in
/// [sharedInitGameResult].
String initGameConfigSignature(GameSetupConfig c) {
  final r = c.startingResources;
  final sortedRoadRegions = c.initTownRoadWiringRegionIds.toList()..sort();
  final sortedHumanSlots = c.humanGreatPowerSlotIndices.toList()..sort();
  final sortedLeaderVariants =
      c.leaderVariantByGpId.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
  final sortedAiProfiles =
      c.aiProfileByGpId.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
  final sortedCivilianUnits =
      r.startingCivilianUnits.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
  return [
    'gps:${c.selectedGreatPowerIds.join(',')}',
    'leaders:${sortedLeaderVariants.join(',')}',
    'continents:${c.continentCount}',
    'minors:${c.minorNationCount}',
    'tribes:${c.tribeCount}',
    'owProvinces:${c.numProvincesOldWorld}',
    'nwProvinces:${c.numProvincesNewWorld}',
    'minPerMinor:${c.minProvincesPerMinor}',
    'seed:${c.seed}',
    'infinite:${c.infiniteMode}',
    'terrainVariation:${c.terrainVariation}',
    'zoom:${c.preferredInitialMapZoomMultiplier}',
    'roadRegions:${sortedRoadRegions.join(',')}',
    'humanSlots:${sortedHumanSlots.join(',')}',
    'aiProfiles:${sortedAiProfiles.join(',')}',
    'advancedStart:${c.advancedStart}',
    'res.peasants:${r.initialPeasants}',
    'res.grainTurns:${r.initialGrainTurns}',
    'res.treasury:${r.initialTreasury}',
    'res.slots:${r.initialImprovementSlots}',
    'res.wool:${r.initialWool}',
    'res.paper:${r.initialPaper}',
    'res.regiments:${r.initialMilitaryRegiments}',
    'res.ships:${r.initialNavalShips}',
    'res.capitalGrain:${r.capitalTileGrainBonusPerTurn}',
    'res.civilianUnits:${sortedCivilianUnits.join(',')}',
  ].join('|');
}

/// Builds a [GameSetupConfig] from [GameSetupConfig.defaultConfig], overriding
/// only the provided fields. Removes the verbose full-config rebuild blocks
/// tests used to vary a single field — the config has no `copyWith` (#3712 /
/// #4029).
///
/// Nullable [Set]/[Map] params: pass `null` to keep the default-config value;
/// pass an empty collection to override with empty.
GameSetupConfig configWithOverrides({
  List<String>? selectedGreatPowerIds,
  Map<String, String>? leaderVariantByGpId,
  int? seed,
  int? continentCount,
  int? minorNationCount,
  int? tribeCount,
  int? numProvincesOldWorld,
  int? numProvincesNewWorld,
  int? minProvincesPerMinor,
  bool? infiniteMode,
  double? terrainVariation,
  StartingResourcesConfig? startingResources,
  double? preferredInitialMapZoomMultiplier,
  Set<String>? initTownRoadWiringRegionIds,
  Set<int>? humanGreatPowerSlotIndices,
  Map<String, String?>? aiProfileByGpId,
  AdvancedStartType? advancedStart,
}) {
  final base = GameSetupConfig.defaultConfig;
  return GameSetupConfig(
    selectedGreatPowerIds: selectedGreatPowerIds ?? base.selectedGreatPowerIds,
    leaderVariantByGpId: leaderVariantByGpId ?? base.leaderVariantByGpId,
    continentCount: continentCount ?? base.continentCount,
    minorNationCount: minorNationCount ?? base.minorNationCount,
    tribeCount: tribeCount ?? base.tribeCount,
    numProvincesOldWorld: numProvincesOldWorld ?? base.numProvincesOldWorld,
    numProvincesNewWorld: numProvincesNewWorld ?? base.numProvincesNewWorld,
    minProvincesPerMinor: minProvincesPerMinor ?? base.minProvincesPerMinor,
    seed: seed ?? base.seed,
    infiniteMode: infiniteMode ?? base.infiniteMode,
    terrainVariation: terrainVariation ?? base.terrainVariation,
    startingResources: startingResources ?? base.startingResources,
    preferredInitialMapZoomMultiplier:
        preferredInitialMapZoomMultiplier ??
        base.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds:
        initTownRoadWiringRegionIds ?? base.initTownRoadWiringRegionIds,
    humanGreatPowerSlotIndices:
        humanGreatPowerSlotIndices ?? base.humanGreatPowerSlotIndices,
    aiProfileByGpId: aiProfileByGpId ?? base.aiProfileByGpId,
    advancedStart: advancedStart ?? base.advancedStart,
  );
}

/// The locked full-init profile config (#1830 AC-10..AC-12): default GP ids and
/// starting resources with the locked partition counts and the given [seed].
GameSetupConfig lockedFullInitConfig({
  required int seed,
  Set<int>? humanGreatPowerSlotIndices,
  AdvancedStartType? advancedStart,
  bool? infiniteMode,
}) => configWithOverrides(
  seed: seed,
  continentCount: 4,
  minorNationCount: 6,
  tribeCount: 10,
  numProvincesOldWorld: 60,
  numProvincesNewWorld: 30,
  minProvincesPerMinor: 3,
  humanGreatPowerSlotIndices: humanGreatPowerSlotIndices,
  advancedStart: advancedStart,
  infiniteMode: infiniteMode,
);

/// Wraps [defaultTileMapRegionGenerator] for tests, exposing the per-region
/// [TileMapParams] via [onParams] and allowing a [continentProvinceSizes]
/// override via [resolveContinentProvinceSizes]. Removes the copy-pasted full
/// generator signature from orchestrator tests (Refs #3712).
TileMapRegionGenerator wrapRegionGenerator({
  void Function(String regionId, TileMapParams params)? onParams,
  List<int>? Function({
    required String regionId,
    required int numProvinces,
    required int numContinents,
    required List<int>? continentProvinceSizes,
  })?
  resolveContinentProvinceSizes,
}) {
  return ({
    required TileMapParams params,
    required int numProvinces,
    required int numContinents,
    required String regionId,
    String seaZoneId = 's1',
    ResourceRules? resourceRules,
    void Function(String)? onLog,
    void Function(List<(int x, int y)> landSeeds, List<int> continentIndices)?
    onLandSeedsPlaced,
    void Function(List<(int x, int y)> continentSeeds)? onContinentSeedsPlaced,
    List<int>? continentProvinceSizes,
  }) {
    onParams?.call(regionId, params);
    final sizes =
        resolveContinentProvinceSizes?.call(
          regionId: regionId,
          numProvinces: numProvinces,
          numContinents: numContinents,
          continentProvinceSizes: continentProvinceSizes,
        ) ??
        continentProvinceSizes;
    return defaultTileMapRegionGenerator(
      params: params,
      numProvinces: numProvinces,
      numContinents: numContinents,
      regionId: regionId,
      seaZoneId: seaZoneId,
      resourceRules: resourceRules,
      onLog: onLog,
      onLandSeedsPlaced: onLandSeedsPlaced,
      onContinentSeedsPlaced: onContinentSeedsPlaced,
      continentProvinceSizes: sizes,
    );
  };
}

