import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_setup_create_capitals.dart';
import 'game_setup_helpers.dart';
import 'gp_old_world_resource_redistribution.dart';
import 'gp_old_world_terrain_redistribution.dart';
import 'gp_ow_terrain_count_restore.dart';
import 'gp_starting_grain.dart';
import 'init_town_roads.dart';
import 'initial_visibility.dart';
import 'minor_tribe_starting_development.dart';

/// Post-ownership pipeline phases for [createGameFromGeneratedMaps]
/// (terrain, capitals, visibility, towns, redistribution, bootstrap, units).
/// Refs #4349 Slice B.
({
  Game game,
  Map<String, TileMapResult> tileMapByRegion,
  MapTopology combinedTopology,
})
applyPostOwnershipSetupPhases({
  required Game game,
  required GameSetupConfig config,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
  required int perturbBase,
  required int namingSeed,
  required List<WarpLink> links,
}) {
  var next = game;

  // §7d.terrain GP Old World terrain redistribution — after ownership, before capitals/towns.
  // SPEC/program/game-setup-pipeline.md; SPEC/game/tile-map-and-generation.md.
  final gpTerrainRedist = applyGreatPowerOldWorldTerrainRedistribution(
    game: next,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    setupSeedBase: perturbBase,
  );
  next = gpTerrainRedist.game;
  tileMapByRegion[kRegionOldWorld] = gpTerrainRedist.tileMap;
  // Snapshot N_T after §7d.terrain so §7d.terrain-restore can relocate labels
  // destroyed by settlement plains conversion (keeps §7d.redist capacity feasible).
  final gpOwTerrainTargets = countGpOwTerrainByType(
    game: next,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
  );

  next = assignAllCapitals(
    game: next,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    tileMapNewWorld: tileMapByRegion[kRegionNewWorld]!,
    tileMapByRegion: tileMapByRegion,
  );

  // Apply initial per-player visibility/prospection (knowledge state) after
  // provinces, capitals, and starting units are set.
  next = applyInitialVisibility(
    game: next,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
  );

  // 7d. Province town assignment. SPEC/program/game-setup-pipeline.md, capital-and-connectivity.md.
  next = assignProvinceTowns(
    game: next,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );

  // Strip RNG/resources and extraction improvements from town and capital tiles only.
  // SPEC/game/tile-map-and-generation.md § Town/capital occupancy.
  final strip = stripResourcesAndExtractionImprovementsOnTileKeys(
    next,
    tileMapByRegion,
    collectTownAndCapitalTileKeys(next),
  );
  next = strip.$1;
  final strippedMaps = strip.$2;
  if (strippedMaps != null) {
    for (final e in strippedMaps.entries) {
      tileMapByRegion[e.key] = e.value;
    }
  }

  // §7d.terrain-restore — relocate non-plains labels lost to settlement plains
  // conversion onto non-settlement plains so §7d.redist capacity stays feasible.
  tileMapByRegion[kRegionOldWorld] =
      restoreGpOwTerrainCountsAfterSettlementPlains(
        game: next,
        tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
        targetCounts: gpOwTerrainTargets,
      );

  // §7d.redist GP Old World terrain resource redistribution (always-on when OW grids exist).
  // SPEC/program/game-setup-pipeline.md; SPEC/game/tile-map-and-generation.md.
  final gpRedist = applyGreatPowerOldWorldResourceRedistribution(
    game: next,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
    setupSeedBase: perturbBase,
  );
  next = gpRedist.game;
  tileMapByRegion[kRegionOldWorld] = gpRedist.tileMap;

  // Great Power starting grain (bootstrap). SPEC/game/tile-map-and-generation.md.
  final gpGrain = applyGreatPowerStartingGrainBootstrap(
    game: next,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
  );
  next = gpGrain.game;
  tileMapByRegion[kRegionOldWorld] = gpGrain.tileMap;

  // 7d.dev Minor Nation and Tribe starting developed resources.
  // SPEC/game/factions.md § Starting developed resources; SPEC/program/game-setup-pipeline.md § 7d.dev.
  final minorTribeDev = applyMinorTribeStartingDevelopment(
    game: next,
    tileMapByRegion: tileMapByRegion,
  );
  next = minorTribeDev.game;

  // 7d.bis Init town → capital roads (per-region via config). SPEC/game/capital-and-connectivity.md.
  next = applyInitTownRoadsToCapitals(
    game: next,
    config: config,
    tileMapByRegion: tileMapByRegion,
    bootstrapGrainTileKeysByPlayerId: gpGrain.grainKeysByPlayerId,
  );

  // Apply historically inspired naming from default ruleset (after capitals are set).
  next = applyNaming(
    game: next,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    namingSeed: namingSeed,
    topologyByRegion: topologyByRegion,
  );

  // Compute 1-character political glyphs per faction for political map layer.
  final politicalGlyphByPlayerId = buildPoliticalGlyphByPlayerId(
    game: next,
    greatPowerIds: gpIds,
    minorNationIds: minorIds,
    tribeIds: tribeIds,
  );
  next = next.copyWith(politicalGlyphByPlayerId: politicalGlyphByPlayerId);

  // Spawn starting units for each Great Power in their capital provinces.
  next = addStartingUnits(game: next, config: config);

  // Spawn starting land regiments and home fleets for each Great Power.
  next = addStartingMilitaryAndNaval(
    game: next,
    config: config,
    topologyOldWorld: topologyOldWorld,
  );
  next = ensureMilitaryArmiesForGame(next);

  // Initialize each Great Power's general cap (1 at start) and spawn one
  // general per GP. SPEC/game/military-generals.md § Count and tech-gated cap.
  next = syncGeneralCapsFromTech(next);

  // Map tint / UI swatches: runtime player ids (gp1..gpN) → GDD default RGB for
  // the semantic Great Power in each setup slot (see greatPowerDefaultColorRgb).
  // Province.ownerId uses gpN; without this, factionOwnershipColorMap misses
  // greatPowerDefaultColorRgb[gpN] and falls back to regionPalette (wrong hues).
  final defaultGpColorsByPlayerId = <String, List<int>>{};
  for (var i = 0; i < gpIds.length; i++) {
    if (i >= config.selectedGreatPowerIds.length) {
      break;
    }
    final semanticId = config.selectedGreatPowerIds[i];
    final rgb = greatPowerDefaultColorRgb[semanticId];
    if (rgb != null) {
      defaultGpColorsByPlayerId[gpIds[i]] = [rgb.$1, rgb.$2, rgb.$3];
    }
  }
  if (defaultGpColorsByPlayerId.isNotEmpty) {
    next = next.copyWith(greatPowerColorOverride: defaultGpColorsByPlayerId);
  }

  final combinedTopology = buildCombinedTopology(
    topologyByRegion: topologyByRegion,
    warpLinks: links,
  );

  return (
    game: next,
    tileMapByRegion: tileMapByRegion,
    combinedTopology: combinedTopology,
  );
}
