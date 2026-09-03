// AppEventHandlerScope combat-mode and debug civilian spawn ACs (Refs #4352).
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
}
