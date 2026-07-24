import 'package:colonizethis_app/core/services/debug/app_event_handler_debug_spawn_civilian.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'debug_handler_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugCivilianSpawnAtCapital', () {
    test('spawns civilians into the capital region bucket', () {
      final game = buildDebugHandlerCapitalGame(id: 'g-civilian');
      final event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
        count: 3,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      final next = result.game;
      expect(next, isNotNull);
      expect(next!.worldState.oldWorld.units, hasLength(3));
      expect(
        next.worldState.oldWorld.units.every((u) => u.type == kUnitTypeBuilder),
        isTrue,
      );
      expect(result.message, 'Spawned 3 $kUnitTypeBuilder at P1 capital.');
    });

    test('short-circuits with no active game', () {
      final event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: no active game.');
    });

    test('short-circuits on unknown player', () {
      final game = buildDebugHandlerCapitalGame(id: 'g-civilian');
      final event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'ghost',
        unitType: kUnitTypeBuilder,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: unknown player ghost.');
    });

    test('rejects unsupported civilian type', () {
      final game = buildDebugHandlerCapitalGame(id: 'g-civilian');
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: 'not_a_civilian',
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug spawn ignored: unsupported civilian type not_a_civilian.',
      );
    });

    test('short-circuits when count below minimum', () {
      final game = buildDebugHandlerCapitalGame(id: 'g-civilian');
      final event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
        count: 0,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: count must be >= 1.');
    });
  });
}
