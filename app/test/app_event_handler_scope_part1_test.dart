import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/services/debug/app_event_handler_debug_spawn_civilian.dart';
import 'package:colonizethis_app/core/services/debug/app_event_handler_debug_spawn_regiment.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
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
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
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
      expect(units.map((u) => u.id).toSet().length, 2);
    });

    test('rejects unsupported unit type', () {
      final game = Game(
        id: 'g3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
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
        ],
      );
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
      final game = Game(
        id: 'g4',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'unit_7',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|1',
                tileKey: 'oldWorld|1|2|3',
              ),
            ],
          ),
          newWorld: const RegionData(),
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
      final game = Game(
        id: 'g5',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
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
        ],
      );
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
      final game = Game(
        id: 'g6',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
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
        ],
      );
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
      final game = Game(
        id: 'g-reg-1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
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
      final game = Game(
        id: 'g-reg-2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
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
      final game = Game(
        id: 'g-reg-3',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
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
      final game = Game(
        id: 'g-reg-not-human',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
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
        final game = Game(
          id: 'g-reg-invalid-capital',
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
          ),
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
      final game = Game(
        id: 'g-reg-4',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
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
