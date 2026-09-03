// AppEventHandlerScope debug regiment spawn ACs (Refs #4720 Slice G).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_scope_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugRegimentSpawnAtCapital', () {
    test('returns message when there is no active game', () {
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('spawns regiment into region units and home army', () {
      final game = scopeCapitalProvinceOnlyGame(id: 'g-reg-1');
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'peasant_levies',
        count: 2,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      final next = result.game;
      expect(next, isNotNull);
      final units = next!.worldState.oldWorld.units;
      expect(units, hasLength(2));
      expect(units.every((u) => u.type == 'peasant_levies'), isTrue);
      expect(units.every((u) => u.tileKey == null), isTrue);
      expect(units.every((u) => u.status == UnitStatus.idle), isTrue);
      expect(units.every((u) => u.medals == 0), isTrue);
      expect(units.every((u) => u.currentWork == null), isTrue);
      final homeArmy = next.worldState.armies.singleWhere(
        (a) => a.id == 'army_p1',
      );
      expect(homeArmy.regimentUnitIds, hasLength(2));
      expect(units.every((u) => u.id.startsWith('unit_')), isTrue);
    });

    test('fails on unknown player and keeps state unchanged', () {
      final game = scopeEmptyWorldGame(
        id: 'g-reg-2',
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'unknown',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('unknown player'));
    });

    test('fails on missing capital and keeps state unchanged', () {
      final game = scopeEmptyWorldGame(
        id: 'g-reg-3',
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no capital province'));
    });

    test('fails when matched player is not human', () {
      final game = scopeEmptyWorldGame(
        id: 'g-reg-not-human',
        players: const [
          Player(
            id: 'p2',
            displayName: 'P2',
            isHuman: false,
            capitalProvinceId: 'oldWorld|1',
          ),
        ],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p2',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('is not human'));
    });

    test(
      'fails on malformed capital province id and keeps state unchanged',
      () {
        final game = scopeEmptyWorldGame(
          id: 'g-reg-invalid-capital',
          players: const [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: 'malformed',
            ),
          ],
        );
        const event = SpawnDebugRegimentAtCapitalEvent(
          humanPlayerId: 'p1',
          regimentTypeId: 'peasant_levies',
        );
        final result = applyDebugRegimentSpawnAtCapital(
          currentGame: game,
          event: event,
        );
        expect(result.game, isNull);
        expect(result.message, contains('invalid capital province id'));
      },
    );

    test('fails on unsupported regiment type and keeps state unchanged', () {
      final game = scopeEmptyWorldGame(
        id: 'g-reg-4',
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
          ),
        ],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'unknown',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('unsupported regiment type'));
    });
  });
}
