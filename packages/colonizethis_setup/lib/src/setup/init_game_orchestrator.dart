// init_game orchestration. SPEC/program/init-game-tool.md, game-setup-pipeline.md
// (effective seed, OW vs NW tile-map seeds). Refs #4086 Slice C topic-split.

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'advanced_start_bootstrap.dart';
import 'effective_setup_seed.dart';
import 'format_init_game_setup_markdown.dart';
import 'hidden_agenda_assignment.dart';
import 'init_game_orchestrator_pipelines.dart';
import 'init_game_orchestrator_types.dart';
import 'setup_exceptions.dart';
import 'setup_logging.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

export 'init_game_orchestrator_types.dart';

/// Runs the full game creation process: generate OW+NW maps, create game, render map, format markdown.
/// Returns InitGameResult; does not save the game.
/// When [generateRegion] is null, uses [defaultTileMapRegionGenerator].
InitGameResult runInitGame({
  required GameSetupConfig config,
  InitGameOptions options = const InitGameOptions(),
  TileMapRegionGenerator? generateRegion,
}) {
  if (config.numProvincesOldWorld < config.greatPowerCount) {
    throw SetupConfigConstraintException(
      code: 'insufficient_old_world_provinces_for_great_powers',
      details:
          'Config requests ${config.numProvincesOldWorld} Old World provinces but '
          '${config.greatPowerCount} Great Powers need at least one each',
    );
  }

  for (final slotIndex in config.humanGreatPowerSlotIndices) {
    if (slotIndex < 0 || slotIndex >= config.greatPowerCount) {
      throw SetupConfigConstraintException(
        code: 'human_slot_index_out_of_range',
        details:
            'humanGreatPowerSlotIndices contains $slotIndex but valid Great '
            'Power slot indices are [0, ${config.greatPowerCount})',
      );
    }
  }

  setupLog.i(
    'init game start OW:${config.numProvincesOldWorld} NW:${config.numProvincesNewWorld}',
  );
  final effectiveSeed = resolveEffectiveSetupSeed(config.seed);

  final gen = generateRegion ?? defaultTileMapRegionGenerator;
  final pipelineResult =
      config.isLockedFullInitProfile &&
          identical(gen, defaultTileMapRegionGenerator)
      ? runLockedFullInitPipeline(
          config: config,
          options: options,
          effectiveSeed: effectiveSeed,
        )
      : runFreeformInitPipeline(
          config: config,
          options: options,
          effectiveSeed: effectiveSeed,
          generateRegion: gen,
        );
  final warpLinks = pipelineResult.warpLinks;
  final setupResult = pipelineResult.setupResult;

  var gameForView = applyAdvancedStartBootstrap(
    game: setupResult.game,
    config: config,
    topologyOldWorld: setupResult.topologyByRegion[kRegionOldWorld],
    topologyNewWorld: setupResult.topologyByRegion[kRegionNewWorld],
    warpLinks: warpLinks,
    tileMapByRegion: setupResult.tileMapByRegion,
    topologyByRegion: setupResult.topologyByRegion,
  );

  // Map semantic GP ids from config.selectedGreatPowerIds to runtime Player ids
  // so colour overrides can be keyed by Player.id for map builders and saves.
  final semanticToPlayerId = <String, String>{};
  for (var i = 0; i < gameForView.players.length; i++) {
    if (i >= config.selectedGreatPowerIds.length) break;
    final semanticId = config.selectedGreatPowerIds[i];
    final playerId = gameForView.players[i].id;
    semanticToPlayerId[semanticId] = playerId;
  }

  Map<String, (int r, int g, int b)>? toolGpColorTuples;
  final rawOverride = options.greatPowerColorOverride;
  if (rawOverride != null && rawOverride.isNotEmpty) {
    toolGpColorTuples = <String, (int, int, int)>{};
    rawOverride.forEach((semanticId, rgb) {
      final playerId = semanticToPlayerId[semanticId];
      if (playerId != null) {
        toolGpColorTuples![playerId] = rgb;
      }
    });
    if (toolGpColorTuples.isEmpty) {
      toolGpColorTuples = null;
    }
  }

  final mergedGpColorTuples = <String, (int r, int g, int b)>{};
  final baseOverride = gameForView.greatPowerColorOverride;
  if (baseOverride != null) {
    baseOverride.forEach((playerId, rgb) {
      if (rgb.length >= 3) {
        mergedGpColorTuples[playerId] = (rgb[0], rgb[1], rgb[2]);
      }
    });
  }
  if (toolGpColorTuples != null) {
    mergedGpColorTuples.addAll(toolGpColorTuples);
  }
  final mapColorTuples = mergedGpColorTuples.isEmpty
      ? null
      : mergedGpColorTuples;

  final mapViewData = buildInitGameMapViewData(
    game: gameForView,
    tileMapByRegion: setupResult.tileMapByRegion,
    topologyByRegion: setupResult.topologyByRegion,
    cellSize: options.cellSize,
    seed: effectiveSeed,
    configSummary:
        'GP:${config.selectedGreatPowerIds.join(",")} MN:${config.minorNationCount} TR:${config.tribeCount} OW:${config.numProvincesOldWorld} NW:${config.numProvincesNewWorld}',
    greatPowerColorOverride: mapColorTuples,
    warpLinks: warpLinks,
  );

  final mapPngBytes = options.renderPng
      ? renderInitGameMapToPngFromViewData(viewData: mapViewData)
      : Uint8List(0);

  final markdown = formatInitGameSetupMarkdown(gameForView);

  // Phase 4: set AI seeds and GP colour override for determinism / display
  var game = gameForView;
  final gpColorOverrideList = mapColorTuples?.map(
    (k, v) => MapEntry(k, [v.$1, v.$2, v.$3]),
  );
  game = game.copyWith(
    globalGameSeed: effectiveSeed,
    aiSeedByGpId: {
      for (final p in game.players) p.id: effectiveSeed + p.id.hashCode,
    },
    greatPowerColorOverride: gpColorOverrideList,
  );
  // Phase 6 full AI: populate hidden agendas before first AI order generation. SPEC: game-setup-pipeline.md step 9, ai-planner.md § Phase 6.
  game = assignHiddenAgendasForGame(game);

  setupLog.i('init game end seed=$effectiveSeed gameId=${game.id}');
  return InitGameResult(
    game: game,
    mapPngBytes: mapPngBytes,
    markdown: markdown,
    mapViewData: mapViewData,
    tileMapByRegion: setupResult.tileMapByRegion,
    topologyByRegion: setupResult.topologyByRegion,
    combinedTopology: setupResult.combinedTopology,
    warpLinks: setupResult.warpLinks,
    greatPowerColorOverride: mapColorTuples,
  );
}
