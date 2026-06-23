import 'package:colonizethis_app/core/services/app_event_handler_debug_spawn_regiment.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const _regimentType = 'peasant_levies';

Game _gameWith({
  bool isHuman = true,
  String? capitalProvinceId = 'oldWorld|1',
}) {
  return Game(
    id: 'g-regiment',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: isHuman,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  group('applyDebugRegimentSpawnAtCapital', () {
    test('spawns regiments into the capital region bucket', () {
      final game = _gameWith();
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: _regimentType,
        count: 2,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      final next = result.game;
      expect(next, isNotNull);
      expect(next!.worldState.oldWorld.units, hasLength(2));
      expect(
        next.worldState.oldWorld.units.every((u) => u.type == _regimentType),
        isTrue,
      );
      expect(result.message, 'Spawned 2 $_regimentType at P1 capital.');
    });

    test('short-circuits with no active game', () {
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: _regimentType,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: no active game.');
    });

    test('short-circuits on unknown player', () {
      final game = _gameWith();
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'ghost',
        regimentTypeId: _regimentType,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: unknown player ghost.');
    });

    test('short-circuits on non-human player', () {
      final game = _gameWith(isHuman: false);
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: _regimentType,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: player p1 is not human.');
    });

    test('rejects unsupported regiment type', () {
      final game = _gameWith();
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'not_a_regiment',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug spawn ignored: unsupported regiment type not_a_regiment.',
      );
    });

    test('short-circuits when count below minimum', () {
      final game = _gameWith();
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: _regimentType,
        count: 0,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, 'Debug spawn ignored: count must be >= 1.');
    });

    test('short-circuits when player has no capital province', () {
      final game = _gameWith(capitalProvinceId: null);
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: _regimentType,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug spawn ignored: player has no capital province.',
      );
    });
  });
}
