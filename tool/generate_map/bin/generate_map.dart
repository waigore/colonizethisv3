// CLI: generate map from province/continent count, infer topology, output tile map and topology graph.
// SPEC/program/map-data.md. Thin facade over colonizethis_map and colonizethis_data.
// Operational/diagnostic output via logger (SPEC/program/ctdev-logging.md); usage and summary to stdout.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

final _log = Logger();

void _errExit(String message) {
  stderr.writeln(message);
  _log.w('map: $message');
  exit(1);
}

const int _defaultProvinces = 60;
const int _defaultContinents = 3;
const int _minContinents = 2;
const int _maxContinents = 4;

void main(List<String> arguments) {
  var interactive = false;
  var withTileMapImage = false;
  String? tileMapImagePath;
  String? topologyGraphPath;
  int? seedOverride;
  String? worldStatePath;
  String? regionOverride;
  int? provincesOverride;
  int? continentsOverride;
  int? tilesPerProvinceOverride;
  double? seaFractionOverride;
  var joinContinents = false;
  var seedBeforeAssignment = false;
  var skipFillLakes = false;
  int? continentBufferOverride;
  int? tileSizeOverride;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      exit(0);
    }
    if (arg == '--interactive') {
      interactive = true;
    } else if (arg == '--tile-map-image') {
      withTileMapImage = true;
    } else if (arg.startsWith('--tile-map-image=')) {
      withTileMapImage = true;
      final path = arg.substring('--tile-map-image='.length).trim();
      tileMapImagePath = path.isEmpty ? null : path;
    } else if (arg == '--topology-graph') {
      topologyGraphPath = '';
    } else if (arg.startsWith('--topology-graph=')) {
      final path = arg.substring('--topology-graph='.length).trim();
      topologyGraphPath = path.isEmpty ? '' : path;
    } else if (arg == '--join-continents') {
      joinContinents = true;
    } else if (arg == '--seed-before-assignment') {
      seedBeforeAssignment = true;
    } else if (arg.startsWith('--seed-before-assignment=')) {
      final v = arg.substring('--seed-before-assignment='.length).trim().toLowerCase();
      seedBeforeAssignment = v == 'true' || v == '1';
    } else if (arg == '--skip-fill-lakes') {
      skipFillLakes = true;
    } else if (arg.startsWith('--skip-fill-lakes=')) {
      final v = arg.substring('--skip-fill-lakes='.length).trim().toLowerCase();
      skipFillLakes = v == 'true' || v == '1';
    } else if (arg == '--continent-buffer' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 0) {
        _errExit('Error: --continent-buffer requires a non-negative integer, got: $value');
      }
      continentBufferOverride = parsed;
    } else if (arg.startsWith('--continent-buffer=')) {
      final value = arg.substring('--continent-buffer='.length).trim();
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 0) {
        _errExit('Error: --continent-buffer requires a non-negative integer, got: $value');
      }
      continentBufferOverride = parsed;
    } else if (arg == '--region' && i + 1 < arguments.length) {
      regionOverride = arguments[++i];
      if (regionOverride != 'oldWorld' && regionOverride != 'newWorld') {
        _errExit('Error: --region must be oldWorld or newWorld, got: $regionOverride');
      }
    } else if (arg.startsWith('--region=')) {
      regionOverride = arg.substring(9).trim();
      if (regionOverride != 'oldWorld' && regionOverride != 'newWorld') {
        _errExit('Error: --region must be oldWorld or newWorld, got: $regionOverride');
      }
    } else if (arg == '--provinces' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        _errExit('Error: --provinces requires a positive integer, got: $value');
      }
      provincesOverride = parsed;
    } else if (arg.startsWith('--provinces=')) {
      final value = arg.substring(12).trim();
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        _errExit('Error: --provinces requires a positive integer, got: $value');
      }
      provincesOverride = parsed;
    } else if (arg == '--continents' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < _minContinents || parsed > _maxContinents) {
        _errExit('Error: --continents must be $_minContinents–$_maxContinents, got: $value');
      }
      continentsOverride = parsed;
    } else if (arg.startsWith('--continents=')) {
      final value = arg.substring(13).trim();
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < _minContinents || parsed > _maxContinents) {
        _errExit('Error: --continents must be $_minContinents–$_maxContinents, got: $value');
      }
      continentsOverride = parsed;
    } else if (arg == '--tiles-per-province' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        _errExit('Error: --tiles-per-province requires a positive integer, got: $value');
      }
      tilesPerProvinceOverride = parsed;
    } else if (arg.startsWith('--tiles-per-province=')) {
      final value = arg.substring('--tiles-per-province='.length).trim();
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        _errExit('Error: --tiles-per-province requires a positive integer, got: $value');
      }
      tilesPerProvinceOverride = parsed;
    } else if (arg == '--sea-fraction' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = double.tryParse(value);
      if (parsed == null || parsed < 0 || parsed >= 1) {
        _errExit('Error: --sea-fraction must be in [0, 1), got: $value');
      }
      seaFractionOverride = parsed;
    } else if (arg.startsWith('--sea-fraction=')) {
      final value = arg.substring('--sea-fraction='.length).trim();
      final parsed = double.tryParse(value);
      if (parsed == null || parsed < 0 || parsed >= 1) {
        _errExit('Error: --sea-fraction must be in [0, 1), got: $value');
      }
      seaFractionOverride = parsed;
    } else if (arg == '--seed' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = int.tryParse(value);
      if (parsed == null) {
        _errExit('Error: --seed requires an integer, got: $value');
      }
      seedOverride = parsed;
    } else if (arg.startsWith('--seed=')) {
      final value = arg.substring(7).trim();
      final parsed = int.tryParse(value);
      if (parsed == null) {
        _errExit('Error: --seed requires an integer, got: $value');
      }
      seedOverride = parsed;
    } else if (arg == '--world-state' && i + 1 < arguments.length) {
      worldStatePath = arguments[++i];
    } else if (arg == '--tile-size' && i + 1 < arguments.length) {
      final value = arguments[++i];
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        _errExit('Error: --tile-size requires a positive integer, got: $value');
      }
      tileSizeOverride = parsed;
    } else if (arg.startsWith('--tile-size=')) {
      final value = arg.substring('--tile-size='.length).trim();
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        _errExit('Error: --tile-size requires a positive integer, got: $value');
      }
      tileSizeOverride = parsed;
    }
  }

  final numProvinces = provincesOverride ?? _defaultProvinces;
  final numContinents = continentsOverride ?? _defaultContinents;
  final   regionId = regionOverride ?? 'oldWorld';
  final seedUsed = seedOverride ?? Random().nextInt(0x7FFFFFFF);

  final mapGenParams = MapGenerationParams(
    targetTilesPerProvince: tilesPerProvinceOverride ?? 35,
    seaFraction: seaFractionOverride ?? 0.6,
    numContinents: numContinents,
    seed: seedUsed,
    joinContinents: joinContinents,
    seedBeforeAssignment: seedBeforeAssignment,
    skipFillLakes: skipFillLakes,
    continentBufferTiles: continentBufferOverride ?? 2,
  );
  final size = computeGridSizeFromParams(numProvinces, mapGenParams);
  final params = TileMapParams(
    width: size.width,
    height: size.height,
    seed: mapGenParams.seed,
    seaFraction: mapGenParams.seaFraction,
    borderNoise: mapGenParams.borderNoise,
    maxEnforceIterations: mapGenParams.maxEnforceIterations,
    clusterShape: mapGenParams.clusterShape,
    voronoiNoiseScale: mapGenParams.voronoiNoiseScale,
    joinContinents: mapGenParams.joinContinents,
    seedBeforeAssignment: mapGenParams.seedBeforeAssignment,
    skipFillLakes: mapGenParams.skipFillLakes,
    continentBufferTiles: mapGenParams.continentBufferTiles,
  );

  _log.i('map: === Map generation ===');
  _log.i('map: Generating map: $numProvinces provinces, $numContinents continents, region $regionId (seed: $seedUsed)');
  stdout.writeln('Generating map: $numProvinces provinces, $numContinents continents, region $regionId (seed: $seedUsed)');
  List<(int x, int y)>? landSeeds;
  List<int>? landSeedContinentIndices;
  List<(int x, int y)>? continentSeeds;
  final (tileMapResult, topology) = TileMapGenerator(params: params).generate(
    numProvinces: numProvinces,
    numContinents: numContinents,
    regionId: regionId,
    resourceRules: ResourceRules.defaultRules,
    onLog: (msg) => _log.i('map: $msg'),
    onLandSeedsPlaced: (s, indices) {
      landSeeds = List.from(s);
      landSeedContinentIndices = List.from(indices);
    },
    onContinentSeedsPlaced: (s) => continentSeeds = List.from(s),
  );

  final tileCounts = computeTileCountsPerRegion(tileMapResult);
  final centroids = computeCentroidsPerRegion(tileMapResult);
  _log.i('map: Tile map seed: $seedUsed');

  if (withTileMapImage) {
    final cellSize = tileSizeOverride;
    final String imagePath;
    if (tileMapImagePath != null && tileMapImagePath.isNotEmpty) {
      final outFile = File(tileMapImagePath);
      writeTileMapImageToFile(
        outFile,
        tileMapResult,
        topology,
        cellSize: cellSize ?? 24,
        landSeedPositions: landSeeds,
        landSeedContinentIndices: landSeedContinentIndices,
        continentSeedPositions: continentSeeds,
      );
      imagePath = outFile.absolute.path;
    } else {
      imagePath = writeTileMapImageToTempFile(
        tileMapResult,
        topology,
        cellSize: cellSize ?? 24,
        landSeedPositions: landSeeds,
        landSeedContinentIndices: landSeedContinentIndices,
        continentSeedPositions: continentSeeds,
      );
    }
    final opened = openInDefaultViewer(imagePath);
    _log.i('map: Tile map image: $imagePath');
    stdout.writeln('Tile map image: $imagePath');
    if (!opened) {
      _log.w('map: Could not open in viewer. Saved to: $imagePath');
    }
  }

  // Topology graph (DOT + PNG when Graphviz installed)
  final dotPath = topologyGraphPath != null
      ? (topologyGraphPath.isEmpty
          ? (withTileMapImage && tileMapImagePath != null
              ? tileMapImagePath.replaceAll(RegExp(r'\.png$'), '_topology.dot')
              : null)
          : topologyGraphPath.endsWith('.dot')
              ? topologyGraphPath
              : '$topologyGraphPath.dot')
      : null;
  final shouldWriteTopologyGraph = withTileMapImage || topologyGraphPath != null;
  if (shouldWriteTopologyGraph) {
    final dotContent = topologyToDot(
      topology,
      tileCounts: tileCounts,
      positions: centroids,
    );
    final dotFile = dotPath ?? _tempDotPath();
    File(dotFile).writeAsStringSync(dotContent);
    _log.i('map: Topology graph (DOT): $dotFile');
    stdout.writeln('Topology graph (DOT): $dotFile');

    try {
      final pngPath = dotFile.replaceAll(RegExp(r'\.dot$'), '.png');
      final proc = Process.runSync('neato', ['-n', '-Tpng', '-o', pngPath, dotFile]);
      if (proc.exitCode == 0) {
        final opened = openInDefaultViewer(pngPath);
        _log.i('map: Topology graph (PNG): $pngPath');
        if (!opened) {
          _log.w('map: Could not open topology graph in viewer. Saved to: $pngPath');
        }
      } else {
        _warnGraphviz();
      }
    } on ProcessException {
      _warnGraphviz();
    }
  }

  Map<String, String?>? ownerByProvinceId;
  if (worldStatePath != null) {
    final wsFile = File(worldStatePath);
    if (!wsFile.existsSync()) {
      _errExit('Error: world state file not found: $worldStatePath');
    }
    final ws = WorldState.fromJson(
      jsonDecode(wsFile.readAsStringSync()) as Map<String, dynamic>,
    );
    ownerByProvinceId = <String, String?>{};
    for (final p in ws.oldWorld.provinces) {
      ownerByProvinceId[p.id] = p.ownerId;
    }
    for (final p in ws.newWorld.provinces) {
      ownerByProvinceId[p.id] = p.ownerId;
    }
  }

  print('=== Topology graph ===');
  print('');
  print(describeTopologyGraph(topology));

  print('=== Map summary ===');
  print('');
  print(formatMapSummary(topology, tileCounts));

  if (interactive) {
    _interactiveLoop(topology, tileCounts, ownerByProvinceId);
  }
}

String _tempDotPath() {
  final tmp = Directory.systemTemp;
  final name = 'topology_${DateTime.now().millisecondsSinceEpoch}.dot';
  return '${tmp.path}/$name';
}

void _warnGraphviz() {
  const msg = 'Warning: Graphviz not installed; run `brew install graphviz` to render topology graph to PNG.';
  stderr.writeln(msg);
  _log.w('map: $msg');
}

void _printUsage() {
  print('Usage:');
  print('  melos run generate_map -- [options]');
  print('');
  print('Generates a tile map from province and continent count, infers topology, outputs graph description, map summary, tile map PNG, and topology graph (DOT; PNG when Graphviz installed).');
  print('');
  print('Options:');
  print('  --provinces N       Number of provinces (default: $_defaultProvinces)');
  print('  --continents M      Number of continents $_minContinents–$_maxContinents (default: $_defaultContinents)');
  print('  --tiles-per-province N  Average land tiles per province for grid sizing (default: 35)');
  print('  --sea-fraction F    Sea fraction 0–1 for grid sizing, e.g. 0.6 for 60:40 sea:land (default: 0.6)');
  print('  --region oldWorld|newWorld  Region type (default: oldWorld)');
  print('  --interactive       Prompt for province id and show detail (q to quit)');
  print('  --tile-map-image[=path]  Export tile map as PNG');
  print('  --tile-size N           Pixels per tile/cell in PNG (default: 24)');
  print('  --topology-graph[=path]  Export topology as DOT (and PNG when Graphviz installed)');
  print('  --seed <n>          Seed for map generation');
  print('  --world-state <path>  Load world state JSON for owner in province detail');
  print('  --join-continents   Enable join step (Pass 10) (default: off)');
  print('  --seed-before-assignment  Use legacy land assignment (default: off)');
  print('  --skip-fill-lakes  Skip Pass 4 (fill lakes); default off');
  print('  --continent-buffer N  Min sea tiles between continents (default: 2)');
}

void _interactiveLoop(
  MapTopology topology,
  Map<String, int>? tileCounts,
  Map<String, String?>? ownerByProvinceId,
) {
  final counts = tileCounts ?? {};
  print('=== Provinces (interactive) ===');
  final list = getProvinceListForInteractive(topology, counts);
  for (final e in list) {
    print('  ${e.id}  region: ${e.regionId}  tiles: ${e.tileCount}');
  }
  print('');
  while (true) {
    stdout.write('Province id (or q to quit): ');
    final raw = stdin.readLineSync();
    final String line = (raw ?? '').trim();
    if (line.isEmpty) continue;
    if (line.toLowerCase() == 'q') break;
    final detail = formatProvinceDetail(
      line,
      topology,
      tileCount: counts[line],
      ownerId: ownerByProvinceId?[line],
    );
    print(detail);
    print('');
  }
}
