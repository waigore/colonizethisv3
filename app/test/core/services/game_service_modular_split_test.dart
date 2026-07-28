import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/core/services/game_service/game_service_map_cache.dart';

/// #2575 work item 12 — [GameService] library split sanity checks.
void main() {
  suppressLogsForTests();

  group('GameService modular split (Refs #2575, #4117, #4183)', () {
    test('game_service cluster does not import colonizethis_logic barrel', () {
      final gameServiceDir = Directory(
        'lib/core/services/game_service',
      );
      final offenders = <String>[];
      for (final entity in gameServiceDir.listSync(recursive: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final contents = entity.readAsStringSync();
        if (contents.contains("package:colonizethis_logic/colonizethis_logic.dart")) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Use narrow domain imports per #4183 Slice C',
      );
    });

    test('newGameSetupProgressStepCount remains on GameService', () {
      expect(GameService.newGameSetupProgressStepCount, 5);
    });

    test('GameMapData and GameMapCache are importable from de-parted libraries', () {
      expect(GameMapData, isNotNull);
      expect(GameMapCache, isNotNull);
      expect(TurnTraceSession, isNotNull);
    });

    test('map-cache seam loads persisted map data through gameServiceRequireMapData', () async {
      final hiveDir = await Directory.systemTemp.createTemp('ct_gs_modular_');
      addTearDown(() async {
        await Hive.close();
        if (await hiveDir.exists()) {
          await hiveDir.delete(recursive: true);
        }
      });
      Hive.init(hiveDir.path);
      final box = await Hive.openBox<dynamic>('games_modular');
      final service = GameService(box, GameSaveAdapter());
      const gameId = 'modular_map';
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['oldWorld|M1'],
        ],
      );
      const topo = MapTopology(nodes: [], edges: []);
      service.state.adapter.saveMapData(
        box,
        gameId,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      service.state.adapter.save(
        box,
        Game(
          id: gameId,
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
          ),
          players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
        ),
      );

      final cache = gameServiceRequireMapData(service, gameId);
      expect(cache.tileMapByRegion['oldWorld']?.width, 1);
      expect(service.hasMapCacheEntry(gameId), isTrue);
    });

    test('turn-trace session seam seeds via GameServiceState', () async {
      final hiveDir = await Directory.systemTemp.createTemp('ct_gs_trace_');
      addTearDown(() async {
        await Hive.close();
        if (await hiveDir.exists()) {
          await hiveDir.delete(recursive: true);
        }
      });
      Hive.init(hiveDir.path);
      final box = await Hive.openBox<dynamic>('games_trace');
      final service = GameService(
        box,
        GameSaveAdapter(),
        turnTraceEnabled: true,
      );
      service.debugSeedTurnTraceSession('trace_game');
      expect(service.turnTraceSessionCount, 1);
      expect(
        service.state.turnTraceSessionsByGameId['trace_game'],
        isA<TurnTraceSession>(),
      );
    });
  });
}
