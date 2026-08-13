import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_scope_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyCombatModeChoiceToGame', () {
    test('returns null when there is no active game', () {
      final updated = applyCombatModeChoiceToGame(null, CombatMode.quickBattle);
      expect(updated, isNull);
    });

    test('returns same instance when mode is unchanged', () {
      final game = scopeGameWithCombatMode(CombatMode.quickBattle);
      final updated = applyCombatModeChoiceToGame(game, CombatMode.quickBattle);
      expect(identical(updated, game), isTrue);
    });

    test('updates default combat mode when player picks a new mode', () {
      final game = scopeGameWithCombatMode(CombatMode.autoResolve);
      final updated = applyCombatModeChoiceToGame(game, CombatMode.quickBattle);
      expect(updated, isNotNull);
      expect(updated!.defaultCombatMode, CombatMode.quickBattle);
      expect(updated.id, game.id);
    });
  });

  group('applyDebugCivilianSpawnAtCapital', () {
    test('returns message when there is no active game', () {
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeExplorer,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('spawns requested civilian count at human capital tile', () {
      final game = scopeCivilianCapitalGame(
        id: 'g2',
        extraPlayers: const [
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
        count: 2,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNotNull);
      expect(result.message, contains('Spawned 2 Builder'));
      final units = result.game!.worldState.oldWorld.units;
      expect(units, hasLength(2));
      expect(units.every((u) => u.type == kUnitTypeBuilder), isTrue);
      expect(units.every((u) => u.tileKey == 'oldWorld|1|2|3'), isTrue);
      expect(units.map((u) => u.id).toSet().length, 2);
    });

    test('rejects unsupported unit type', () {
      final game = scopeCivilianCapitalGame(id: 'g3');
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: 'InvalidType',
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNull);
      expect(result.message, contains('unsupported civilian type'));
    });

    test('continues deterministic canonical unit id sequence', () {
      final game = scopeCivilianCapitalGame(
        id: 'g4',
        existingUnits: [
          Unit(
            id: 'unit_7',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: 'oldWorld|1',
            tileKey: 'oldWorld|1|2|3',
          ),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
        count: 2,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      final ids = result.game!.worldState.oldWorld.units
          .map((u) => u.id)
          .toList();
      expect(ids, contains('unit_8'));
      expect(ids, contains('unit_9'));
    });

    test('caps oversized debug spawn count to 25', () {
      final game = scopeCivilianCapitalGame(id: 'g5');
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeExplorer,
        count: 99,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNotNull);
      expect(result.game!.worldState.oldWorld.units, hasLength(25));
      expect(result.message, contains('Spawned 25 Explorer'));
    });

    test('rejects zero or negative count', () {
      final game = scopeCivilianCapitalGame(id: 'g6');
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeExplorer,
        count: 0,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNull);
      expect(result.message, contains('count must be >= 1'));
    });
  });

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
