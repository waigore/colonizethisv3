// ignore_for_file: avoid_print
/// CLI: load a region topology and describe it (graph, map summary, optional interactive province detail).
/// SPEC/program/map-data.md. Thin facade over colonizethis_data; logic lives in the library.
import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main(List<String> arguments) {
  String? topologyPath;
  var interactive = false;
  var withTileMap = false;
  var withTileMapImage = false;
  String? tileMapImagePath;
  String? worldStatePath;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--interactive') {
      interactive = true;
    } else if (arg == '--tile-map') {
      withTileMap = true;
    } else if (arg == '--tile-map-image') {
      withTileMapImage = true;
    } else if (arg.startsWith('--tile-map-image=')) {
      withTileMapImage = true;
      tileMapImagePath = arg.substring('--tile-map-image='.length).trim();
      if (tileMapImagePath.isEmpty) tileMapImagePath = null;
    } else if (arg == '--world-state' && i + 1 < arguments.length) {
      worldStatePath = arguments[++i];
    } else if (!arg.startsWith('--')) {
      topologyPath = arg;
    }
  }

  if (topologyPath == null || topologyPath.isEmpty) {
    _printUsage();
    exit(64);
  }

  final file = File(topologyPath);
  if (!file.existsSync()) {
    print('Error: file not found: $topologyPath');
    exit(1);
  }

  final topology = MapTopology.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );

  TileMapResult? tileMapResult;
  Map<String, int>? tileCounts;
  if (withTileMap || withTileMapImage) {
    final params = TileMapParams(width: 64, height: 48, seed: 0);
    final result = TileMapGenerator(params: params).generate(topology);
    tileMapResult = result;
    tileCounts = computeTileCountsPerRegion(result);
  }

  if (withTileMapImage && tileMapResult != null) {
    final String imagePath;
    if (tileMapImagePath != null) {
      final outFile = File(tileMapImagePath);
      writeTileMapImageToFile(outFile, tileMapResult, topology);
      imagePath = outFile.absolute.path;
    } else {
      imagePath = writeTileMapImageToTempFile(tileMapResult, topology);
    }
    final opened = openInDefaultViewer(imagePath);
    print('Tile map image: $imagePath');
    if (!opened) {
      print('Could not open in viewer. Saved to: $imagePath');
    }
  }

  Map<String, String?>? ownerByProvinceId;
  if (worldStatePath != null) {
    final wsFile = File(worldStatePath);
    if (!wsFile.existsSync()) {
      print('Error: world state file not found: $worldStatePath');
      exit(1);
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

  if (tileCounts != null) {
    print('=== Map summary ===');
    print('');
    print(formatMapSummary(topology, tileCounts));
  }

  if (interactive) {
    _interactiveLoop(topology, tileCounts, ownerByProvinceId);
  }
}

void _printUsage() {
  print('Usage: dart run bin/describe_topology.dart <path_to_topology.json> [options]');
  print('Options:');
  print('  --interactive     Prompt for province id and show detail (q to quit)');
  print('  --tile-map       Generate tile map and show map summary');
  print('  --tile-map-image[=path]  Export tile map as PNG (legend included); open in viewer or save to path/temp');
  print('  --world-state <path>  Load world state JSON for owner in province detail');
  print('');
  print('Example topology JSON:');
  print('''
{
  "nodes": [
    {"id": "p1", "regionId": "oldWorld", "type": "province"},
    {"id": "p2", "regionId": "oldWorld", "type": "province"},
    {"id": "s1", "regionId": "oldWorld", "type": "seaZone"}
  ],
  "edges": [["p1", "p2"], ["p1", "s1"]]
}
''');
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
