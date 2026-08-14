import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_setup_context.dart';
import 'game_setup_create_initial_game.dart';
import 'game_setup_create_ownership.dart';
import 'game_setup_create_post_ownership.dart';

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
  final ownership = assignInitialOwnership(
    config: config,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
  );
  final oldWorldProvinces = ownership.oldWorldProvinces;
  final newWorldProvinces = ownership.newWorldProvinces;
  final gpIds = ownership.gpIds;
  final minorIds = ownership.minorIds;
  final tribeIds = ownership.tribeIds;
  final game = buildInitialGame(
    config: config,
    gameId: gameId,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    initialMapZoomMultiplier: initialMapZoomMultiplier,
  );

  final phased = applyPostOwnershipSetupPhases(
    game: game,
    config: config,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    perturbBase: perturbBase,
    namingSeed: namingSeed ?? config.seed,
    links: links,
  );

  gameSetupLog.i('game setup end gameId=${phased.game.id}');
  return GameSetupResult(
    game: phased.game,
    tileMapByRegion: phased.tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: phased.combinedTopology,
    warpLinks: links,
  );
}

double _resolveInitialMapZoomMultiplier(GameSetupConfig config) {
  final preferred =
      config.preferredInitialMapZoomMultiplier ??
      _kNewCampaignDefaultMapZoomMultiplier;
  return preferred.clamp(_kMapZoomMultiplierMin, _kMapZoomMultiplierMax);
}
