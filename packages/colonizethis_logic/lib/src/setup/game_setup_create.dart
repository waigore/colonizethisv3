import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import '../world/army_migration.dart';
import 'capital_choice.dart';
import 'game_setup_context.dart';
import 'game_setup_helpers.dart';
import 'game_setup_ownership.dart';
import 'game_setup_topology.dart';
import 'gp_old_world_resource_redistribution.dart';
import 'gp_old_world_terrain_redistribution.dart';
import 'gp_starting_grain.dart';
import 'minor_tribe_starting_development.dart';
import 'init_town_roads.dart';
import 'initial_visibility.dart';
import 'setup_exceptions.dart';
import 'town_capital_occupancy.dart';

part 'game_setup_create_ownership.dart';
part 'game_setup_create_initial_game.dart';
part 'game_setup_create_capitals.dart';

/// Result of game setup: the Game and the map data needed for turn resolution.
class GameSetupResult {
  const GameSetupResult({
    required this.game,
    required this.tileMapByRegion,
    required this.topologyByRegion,
    required this.combinedTopology,
    this.warpLinks = const [],
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;

  /// Single topology with prefixed node ids and warp edges for resolveTurnForGame (movement, extraction). SPEC/game/map-topology.md.
  final MapTopology combinedTopology;

  /// Warp zone links between regions (OW↔NW). Empty if none generated.
  final List<WarpLink> warpLinks;
}

const double _kNewCampaignDefaultMapZoomMultiplier = 4.0;
const double _kMapZoomMultiplierMin = 0.5;
const double _kMapZoomMultiplierMax = 8.0;

/// Builds a new Game from pre-generated Old World and New World maps and config.
/// Caller is responsible for generating tileMap and topology per region (e.g. via colonizethis_map).
/// Per SPEC/program/game-setup-pipeline.md: assignment (GPs, minors, tribes), build state, capital auto-choice.
GameSetupResult createGameFromGeneratedMaps({
  required GameSetupConfig config,
  required TileMapResult tileMapOldWorld,
  required MapTopology topologyOldWorld,
  required TileMapResult tileMapNewWorld,
  required MapTopology topologyNewWorld,
  required String gameId,
  int? namingSeed,

  /// Base for salted assignment perturbation on OW reassignment retries.
  /// Defaults to [namingSeed] if set, else [GameSetupConfig.seed].
  int? assignmentPerturbationBase,
  List<WarpLink>? warpLinks,
}) {
  gameSetupLog.i('game setup start gameId=$gameId');
  final tileMapByRegion = <String, TileMapResult>{
    kRegionOldWorld: tileMapOldWorld,
    kRegionNewWorld: tileMapNewWorld,
  };
  final topologyByRegion = <String, MapTopology>{
    kRegionOldWorld: topologyOldWorld,
    kRegionNewWorld: topologyNewWorld,
  };
  final links = warpLinks ?? [];
  final perturbBase = assignmentPerturbationBase ?? namingSeed ?? config.seed;
  final initialMapZoomMultiplier = _resolveInitialMapZoomMultiplier(config);
  final ownership = _assignInitialOwnership(
    config: config,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
  );
  final oldWorldProvinces = ownership.oldWorldProvinces;
  final newWorldProvinces = ownership.newWorldProvinces;
  final gpIds = ownership.gpIds;
  final minorIds = ownership.minorIds;
  final tribeIds = ownership.tribeIds;
  var game = _buildInitialGame(
    config: config,
    gameId: gameId,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    initialMapZoomMultiplier: initialMapZoomMultiplier,
  );

  game = _assignAllCapitals(
    game: game,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
    tileMapOldWorld: tileMapOldWorld,
    tileMapNewWorld: tileMapNewWorld,
    tileMapByRegion: tileMapByRegion,
  );

  // Apply initial per-player visibility/prospection (knowledge state) after
  // provinces, capitals, and starting units are set.
  game = applyInitialVisibility(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
  );

  // 7d. Province town assignment. SPEC/program/game-setup-pipeline.md, capital-and-connectivity.md.
  game = assignProvinceTowns(
    game: game,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );

  // Strip RNG/resources and extraction improvements from town and capital tiles only.
  // SPEC/game/tile-map-and-generation.md § Town/capital occupancy.
  final strip = stripResourcesAndExtractionImprovementsOnTileKeys(
    game,
    tileMapByRegion,
    collectTownAndCapitalTileKeys(game),
  );
  game = strip.$1;
  final strippedMaps = strip.$2;
  if (strippedMaps != null) {
    for (final e in strippedMaps.entries) {
      tileMapByRegion[e.key] = e.value;
    }
  }

  // §7d.terrain GP Old World terrain redistribution (always-on when OW grids exist), then §7d.redist resources.
  // SPEC/program/game-setup-pipeline.md; SPEC/game/tile-map-and-generation.md.
  final gpTerrainRedist = applyGreatPowerOldWorldTerrainRedistribution(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    setupSeedBase: perturbBase,
  );
  game = gpTerrainRedist.game;
  tileMapByRegion[kRegionOldWorld] = gpTerrainRedist.tileMap;

  // §7d.redist GP Old World terrain resource redistribution (always-on when OW grids exist).
  // SPEC/program/game-setup-pipeline.md; SPEC/game/tile-map-and-generation.md.
  final gpRedist = applyGreatPowerOldWorldResourceRedistribution(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
    setupSeedBase: perturbBase,
  );
  game = gpRedist.game;
  tileMapByRegion[kRegionOldWorld] = gpRedist.tileMap;

  // Great Power starting grain (bootstrap). SPEC/game/tile-map-and-generation.md.
  final gpGrain = applyGreatPowerStartingGrainBootstrap(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
  );
  game = gpGrain.game;
  tileMapByRegion[kRegionOldWorld] = gpGrain.tileMap;

  // 7d.dev Minor Nation and Tribe starting developed resources.
  // SPEC/game/factions.md § Starting developed resources; SPEC/program/game-setup-pipeline.md § 7d.dev.
  final minorTribeDev = applyMinorTribeStartingDevelopment(
    game: game,
    tileMapByRegion: tileMapByRegion,
  );
  game = minorTribeDev.game;

  // 7d.bis Init town → capital roads (per-region via config). SPEC/game/capital-and-connectivity.md.
  game = applyInitTownRoadsToCapitals(
    game: game,
    config: config,
    tileMapByRegion: tileMapByRegion,
    bootstrapGrainTileKeysByPlayerId: gpGrain.grainKeysByPlayerId,
  );

  // Apply historically inspired naming from default ruleset (after capitals are set).
  game = applyNaming(
    game: game,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    namingSeed: namingSeed ?? config.seed,
    topologyByRegion: topologyByRegion,
  );

  // Compute 1-character political glyphs per faction for political map layer.
  final politicalGlyphByPlayerId = buildPoliticalGlyphByPlayerId(
    game: game,
    greatPowerIds: gpIds,
    minorNationIds: minorIds,
    tribeIds: tribeIds,
  );
  game = game.copyWith(politicalGlyphByPlayerId: politicalGlyphByPlayerId);

  // Spawn starting units for each Great Power in their capital provinces.
  game = addStartingUnits(game: game, config: config);

  // Spawn starting land regiments and home fleets for each Great Power.
  game = addStartingMilitaryAndNaval(
    game: game,
    config: config,
    topologyOldWorld: topologyOldWorld,
  );
  game = ensureMilitaryArmiesForGame(game);

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
    game = game.copyWith(greatPowerColorOverride: defaultGpColorsByPlayerId);
  }

  final combinedTopology = buildCombinedTopology(
    topologyByRegion: topologyByRegion,
    warpLinks: links,
  );

  gameSetupLog.i('game setup end gameId=${game.id}');
  return GameSetupResult(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
    warpLinks: links,
  );
}

double _resolveInitialMapZoomMultiplier(GameSetupConfig config) {
  final preferred =
      config.preferredInitialMapZoomMultiplier ??
      _kNewCampaignDefaultMapZoomMultiplier;
  return preferred.clamp(_kMapZoomMultiplierMin, _kMapZoomMultiplierMax);
}
