// init_game orchestration. SPEC/program/init-game-tool.md, game-setup-pipeline.md
// (effective seed, OW vs NW tile-map seeds).

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/hidden_agenda_assignment.dart';
import '../constants.dart';
import '../world/unit_lookup.dart';
import 'effective_setup_seed.dart';
import 'game_setup.dart';
import 'setup_exceptions.dart';
import 'warp_zone_generator.dart';

final _log = packageLogger();
const int _kLockedGreatPowerCount = 6;
const int _kLockedMinorNationCount = 6;
const int _kLockedOldWorldProvinceCount = 60;
const int _kLockedOldWorldContinentCount = 3;
const int _kLockedOldWorldRetryCount = 5;
const List<int> _kLockedOldWorldPartition = [18, 21, 21];

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
  final effectiveConfig = _withLockedOldWorldConfig(config);
  if (effectiveConfig.numProvincesOldWorld < effectiveConfig.greatPowerCount) {
    throw SetupConfigConstraintException(
      code: 'insufficient_old_world_provinces_for_great_powers',
      details:
          'Config requests ${effectiveConfig.numProvincesOldWorld} Old World provinces but '
          '${effectiveConfig.greatPowerCount} Great Powers need at least one each',
    );
  }

  _log.i(
    'init game start OW:${effectiveConfig.numProvincesOldWorld} NW:${effectiveConfig.numProvincesNewWorld}',
  );
  final effectiveSeed = resolveEffectiveSetupSeed(effectiveConfig.seed);

  final mapGenParams = MapGenerationParams(
    numContinents: effectiveConfig.continentCount,
    seed: effectiveSeed,
    seaFraction: kDefaultSeaFraction,
  );
  final gen = generateRegion ?? defaultTileMapRegionGenerator;
  _log.d('init game generating OW map with locked partition retries');
  final (tileMapOW, topoOW) = _generateLockedOldWorldMap(
    options: options,
    effectiveSeed: effectiveSeed,
    generateRegionFn: gen,
  );

  _log.d('init game generating NW map');
  final sizeNW = computeGridSizeFromParams(
    effectiveConfig.numProvincesNewWorld,
    mapGenParams,
  );
  final paramsNW = TileMapParams(
    width: sizeNW.width,
    height: sizeNW.height,
    seed: effectiveSeed + 1,
    seaFraction: kDefaultSeaFraction,
    skipFillLakes: options.skipFillLakes,
  );
  final (tileMapNW, topoNW) = gen(
    params: paramsNW,
    numProvinces: effectiveConfig.numProvincesNewWorld,
    numContinents: effectiveConfig.continentCount.clamp(
      1,
      effectiveConfig.numProvincesNewWorld,
    ),
    regionId: kRegionNewWorld,
    resourceRules: ResourceRules.defaultRules,
  );

  final warpLinks = generateWarpZones(
    tileMapOldWorld: tileMapOW,
    topologyOldWorld: topoOW,
    tileMapNewWorld: tileMapNW,
    topologyNewWorld: topoNW,
    regionIdOld: kRegionOldWorld,
    regionIdNew: kRegionNewWorld,
    seed: effectiveSeed,
  );

  final setupResult = createGameFromGeneratedMaps(
    config: effectiveConfig,
    tileMapOldWorld: tileMapOW,
    topologyOldWorld: topoOW,
    tileMapNewWorld: tileMapNW,
    topologyNewWorld: topoNW,
    gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
    namingSeed: effectiveSeed,
    assignmentPerturbationBase: effectiveSeed,
    warpLinks: warpLinks,
  );

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
        'GP:${effectiveConfig.selectedGreatPowerIds.join(",")} MN:${effectiveConfig.minorNationCount} TR:${effectiveConfig.tribeCount} OW:${effectiveConfig.numProvincesOldWorld} NW:${effectiveConfig.numProvincesNewWorld}',
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

  _log.i('init game end seed=$effectiveSeed gameId=${game.id}');
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

GameSetupConfig _withLockedOldWorldConfig(GameSetupConfig config) {
  final selectedIds =
      config.selectedGreatPowerIds.length == _kLockedGreatPowerCount
      ? config.selectedGreatPowerIds
      : GameSetupConfig.defaultConfig.selectedGreatPowerIds
            .take(_kLockedGreatPowerCount)
            .toList();
  return GameSetupConfig(
    selectedGreatPowerIds: selectedIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    continentCount: _kLockedOldWorldContinentCount,
    minorNationCount: _kLockedMinorNationCount,
    tribeCount: config.tribeCount,
    numProvincesOldWorld: _kLockedOldWorldProvinceCount,
    numProvincesNewWorld: config.numProvincesNewWorld,
    minProvincesPerMinor: 3,
    seed: config.seed,
    startingResources: config.startingResources,
    enforceFairGpOldWorldAssignment: config.enforceFairGpOldWorldAssignment,
    preferredInitialMapZoomMultiplier: config.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: config.initTownRoadWiringRegionIds,
  );
}

(TileMapResult, MapTopology) _generateLockedOldWorldMap({
  required InitGameOptions options,
  required int effectiveSeed,
  required TileMapRegionGenerator generateRegionFn,
}) {
  (TileMapResult, MapTopology)? fallback;
  for (var attempt = 0; attempt <= _kLockedOldWorldRetryCount; attempt++) {
    final attemptSeed = effectiveSeed + attempt;
    final mapGenParams = MapGenerationParams(
      numContinents: _kLockedOldWorldContinentCount,
      seed: attemptSeed,
      seaFraction: kDefaultSeaFraction,
    );
    final sizeOW = computeGridSizeFromParams(
      _kLockedOldWorldProvinceCount,
      mapGenParams,
    );
    final paramsOW = TileMapParams(
      width: sizeOW.width,
      height: sizeOW.height,
      seed: attemptSeed,
      seaFraction: kDefaultSeaFraction,
      skipFillLakes: options.skipFillLakes,
    );
    final (tileMapOW, topoOW) = generateRegionFn(
      params: paramsOW,
      numProvinces: _kLockedOldWorldProvinceCount,
      numContinents: _kLockedOldWorldContinentCount,
      regionId: kRegionOldWorld,
      resourceRules: ResourceRules.defaultRules,
    );
    fallback ??= (tileMapOW, topoOW);
    if (_matchesLockedOldWorldPartition(topoOW)) {
      return (tileMapOW, topoOW);
    }
  }
  _log.w(
    'locked OW partition 21/21/18 not reached in ${_kLockedOldWorldRetryCount + 1} attempts; using deterministic fallback map',
  );
  if (fallback == null) {
    throw SetupTopologyDataException(
      code: 'old_world_partition_retry_exhausted',
      details: 'Old World generation failed before producing a fallback map.',
    );
  }
  return fallback;
}

bool _matchesLockedOldWorldPartition(MapTopology topology) {
  final provinceIds = <String>{
    for (final node in topology.nodes)
      if (node.type == TopologyNodeType.province) node.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinceIds) id: <String>{},
  };
  for (final edge in topology.edges) {
    if (!provinceIds.contains(edge.id1) || !provinceIds.contains(edge.id2)) {
      continue;
    }
    neighbours[edge.id1]!.add(edge.id2);
    neighbours[edge.id2]!.add(edge.id1);
  }
  final componentSizes = <int>[];
  final seen = <String>{};
  final idsSorted = provinceIds.toList()..sort();
  for (final id in idsSorted) {
    if (!seen.add(id)) continue;
    var size = 0;
    final stack = <String>[id];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      size++;
      for (final n in neighbours[current] ?? const <String>{}) {
        if (seen.add(n)) {
          stack.add(n);
        }
      }
    }
    componentSizes.add(size);
  }
  componentSizes.sort();
  return componentSizes.length == _kLockedOldWorldPartition.length &&
      componentSizes[0] == _kLockedOldWorldPartition[0] &&
      componentSizes[1] == _kLockedOldWorldPartition[1] &&
      componentSizes[2] == _kLockedOldWorldPartition[2];
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

  for (final p in game.players) {
    final owned =
        game.worldState.oldWorld.provinces
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
        game.worldState.oldWorld.provinces
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
        game.worldState.newWorld.provinces
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
