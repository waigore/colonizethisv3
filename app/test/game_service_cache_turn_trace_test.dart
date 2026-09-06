// Turn-trace export branch for GameService cache tests (#4734 Slice J).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ct_app_test_hive_trace_');
    box = await openAppTestHiveBox(
      suiteId: 'game_service_cache_trace',
      directory: hiveDir,
      boxName: 'games_cache_trace',
    );
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  test(
    'runTurnResolution exports merged turn trace when debug trace is enabled',
    () async {
      final traceRoot = await Directory.systemTemp.createTemp(
        'ct_turn_trace_app_',
      );
      addTearDown(() async {
        if (await traceRoot.exists()) {
          await traceRoot.delete(recursive: true);
        }
      });
      final traceService = GameService(
        box,
        GameSaveAdapter(),
        turnTraceEnabled: true,
        turnTraceRootDirectory: traceRoot.path,
      );
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final game = traceService.createNewGame(
        id: 'trace_app_game',
        config: config,
      );
      final aiEnabledGame = game.copyWith(
        aiControlByGpId: {for (final player in game.players) player.id: true},
      );

      final result = traceService.runTurnResolution(
        aiEnabledGame,
        orders: const Orders(),
      );
      expect(result, isA<TurnResolutionComplete>());

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final traceDir = Directory('${traceRoot.path}/turn-traces/${game.id}');
      expect(await traceDir.exists(), isTrue);
      final files = traceDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      expect(files.length, 1);
      final payload =
          jsonDecode(await files.single.readAsString()) as Map<String, dynamic>;
      expect(payload['schemaVersion'], 'v1');
      final meta = payload['meta'] as Map<String, dynamic>;
      expect(meta['source'], 'app');
      expect(meta['traceEnabled'], isTrue);
      final phases =
          ((payload['turnResolution'] as Map<String, dynamic>)['phases']
              as List<dynamic>);
      expect(phases, isNotEmpty);
      final ai = payload['ai'] as List<dynamic>;
      expect(ai, isNotEmpty);
      final firstAi = ai.first as Map<String, dynamic>;
      expect(firstAi['factionId'], isNotEmpty);
      expect(firstAi['state'], isA<Map<String, dynamic>>());
      expect(firstAi['thresholds'], isA<Map<String, dynamic>>());
      expect(firstAi['outcome'], isA<Map<String, dynamic>>());
    },
  );
}
