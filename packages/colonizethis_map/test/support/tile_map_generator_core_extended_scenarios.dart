import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'tile_map_gen_fixtures.dart';
import 'tile_map_generator_core_scenarios.dart';

/// Extended core generator scenarios. Refs #4561.

void expectGenerationParamsMapLog() {
  final capturedEvents = <LogEvent>[];
  addLoggerCaptureTearDown(capturedEvents);

  final params = genParams(
    width: 12,
    height: 9,
    seed: 77,
    seaFraction: 0.55,
    joinContinents: true,
    skipFillLakes: true,
    seedBeforeAssignment: false,
  );
  runTileMapGeneration(
    params: params,
    numProvinces: 3,
    numContinents: 2,
    regionId: 'oldWorld',
    omitResourceRules: true,
  );

  final message = capturedEvents
      .map((e) => e.message.toString())
      .firstWhere((m) => m.contains('map: generation_params'));
  expect(message, contains('regionId=oldWorld'));
  expect(message, contains('numProvinces=3'));
  expect(message, contains('numContinents=2'));
  expect(message, contains('width=12'));
  expect(message, contains('height=9'));
  expect(message, contains('seed=77'));
  expect(message, contains('seaFraction=0.55'));
  expect(message, contains('joinContinents=true'));
  expect(message, contains('skipFillLakes=true'));
  expect(message, contains('seedBeforeAssignment=false'));
}

void expectJoinContinentsCompletesForSmallMultiContinentGrids() {
  for (final seed in [0, 7, 42, 99, 777]) {
    runTileMapGeneration(
      params: genParams(
        width: 20,
        height: 18,
        seed: seed,
      ),
      numProvinces: 6,
      numContinents: 3,
      regionId: 'oldWorld',
    );
  }
}
