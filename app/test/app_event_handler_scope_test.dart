import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Game gameWithMode(CombatMode mode) {
    return Game(
      id: 'g1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: false),
      ],
      defaultCombatMode: mode,
    );
  }

  group('applyCombatModeChoiceToGame', () {
    test('returns null when there is no active game', () {
      final updated = applyCombatModeChoiceToGame(null, CombatMode.quickBattle);
      expect(updated, isNull);
    });

    test('returns same instance when mode is unchanged', () {
      final game = gameWithMode(CombatMode.quickBattle);
      final updated = applyCombatModeChoiceToGame(game, CombatMode.quickBattle);
      expect(identical(updated, game), isTrue);
    });

    test('updates default combat mode when player picks a new mode', () {
      final game = gameWithMode(CombatMode.autoResolve);
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
      final game = Game(
        id: 'g2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|1',
              x: 2,
              y: 3,
            ),
          ),
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
    });
  });
}
