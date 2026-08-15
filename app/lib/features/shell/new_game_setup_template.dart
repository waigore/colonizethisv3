import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Shared DLG10001 / Quick Start template (Refs #4416).
///
/// `CT_E2E_LOCKED_FULL_INIT` → [GameSetupConfig.defaultConfig];
/// else `CT_E2E` → reduced map sizes for CI wall clocks;
/// else [GameSetupConfig.defaultConfig].
GameSetupConfig newGameSetupTemplateConfig({
  bool? e2eEnabled,
  bool? lockedFullInit,
}) {
  final locked = lockedFullInit ?? kCtE2ELockedFullInitEnabled;
  final e2e = e2eEnabled ?? kCtE2EEnabled;
  if (locked) {
    return GameSetupConfig.defaultConfig;
  }
  if (e2e) {
    return ctE2eReducedNewGameSetupTemplate();
  }
  return GameSetupConfig.defaultConfig;
}

/// Smaller than [GameSetupConfig.defaultConfig]: integration tests compile with
/// `CT_E2E=true` and must stay inside CI wall clocks (not the locked full-init
/// 60/30 profile). Production `main` / widget tests use [GameSetupConfig.defaultConfig].
GameSetupConfig ctE2eReducedNewGameSetupTemplate() {
  final d = GameSetupConfig.defaultConfig;
  return GameSetupConfig(
    selectedGreatPowerIds: d.selectedGreatPowerIds,
    leaderVariantByGpId: d.leaderVariantByGpId,
    continentCount: 2,
    minorNationCount: 2,
    tribeCount: 4,
    numProvincesOldWorld: 24,
    numProvincesNewWorld: 12,
    minProvincesPerMinor: 2,
    seed: d.seed,
    infiniteMode: d.infiniteMode,
    startingResources: d.startingResources,
    preferredInitialMapZoomMultiplier: d.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: d.initTownRoadWiringRegionIds,
    humanGreatPowerSlotIndices: d.humanGreatPowerSlotIndices,
    aiProfileByGpId: d.aiProfileByGpId,
    advancedStart: d.advancedStart,
    terrainVariation: d.terrainVariation,
  );
}

/// Quick Start payload: shared template with `seed == 0` (time-derived world).
GameSetupConfig quickStartSetupConfig({
  bool? e2eEnabled,
  bool? lockedFullInit,
}) {
  return gameSetupConfigWithSeed(
    newGameSetupTemplateConfig(
      e2eEnabled: e2eEnabled,
      lockedFullInit: lockedFullInit,
    ),
    0,
  );
}

GameSetupConfig gameSetupConfigWithSeed(GameSetupConfig source, int seed) {
  return GameSetupConfig(
    selectedGreatPowerIds: source.selectedGreatPowerIds,
    leaderVariantByGpId: source.leaderVariantByGpId,
    continentCount: source.continentCount,
    minorNationCount: source.minorNationCount,
    tribeCount: source.tribeCount,
    numProvincesOldWorld: source.numProvincesOldWorld,
    numProvincesNewWorld: source.numProvincesNewWorld,
    minProvincesPerMinor: source.minProvincesPerMinor,
    seed: seed,
    infiniteMode: source.infiniteMode,
    terrainVariation: source.terrainVariation,
    startingResources: source.startingResources,
    preferredInitialMapZoomMultiplier: source.preferredInitialMapZoomMultiplier,
    humanGreatPowerSlotIndices: source.humanGreatPowerSlotIndices,
    initTownRoadWiringRegionIds: source.initTownRoadWiringRegionIds,
    aiProfileByGpId: source.aiProfileByGpId,
    advancedStart: source.advancedStart,
  );
}
