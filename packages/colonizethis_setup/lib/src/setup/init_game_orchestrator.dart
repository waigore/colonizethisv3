// init_game orchestration. SPEC/program/init-game-tool.md, game-setup-pipeline.md
// (effective seed, OW vs NW tile-map seeds).

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'setup_logging.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'hidden_agenda_assignment.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_constants.dart';
import 'effective_setup_seed.dart';
import 'game_setup.dart';
import 'setup_exceptions.dart';
import 'warp_zone_generator.dart';

/// Result of running init game.
class InitGameResult {
  const InitGameResult({
    required this.game,
    required this.mapPngBytes,
    required this.markdown,
    required this.mapViewData,
    required this.tileMapByRegion,
    required this.topologyByRegion,
    required this.combinedTopology,
    this.warpLinks = const [],
    this.greatPowerColorOverride,
  });

  final Game game;
  final Uint8List mapPngBytes;
  final String markdown;
  final InitGameMapViewData mapViewData;

  /// Tile maps per region (e.g. 'oldWorld', 'newWorld'); needed for extraction.
  final Map<String, TileMapResult> tileMapByRegion;

  /// Topology per region; used by visualizers and debug tooling.
  final Map<String, MapTopology> topologyByRegion;

  /// Single topology with prefixed node ids and warp edges for resolveTurnForGame.
  final MapTopology combinedTopology;

  /// Warp zone links between OW and NW. SPEC/game/map-topology.md.
  final List<WarpLink> warpLinks;

  /// GP id → (r, g, b) used for map view; ctdev uses this when rebuilding view data.
  final Map<String, (int r, int g, int b)>? greatPowerColorOverride;
}

/// Options for runInitGame.
class InitGameOptions {
  const InitGameOptions({
    this.cellSize = 24,
    this.skipFillLakes = false,
    this.renderPng = true,
    this.greatPowerColorOverride,
  });

  final int cellSize;

  /// When true, forward skipFillLakes to TileMapParams so Pass 4 (fill lakes)
  /// is skipped in tile-map generation for both Old World and New World.
  final bool skipFillLakes;

  /// When false, skips PNG rendering inside runInitGame; mapViewData and
  /// markdown are still produced.
  final bool renderPng;

  /// Optional GP id → (r, g, b) for map ownership colours; stored on Game and in result.
  final Map<String, (int r, int g, int b)>? greatPowerColorOverride;
}

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
      ? _runLockedFullInitPipeline(
          config: config,
          options: options,
          effectiveSeed: effectiveSeed,
        )
      : _runFreeformInitPipeline(
          config: config,
          options: options,
          effectiveSeed: effectiveSeed,
          generateRegion: gen,
        );
  final warpLinks = pipelineResult.warpLinks;
  final setupResult = pipelineResult.setupResult;

  // Map semantic GP ids from config.selectedGreatPowerIds to runtime Player ids
  // so colour overrides can be keyed by Player.id for map builders and saves.
  final semanticToPlayerId = <String, String>{};
  for (var i = 0; i < setupResult.game.players.length; i++) {
    if (i >= config.selectedGreatPowerIds.length) break;
    final semanticId = config.selectedGreatPowerIds[i];
    final playerId = setupResult.game.players[i].id;
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
  final baseOverride = setupResult.game.greatPowerColorOverride;
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
    game: setupResult.game,
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

  final markdown = formatInitGameSetupMarkdown(setupResult.game);

  // Phase 4: set AI seeds and GP colour override for determinism / display
  var game = setupResult.game;
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

({List<WarpLink> warpLinks, GameSetupResult setupResult})
_runLockedFullInitPipeline({
  required GameSetupConfig config,
  required InitGameOptions options,
  required int effectiveSeed,
}) {
  setupLog.d(
    'init game generating OW+NW maps (locked partition + setup retries)',
  );
  const maxPipelineAttempts = 64;
  for (var pipelineTry = 0; pipelineTry < maxPipelineAttempts; pipelineTry++) {
    final mapSeed = effectiveSeed + pipelineTry * 100003;
    try {
      final locked = generateLockedFullInitTileMapPair(
        config: config,
        effectiveSeed: mapSeed,
        skipFillLakes: options.skipFillLakes,
        onLog: setupLog.d,
      );
      final warpLinks = generateWarpZones(
        tileMapOldWorld: locked.tileOw,
        topologyOldWorld: locked.topoOw,
        tileMapNewWorld: locked.tileNw,
        topologyNewWorld: locked.topoNw,
        regionIdOld: kRegionOldWorld,
        regionIdNew: kRegionNewWorld,
        seed: mapSeed,
      );
      final setupResult = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: locked.tileOw,
        topologyOldWorld: locked.topoOw,
        tileMapNewWorld: locked.tileNw,
        topologyNewWorld: locked.topoNw,
        gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
      return (warpLinks: warpLinks, setupResult: setupResult);
    } on MapPartitionGatesExhaustedException catch (e) {
      if (pipelineTry < maxPipelineAttempts - 1) {
        setupLog.w(
          'logic: locked full-init partition gates exhausted at '
          'pipelineTry=$pipelineTry; bumping mapSeed (details=$e)',
        );
        continue;
      }
      throw SetupTopologyDataException(
        code: MapPartitionGatesExhaustedException.codeValue,
        details: e.toString(),
      );
    } on SetupTopologyDataException catch (e, st) {
      final retriableTopology =
          e.code == 'assigner_exhausted' ||
          e.code == 'faction_component_bin_pack_failed' ||
          e.code == 'assignment_remainder_not_connected';
      if (retriableTopology && pipelineTry < maxPipelineAttempts - 1) {
        setupLog.w(
          'logic: locked full-init setup topology retry at pipelineTry=$pipelineTry '
          '(code=${e.code}; regenerating maps mapSeed=$mapSeed)',
        );
        continue;
      }
      setupLog.e(
        'logic: locked full-init setup failed: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        'Locked full-init pipeline exhausted after $maxPipelineAttempts '
        'map+setup attempts',
  );
}

({List<WarpLink> warpLinks, GameSetupResult setupResult})
_runFreeformInitPipeline({
  required GameSetupConfig config,
  required InitGameOptions options,
  required int effectiveSeed,
  required TileMapRegionGenerator generateRegion,
}) {
  const maxFreeformAttempts = 64;
  for (var attempt = 0; attempt < maxFreeformAttempts; attempt++) {
    final mapSeed = effectiveSeed + attempt * 100003;
    try {
      final mapGenParams = MapGenerationParams(
        numContinents: config.continentCount,
        seed: mapSeed,
        seaFraction: kDefaultSeaFraction,
      );
      final sizeOW = computeGridSizeFromParams(
        config.numProvincesOldWorld,
        mapGenParams,
      );
      final paramsOW = TileMapParams(
        width: sizeOW.width,
        height: sizeOW.height,
        seed: mapSeed,
        seaFraction: kDefaultSeaFraction,
        skipFillLakes: options.skipFillLakes,
      );
      setupLog.d(
        'init game generating OW map (freeform attempt=$attempt mapSeed=$mapSeed)',
      );
      final ow = generateRegion(
        params: paramsOW,
        numProvinces: config.numProvincesOldWorld,
        numContinents: config.continentCount,
        regionId: kRegionOldWorld,
        resourceRules: ResourceRules.defaultRules,
      );

      setupLog.d('init game generating NW map');
      final sizeNW = computeGridSizeFromParams(
        config.numProvincesNewWorld,
        mapGenParams,
      );
      final paramsNW = TileMapParams(
        width: sizeNW.width,
        height: sizeNW.height,
        seed: mapSeed + 1,
        seaFraction: kDefaultSeaFraction,
        skipFillLakes: options.skipFillLakes,
      );
      final nw = generateRegion(
        params: paramsNW,
        numProvinces: config.numProvincesNewWorld,
        numContinents: config.continentCount.clamp(
          1,
          config.numProvincesNewWorld,
        ),
        regionId: kRegionNewWorld,
        resourceRules: ResourceRules.defaultRules,
      );
      final warpLinks = generateWarpZones(
        tileMapOldWorld: ow.$1,
        topologyOldWorld: ow.$2,
        tileMapNewWorld: nw.$1,
        topologyNewWorld: nw.$2,
        regionIdOld: kRegionOldWorld,
        regionIdNew: kRegionNewWorld,
        seed: mapSeed,
      );
      final setupResult = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: ow.$1,
        topologyOldWorld: ow.$2,
        tileMapNewWorld: nw.$1,
        topologyNewWorld: nw.$2,
        gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
      return (warpLinks: warpLinks, setupResult: setupResult);
    } on SetupTopologyDataException catch (e, st) {
      final retriableTopology =
          e.code == 'assigner_exhausted' ||
          e.code == 'faction_component_bin_pack_failed' ||
          e.code == 'assignment_remainder_not_connected';
      if (retriableTopology && attempt < maxFreeformAttempts - 1) {
        setupLog.w(
          'logic: freeform init topology retry at attempt=$attempt '
          '(code=${e.code}; mapSeed=$mapSeed)',
        );
        continue;
      }
      setupLog.e(
        'logic: freeform init setup failed: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        'Freeform init pipeline exhausted after $maxFreeformAttempts '
        'map+setup attempts',
  );
}

/// Formats faction setup and starting state as markdown tables.
String formatInitGameSetupMarkdown(Game game) {
  final buf = StringBuffer();
  buf.writeln('# Game Setup');
  buf.writeln();
  buf.writeln('## Faction Setup');
  buf.writeln();
  buf.writeln('| Faction | Type | Capital Province | Provinces Owned |');
  buf.writeln('|---------|------|------------------|-----------------|');

  final oldWorldProvinces = game.worldState.provincesForRegion(kRegionOldWorld);
  final newWorldProvinces = game.worldState.provincesForRegion(kRegionNewWorld);
  for (final p in game.players) {
    final owned =
        oldWorldProvinces
            .where((pr) => pr.ownerId == p.id)
            .map((pr) => pr.id)
            .toList()
          ..sort();
    final capital = p.capitalProvinceId ?? '—';
    buf.writeln(
      '| ${p.displayName} (${p.id}) | Great Power | $capital | ${owned.join(", ")} |',
    );
  }
  for (final m in game.minorNations) {
    final owned =
        oldWorldProvinces
            .where((pr) => pr.ownerId == m.id)
            .map((pr) => pr.id)
            .toList()
          ..sort();
    final capital = m.capitalProvinceId ?? '—';
    buf.writeln(
      '| ${m.displayName ?? m.id} (${m.id}) | Minor Nation | $capital | ${owned.join(", ")} |',
    );
  }
  for (final t in game.tribes) {
    final owned =
        newWorldProvinces
            .where((pr) => pr.ownerId == t.id)
            .map((pr) => pr.id)
            .toList()
          ..sort();
    final capital = t.capitalProvinceId ?? '—';
    buf.writeln(
      '| ${t.displayName ?? t.id} (${t.id}) | Tribe | $capital | ${owned.join(", ")} |',
    );
  }

  buf.writeln();
  buf.writeln('## Faction Starting State');
  buf.writeln();
  buf.writeln('| Faction | Stockpile | Workers | Treasury | Units |');
  buf.writeln('|---------|-----------|---------|----------|-------|');

  for (final p in game.players) {
    final stock = p.stockpile.quantities.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final workers =
        '${p.workerPool.peasants}p/${p.workerPool.apprentices}a/${p.workerPool.journeymen}j/${p.workerPool.masters}m';
    final units = allUnitsFromWorld(
      game.worldState,
    ).where((u) => u.ownerId == p.id).length;
    buf.writeln(
      '| ${p.displayName} (${p.id}) | ${stock.isEmpty ? "—" : stock} | $workers | ${p.treasury} | $units |',
    );
  }
  for (final m in game.minorNations) {
    buf.writeln('| ${m.displayName ?? m.id} (${m.id}) | — | — | — | — |');
  }
  for (final t in game.tribes) {
    buf.writeln('| ${t.displayName ?? t.id} (${t.id}) | — | — | — | — |');
  }

  return buf.toString();
}
