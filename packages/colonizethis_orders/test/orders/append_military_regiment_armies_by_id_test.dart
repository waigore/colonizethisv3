/// Equivalence + in-place-mutation tests for the optional `armiesById`
/// snapshot threaded into [appendMilitaryRegimentToArmy] (Refs #2394;
/// SPEC/program/order-suggestions.md § Throughput bounds).
///
/// Verifies:
///
/// - The map and scan paths produce identical Game results for both the
///   "append to existing army" and "create new army" branches.
/// - The supplied `armiesById` is mutated in place so subsequent calls
///   observe the just-updated/added army (eliminating the per-recruit
///   `indexWhere` over `worldState.armies`).
/// - A partial map still resolves correctly via the single-pass fallback.
library;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'p1';
  const capProvinceId = 'oldWorld|P1';

  Player buildPlayer() => Player(
        id: playerId,
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capProvinceId,
        stockpile: const Stockpile(),
        workerPool: const WorkerPool(peasants: 10),
        treasury: 10000,
      );

  Game emptyArmyGame() {
    final world = WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: capProvinceId, regionId: 'oldWorld', ownerId: playerId),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    );
    return Game(id: 'g', worldState: world, players: [buildPlayer()]);
  }

  Game gameWithExistingHomeArmy() {
    final existing = Army(
      id: homeArmyIdFor(playerId),
      ownerId: playerId,
      regionId: 'oldWorld',
      stationedProvinceId: capProvinceId,
      regimentUnitIds: const ['u_existing'],
      isHomeArmy: true,
    );
    final world = WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: capProvinceId, regionId: 'oldWorld', ownerId: playerId),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
      armies: [existing],
    );
    return Game(id: 'g', worldState: world, players: [buildPlayer()]);
  }

  group('appendMilitaryRegimentToArmy armiesById equivalence (Refs #2394)', () {
    test('create-new-army path matches with and without armiesById', () {
      final game = emptyArmyGame();
      final viaMap = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
        armiesById: armiesByIdForWorld(game.worldState),
      );
      final viaScan = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
      );

      expect(viaMap.worldState.armies.length, viaScan.worldState.armies.length);
      expect(viaMap.worldState.armies.single.id, viaScan.worldState.armies.single.id);
      expect(
        viaMap.worldState.armies.single.regimentUnitIds,
        viaScan.worldState.armies.single.regimentUnitIds,
      );
      expect(
        viaMap.worldState.armies.single.isHomeArmy,
        viaScan.worldState.armies.single.isHomeArmy,
      );
    });

    test('append-existing-army path matches with and without armiesById', () {
      final game = gameWithExistingHomeArmy();
      final viaMap = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
        armiesById: armiesByIdForWorld(game.worldState),
      );
      final viaScan = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
      );

      expect(viaMap.worldState.armies.length, 1);
      expect(viaScan.worldState.armies.length, 1);
      expect(
        viaMap.worldState.armies.single.regimentUnitIds,
        viaScan.worldState.armies.single.regimentUnitIds,
      );
      expect(
        viaMap.worldState.armies.single.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
    });

    test('mutates armiesById in place when appending to an existing army', () {
      final game = gameWithExistingHomeArmy();
      final armiesById = armiesByIdForWorld(game.worldState);
      final homeArmyId = homeArmyIdFor(playerId);
      expect(armiesById[homeArmyId]!.regimentUnitIds, ['u_existing']);

      final next = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
        armiesById: armiesById,
      );

      expect(
        armiesById[homeArmyId]!.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
      expect(
        next.worldState.armies.single.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
    });

    test('mutates armiesById in place when creating a new army', () {
      final game = emptyArmyGame();
      final armiesById = armiesByIdForWorld(game.worldState);
      expect(armiesById, isEmpty);

      final next = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
        armiesById: armiesById,
      );

      final homeArmyId = homeArmyIdFor(playerId);
      expect(armiesById.containsKey(homeArmyId), isTrue);
      expect(armiesById[homeArmyId]!.regimentUnitIds, ['u_new']);
      expect(next.worldState.armies.single.id, homeArmyId);
    });

    test('multiple recruits with shared map match repeated scan-path runs', () {
      // The shared map must never drift from the canonical world-state-derived
      // behavior; comparing the K-step pipelines exercises this invariant.
      final start = emptyArmyGame();

      var mapGame = start;
      final armiesById = armiesByIdForWorld(start.worldState);
      for (final id in const ['u_a', 'u_b', 'u_c']) {
        mapGame = appendMilitaryRegimentToArmy(
          mapGame,
          start.players.single,
          capProvinceId,
          id,
          armiesById: armiesById,
        );
      }

      var scanGame = start;
      for (final id in const ['u_a', 'u_b', 'u_c']) {
        scanGame = appendMilitaryRegimentToArmy(
          scanGame,
          start.players.single,
          capProvinceId,
          id,
        );
      }

      expect(
        mapGame.worldState.armies.single.regimentUnitIds,
        scanGame.worldState.armies.single.regimentUnitIds,
      );
      expect(
        mapGame.worldState.armies.single.regimentUnitIds,
        ['u_a', 'u_b', 'u_c'],
      );
    });

    test('falls back to single-pass scan when armiesById lacks the entry', () {
      // Partial maps (e.g. built before a recent insertion) must still resolve
      // correctly via the fallback scan instead of forking duplicate armies.
      final game = gameWithExistingHomeArmy();
      final partialMap = <String, Army>{};

      final next = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        capProvinceId,
        'u_new',
        armiesById: partialMap,
      );

      expect(next.worldState.armies.length, 1);
      expect(
        next.worldState.armies.single.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
      expect(
        partialMap[homeArmyIdFor(playerId)]!.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
    });
  });
}
