import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'tile_map_gen_fixtures.dart';

/// Shared helpers for `tile_map_generator_core_test.dart`.
/// Refs #4297 wave-5 test densify.

void expectAllCellsHaveValidTopologyIds(
  TileMapResult result,
  MapTopology topology,
) {
  final validIds = topology.nodes.map((n) => n.id).toSet();
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      expect(
        validIds.contains(result.cell(x, y)),
        isTrue,
        reason: 'cell ($x,$y) has id ${result.cell(x, y)}',
      );
    }
  }
}

int countLandCells(TileMapResult result, int width, int height) {
  var landCount = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
    }
  }
  return landCount;
}

void expectStandardPassLogLines(List<String> logLines) {
  for (final pass in [
    'Pass 1',
    'Pass 2',
    'Pass 3',
    'Pass 4',
    'Pass 5',
    'Pass 6',
    'Pass 8',
    'Pass 9',
    'Pass 11',
  ]) {
    expect(logLines.any((s) => s.contains(pass)), isTrue);
  }
}

MapTopology runLandBridgeRegressionGeneration() {
  final mapGenParams = MapGenerationParams(
    seed: 125148772,
    numContinents: 3,
    continentBufferTiles: 2,
    skipFillLakes: false,
  );
  final size = computeGridSizeFromParams(60, mapGenParams);
  final params = genParams(
    width: size.width,
    height: size.height,
    seed: mapGenParams.seed,
    seaFraction: mapGenParams.seaFraction,
    continentBufferTiles: mapGenParams.continentBufferTiles,
    skipFillLakes: mapGenParams.skipFillLakes,
  );
  final (_, topology) = runTileMapGeneration(
    params: params,
    numProvinces: 60,
    numContinents: 3,
    regionId: 'oldWorld',
  );
  return topology;
}

bool topologyHasProvinceEdge(MapTopology topology, String provinceA, String provinceB) {
  final key = provinceA.compareTo(provinceB) < 0
      ? '$provinceA|$provinceB'
      : '$provinceB|$provinceA';
  return topology.edges.any((e) {
    final edgeKey = e.id1.compareTo(e.id2) < 0
        ? '${e.id1}|${e.id2}'
        : '${e.id2}|${e.id1}';
    return edgeKey == key;
  });
}

void addLoggerCaptureTearDown(List<LogEvent> captured) {
  void listener(LogEvent event) => captured.add(event);
  Logger.addLogListener(listener);
  addTearDown(() => Logger.removeLogListener(listener));
}

TileMapGenerator coreTestGenerator({required int width, required int height}) {
  return TileMapGenerator(params: genParams(width: width, height: height));
}
